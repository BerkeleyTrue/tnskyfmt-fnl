(when true
  (print "you can't handle the truth!")
  (os.exit 1))

;; what

(do (fn abc []
      "this docstring
has a newline in it"
      (do (set fail (+ fail 1))
          (print :FAIL)
          ;; hey
          (print "Expected:")
          (print after)
          (print "Got:")
          (print actual))))

(if (. {:fn true :lambda true "λ" true} callee)
    (view-fn-args t view inspector (+ indent (length second)) out callee)
    3)

;; This currently prints the binding sequence as one-element-per-line
(each [_ key (ipairs (icollect [k v (pairs form)]
                       (when (shorthand-pair? k v)
                         k)))]
  (tset form (fennel.sym ":") (. form key))
  (tset form key nil))
