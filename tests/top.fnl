(local hello 12)

(local second (do
                (print :abc)
                11))

(define-arithmetic-special 1)
(define-arithmetic-special 2)
(define-arithmetic-special 3)

;; should preserve whether top-level forms have blank newlines between them!
(print "this string\nhas many\nlines" "in it")

(->> hey doin a thing)

(local slength (or (-?> (rawget _G :utf8) (. :len)) #(length $)))

(fn abc []
  (fn xyz []
    123)

  (fn def []
    456)

  (.. (xyz) (def))
  (fn []
    :return-a-function))

(fn abc2 []
  "this function returns abc"
  (fn r []
    :abc)

  (r))
