# pukdoc

initially, documentation for PµK was written as plain UTF-8 text with specific
formatting. after some time we realised that we might also want to provide this
documentation in other formats such as HTML.

given that the our formatting could be a bit annoying to parse and is annoying
to write by hand anyway, we thought "why not move to markdown and write a
converter to our style?".

this is that converter.

## usage

**this is subject to change since i have not yet invested any time into making
this pleasent to use**

`pukdoc <input>` converts the given file and writes the result to stdout.

`pukdoc` reads from stdin and also writes the result to stdout.

## on input formatting

at this moment pukdoc is a bit picky about what input it accepts/interprets
properly, mostly because i wanted something that works before making it "fully"
markdown "compliant".

these are some of the limitations that apply:

1. codeblocks must be opened on a seperate line
2. codeblocks must be closed on a seperate line
3. special formatting is ignored (bold, italic, links, monospace, quotes, etc.)
