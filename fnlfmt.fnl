(local fennel (require :fennel))
(local unpack (or table.unpack _G.unpack))

;; The basic idea is to run the code thru the parser, set a few overrides on the
;; __fennelview metamethods of the AST, then run it thru the fennel.view
;; pretty-printer. The bulk of this file consists of metamethods for lists and
;; tables which improve on fennel.view's existing logic of how to indent and
;; where to place newlines.

(local syntax (fennel.syntax))

(fn last-line-length [line]
  (length (line:match "[^\n]*$")))

(fn any? [tbl pred]
  (not= 0 (length (icollect [_ v (pairs tbl)]
                    (if (pred v) true)))))

(fn strip-comments [t]
  (icollect [_ x (ipairs t)]
    (when (not (fennel.comment? x))
      x)))

(fn view-fn-args [t view inspector indent start-indent out callee]
  "Named functions need their name and arglists to be on the first line.
Returns the index of where the body of the function starts."
  (if (fennel.sym? (. t 2))
      (let [third (view (. t 3) inspector (+ indent 1))]
        (table.insert out " ")
        (table.insert out third)
        (if (= :string (type (. t 4)))
            (do
              (table.insert out (.. "\n" (string.rep " " start-indent)))
              (set inspector.escape-newlines? false)
              (table.insert out (view (. t 4) inspector start-indent))
              (set inspector.escape-newlines? true)
              5)
            4))
      3))

(fn first-thing-in-line? [out]
  (let [last (or (. out (length out)) "")]
    (not (: (last:match "[^\n]*$") :match "[^ ]"))))

(fn break-pair? [pair-wise? count viewed next-ast indent]
  (and pair-wise? (= 1 (math.fmod count 2))
       (not (and (fennel.comment? next-ast) ; does the trailing comment fit?
                 (<= (+ indent 1 (last-line-length viewed) 1
                        (length (tostring next-ast))) 80)))))

(fn binding-comment [c indent out start-indent]
  (when (and (< 80 (+ indent (length (tostring c))))
             (: (. out (length out)) :match "^[^%s]"))
    (table.insert out (.. "\n" (string.rep " " start-indent))))
  (when (and (not (first-thing-in-line? out)) (not= (length out) 1))
    (table.insert out " "))
  (table.insert out (tostring c))
  (table.insert out (.. "\n" (string.rep " " start-indent))))

(fn view-binding [bindings view inspector start-indent pair-wise? open close]
  "Binding sequences need special care; regular sequence assumptions don't work.
We want everything to be on one line as much as possible, (except for let)."
  (let [out [open]]
    (var (indent offset non-comment-count) (values start-indent 0 1))
    (for [i 1 (length bindings)]
      (while (fennel.comment? (. bindings (+ i offset)))
        ;; when a binding has a comment in it, emit it but don't let it throw
        ;; off the name/value pair counting
        (binding-comment (. bindings (+ i offset)) indent out start-indent)
        (set (indent offset) (values start-indent (+ offset 1))))
      (let [i (+ offset i)
            viewed (view (. bindings i) inspector indent)]
        (when (<= i (length bindings))
          (table.insert out viewed)
          (set non-comment-count (+ non-comment-count 1))
          (when (< i (length bindings))
            (if (break-pair? pair-wise? non-comment-count viewed
                             (. bindings (+ i 1)) indent)
                (do
                  (table.insert out (.. "\n" (string.rep " " start-indent)))
                  (set indent start-indent))
                (do
                  (set indent (+ indent 1 (last-line-length viewed)))
                  (table.insert out " ")))))))
    (table.insert out close)
    (table.concat out)))

(local fn-forms {:fn true :lambda true "λ" true :macro true})

(local force-initial-newline {:do true :eval-compiler true})

(fn view-init-body [t view inspector start-indent out callee]
  "Certain forms need special handling of their first few args. Returns the
number of handled arguments."
  (if (. force-initial-newline callee)
      (table.insert out (.. "\n" (string.rep " " start-indent)))
      (table.insert out " "))
  (let [indent (if (. force-initial-newline callee)
                   start-indent
                   (+ start-indent (length callee)))
        second (if (and (?. syntax callee :binding-form?)
                        (not= :unquote (tostring (. t 2 1))))
                   (view-binding (. t 2) view inspector (+ indent 1)
                                 (= :let callee) "[" "]")
                   (view (. t 2) inspector indent))
        indent2 (+ indent (length (second:match "[^\n]*$")))]
    (when (not= nil (. t 2))
      (table.insert out second))
    (if (. fn-forms callee)
        (view-fn-args t view inspector indent2 start-indent out callee)
        3)))

