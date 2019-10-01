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
  (let [before (read (.. "tests/" name ".fnl"))
        after (read (.. "tests/" name "-fixed.fnl"))
        actual (.. (fmt.fmt before) "\n")]
    (if (= actual after)
        (set pass (+ pass 1))
        (failed after actual))))

(print (: "%s passed, %s failed" :format pass fail))
(os.exit fail)
