(call (this needs to be a really long call to another function to trigger wrap)
      :a (print :b) :c)

(table.concat [:also :a :rather :long :thing :you :know]
              "funny how python makes joining a method of the separator!")

(call (call 1 2))

(fn match-same-line? [callee i out viewed]
  (and (= :match callee) (= 0 (math.fmod i 2))
       (<= (+ (or (string.find viewed "\n") (length viewed)) 1
              (last-line-length (. out (length out)))) 80)))
