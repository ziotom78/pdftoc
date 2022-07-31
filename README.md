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


## Adding the TOC to a PDF file

Be sure to have [`pdftk`](https://www.pdflabs.com/tools/pdftk-server/) installed on your system. Open a text editor, create a file named `toc.txt` and write the TOC as shown in the above example, then run `pdftoc`:

    pdftoc pdftk toc.txt > toc.idx
    
Then, run [`pdftk`](https://www.pdflabs.com/tools/pdftk-server/) on your file:

    pdftk myfile.pdf update_info_utf8 toc.idx output output_file.pdf
    
This will create a **new** file, `output_file.pdf`, which is the same as `myfile.pdf` but will be navigable.

## Adding the TOC to a DJVU file

You should have [`djvused`](http://djvu.sourceforge.net/doc/man/djvused.html) installed on your system. Open a text editor, create a file named `toc.txt` and write the TOC as shown in the above example, then run `pdftoc`:

    pdftoc djvu toc.txt > toc.idx
    
Then, run [`djvused`](http://djvu.sourceforge.net/doc/man/djvused.html) on your file:

    djvused myfile.djvu -e "set-outline toc.idx" -s
    
Be aware that, unlike [`pdftk`](https://www.pdflabs.com/tools/pdftk-server/) (see above), this command will **alter** `myfile.djvu`. If you want to play safe, better to copy your DJVU file and run [`djvused`](http://djvu.sourceforge.net/doc/man/djvused.html) on the copy; if the result looks ok, you can overwrite the original file with the copy.

## License

This program is released under the MIT license; see [LICENSE.md](./LICENSE.md).
