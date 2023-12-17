
(def! run-time (fn* (f) (let* [start (time-ms) result (f) end (time-ms)] (list (/ (- end start) 1000) result))))
(def! tarai (fn* (x y z) (if (<= x y) y (tarai (tarai (- x 1) y z) (tarai (- y 1) z x) (tarai (- z 1) x y)))))
(run-time (fn* () (tarai 12 6 0)))


