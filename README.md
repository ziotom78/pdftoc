# Pdftoc

Pdftoc is a command-line utility that reads a text file containing a table of contents for a PDF/DJVU file, like the following:

```
Title page 1
First lesson (1998/03/01) 2
    What is a fluid 2
    Lagrangean and Eulerian frames 3
    The fluid equations 6
Second lesson (1998/3/03) 8
    First-order solutions 8
    Potentials 14
```

and produce a text file that can be used with tools like [`pdftk`](https://www.pdflabs.com/tools/pdftk-server/) and [`djvused`](http://djvu.sourceforge.net/doc/man/djvused.html) to add bookmarks to the PDF/DJVU file. The numbers at the end of each line mark the page number, and indentation provide a tree structure for bookmarks.

I wrote this code because I am slowly converting a number of handwritten notes to PDF and DJVU files, and I wanted to add a way to quickly navigate through them.


## Compiling the code

To compile the code, you will need the [Nim](https://nim-lang.org/) compiler. Run the following command to build the executable `pdfpc` (or `pdfpc.exe` if you are using Windows):

    nimble build

The executable can be copied anywhere, as it is a standalone binary. The usage is the following:

    pdftoc pdftk input_file.pdf index_file.txt output_file.pdf
    pdftoc djvu input_file.djvu index_file.txt output_file.djvu

where the parameters `pdftk` or `djvu` are used to understand which tool to use. The input file is never changed. To get help about command-line options, call the executable without arguments:

    pdftoc


## Syntax of the input file

The input file must be a UTF-8 encoded text file containing just one line per each bookmark. The last element in the line must be the page number, with the caveat that this is the *real* page number. (Some PDF files have aliases like `i`, `ii`, `iii`, `iv`, `v`… for the preliminary chapters: these won't work with `pdftoc`!).

Indented lines mark a nested level of bookmarks; you must use spaces instead of tabulations, but you are free to use whatever level of indentation you want. For instance, you can use two spaces:

```
Title page 1
First lesson (1998/03/01) 2
  What is a fluid 2
  Lagrangean and Eulerian frames 3
    The Lagrangean frame 3
    The Eulerian frame 4
  The fluid equations 6
```

or four spaces:

```
Title page 1
First lesson (1998/03/01) 2
    What is a fluid 2
    Lagrangean and Eulerian frames 3
        The Lagrangean frame 3
        The Eulerian frame 4
    The fluid equations 6
```

or even use different indentation levels:

```
Title page 1
First lesson (1998/03/01) 2
 What is a fluid 2
 Lagrangean and Eulerian frames 3
             The Lagrangean frame 3
             The Eulerian frame 4
 The fluid equations 6
```

The result will be the same for all the three examples.

## License

This program is released under the MIT license; see [LICENSE.md](./LICENSE.md).
