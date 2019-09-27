SRC = fnlfmt.fnl fnlfmt test.fnl

test: ; fennel test.fnl
count: ; cloc fnlfmt.fnl
roundtrip: ; @for file in $(SRC) ; do ./fnlfmt $$file | diff -u $$file - ; done
