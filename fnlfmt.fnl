(local fennel (require :fennel))
(local body-specials {:-> true
                      :->> true
                      :-?> true
                      :-?>> true
                      :collect true
                      :do true
                      :doto true
                      :each true
                      :eval-compiler true
                      :fn true
                      :for true
                      :icollect true
                      :if true
                      :lambda true
                      :let true
                      :macro true
                      :match true
                      :when true
                      :while true
                      :with-open true
                      "λ" true})

(fn last-line-length [line]
  (length (line:match "[^\n]*$")))

(fn any? [tbl pred]
  (not= 0 (length (icollect [_ v (pairs tbl)]
                    (if (pred v)
                        true)))))

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

(fn first-thing-in-line? [out]
  (let [last (or (. out (length out)) "")]
    (not (: (last:match "[^\n]*$") :match "[^ ]"))))

(fn view-binding [bindings view inspector start-indent callee]
  "Binding sequences need special care; regular sequence assumptions don't work.
We want everything to be on one line as much as possible, (except for let)."
  (let [out ["["]]
    (var (offset count) (values 0 0))
    (var indent start-indent)
    (for [i 1 (length bindings)]
      ;; when a binding has a comment in it, emit it but don't let it throw
      ;; off the name/value pair counting
      (while (fennel.comment? (. bindings (+ i offset)))
        (when (< 80 (+ indent 1 (length (tostring (. bindings (+ i offset))))))
          (table.insert out (.. "\n" (string.rep " " start-indent))))
        (when (and (not (first-thing-in-line? out)) (not= (length out) 1))
          (table.insert out " "))
        (table.insert out (view (. bindings (+ i offset))))
        (table.insert out (.. "\n" (string.rep " " start-indent)))
        (set indent start-indent)
        (set offset (+ offset 1)))
      (let [i (+ offset i)
            viewed (view (. bindings i) inspector indent)]
        (when (<= i (length bindings))
          (if (or (first-thing-in-line? out) (= i 1))
              nil
              (and (= :let callee) (= 0 (math.fmod count 2)))
              (do (table.insert out (.. "\n" (string.rep " " start-indent)))
                  (set indent start-indent))
              (table.insert out " "))
          (table.insert out viewed)
          (set count (+ count 1))
          (set indent (+ indent 1 (last-line-length viewed))))))
    (table.insert out "]")
    (table.concat out)))

(local init-bindings {:collect true
                      :each true
                      :for true
                      :icollect true
                      :let true
                      :with-open true})

(fn view-init-body [t view inspector start-indent out callee]
  "Certain forms need special handling of their first few args. Returns the
number of handled arguments."
  (table.insert out " ")
  (let [indent (+ start-indent (length callee))
        second (match (. init-bindings callee)
                 true (view-binding (. t 2) view inspector (+ indent 1) callee)
                 _ (view (. t 2) inspector indent))
        indent (+ indent (length (second:match "[^\n]*$")))]
    (table.insert out second)
    (if (. {:fn true :lambda true "λ" true :macro true} callee)
        (view-fn-args t view inspector indent start-indent out callee)
        3)))

(fn match-same-line? [callee i out viewed t]
  ;; just don't even try if there's comments!
  (and (= :match callee) (= 0 (math.fmod i 2)) (not (any? t fennel.comment?))
       (<= (+ (or (string.find viewed "\n") (length (viewed:match "[^\n]*$")))
              1 (last-line-length (. out (length out)))) 80)))

(fn trailing-comment? [out viewed body-indent]
  (and (viewed:match "^; ")
       (<= (+ body-indent (length (. out (length out)))) 80)))

(local one-element-per-line-forms {:-> true
                                   :->> true
                                   :-?> true
                                   :-?>> true
                                   :do true
                                   :if true})

(fn view-body [t view inspector start-indent out callee]
  "Insert arguments to a call to a special that takes body arguments."
  (let [start-index (view-init-body t view inspector start-indent out callee)
        ;; do and if don't actually have special indentation but they do need
        ;; a newline after every form, so we can't use normal call formatting
        indent (if (. one-element-per-line-forms callee)
                   (+ start-indent (length callee))
                   start-indent)]
    (for [i start-index (length t)]
      (let [viewed (view (. t i) inspector indent)
            body-indent (+ indent 1 (last-line-length (. out (length out))))]
        ;; every form except match needs a newline after every form; match needs
        ;; it after every other form!
        (if (or (match-same-line? callee i out viewed t)
                (trailing-comment? out viewed body-indent))
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
    (+ start-indent (length (viewed:match "[^\n]*$")))))

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
              (set indent (+ indent (length (viewed:match "[^\n]*$")))))))))

(fn view-hashfn [t view inspector indent view-list]
  (.. "#" (view-list (. t 2) view inspector (+ indent 1))))

