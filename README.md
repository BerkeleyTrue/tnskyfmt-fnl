# Fennel Format

Format your Fennel!

Note that this is somewhat of a work in progress and should not at
this point be considered authoritative on how to format Fennel code.
However, almost all of the current bugs involve comments, so using
the `--no-comments` flag produces reasonable (non-commented) results.

## Usage

    $ make # compile fnlfmt script you can place on your $PATH
    $ ./fnlfmt mycode.fnl # prints formatted code to standard out
    $ curl localhost:8080/my-file.fnl | ./fnlfmt - # pipe to stdin

You can skip reformatting of top-level forms by placing a comment
before them:

```fennel
(fn this-function [can be formatted ...]
  ...)

;; fnlfmt: skip
(local this-table ["benefits"          :from
                   "different kind of" :FORMATTING
                   "because of"        :reasons])

(fn this-function [will-be]
  (formatted :normally "again"))
```

## Description

Formatting is essentially an aesthetic process; any automated attempt
at doing it will necessarily encounter situations where it produces
output that doesn't look as good as it would if a human were making
the decisions. That said, the goal is to at worst emit output which,
if less than ideal, is at least not objectionable.

For the most part, `fnlfmt` follows established lisp conventions when
determining how to format a given piece of code. Key/value tables are
shown with each key/value pair on its own line, unless they are small
enough to all fit on one line. Sequential tables similarly have each
element on their own line unless they fit all on a single line. Tables
with string keys and symbol values will use `{: foo : bar}` shorthand
notation where possible.

Calls are formatted differently depending on whether they are calling
a regular function/macro or whether they're calling a special macro
which is known to have a "body"; in the latter case every element is
given its own line, usually indented 2 spaces in. Calls to `match`
will try to fit their pattern and body on the same line where possible.

Strings are formatted using `:colon-notation` where possible, unless
they consist entirely of punctuation.

Top level forms may or may not have blank lines between them depending on
whether the input code spaces them out. Similarly `if` forms and arrow
forms will occasionally be allowed to be one line if the original code
had them as one-liners.

## Known issues

* When using fnlfmt programmatically, it may modify the AST argument.
* Macros that aren't built-in are always indented like functions.
* Preserving multi-line forms doesn't work if the first or second
  argument is a number, string, boolean, or varg.

## Contributing

Send patches directly to the maintainer or the
[Fennel mailing list](https://lists.sr.ht/%7Etechnomancy/fennel).

## License

Copyright © 2019-2021 Phil Hagelberg and contributors

Released under the terms of the GNU Lesser General Public License
version 3 or later; see the file LICENSE.

