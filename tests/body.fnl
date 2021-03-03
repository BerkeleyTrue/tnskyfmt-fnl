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
