;; this example comes from fennelview

(fn one-line [str]
  ;; save return value as local to ignore gsub's extra return value
  (let [ret (-> str
                (: :gsub "\n" " ")
                (: :gsub "%[ " "[")
                (: :gsub " %]" "]")
                (: :gsub "%{ " "{")
                (: :gsub " %}" "}")
                (: :gsub "%( " "(")
                (: :gsub " %)" ")"))]
    ret))

(let [;; start with
      a comment]
  nil)

(local stringy "this string is really long; in fact, putting a backslash n in it
for the newline would push it way over the limit")

;; this )comment has a ( in it!

xyz

(let [what-is "a\"quoted string"]
  this-is-weird)
