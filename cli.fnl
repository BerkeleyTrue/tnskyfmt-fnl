(local fennel (require :fennel))

(local {: format-file} (require :fnlfmt))

(fn help []
  (print "Usage: fnlfmt [--fix] FILENAME")
  (print "With the --fix argument, updates the file in-place; otherwise")
  (print "prints the formatted file to stdout."))

(match arg
  [:--fix filename] (let [new (format-file filename)
                          f (assert (io.open filename :w))]
                      (f:write new)
                      (f:close))
  [filename] (print (format-file filename))
  _ (help))
