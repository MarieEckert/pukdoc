# pukdoc

initially documentation for PµK was written in a custom format as raw UTF-8.
after some time we realised that we might also want to provide this
documentation in other formats such as HTML.

given that the custom format is could be a bit annoying to parse and it is
annoying to write from hand anyway, we thought why not move to markdown and
write a converter to our style.

and this is that converter.

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
