(print "this line that's right here on the first line" ; has a semicolon
       "but it is outside a string")

(print "this string; the one in the second form--it also has a semicolon"
       "what will we do??")

(do
  (let [this form ; has a trailing comment
        ;; so many
        ;; such comments aaaah
        in it! ;; and another
        a 9]
    (oh-no!)))

(fn flatten-chunk-correlated [main-chunk]
  (each [_ subchunk (ipairs chunk)]
    (when (or subchunk.leaf (> (# subchunk) 0)) ; trailing
      ;; don't increase line unless it's from the same file
      (print :sup)
      ;; this one ends in a comment!
      ))
  (this is a normal call ; which ends in a comment
        ))
