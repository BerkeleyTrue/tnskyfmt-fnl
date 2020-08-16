(local view (require :fennelview))

;; Roughly the strategy is to find whether the current line is part of a table,
;; a "body" special form call, a regular function call, or none of the above.
;; Each of these are indented differently.
;;
;; Examples:
;;
;; (local table-type {:a 1
;;                    :b 2
;;                    :c 3})
;;
;; (when body-type?
;;   (print "This form is indented in body type."))
;;
;; (local regular-call (this-is indented-as
;;                              a-regular "function call"))
;;
;; "this is none of the above."

(fn identify-line [line pos stack]
  "For the given line, identify the kind of form it opens, if any.
Returns nil if the given line doesn't open any form; in that case the caller
should continue looking to previous lines."
  (let [closers {")" "(" "]" "[" "}" "{" "\"" "\""}
        char (line:sub pos pos)
        looking-for (. stack (# stack))
        continue #(identify-line line (- pos 1) stack)]
    (if (= 0 pos) nil
        ;; TODO: backslashed delimiters aren't consistently handled
        (= (line:sub (- pos 1) (- pos 1)) :\ ) (continue)
        ;; if we find the delimiter we're looking for, stop looking
        (= looking-for char) (do (table.remove stack) (continue))
        ;; if we find a new form, start looking for the delimiter that begins it
        (and (. closers char)
             ;; (unless we're already in a string)
             (not= looking-for "\"")) (do (table.insert stack (. closers char))
                                        (continue))
        ;; if we're looking for a delimiter, skip everything till we find it
        looking-for (continue)
        ;; if we hit an opening table char, we're in a table!
        (or (= "[" char) (= "{" char)) (values :table pos)
        ;; if we hit an open paren, we're in a call!
        (= "(" char) (values :call pos line)
        :else (continue))))

(fn symbol-at [line pos]
  (: (line:sub pos) :match "[^%s]+"))

;; Some special forms have their own indentation rules, but specials which
;; aren't on this list are indented like normal function calls.
(local body-specials {"let" true "fn" true "lambda" true "λ" true "when" true
                      "do" true "eval-compiler" true "for" true "each" true
                      "while" true "macro" true "match" true "doto" true
                      "with-open" true})

(fn remove-comment [line in-string? pos]
  (if (< (# line) pos) line
      (= (line:sub pos pos) "\"")
      (remove-comment line (not in-string?) (+ pos 1))
      (and (= (line:sub pos pos) ";") (not in-string?))
      (line:sub 1 (- pos 1)) ; could hit false positives in multi-line strings
      (remove-comment line in-string? (+ pos 1))))

(fn identify-indent-type [lines last stack]
  "Distinguish between forms that are part of a table vs a function call.
This function iterates backwards thru a table of lines to find where the current
form begins. Also returns details about the position in the line."
  (let [line (remove-comment (or (. lines last) "") false 1)]
    (match (identify-line line (# line) stack)
      (:table pos) (values :table pos)
      (:call pos line) (let [function-name (symbol-at line (+ pos 1))]
                         (if (. body-specials function-name)
                             (values :body-special (- pos 1))
                             (values :call (- pos 1) function-name)))
      (_ ? (< 1 last)) (identify-indent-type lines (- last 1) stack))))

(fn indentation [lines prev-line-num]
  "Return indentation for a line, given a table of lines and a number offset.
The prev-line-num indicates the line previous to the current line, which will be
looked up in the table of lines. Returns the column number to indent to."
  (match (identify-indent-type lines prev-line-num [])
    ;; three kinds of indentation:
    (:table opening) opening
    (:body-special prev-indent) (+ prev-indent 2)
    (:call prev-indent function-name) (+ prev-indent (# function-name) 2)
    _ 0))

(fn indent-line [line lines prev-line-num]
  (let [without-indentation (line:match "[^%s]+.*")]
    (if without-indentation
        (.. (: " " :rep (indentation lines prev-line-num)) without-indentation)
        "")))

(fn indent [code]
  "Reformat an entire block of code."
  (let [lines []]
    (each [line (code:gmatch "([^\n]*)\n")]
      (table.insert lines (indent-line line lines (# lines))))
    (table.concat lines "\n")))

(local newline (setmetatable {} {:__fennelview #"\n"}))

(fn nospace-concat [tbl sep start end]
  (var out "")
  (for [i start end]
    (let [val (. tbl i)]
      (if (or (= i start) (= val "\n"))
          (set out (.. out val))
          (set out (.. out " " val)))))
  out)

(local nil-sym (setmetatable {} {:__fennelview #"nil"}))

;; regular fennelview for lists splices in a string in between every value but
;; we need to suppress the string if it happens at the end of a line!
(fn view-list [open close self tostring2]
  (var (safe max) (values {} 0))
  (each [k (pairs self)]
    (when (and (= (type k) "number") (> k max))
      (set max k)))
  (let [ts (or tostring2 tostring)]
    (for [i 1 max 1]
      (tset safe i (ts (if (= (. self i) nil) nil-sym (. self i))))))
  (.. open (nospace-concat safe " " 1 max) close))

;; TODO: same as above but for binding tables

(local list-mt {:__fennelview (partial view-list "(" ")")})

(fn walk-tree [root f iterator]
  (fn walk [iterfn parent idx node]
    (when (f idx node parent)
      (each [k v (iterfn node)]
        (walk iterfn node k v))))
  (walk (or iterator pairs) nil nil root)
  root)

(fn step-for [[callee]]
  (if (. {:match true} (tostring callee))
      -2
      -1))

(fn end-for [node]
  (if (= (tostring (. node 1)) :match)
      (- (# node) 1)
      (# node)))

(fn anonymous-fn? [[callee name-org-arglist]]
  (and (= :fn (tostring callee))
       (not (match (getmetatable name-org-arglist)
              [which] (= which :SYMBOL)))))

(fn start-for [form]
  (if (anonymous-fn? form) 3
      (. {:fn 4 :match 3 :do 2 :let 3 :when 3 :if 3
          :while 3 :each 3 :for 3} (tostring (. form 1)))))

(fn add-newlines [idx node parent]
  (when (= :table (type node))
    (let [mt (or (getmetatable node) [])]
      (match mt
        [:LIST] (do
                  (setmetatable node list-mt)
                  (when (start-for node)
                    (for [i (end-for node) (start-for node) (step-for node)]
                      (table.insert node i newline))))
        ;; let bindings are the only square-bracket tables that need newlines
        {: sequence} (when (= :let (-> parent (. 1) tostring))
                       (set mt.__fennelview (partial view-list "[" "]"))
                       (for [i (- (# node) 1) 2 -2]
                         (table.insert node i newline)))))
    true))

(fn fnlfmt [ast options]
  (indent (.. (view (walk-tree ast add-newlines) {:table-edges false
                                                  :empty-as-square true})
              "\n\n")))

{: fnlfmt : indentation}
