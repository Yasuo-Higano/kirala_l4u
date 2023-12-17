(def! read-file
    (fn* (filename)
        (eval (load-file filename))
))

(def! defmac (macro* (name args & body)
    `(def! ~name (macro* ~args ~@body))))

(def! defun (macro* (name args & body)
    `(def! ~name (fn* ~args ~@body))))

;(def! defmacro! defmacro)
(def! defn defun)
(def! def def!)
(def! let let*)
(def! fn fn*)
(def! first car)
(def! rest cdr)
(def! head car)
(def! tail cdr)

(def! swap! (fn* [a f & xs] (reset! a (apply f (deref a) xs))))
;(defmacro! swap! (fn* (a f & xs) `(reset! ~a (apply ~f (deref ~a) ~@xs))))

;(def! <= (fn* [a b] (not (< b a))))
;(def! >= (fn* [a b] (not (< a b))))

(defmacro! rename!
    (fn* [name_from name_to]
        `(do
            (bindf old_value (erase! ~name_from))
            (def! ~name_to old_value))))

(def! run-time (fn* [f]
    (let* [start (time-ms)
           result (f)
           end (time-ms)]
        (list (/ (- end start) 1000.0) result))))

