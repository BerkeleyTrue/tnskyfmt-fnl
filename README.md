# Fennel Format

Format your Fennel!

## Usage

    $ make # compile fnlfmt script you can place on your $PATH
    $ ./fnlfmt mycode.fnl # prints formatted code to standard out
    $ ./fnlfmt --fix mycode.fnl # replaces the file with formatted code
    $ curl localhost:8080/my-file.fnl | ./fnlfmt - # pipe to stdin

You can skip reformatting of top-level forms by placing a comment
before them. This does not work for nested forms.

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
if less than ideal, is at least not objectionable. Currently the
indentation decisions it makes are great, but it occasionally puts
newlines in places that a human would not.

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
given its own line, usually indented 2 spaces in.

Forms calling `match` and `if` are treated differently; if possible it
will attempt to pair off their pattern/condition clauses with the body
on the same line. If that can't fit, it falls back to one-form-per-line.

Strings are formatted using `:colon-notation` where possible, unless
they consist entirely of punctuation.

Top level forms may or may not have blank lines between them depending on
whether the input code spaces them out. Functions defined inside a
body form get empty lines spacing them out as well.

Similarly `if` forms and arrow forms will occasionally be allowed to
be one line if the original code had them as one-liners.

## Known issues

* When using fnlfmt programmatically, it may modify the AST argument.
* Macros that aren't built-in are always indented like functions.
* Page breaks will not be preserved.

## Other functionality

The file `indentation.fnl` contains functionality for implementing
heuristic-based indentation which does not use a parser. This can be
useful for text editors where you want to be able to indent even in
cases where the code does not parse because it's incomplete.

The file `macrodebug.fnl` contains a replacement for Fennel's
`macrodebug` function which pretty-prints the macroexpansion using the
full formatter.

## Contributing

Send patches directly to the maintainer or the
[Fennel mailing list](https://lists.sr.ht/%7Etechnomancy/fennel).

## License

Copyright © 2019-2021 Phil Hagelberg and contributors

Released under the terms of the GNU Lesser General Public License
version 3 or later; see the file LICENSE.

