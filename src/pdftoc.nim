# -*- encoding: utf-8 -*-

import std/os
import std/osproc
import std/tempfiles
import std/strutils
import std/strformat

import therapist

const NimblePkgVersion {.strdefine.} = "Unknown"
const VERSION = NimblePkgVersion
const LICENSE_TEXT = staticread(joinPath("..", "LICENSE.md"))

const MAX_NEST_LEVEL = 20

type
  Entry = ref object
    page : int
    name : string
    level : int


func countSpaces(s: string): int =
  result = 0
  while (result < len(s)) and s[result] == ' ':
    inc(result)


proc newEntry(strippedLine: string, level: int): Entry =
  assert len(strippedLine) > 1
  var startNum = len(strippedLine) - 1
  while (startNum > 0) and (isdigit(strippedLine[startNum])):
    dec(startNum)

  inc(startNum)

  try:
    let page = parseInt(strippedLine[startNum..<len(strippedLine)])
    return Entry(page: page, name: strip(strippedLine[0..<startNum]), level: level)
  except ValueError:
    stderr.writeLine("error, missing page number in line '", strippedLine, "'")
    quit(1)


proc processInput(inputFileName : string): seq[Entry] =
  var indentStack = newSeqOfCap[int](MAX_NEST_LEVEL)
  indentStack.add(0)

  var inputFile = if inputFileName != "":
                    open(inputFileName, fmRead)
                  else:
                    stdin

  defer:
    if inputFile != stdin:
      inputFile.close()

  try:
    while true:
      let curLine = readline(inputFile)
      let cur_indent = countSpaces(curLine)

      let stripped = curLine.strip()
      if stripped == "":
        continue

      if cur_indent > indentStack[^1]:
        indentStack.add(cur_indent)
      elif cur_indent < indentStack[^1]:
        while (len(indentStack) > 0) and (cur_indent < indentStack[^1]):
          discard indentStack.pop()

        assert len(indentStack) > 0
        assert indentStack[^1] == cur_indent

      result.add(newEntry(strippedLine = stripped, level = len(indentStack)))
  except EOFError:
    discard


proc printPdfTk(entries: seq[Entry], outputIndexFilePath: string) =
  var outf = open(outputIndexFilePath, fmWrite)
  defer:
    outf.close()

  for entry in entries:
    outf.write "BookmarkBegin\n"
    outf.write "BookmarkTitle: ", entry.name, "\n"
    outf.write "BookmarkLevel: ", entry.level, "\n"
    outf.write "BookmarkPageNumber: ", entry.page, "\n"


proc printDjvu(entries: seq[Entry], outputIndexFilePath: string) =

  proc indent(level: int) =
    const INDENT_SPACES = 2
    stdout.write repeat(' ', level * INDENT_SPACES)

  func escapeDjvu(s: string): string =
    result = multiReplace(s, ("\"", "\\\""))

  var outf = open(outputIndexFilePath, fmWrite)
  defer:
    outf.close()

  outf.write "(bookmarks\n"

  for idx in 0..<len(entries):
    let entry = entries[idx]

    indent(entry.level)
    outf.write "(\"", escapeDjvu(entry.name), "\" \"#", entry.page, '\"'

    if idx + 1 < len(entries):
      if entries[idx + 1].level <= entry.level:
        outf.write ")\n"
      else:
        outf.write '\n'

      for j in countdown(entry.level - 1, entries[idx + 1].level):
        indent(j)
        outf.write ")\n"
    else:
      outf.write ")\n"

  outf.write ")\n"


let help = """
Add a set of bookmarks to a PDF or DJVU file

Usage:
    pdftoc pdftk <input> <output>
    pdftoc djvu <input> <output>
    pdftoc help
    pdftoc version

Commands:
    pdftk     Use `pdftk` to add the bookmarks to a PDF file
    djvu      Use `djvused` to add the bookmarks to a DJVU file
    help      Print this help
    version   Print version information
"""

let pdftk = (
  pdftkPath: newFileArg(@["--pdftk-path"], help = "Path to `pdftk`"),
  inputPdfFile: newFileArg(@["<input_pdf>"], help = "Path to the input PDF file to process"),
  indexFile: newFileArg(@["<index_file>"], help = "Text file containing the bookmarks"),
  outputPdfFile: newStringArg(@["<output_pdf>"], help = "Path to the output PDF file that will be created"),
  help: newHelpArg(@["-h", "--help"]),
)

let djvu = (
  djvusedPath: newFileArg(@["--djvused-path"], help = "Path to `djvused`"),
  inputDjvuFile: newFileArg(@["<input_djvu>"], help = "Path to the input DJVU file to process"),
  indexFile: newFileArg(@["<index_file>"], help = "Text file containing the bookmarks"),
  outputDjvuFile: newStringArg(@["<output_djvu>"], help = "Path to the output DJVU file that will be created"),
  help: newHelpArg(@["-h", "--help"]),
)

let spec = (
  pdftk: newCommandArg(@["pdftk"], pdftk, help="Use `pdftk` to add the bookmarks to a PDF file"),
  djvu: newCommandArg(@["djvu"], djvu, help = "Use `djvused` to add bookmarks to a DJVU file"),
  version: newMessageArg(@["-v", "--version"], VERSION, help = "Print version information"),
  license: newMessageArg(@["--license"], LICENSE_TEXT, help = "Print license information"),
  help: newHelpArg(@["-h", "--help"], help = "Print this help"),
)

proc main() =
  spec.parseOrHelp(prolog = "Add a set of bookmarks to a PDF or DJVU file")

  if spec.pdftk.seen:
    let entries = processInput(pdftk.indexFile.value)
    let pdftkScriptFile = genTempPath(prefix = "pdftk", suffix = ".idx")
    let executable = if pdftk.pdftkPath.value != "":
                       pdftk.pdftkPath.value
                     else:
                       "pdftk"

    printPdfTk(entries, pdftkScriptFile)
    defer:
      os.removeFile(pdftkScriptFile)

    let result = osproc.execCmd(&""""{executable}" "{pdftk.inputPdfFile.value}" update_info_utf8 {pdftkScriptFile} output "{pdftk.outputPdfFile.value}"""")
    if result != 0:
      quit 2
  elif spec.djvu.seen:
    let entries = processInput(djvu.indexFile.value)
    let djvuScriptFile = genTempPath(prefix = "djvused", suffix = ".idx")
    let executable = if djvu.djvusedPath.value != "":
                       djvu.djvusedPath.value
                     else:
                       "djvused"

    printDjvu(entries, djvuScriptFile)
    defer:
      os.removeFile(djvuScriptFile)

    os.copyFile(source = djvu.inputDjvuFile.value, dest = djvu.outputDjvuFile.value)

    let result = execCmd(&""""{executable}" "{djvu.outputDjvuFile.value}" -e "set-outline {djvuScriptFile}" -s""")
    if result != 0:
      quit 2
  else:
    echo render_help(spec)


when isMainModule:
  main()
