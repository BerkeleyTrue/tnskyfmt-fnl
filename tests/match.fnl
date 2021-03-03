(local x (require :x))

(match [:a :b :c]
  [this pattern is really long! too long fer one line]
  (do (the body is long too!)
      (too long to fit on one line of course))
  [a b c] (print "this one can fit on the pattern line"
                 "and it has a couple args in the print line"))

(match (identify-indent-type lines prev-line-num [])
  ;; three kinds of indentation:
  (:table opening)
  opening
  (:body-special prev-indent)
  (+ prev-indent 2)
  (:call prev-indent function-name)
  (+ prev-indent (# function-name) 2))

(fn *macros*.pretty-macrodebug [expr return-string?]
  "Patched version of Fennel's macrodebug that calls fnlfmt on expanded form."
  (let [warn (fn [msg ...]
               (io.stderr:write (.. "Warning: " msg "\n"))
               ...)
        fmt (match (pcall require :fnlfmt)
              (fmt-ok {: fnlfmt}) fnlfmt
              (->> (match (pcall require :fennel)
                     (ok {: view}) view
                     tostring)
                   (warn "Failed to load fnlfmt; try checking package.path")))
        out (fmt (macroexpand expr _SCOPE))]
    (if return-string?
        out
        (print (pick-values 1 (string.gsub out "\n$" ""))))))
