
(def! reduce (fn* (f init xs)
  (if (empty? xs) init (reduce f (f init (first xs)) (rest xs)))))
(def! foldr (fn* [f init xs]
  (if (empty? xs) init (f (first xs) (foldr f init (rest xs))))))

(def! nth
  (fn* [xs index]
    (if (if (<= 0 index) (not (empty? xs))) ; logical and
      (if (= 0 index)
        (first xs)
        (nth (rest xs) (- index 1)))
      (throw "nth: index out of range"))))

;; ;  実行される順番が逆で、結果は正しい
;; (def! map
;;   (fn* [f xs]
;;     (foldr (fn* [x acc] (cons (f x) acc)) () xs)))


(def! concat
  (fn* [& xs]
    (foldr (fn* [x acc] (foldr cons acc x)) () xs)))
(def! conj
  (fn* [xs & ys]
    (if (vector? xs)
      (vec (concat xs ys))
      (reduce (fn* [acc x] (cons x acc)) xs ys))))

;; Folds

(def! sum     (fn* [xs] (reduce + 0 xs)))
(def! product (fn* [xs] (reduce * 1 xs)))

(def! conjunction
  (let* [and2 (fn* [acc x] (if acc x false))]
    (fn* [xs]
      (reduce and2 true xs))))
(def! disjunction
  (let* [or2 (fn* [acc x] (if acc true x))]
    (fn* [xs]
      (reduce or2 false xs))))

(def! sum_len
  (let* [add_len (fn* [acc x] (+ acc (count x)))]
    (fn* [xs]
      (reduce add_len 0 xs))))
(def! max_len
  (let* [update_max (fn* [acc x] (let* [l (count x)] (if (< acc l) l acc)))]
    (fn* [xs]
      (reduce update_max 0 xs))))

;; (fn* [& fs] (foldr (fn* [f acc] (fn* [x] (f (acc x)))) identity fs))
;; computes the composition of an arbitrary number of functions.
;; The first anonymous function is the mathematical composition.
;; For practical purposes, `->` and `->>` in `core.l4u` are more
;; efficient and general.

; (cond COND1 EXPR1 COND2 EXPR2.....)
(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw "odd number of forms to cond")) (cons 'cond (rest (rest xs)))))))


