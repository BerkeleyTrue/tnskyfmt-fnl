(if hey there :oneliner!)

(if this-one
    is
    multiline)

(fn parse-loop [b]
  (if (not b) nil
      (= b 59) (parse-comment (getb) [";"])
      (= (type (. delims b)) :number) (open-table b)
      (. delims b) (close-table b)
      (= b 34) (parse-string b)
      (. prefixes b) (parse-prefix b)
      (or (sym-char? b) (= b (string.byte "~"))) (parse-sym b)
      (parse-error (.. "illegal character: " (string.char b))))
  (if (not b) nil ; EOF
      done? (values true retval)
      (parse-loop (skip-whitespace (getb)))))
