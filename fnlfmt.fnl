(local body-specials {"let" true "fn" true "lambda" true "λ" true "when" true
                      "do" true "eval-compiler" true "for" true "each" true
                      "while" true "macro" true "match" true "doto" true})

(local closers {")" "(" "]" "[" "}" "{" "\"" "\""})

(fn symbol-at [line pos]
  (: (line:sub pos) :match "[^%s]+"))

(fn identify-line [line pos stack]
  (let [char (line:sub pos pos)
        looking-for (. stack (# stack))
        continue #(identify-line line (- pos 1) stack)]
    (if (= 0 pos) nil
        (= (line:sub (- pos 1) (- pos 1)) :\ ) (continue)
        (= looking-for char) (do (table.remove stack)
                               (identify-line line (- pos 1) stack))
        (and (. closers char)
             ;; TODO: backslashed delimiters aren't consistently handled
             (not= looking-for "\"")) (do (table.insert stack (. closers char))
                                        (identify-line line (- pos 1) stack))
        ;; if we're looking for a delimiter, skip everything till we find it
        looking-for (continue)
        (or (= "[" char) (= "{" char)) (values :table pos)
        (= "(" char) (values :call pos line)
        :else (continue))))

(fn identify-indent-type [lines last stack]
  ;; TODO: this gives us some false positives with semicolons in strings
  (let [line (: (or (. lines last) "") :gsub ";.*" "")]
    (match (identify-line line (# line) stack)
      (:table pos) (values :table pos)
      (:call pos line) (let [function-name (symbol-at line (+ pos 1))]
                         (if (. body-specials function-name)
                             (values :body-special (- pos 1))
                             (values :call (- pos 1) function-name)))
      (_ ? (< 1 last)) (identify-indent-type lines (- last 1) stack))))

(fn indentation [lines prev-line-num]
  "Return indentation for a line, given a table of lines and a number offset.
The number indicates the line previous to the current line, which will be
looked up in the table."
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
  "Reformat an entire block of code."
  (let [lines []]
    (each [line (code:gmatch "([^\n]*)\n")]
      (table.insert lines (indent line lines (# lines))))
    (table.concat lines "\n")))

{:fmt fmt :indentation indentation}
