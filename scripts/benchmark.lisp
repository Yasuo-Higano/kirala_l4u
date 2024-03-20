
(def! run-time (fn* (f) (let* [
    start (time-ms)
    ]
    (println "start:" start)
    (bindf result (f))
    (bindf end (time-ms))
    (println "end:" end)
    (list (/ (- end start) 1000.0) result))))
(def! tarai (fn* (x y z) (if (<= x y) y (tarai (tarai (- x 1) y z) (tarai (- y 1) z x) (tarai (- z 1) x y)))))
(println "(run-time (fn* () (tarai 12 6 0)))")


