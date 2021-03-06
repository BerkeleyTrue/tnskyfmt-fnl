(local fmt (require :fnlfmt))
(local cases [:top
              :table
              :call
              :body
              :misc
              :semicolon
              :match
              :binding
              :comment
              :sugar
              :skip
              :macro
              :if])

(var pass 0)

(fn read [filename]
  (let [f (assert (io.open filename :r))
        contents (f:read :*all)]
    (f:close)
    contents))

(local failures [])

(fn failed [name after actual]
  (table.insert failures name)
  (print :FAIL name)
  (print "Expected:")
  (print after)
  (print "Got:")
  (print actual))

(each [_ name (ipairs (if (< 0 (length arg))
                          arg
                          cases))]
  (let [filename (.. :tests/ name :.fnl)
        expected (read filename)
        actual (fmt.format-file filename {})]
    (if (= actual expected)
        (set pass (+ pass 1))
        (failed name expected actual))))

(print (: "%s passed, %s failed" :format pass (length failures)))
(when (not= 0 (length failures))
  (print "Failures:" (table.concat failures ", "))
  (os.exit 1))
