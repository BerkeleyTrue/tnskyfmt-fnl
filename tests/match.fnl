(local x (require :x))

(match [:a :b :c]
  [this pattern is really long! too long fer one line]
  (do (the body is long too)
      (too long to fit on one line))
  [a b c] (print "this one can fit on the pattern line"
                 "and it has a couple args in the print line"))
