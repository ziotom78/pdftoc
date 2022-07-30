# -*- encoding: utf-8 -*-

import std/os
import std/strutils
import std/strformat

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


proc printPdfTk(entries: seq[Entry]) =
  for entry in entries:
    stdout.write "BookmarkBegin\n"
    stdout.write "BookmarkTitle: ", entry.name, "\n"
    stdout.write "BookmarkLevel: ", entry.level, "\n"
    stdout.write "BookmarkPageNumber: ", entry.page, "\n"


proc printDjvu(entries: seq[Entry]) =

  proc indent(level: int) =
    const INDENT_SPACES = 2
    stdout.write repeat(' ', level * INDENT_SPACES)

  func escapeDjvu(s: string): string =
    result = multiReplace(s, ("\"", "\\\""))
    
  stdout.write "(bookmarks\n"

  for idx in 0..<len(entries):
    let entry = entries[idx]
    
    indent(entry.level)
    stdout.write "(\"", escapeDjvu(entry.name), "\" \"#", entry.page, '\"'
    
    if idx + 1 < len(entries):
      if entries[idx + 1].level <= entry.level:
        stdout.write ")\n"
      else:
        stdout.write '\n'

      for j in countdown(entry.level - 1, entries[idx + 1].level):
        indent(j)
        stdout.write ")\n"
    else:
      stdout.write ")\n"
      
  stdout.write ")\n"


proc main() =
  if paramCount() == 0 or paramCount() > 2:
    echo fmt"Usage: {getAppFileName()} FORMAT [FILE]"
    echo ""
    echo "FORMAT can either be 'pdftk', 'djvu':"
    echo "  - For 'pdftk', run the following command to add bookmarks to the PDF file:"
    echo ""
    echo "        pdftk INPUT.pdf update_info_utf8 FILE.txt output OUTPUT.pdf"
    echo ""
    echo "    where INPUT.pdf is the file to use as source, FILE.txt is the output"
    echo "    of this program, and OUTPUT.pdf is the new file to create."
    echo ""
    echo "  - For 'djvu', run the following command to add bookmarks to the DJVU file:"
    echo ""
    echo "        djvused INPUT_OUTPUT.djvu -e \"set-outline FILE.txt\" -s"
    echo ""
    echo "    where INPUT_OUTPUT.djvu is the file to be modified in-place, and"
    echo "    FILE.txt is the output of this program."
    echo ""
    echo "If FILE is not present, input will be read from terminal"
    quit(1)
    
  let outputFormatStr = paramStr(1)
  let inputFileName = if paramCount() > 1:
                        paramStr(2)
                      else:
                        ""
  
  let entries = processInput(inputFileName)

  case outputFormatStr.toUpperAscii():
    of "PDFTK":
      printPdfTk(entries)
    of "DJVU":
      printDjvu(entries)
    else:
      stderr.write(fmt"unknown output format {outputFormatStr}")
      quit(1)
  

    
when isMainModule:
  main()
