(let [{: __fennelview} (getmetatable (fennel.list))
      ;; list's metamethod for fennelview is where the magic happens!
      _ (set list-mt.__fennelview list-view)
      ;; this would be better if we operated on a copy!
      _ (walk-tree ast table-shorthand)
      (ok? val) (pcall fennel.view ast
                       {:empty-as-sequence? true
                        :escape-newlines? true
                        :prefer-colon? true})]
  ;; clean up after the metamethod patching
  (set list-mt.__fennelview __fennelview)
  (assert ok? val)
  val)

(fn view-body [t view inspector start-indent out callee]
  "Insert arguments to a call to a special that takes body arguments."
  (let [start-index (view-init-body t view inspector start-indent out callee)
        ;; do and if don't actually have special indentation but they do need
        ;; a newline after every form, so we can't use normal call formatting
        indent (if (. one-element-per-line-forms callee)
                   (+ start-indent 2)
                   start-indent)]
    12))
