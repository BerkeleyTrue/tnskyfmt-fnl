(local fennel (require :fennel))

(local body-specials {"let" true "fn" true "lambda" true "λ" true "when" true
                      "do" true "eval-compiler" true "for" true "each" true
                      "while" true "macro" true "match" true "doto" true
                      "with-open" true "collect" true "icollect" true "if" true})

(fn last-line-length [line]
  (length (line:match "[^\n]*$")))

(fn view-fn-args [t view inspector indent start-indent out callee]
  "Named functions need their name and arglists to be on the first line."
  (if (fennel.sym? (. t 2))
      (let [third (view (. t 3) inspector indent)]
        (table.insert out " ")
        (table.insert out third)
        (if (= :string (type (. t 4)))
            (do (table.insert out (.. "\n" (string.rep " " start-indent)))
                (set inspector.escape-newlines? false)
                (table.insert out (view (. t 4) inspector start-indent))
                (set inspector.escape-newlines? true)
                5)
            4))
      3))

(fn view-let [bindings view inspector indent]
  "The let bindings sequence needs name/value name/value formatting."
  (let [out ["["]]
    (var offset 0)
    (for [i 1 (length bindings) 2]
      ;; when a let binding has a comment in it, emit it but don't let it throw
      ;; off the name/value pair counting
      (while (fennel.comment? (. bindings (+ i offset)))
        (table.insert out (view (. bindings (+ i offset))))
        (table.insert out (.. "\n " (string.rep " " indent)))
        (set offset (+ offset 1)))
      (let [i (+ offset i)
            name (view (. bindings i) inspector (+ indent 1))
            indent-value (+ indent 2 (last-line-length name))
            value (view (. bindings (+ i 1)) inspector indent-value)]
        (when (<= i (length bindings))
          (table.insert out name)
          (table.insert out " ")
          (table.insert out value)
          ;; unless it's the last pair, indent for the next one
          (when (< i (- (length bindings) 1))
            (table.insert out (.. "\n " (string.rep " " indent)))))))
    (table.insert out "]")
    (table.concat out)))

(local one-line-init-forms
       {:each true :for true :with-open true :collect true :icollect true})

(fn view-init-body [t view inspector start-indent out callee]
  "Certain forms need special handling of their first few args. Returns the
number of handled arguments."
  (table.insert out " ")
  (set inspector.one-line? (. one-line-init-forms callee))
  (let [indent (+ start-indent (length callee))
        second (match callee
                 :let (view-let (. t 2) view inspector indent)
                 _ (view (. t 2) inspector indent))]
    (set inspector.one-line? false)
    (table.insert out second)
    (if (. {:fn true :lambda true :λ true} callee)
        (view-fn-args t view inspector (+ indent (length second)) start-indent
                      out callee)
        3)))

(fn match-same-line? [callee i out viewed]
  (and (= :match callee) (= 0 (math.fmod i 2))
       (<= (+ (or (string.find viewed "\n") (length viewed)) 1
              (last-line-length (. out (length out)))) 80)))

(fn view-body [t view inspector start-indent out callee]
  "Insert arguments to a call to a special that takes body arguments."
  (let [start-index (view-init-body t view inspector start-indent out callee)
        ;; do and if don't actually have special indentation but they do need
        ;; a newline after every form, so we can't use normal call formatting
        indent (if (or (= callee :do) (= callee :if))
                   (+ start-indent 2)
                   start-indent)]
    (for [i start-index (length t)]
      (let [viewed (view (. t i) inspector indent)
            body-indent (+ indent 1 (last-line-length (. out (length out))))]
        ;; every form except match needs a newline after every form; match needs
        ;; it after every other form!
        (if (match-same-line? callee i out viewed)
            (do (table.insert out " ")
                (table.insert out (view (. t i) inspector body-indent)))
            (do (table.insert out (.. "\n" (string.rep " " indent)))
                (table.insert out viewed)))))))

(fn line-exceeded? [inspector indent viewed]
  (< inspector.line-length (+ indent (last-line-length viewed))))

(fn view-with-newline [view inspector out t i start-indent]
  (when (= " " (. out (length out)))
    (table.remove out))
  (table.insert out (.. "\n" (string.rep " " start-indent)))
  (let [viewed (view (. t i) inspector start-indent)]
    (table.insert out viewed)
    (+ start-indent (length viewed))))

(fn view-call [t view inspector start-indent out]
  "Insert arguments to a normal function call."
  (var indent start-indent)
  (for [i 2 (length t)]
    (table.insert out " ")
    (set indent (+ indent 1))
    (let [viewed (view (. t i) inspector (- indent 1))]
      (if (and (line-exceeded? inspector indent viewed) (< 2 i))
          (set indent (view-with-newline view inspector out t i start-indent))
          (do (table.insert out viewed)
              (set indent (+ indent (length viewed))))))))

(fn list-view [t view inspector indent]
  (let [callee (view (. t 1) inspector (+ indent 1))
        out ["(" callee]]
    ;; indent differently if it's calling a special form with body args
    (if (. body-specials callee)
        (view-body t view inspector (+ indent 2) out callee)
        (view-call t view inspector (+ indent (length callee) 2) out))
    (table.insert out ")")
    (table.concat out)))

(fn walk-tree [root f custom-iterator]
  "Walks a tree (like the AST), invoking f(node, idx, parent) on each node.
When f returns a truthy value, recursively walks the children."
  (fn walk [iterfn parent idx node]
    (when (f idx node parent)
      (each [k v (iterfn node)]
        (walk iterfn node k v))))
  (walk (or custom-iterator pairs) nil nil root)
  root)

(fn shorthand-pair? [k v]
  (and (= :string (type k)) (fennel.sym? v) (= k (tostring v))))

(fn table-shorthand [idx form parent]
  "Walker function to replace {:foo foo :bar bar} with {: foo : bar} shorthand."
  (when (and (= :table (type form)) (not (fennel.sym? form))
             (not (fennel.comment? form)) (not= fennel.varg form))
    (when (and (not (fennel.list? form)) (not (fennel.sequence? form)))
      (each [_ key (ipairs (icollect [k v (pairs form)]
                             (when (shorthand-pair? k v)
                               k)))]
        (tset form (fennel.sym ":") (. form key))
        (tset form key nil)))
    true))

(fn fnlfmt [ast]
  "Return a formatted representation of ast."
  (let [{: __fennelview &as list-mt} (getmetatable (fennel.list))
        ;; list's metamethod for fennelview is where the magic happens!
        _ (set list-mt.__fennelview list-view)
        ;; this would be better if we operated on a copy!
        _ (walk-tree ast table-shorthand)
        (ok? val) (pcall fennel.view ast {:empty-as-sequence? true
                                          :prefer-colon? true
                                          :escape-newlines? true})]
    ;; clean up after the metamethod patching
    (set list-mt.__fennelview __fennelview)
    (assert ok? val)
    val))

(fn format-file [filename]
  "Read source from a file and return formatted source."
  (let [f (match filename
            :- io.stdin
            _ (assert (io.open filename :r) "File not found."))
        parser (-> (f:read :*all)
                   (fennel.stringStream)
                   (fennel.parser filename {:comments true}))
        out []]
    (f:close)
    (each [ok? ast parser]
      (assert ok? ast)
      (let [formatted (fnlfmt ast)
            prev (. out (length out))]
        ;; Don't add extra newlines between top-level comments.
        (when (and prev (not (and (formatted:match "^ *;")
                                  (string.match prev "^ *;"))))
          (table.insert out ""))
        (table.insert out formatted)))
    (table.insert out "")
    (table.concat out "\n")))

{: fnlfmt : format-file}
