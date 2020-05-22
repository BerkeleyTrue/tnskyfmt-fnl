SRC = fnlfmt.fnl cli.fnl test.fnl

fnlfmt: cli.fnl
	echo "#!/usr/bin/env lua" > $@
	fennel --compile --require-as-include $< >> $@
	chmod +x fnlfmt

test: fnlfmt ; fennel test.fnl
count: ; cloc fnlfmt.fnl
roundtrip: fnlfmt ; @for file in $(SRC) ; do ./fnlfmt $$file | diff -u $$file - ; done

.PHONY: test count roundtrip
