(local fmt (require :fnlfmt))

(local cases ["top" "table" "call" "body" "misc" "semicolon"])

(var pass 0)
(var fail 0)

(fn read [filename]
  (let [f (assert (io.open filename :r))
        contents (f:read :*all)]
    (f:close)
    contents))

(fn failed [after actual]
  (set fail (+ fail 1))
  (print "FAIL")
  (print "Expected:")
  (print after)
  (print "Got:")
  (print actual))

(each [_ name (ipairs cases)]
  (let [expected (read (.. "tests/" name ".fnl"))
        actual (.. (fmt.fmt expected) "\n")]
    (if (= actual expected)
        (set pass (+ pass 1))
        (failed expected actual))))

(print (: "%s passed, %s failed" :format pass fail))
(os.exit fail)
