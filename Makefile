SRC = fnlfmt.fnl cli.fnl test.fnl

fnlfmt: cli.fnl fnlfmt.fnl
	echo "#!/usr/bin/env lua" > $@
	fennel --require-as-include --compile $< >> $@
	chmod +x $@

selfhost:
	fnlfmt --fix fnlfmt.fnl
	fnlfmt --fix cli.fnl
	fnlfmt --fix indentation.fnl
	fnlfmt --fix macrodebug.fnl

fennel.lua: ../fennel/fennel.lua ; cp $< $@

test: fnlfmt ; fennel test.fnl
count: ; cloc fnlfmt.fnl
roundtrip: fnlfmt ; @for file in $(SRC) ; do ./fnlfmt $$file | diff -u $$file - ; done
clean: ; rm fnlfmt

.PHONY: test count roundtrip clean