(fn match-same-line? [callee i out viewed t]
  ;; just don't even try if there's comments!
  (and (= :match callee) (= 0 (math.fmod i 2)) (not (any? t fennel.comment?))
       (<= (+ (or (string.find viewed "\n") (length (viewed:match "[^\n]*$")))
              1 (last-line-length (. out (length out)))) 80)))

(fn trailing-comment? [out viewed body-indent indent]
  (and (viewed:match "^; ") (<= body-indent 80)))

(local one-element-per-line-forms {:-> true
                                   :->> true
                                   :-?> true
                                   :-?>> true
                                   :if true})

(fn space-out-fns? [prev viewed start-index i]
  ;; functions inside a body form shouldn't be spaced if they're the first thing
  (and (not (= start-index i))
       (or (prev:match "^ *%(fn [^%[]") (viewed:match "^ *%(fn [^%[]"))))

(fn view-body [t view inspector start-indent out callee]
  "Insert arguments to a call to a special that takes body arguments."
  (let [start-index (view-init-body t view inspector start-indent out callee)
        ;; do and if don't actually have special indentation but they do need
        ;; a newline after every form, so we can't use normal call formatting
        indent (if (. one-element-per-line-forms callee)
                   (+ start-indent (length callee))
                   start-indent)]
    (for [i (or start-index (+ (length t) 1)) (length t)]
      (let [viewed (view (. t i) inspector indent)
            body-indent (+ indent 1 (last-line-length (. out (length out))))]
        (if (or (match-same-line? callee i out viewed t)
                (trailing-comment? out viewed body-indent indent))
            (do
              (table.insert out " ")
              (table.insert out (view (. t i) inspector body-indent)))
            (do
              (when (space-out-fns? (. out (length out)) viewed start-index i)
                (table.insert out "\n"))
              (table.insert out (.. "\n" (string.rep " " indent)))
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
  "Insert arguments to a normal function call. "
  (var indent start-indent)
  (for [i 2 (length t)]
    (table.insert out " ")
    (set indent (+ indent 1))
    (let [viewed (view (. t i) inspector (- indent 1))]
      ;; Attempt to fit as many args on a single line until it gets too long.
      (if (or (fennel.comment? (. t (- i 1)))
              (and (line-exceeded? inspector indent viewed) (not= 2 i)))
          (set indent (view-with-newline view inspector out t i start-indent))
          (do
            (table.insert out viewed)
            (set indent (+ indent (length (viewed:match "[^\n]*$")))))))))

(fn view-pairwise-if [t view inspector indent out]
  (table.insert out (.. " "
                        (view-binding [(select 2 (unpack t))] view inspector
                                      indent true "" ""))))

(fn if-pair [view a b c]
  (.. (view a) " " (view b) (if (fennel.comment? c) (.. " " (view c)) "")))

(fn pairwise-if? [t indent i view]
  (if (< (length (strip-comments t)) 5) false
      (not= :if (tostring (. t 1))) false
      (not (. t i)) true
      (< 80 (+ indent 1 (length (if-pair view (select i (unpack t)))))) false
      (pairwise-if? t indent (if (fennel.comment (. t (+ i 2)))
                                 (+ i 3)
                                 (+ i 2)) view)))

(fn originally-different-lines? [[_ first second] line]
  (and (= :table (type first)) (= :table (type second))
       (not= line (or first.line line) (or second.line line))))

(fn view-maybe-body [t view inspector indent start-indent out callee]
  (if (pairwise-if? t indent 2 view)
      (view-pairwise-if t view inspector indent out)
      (originally-different-lines? t t.line)
      (view-body t view inspector (+ start-indent 2) out callee)
      (view-call t view inspector indent out callee)))

(fn newline-if-ends-in-comment [out indent]
  (when (: (. out (length out)) :match "^ *;[^\n]*$")
    (table.insert out (.. "\n" (string.rep " " indent)))))

(local sugars {:hashfn "#" :quote "`" :unquote ","})

(fn sweeten [t view inspector indent view-list]
  (.. (. sugars (tostring (. t 1))) (view (. t 2) inspector (+ indent 1))))

(local maybe-body {:-> true :->> true :-?> true :-?>> true :doto true :if true})

(local renames {"#" :length "~=" :not=})

(fn view-list [t view inspector start-indent]
  (if (. sugars (tostring (. t 1)))
      (sweeten t view inspector start-indent view-list)
      (let [callee (view (. t 1) inspector (+ start-indent 1))
            callee (or (. renames callee) callee)
            out ["(" callee]
            indent (if (?. syntax callee :body-form?)
                       (+ start-indent 2)
                       (+ start-indent (length callee) 2))]
        ;; indent differently if it's calling a special form with body args
        (if (?. syntax callee :body-form?)
            (view-body t view inspector indent out callee)
            ;; in some cases we treat it differently depending on whether the
            ;; original code was multi-line or not
            (. maybe-body callee)
            (view-maybe-body t view inspector indent start-indent out callee)
            (view-call t view inspector indent out))
        (newline-if-ends-in-comment out indent)
        (table.insert out ")")
        (table.concat out))))

(local slength (or (-?> (rawget _G :utf8) (. :len)) #(length $)))

(fn maybe-attach-comment [x indent cs]
  (if (and cs (< 0 (length cs)))
      (.. (table.concat (icollect [_ c (ipairs cs)]
                          (tostring c)) (.. "\n" (string.rep " " indent)))
          (.. "\n" (string.rep " " indent)) x)
      x))

(fn shorthand-pair? [k v]
  (and (= :string (type k)) (fennel.sym? v) (= k (tostring v))))

(fn view-pair [t view inspector indent mt key]
  (let [val (. t key)
        k (if (shorthand-pair? key val) ":"
              (view key inspector (+ indent 1) true))
        v (view val inspector (+ indent (slength k) 1))]
    (.. (maybe-attach-comment k indent (?. mt :comments :keys key)) " "
        (maybe-attach-comment v indent (?. mt :comments :values val)))))

(fn view-multiline-kv [pair-strs indent last-comments]
  (if (< 0 (length last-comments))
      (do
        (each [_ c (ipairs last-comments)]
          (table.insert pair-strs (tostring c)))
        (table.insert pair-strs "}")
        (.. "{" (table.concat pair-strs
                              (.. "\n" (string.rep " " indent)))))
      (.. "{" (table.concat pair-strs (.. "\n" (string.rep " " indent))) "}")))

(fn view-kv [t view inspector indent]
  "Normal fennelview table printing is insufficient for two reasons: it doesn't
know what to do with : foo shorthand notation, and it doesn't emit comments."
  (let [indent (+ indent 1)
        mt (getmetatable t)
        keys (or mt.keys (icollect [k (pairs t)]
                           k))
        pair-strs (icollect [_ k (ipairs keys)]
                    (view-pair t view inspector indent mt k))
        oneline (.. "{" (table.concat pair-strs " ") "}")]
    (if (or (oneline:match "\n") (?. mt :comments :last 1)
            (> (+ indent (length oneline)) inspector.line-length))
        (view-multiline-kv pair-strs indent (?. mt :comments :last))
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
      ;; Fennel's parser will always set the metatable, but we could get tables
      ;; from other places.
      (match (getmetatable form)
        mt (tset mt :__fennelview view-kv)
        _ (setmetatable form {:__fennelview view-kv})))
    true))

(fn prefer-colon? [s]
  ;; it has to be a legal colon-string, but it shouldn't be *just* punctuation
  (and (s:find "^[-%w?^_!$%&*+./|<=>]+$")
       (not (s:find "^[-?^_!$%&*+./@|<=>%\\]+$"))))

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

(fn space-out-forms? [prev-ast ast]
  "Use previous line numbering to determine whether to space out forms."
  (not (and prev-ast.line ast.line (= 1 (- ast.line prev-ast.line)))))

(fn format-file [filename {: no-comments}]
  "Read source from a file and return formatted source."
  (let [f (match filename
            "-" io.stdin
            _ (assert (io.open filename :r) "File not found."))
        contents (f:read :*all)
        parser (-> (fennel.stringStream contents)
                   (fennel.parser filename {:comments (not no-comments)}))
        out []]
    (f:close)
    (var (skip-next? prev-ast) false)
    (each [ok? ast parser]
      (assert ok? ast)
      (if (and skip-next? ast.bytestart ast.byteend)
          (do
            (table.insert out (contents:sub ast.bytestart ast.byteend))
            (set skip-next? false))
          (= (fennel.comment ";; fnlfmt: skip") ast)
          (do
            (set skip-next? true)
            (table.insert out "")
            (table.insert out (tostring ast)))
          (do
            (when (and prev-ast (space-out-forms? prev-ast ast))
              (table.insert out ""))
            (table.insert out (fnlfmt ast))
            (set skip-next? false)))
      (set prev-ast ast))
    (table.insert out "")
    (table.concat out "\n")))

{: fnlfmt : format-file :version :0.2.2}
