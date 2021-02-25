(local fennel (require :fennel))

(local body-specials {"let" true "fn" true "lambda" true "λ" true "when" true
                      "do" true "eval-compiler" true "for" true "each" true
                      "while" true "macro" true "match" true "doto" true
                      "with-open" true "collect" true "icollect" true "if" true})

(fn colon-string? [s]
  (and (= :string (type s)) (s:find "^[-%w?\\^_!$%&*+./@:|<=>]+$")))

(fn last-line-length [line]
  (length (line:match "[^\n]*$")))

(fn view-fn-args [t view inspector indent out callee]
  "Named functions need their name and arglists to be on the first line."
  (if (fennel.sym? (. t 2))
      (let [third (view (. t 3) inspector indent)]
        (table.insert out " ")
        (table.insert out third)
        (if (= :string (type (. t 4)))
            (let [inspector (doto (collect [k v (pairs inspector)]
                                    (values k v))
                              (tset :newline-in-string? true))
                  docstring (view (. t 3) inspector indent)]
              (table.insert out " ")
              (table.insert out docstring)
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

(fn view-init-body [t view inspector indent out callee]
  "Certain forms need special handling of their first few args. Returns the
number of handled arguments."
  (table.insert out " ")
  (let [indent (+ indent (length callee))
        second (match callee
                 :let (view-let (. t 2) view inspector indent)
                 _ (view (. t 2) inspector indent))]
    (table.insert out second)
    (if (. {:fn true :lambda true :λ true} callee)
        (view-fn-args t view inspector (+ indent (length second)) out callee)
        3)))

(fn match-same-line? [callee i out viewed]
  (and (= :match callee) (= 0 (math.fmod i 2))
       (< (+ (or (string.find viewed "\n") (length viewed)) 1
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
    ;; special-case strings passed to require; kinda cheesy I guess
    (let [viewed (if (and (= :require (tostring (. t 1)))
                          (colon-string? (. t i)))
                     (.. ":" (. t i))
                     (view (. t i) inspector (- indent 1)))]
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

(fn fnlfmt [ast]
  "Return a formatted representation of ast."
  (let [{: __fennelview &as list-mt} (getmetatable (fennel.list))
        ;; list's metamethod for fennelview is where the magic happens!
        _ (set list-mt.__fennelview list-view)
        (ok? val) (pcall fennel.view ast {:empty-as-sequence? true
                                          :newline-in-string? false})]
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
    (each [ok? value parser]
      (assert ok? value)
      (let [formatted (fnlfmt value)
            prev (. out (length out))]
        ;; Don't add extra newlines between top-level comments.
        (when (and prev (not (and (formatted:match "^ *;")
                                  (string.match prev "^ *;"))))
          (table.insert out ""))
        (table.insert out formatted)))
    (table.insert out "")
    (table.concat out "\n")))

{: fnlfmt : format-file}
