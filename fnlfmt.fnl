(local fennel (require :fennel))
(local unpack (or table.unpack _G.unpack))

(local body-specials {"let" true "fn" true "lambda" true "λ" true "when" true
                      "do" true "eval-compiler" true "for" true "each" true
                      "while" true "macro" true "match" true "doto" true
                      "with-open" true "collect" true "icollect" true})

(fn anonymous-fn? [[callee name-org-arglist]]
  (and (= :fn (tostring callee))
       (not (match (getmetatable name-org-arglist)
              [which] (= which :SYMBOL)))))

(fn start-for [form]
  (if (anonymous-fn? form) 3
      (. {:fn 4 :match 3 :do 2 :let 3 :when 3 :if 3
          :while 3 :each 3 :for 3} (tostring (. form 1)))))

(fn line-exceeded? [inspector indent viewed]
  (< inspector.line-length (+ indent (length (viewed:match "[^\n]*$")))))

(fn view-fn-args [t view inspector indent out callee]
  (if (or (fennel.sym? (. t 2))
          (= :string (type (. t 3))))
      (let [third (view (. t 3) inspector indent)]
        (table.insert out " ")
        (table.insert out third)
        4)
      3))

(fn view-let [bindings view inspector indent]
  (let [out ["["]]
    (for [i 1 (length bindings) 2]
      ;; TODO: comments inside let throw this all off!
      (let [name (view (. bindings i) inspector (+ indent 1))
            indent2 (+ indent 2 (length (name:match "[^\n]*$")))
            value (view (. bindings (+ i 1)) inspector indent2)]
        (table.insert out name)
        (table.insert out " ")
        (table.insert out value)
        (when (< i (- (length bindings) 1))
          (table.insert out (.. "\n " (string.rep " " indent))))))
    (table.insert out "]")
    (table.concat out)))

(fn view-init-body [t view inspector indent out callee]
  (table.insert out " ")
  (let [indent (+ indent (length callee))
        second (if (= callee :let)
                   (view-let (. t 2) view inspector indent)
                   (view (. t 2) inspector indent))]
    (table.insert out second)
    (if (. {:fn true :lambda true :λ true} callee)
        (view-fn-args t view inspector (+ indent (length second)) out callee)
        3)))

(fn view-body [t view inspector start-indent out callee]
  (let [start-index (view-init-body t view inspector start-indent out callee)
        indent (if (= callee :do) (+ start-indent 2) start-indent)]
    (for [i start-index (length t)]
      (let [viewed (view (. t i) inspector indent)]
        ;; TODO: allow match clauses and body to share a line sometimes
        (table.insert out (.. "\n" (string.rep " " indent)))
        (table.insert out viewed)))))

(fn view-call [t view inspector start-indent out]
  (var indent start-indent)
  (for [i 2 (length t)]
    (table.insert out " ")
    (set indent (+ indent 1))
    (let [viewed (view (. t i) inspector indent)]
      (if (and (line-exceeded? inspector indent viewed) (< 2 i))
          (do (when (= " " (. out (length out)))
                (table.remove out)) ; trailing space
              (table.insert out (.. "\n" (string.rep " " start-indent)))
              (set indent start-indent)
              (let [viewed2 (view (. t i) inspector indent)]
                (table.insert out viewed2)
                (set indent (+ indent (length viewed2)))))
          (do (table.insert out viewed)
              (set indent (+ indent (length viewed))))))))

(fn list-view [t view inspector indent]
  (let [first-viewed (view (. t 1) inspector (+ indent 1))
        out ["(" first-viewed]]
    (if (. body-specials first-viewed)
        (view-body t view inspector (+ indent 2) out first-viewed)
        (view-call t view inspector (+ indent (length first-viewed) 2) out))
    (table.insert out ")")
    (table.concat out)))

(fn fnlfmt [ast]
  (let [{: __fennelview &as list-mt} (getmetatable (fennel.list))
        ;; override fennelview method for lists!
        _ (set list-mt.__fennelview list-view)
        (ok val) (pcall fennel.view ast {:empty-as-sequence? true})]
    ;; clean up after the metamethod patching
    (set list-mt.__fennelview __fennelview)
    (when (not ok) (error val))
    val))

(fn format-file [filename]
  (let [f (match filename
            :- io.stdin
            _ (assert (io.open filename :r) "File not found."))
        parser (-> (f:read :*all)
                   (fennel.stringStream)
                   (fennel.parser filename {:comments true}))
        out []]
    (f:close)
    (each [ok? value parser]
      (let [formatted (fnlfmt value)
            prev (. out (length out))]
        (if (and (formatted:match "^ *;") prev (string.match prev "^ *;"))
            (table.insert out formatted)
            (table.insert out (.. formatted "\n")))))
    (table.concat out "\n")))

{: fnlfmt : format-file}
