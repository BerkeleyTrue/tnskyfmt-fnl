fnlfmt: cli.fnl fnlfmt.fnl
	echo "#!/usr/bin/env lua" > $@
	./fennel --require-as-include --compile $< >> $@
	chmod +x $@

selfhost:
	./fnlfmt --fix fnlfmt.fnl
	./fnlfmt --fix cli.fnl
	./fnlfmt --fix indentation.fnl
	./fnlfmt --fix macrodebug.fnl

fennel.lua: ../fennel/fennel.lua ; cp $< $@
fennel: ../fennel/fennel ; cp $< $@

test: fnlfmt ; ./fennel test.fnl
count: ; cloc fnlfmt.fnl
clean: ; rm fnlfmt

.PHONY: test count roundtrip clean
