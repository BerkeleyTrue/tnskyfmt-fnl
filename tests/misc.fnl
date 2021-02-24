;; this example comes from fennelview

(fn one-line [str]
  ;; save return value as local to ignore gsub's extra return value
  (let [ret (-> str (: "gsub" "
" " ") (: "gsub" "%[ " "[")
                (: "gsub" " %]" "]") (: "gsub" "%{ " "{") (: "gsub" " %}" "}")
                (: "gsub" "%( " "(") (: "gsub" " %)" ")"))]
    ret))

;; this )comment has a ( in it!

xyz

(let [what-is "a\"quoted string"]
  this-is-weird)
