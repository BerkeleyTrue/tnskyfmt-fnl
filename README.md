# Fennel Format

Format your Fennel!

Right now it is strictly for indentation only. It's up to you to keep
your column lengths at 80 or under, so please do that.

## Usage

    $ ./fnlfmt mycode.fnl # prints formatted code to standard out

    $ cat my-file.fnl | fnlfmt - # pipe fennel to stdin, get formatted stdout

## Contributing

Send patches directly to the maintainer or the
[Fennel mailing list](https://lists.sr.ht/%7Etechnomancy/fennel)

## Known issues

Multi-line strings containing semicolons or delimiters may result in
incorrect indentation in certain situations.

## License

Copyright © 2019 Phil Hagelberg and contributors

Released under the terms of the GNU Lesser General Public License
version 3 or later; see the file LICENSE.

