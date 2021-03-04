(local hello 12)

(local second (do
                (print :abc)
                11))

(define-arithmetic-special 1)
(define-arithmetic-special 2)
(define-arithmetic-special 3)

;; should preserve whether top-level forms have blank newlines between them!
(print "this string\nhas many\nlines" "in it")
