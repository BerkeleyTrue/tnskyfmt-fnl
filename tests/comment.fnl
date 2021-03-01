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
