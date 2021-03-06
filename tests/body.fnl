(when true
  (print "you can't handle the truth!")
  (os.exit 1))

;; what

(do
  (fn abc []
    "this docstring
has a newline in it"
    (do
      (set fail (+ fail 1))
      (print :FAIL)
      ;; hey
      (print "Expected:")
      (print after)
      (print "Got:")
      (print actual))))

(if (. {:fn true :lambda true "λ" true} callee)
    (view-fn-args t view inspector (+ indent (length second)) out callee)
    3)

(fn pp-string [str options indent]
  (let [escs (setmetatable {"\a" "\\a"
                            "\b" "\\b"
                            "\f" "\\f"
                            "\v" "\\v"
                            "\r" "\\r"
                            "\t" "\\t"
                            "\\" "\\\\"
                            "\"" "\\\""
                            "\n" (if (and options.escape-newlines?
                                          (< (length str)
                                             (- options.line-length indent)))
                                     "\\n" "\n")}
                           {:__index #(: "\\%03d" :format ($2:byte))})]
    (.. "\"" (str:gsub "[%c\\\"]" escs) "\"")))
