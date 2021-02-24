(local fmt (require :fnlfmt))

(local cases ["top" "table" "call" "body" "misc" "semicolon"])

(var pass 0)
(var fail 0)

(fn read [filename]
  (let [f (assert (io.open filename :r))
        contents (f:read :*all)]
    (f:close)
    contents))

(fn failed [name after actual]
  (set fail (+ fail 1))
  (print "FAIL" name)
  (print "Expected:")
  (print after)
  (print "Got:")
  (print actual))

(each [_ name (ipairs (if (< 0 (length arg)) arg cases))]
  (let [filename (.. "tests/" name ".fnl")
        expected (read filename)
        actual (fmt.format-file filename)]
    (if (= actual expected)
        (set pass (+ pass 1))
        (failed name expected actual))))

(print (: "%s passed, %s failed" :format pass fail))
(os.exit fail)
