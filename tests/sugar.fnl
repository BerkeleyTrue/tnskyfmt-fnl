(#(+ $ 5) 9)

(macro foo []
  `(do
     (print :stuff)
     (hello ,world)))
