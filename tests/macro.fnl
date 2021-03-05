(fn with-open* [closable-bindings ...]
  "Like `let`, but invokes (v:close) on each binding after evaluating the body.
The body is evaluated inside `xpcall` so that bound values will be closed upon
encountering an error before propagating it."
  (let [bodyfn `(fn []
                  ,...)
        closer `(fn close-handlers# [ok# ...]
                  (if first
                      second)
                  (if ok#
                      abc
                      (error ... 0)))
        traceback `(. (or package.loaded.fennel debug) :traceback)
        out [`(if) `(fn )]]
    (for [i 1 (# closable-bindings) 2]
      (assert (sym? (. closable-bindings i))
              "with-open only allows symbols in bindings")
      (table.insert closer 4 `(: ,(. closable-bindings i) :close)))
    `(let ,closable-bindings
       ,closer
       (close-handlers# (xpcall ,bodyfn ,traceback)))))

`(let [,tmp ,val]
   (if ,tmp
       (-?> ,el ,(unpack els))
       ,tmp))
