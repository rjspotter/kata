(ns euler.problem_2)

(defn solve
  "Each new term in the Fibonacci sequence is generated by adding the previous
   two terms. By starting with 1 and 2, the first 10 terms will be:

   1, 2, 3, 5, 8, 13, 21, 34, 55, 89, ...

   By considering the terms in the Fibonacci sequence whose values do not exceed
    four million, find the sum of the even-valued terms."
  []
  (reduce + (for [x fib-seq :when (even? x) :while (< x 4000000)] x)))

(def fib-seq
  ((fn rfib [x y]
     (lazy-seq (cons x (rfib y (+ x y))))) 1 2))