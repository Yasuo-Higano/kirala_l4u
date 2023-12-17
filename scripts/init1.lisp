(defn reverse [xs]
  (let* [
          rev (fn* [xs acc]
                    (if (empty? xs)
                    acc
                    (rev (rest xs) (cons (first xs) acc))))
        ]
        (rev xs ())))

(defn map [f xs]
  (let* [
          map-rec (fn* [xs acc]
            (if (empty? xs)
                (reverse acc)
                (map-rec (rest xs) (cons (f (first xs)) acc))))
        ]
        (map-rec xs ())))

(defn for-each [f xs]
  (let* [
          map-rec (fn* [xs]
            (if (empty? xs)
                (map-rec (rest xs) )))
        ]
        (map-rec xs)))

(defn range [start end]
        :description
        """
        Returns a list of integers from start (inclusive) to end (exclusive). 
        """
    (let* [
          range-rec (fn* [start end acc]
                        (if (= start end)
                        acc
                        (range-rec (+ start 1) end (cons start acc))))
        ]
        (reverse (range-rec start end ()))
  ))

;

(defn caar [x] (car (car x)))
(defn cadr [x] (car (cdr x)))
(defn cadar [x] (car (cdr (car x))))
(defn caddr [x] (car (cdr (cdr x))))
(defn caddar [x] (car (cdr (cdr (car x)))))

(def! case case*)