(fn view-list [t view inspector indent]
  (if (= (fennel.sym :hashfn) (. t 1))
      (view-hashfn t view inspector indent view-list)
      (let [callee (view (. t 1) inspector (+ indent 1))
            out ["(" callee]]
        ;; indent differently if it's calling a special form with body args
        (if (. body-specials callee)
            (view-body t view inspector (+ indent 2) out callee)
            (view-call t view inspector (+ indent (length callee) 2) out))
        (table.insert out ")")
        (table.concat out))))

(local slength (or (-?> (rawget _G :utf8)
                        (. :len)) #(length $)))

(fn maybe-attach-comment [x indent c]
  (if c
      (.. (tostring c) "\n" (string.rep " " indent) x)
      x))

(fn shorthand-pair? [k v]
  (and (= :string (type k)) (fennel.sym? v) (= k (tostring v))))

(fn view-pair [t view inspector indent mt key]
  (let [val (. t key)
        k (if (shorthand-pair? key val)
              ":"
              (view key inspector (+ indent 1) true))
        v (view val inspector (+ indent (slength k) 1))]
    (.. (maybe-attach-comment k indent (. mt.comments.keys key)) " "
        (maybe-attach-comment v indent (. mt.comments.values val)))))

(fn view-multiline-kv [pair-strs indent last-comment]
  (if last-comment
      (.. "{" (table.concat (doto pair-strs
                              (table.insert (tostring last-comment))
                              (table.insert "}"))
                            (.. "\n" (string.rep " " indent))))
      (.. "{" (table.concat pair-strs (.. "\n" (string.rep " " indent))) "}")))

(fn view-kv [t view inspector indent]
  "Normal fennelview table printing is insufficient for two reasons: it doesn't
know what to do with : foo shorthand notation, and it doesn't emit comments."
  (let [indent (+ indent 1)
        mt (getmetatable t)
        pair-strs (icollect [_ k (ipairs mt.keys)]
                    (view-pair t view inspector indent mt k))
        oneline (.. "{" (table.concat pair-strs " ") "}")]
    (if (or (oneline:match "\n") mt.comments.last
            (> (+ indent (length oneline)) inspector.line-length))
        (view-multiline-kv pair-strs indent mt.comments.last)
        oneline)))

(fn walk-tree [root f custom-iterator]
  "Walks a tree (like the AST), invoking f(node, idx, parent) on each node.
When f returns a truthy value, recursively walks the children."
  (fn walk [iterfn parent idx node]
    (when (f idx node parent)
      (each [k v (iterfn node)]
        (walk iterfn node k v))))
  (walk (or custom-iterator pairs) nil nil root)
  root)

(fn set-fennelview-metamethod [idx form parent]
  (when (and (= :table (type form)) (not (fennel.sym? form))
             (not (fennel.comment? form)) (not= (fennel.varg) form))
    (when (and (not (fennel.list? form)) (not (fennel.sequence? form)))
      (tset (getmetatable form) :__fennelview view-kv))
    true))

(fn prefer-colon? [s]
  ;; it has to be a legal colon-string, but it shouldn't be *just* punctuation
  (and (s:find "^[-%w?^_!$%&*+./@|<=>]+$")
       (not (s:find "^[-?^_!$%&*+./@|<=>]+$"))))

(fn fnlfmt [ast]
  "Return a formatted representation of ast."
  (let [{&as list-mt : __fennelview} (getmetatable (fennel.list))
        ;; list's metamethod for fennelview is where the magic happens!
        _ (set list-mt.__fennelview view-list)
        ;; this would be better if we operated on a copy!
        _ (walk-tree ast set-fennelview-metamethod)
        (ok? val) (pcall fennel.view ast
                         {:empty-as-sequence? true
                          :escape-newlines? true
                          : prefer-colon?})]
    ;; clean up after the metamethod patching
    (set list-mt.__fennelview __fennelview)
    (assert ok? val)
    val))

(fn space-out-forms? [prev this]
  (and (not (and (this:match "^ *;") (string.match prev "^ *;")))
       (not (and (this:match "^%(local ") (string.match prev "^%(local ")))))

(fn format-file [filename {: no-comments}]
  "Read source from a file and return formatted source."
  (let [f (match filename
            "-" io.stdin
            _ (assert (io.open filename :r) "File not found."))
        parser (-> (f:read :*all)
                   (fennel.stringStream)
                   (fennel.parser filename {:comments (not no-comments)}))
        out []]
    (f:close)
    (each [ok? ast parser]
      (assert ok? ast)
      (let [formatted (fnlfmt ast)
            prev (. out (length out))]
        ;; Don't add extra newlines between top-level comments or locals.
        (when (and prev (space-out-forms? prev formatted))
          (table.insert out ""))
        (table.insert out formatted)))
    (table.insert out "")
    (table.concat out "\n")))

{: fnlfmt : format-file}
