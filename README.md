# Fennel Format

Format your Fennel!

Note that this is somewhat of a work in progress and should not at
this point be considered authoritative on how to format Fennel code.
However, almost all of the current bugs involve comments, so using
the `--no-comments` flag produces reasonable (non-commented) results.

## Usage

    $ make # compile fnlfmt script you can place on your $PATH
    $ ./fnlfmt mycode.fnl # prints formatted code to standard out
    $ cat my-file.fnl | fnlfmt - # pipe fennel to stdin, get formatted stdout

## Contributing

Send patches directly to the maintainer or the
[Fennel mailing list](https://lists.sr.ht/%7Etechnomancy/fennel)

## Known issues

* When using fnlfmt programmatically, it may modify the AST argument.

## License

Copyright © 2019-2021 Phil Hagelberg and contributors

Released under the terms of the GNU Lesser General Public License
version 3 or later; see the file LICENSE.

