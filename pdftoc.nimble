# Package

version       = "0.1.0"
author        = "Maurizio Tomasi"
description   = "A command-line tool to add a navigable table of contents to PDF and DJVU files"
license       = "MIT"
srcDir        = "src"
bin           = @["pdftoc"]


# Dependencies

requires "nim >= 1.6.6"
requires "therapist == 0.2"
