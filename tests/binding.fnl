(each [_ key (ipairs (icollect [k v (pairs form)]
                       (when (shorthand-pair? k v)
                         k)))]
  (tset form (fennel.sym ":") (. form key)))

(collect [k v ;; what
          (pairs [])]
  (print k v))
