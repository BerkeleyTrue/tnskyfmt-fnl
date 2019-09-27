;; this example comes from fennelview

(fn one-line [str]
  ;; save return value as local to ignore gsub's extra return value
  (let [ret (-> str
                (: :gsub "\n" " ")
                (: :gsub "%[ " "[") (: :gsub " %]" "]")
                (: :gsub "%{ " "{") (: :gsub " %}" "}")
                (: :gsub "%( " "(") (: :gsub " %)" ")"))]
    ret))
