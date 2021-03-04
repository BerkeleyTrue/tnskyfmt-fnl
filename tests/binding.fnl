(each [_ key (ipairs (icollect [k v (pairs form)]
                       (when (shorthand-pair? k v)
                         k)))]
  (tset form (fennel.sym ":") (. form key)))

(collect [k v ;; what
          (pairs [])]
  (print k v))

(fn compile-binary [lua-c-path
                    executable-name
                    static-lua
                    lua-include-dir
                    native-thingy]
  (let [cc (or (os.getenv :CC) :cc)]
    nil))
