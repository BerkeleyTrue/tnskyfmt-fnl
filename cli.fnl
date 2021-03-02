(local fennel (require :fennel))

(local {: format-file} (require :fnlfmt))

(fn help []
  (print "Usage: fnlfmt [--no-comments] [--fix] FILENAME")
  (print "With the --fix argument, updates the file in-place; otherwise")
  (print "prints the formatted file to stdout."))

(local options [])

(for [i (length arg) 1 -1]
  (when (= :--fix (. arg i))
    (set options.fix true)
    (table.remove arg i))
  (when (= :--no-comments (. arg i))
    (set options.no-comments true)
    (table.remove arg i)))

(match arg
  [:--fix filename nil] (let [new (format-file filename options)
                              f (assert (io.open filename :w))]
                          (f:write new)
                          (f:close))
  [filename nil] (print (format-file filename options))
  _ (help))

