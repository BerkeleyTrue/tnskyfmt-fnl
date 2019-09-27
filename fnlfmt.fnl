(local body-specials {"let" true "fn" true "lambda" true "λ" true "when" true
                      "do" true "eval-compiler" true "for" true "each" true
                      "while" true "macro" true "match" true})

(local closers {")" "(" "]" "[" "}" "{" "\"" "\""})

(fn symbol-at [line pos]
  (: (line:sub pos) :match "[^%s]+"))

(fn identify-line [line pos stack]
  (let [char (line:sub pos pos)
        looking-for (. stack (# stack))]
    (if (= 0 pos) nil
        (= looking-for char) (do (table.remove stack)
                               (identify-line line (- pos 1) stack))
        (and (. closers char)
             (not= looking-for "\"")) (do (table.insert stack (. closers char))
                                        (identify-line line (- pos 1) stack))
        ;; if we're looking for a delimiter, skip everything till we find it
        looking-for (identify-line line (- pos 1) stack)
        (or (= "[" char) (= "{" char)) (values :table pos)
        (= "(" char) (values :call pos line)
        (identify-line line (- pos 1) stack))))

(fn identify-indent-type [lines last stack]
  (let [line (: (or (. lines last) "") :gsub ";.*" "")]
    (match (identify-line line (# line) stack)
      (:table pos) (values :table pos)
      (:call pos line) (let [function-name (symbol-at line (+ pos 1))]
                         (if (. body-specials function-name)
                             (values :body-special (- pos 1))
                             (values :call (- pos 1) function-name)))
      (_ ? (< 1 last)) (identify-indent-type lines (- last 1) stack))))

(fn indentation [lines prev-line-num]
  (match (identify-indent-type lines prev-line-num [])
    ;; three kinds of indentation:
    (:table opening) opening
    (:body-special prev-indent) (+ prev-indent 2)
    (:call prev-indent function-name) (+ prev-indent (# function-name) 2)
    _ 0))

(fn indent [line lines prev-line-num]
  (let [without-indentation (line:match "[^%s]+.*")]
    (if without-indentation
        (.. (: " " :rep (indentation lines prev-line-num)) without-indentation)
        "")))

(fn fmt [code]
  (let [lines []]
    (each [line (code:gmatch "([^\n]*)\n")]
      (table.insert lines (indent line lines (# lines))))
    (table.concat lines "\n")))

{:fmt fmt :indentation indentation}
