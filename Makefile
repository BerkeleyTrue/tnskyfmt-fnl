SRC = fnlfmt.fnl cli.fnl test.fnl

fnlfmt: cli.fnl fnlfmt.fnl
	echo "#!/usr/bin/env lua" > $@
	fennel --require-as-include --compile $< >> $@
	chmod +x fnlfmt

test: fnlfmt ; fennel test.fnl
count: ; cloc fnlfmt.fnl
roundtrip: fnlfmt ; @for file in $(SRC) ; do ./fnlfmt $$file | diff -u $$file - ; done
clean: rm fnlfmt

.PHONY: test count roundtrip clean
