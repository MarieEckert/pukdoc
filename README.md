# pukdoc

initially, documentation for PµK was written as plain UTF-8 text with specific
formatting. after some time we realised that we might also want to provide this
documentation in other formats such as HTML.

given that the our formatting could be a bit annoying to parse and is annoying
to write by hand anyway, we thought "why not move to markdown and write a
converter to our style?".

this is that converter.

## usage

```
usage: pukdoc [input file] [additional arguments]

if no input file is provided, input is read from stdin.
if no output file is provided, output is written to stdout.

ARGUMENTS
  --out | -o <file>
    Specify an output file
  --version | -v
    Show the version of the program
  --help | -h
    Show this help text
```

## on input formatting

at this moment pukdoc is a bit picky about what input it accepts/interprets
properly, mostly because i wanted something that works before making it "fully"
markdown "compliant".

these are some of the limitations that apply:

1. codeblocks must be opened on a seperate line
2. codeblocks must be closed on a seperate line
3. special formatting is ignored (bold, italic, links, monospace, quotes, etc.)

## todo

* [ ] wrap tables if they exceed 80 columns (headache)
* [ ] parse lists
  * [ ] translate them back accordingly
* [ ] cleanup or just rewrite the parser
