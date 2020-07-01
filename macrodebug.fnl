;; Macro module containing version of macrodebug that displays via fnlfmt.
;; Also contains macros for patching macrodebug in the root compiler scoop
;; and restoring the original.

(local *macros* {})

;; internal utils
(fn warn [msg ...] (io.stderr:write (.. "Warning: " msg "\n")) ...)

;; macros

(fn *macros*.pretty-macrodebug [expr return-string?]
  "Patched version of Fennel's macrodebug that calls fnlfmt on the expanded form."
  (let [warn (fn [msg ...] (io.stderr:write (.. "Warning: " msg "\n")) ...)
        fmt  (match (pcall require :fnlfmt)
               (fmt-ok {: fnlfmt}) fnlfmt
               (->> (match (pcall require :fennelview)
                      (ok view) view tostring)
                    (warn "Failed to load fnlfmt; try checking package.path")))
        out (fmt (macroexpand expr _SCOPE))]
    (if return-string?
        out
        (print (pick-values 1 (string.gsub out "\n$" ""))))))

(fn *macros*.restore-default []
  "Resets macrodebug to the built-in version."
  (var root-scope _SCOPE)
  (while root-scope.parent (set root-scope root-scope.parent))
  (match root-scope.macros
    (core-macros ? (. core-macros :-macrodebug))
    (set (core-macros.macrodebug core-macros.-macrodebug)
         (values core-macros.-macrodebug nil))))

(fn *macros*.inject []
  "Globally patches Fennel's macrodebug with fnlfmt's drop-in replacement.
The original macrodebug is accessible as -macrodebug, and can be restored
with restore-default-macrodebug"
  (var root-scope _SCOPE) ; find root scope
  (while root-scope.parent (set root-scope root-scope.parent))
  ;; patch macrodebug, alias original to -macrodebug
  (let [core-macros           root-scope.macros
        {: pretty-macrodebug} _SCOPE.macros
        default-macrodebug    core-macros.macrodebug]
    (set core-macros.macrodebug  pretty-macrodebug)
    (set core-macros.-macrodebug default-macrodebug)))

*macros*
