(local fennel (require :fennel))
(local view (require :fennelview))
(local {: fnlfmt} (require :fnlfmt))

(fn format [filename]
  (let [f (match filename
            :- io.stdin
            _ (assert (io.open filename :r) "File not found."))
        parser (-> (f:read :*all)
                   (fennel.stringStream)
                   (fennel.parser))
        out []]
    (f:close)
    (each [ok? value parser]
      (table.insert out (fnlfmt value)))
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

