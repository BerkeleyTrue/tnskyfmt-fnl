(call (this needs to be a really long call to another function to trigger wrap)
      :a (print :b) :c)

(table.concat [:also :a :rather :long :thing :you :know]
              "funny how python makes joining a method of the separator!")

(call (call 1 2))

(if this?
    then ; <- sometimes!
    that)

(fn match-same-line? [callee i out viewed]
  (and (= :match callee) (= 0 (math.fmod i 2))
       (<= (+ (or (string.find viewed "\n") (length viewed)) 1
              (last-line-length (. out (length out)))) 80)))

(#(+ $ 5) 9)

(fn blood [v n c]
  (let [pv (->view (vadd (vmul v 8) (point 4 4)))]
    (for [i 1 n]
      (var c {:type :circ :pos (vadd pv (rand-point 4)) :r 1 :c (or c 6)})
      (add fx c)
      (wait (rand 5)
            (fn []
              (tween c :r (rand 4) 6
                     {:f (fn [c]
                           (tween c :r 0 6
                                  {:f (fn [c]
                                        (remove fx c))}))}))))))
