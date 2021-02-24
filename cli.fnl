(local fennel (require :fennel))
(local {: fnlfmt} (require :fnlfmt))

(fn format [filename]
  (let [f (match filename
            :- io.stdin
            _ (assert (io.open filename :r) "File not found."))
        parser (-> (f:read :*all)
                   (fennel.stringStream)
                   (fennel.parser filename {:comments true}))
        out []]
    (f:close)
    (each [ok? value parser]
      (let [formatted (fnlfmt value)
            prev (. out (length out))]
        (if (and (formatted:match "^ *;") prev (string.match prev "^ *;"))
            (table.insert out formatted)
            (table.insert out (.. formatted "\n")))))
    (table.concat out "\n")))

(fn help []
  (print "Usage: fnlfmt [--fix] FILENAME")
  (print "With the --fix argument, updates the file in-place; otherwise")
  (print "prints the formatted file to stdout."))

(match arg
  ["--fix" filename] (let [new (format filename)
                           f (assert (io.open filename :w))]
                       (f:write new)
                       (f:close))
  [filename] (print (format filename))
  _ (help))

