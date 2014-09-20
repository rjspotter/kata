(ns euler.core.problem_1)

(defn solve
  "If we list all the natural numbers below 10 that are multiples of 3 or 5, we
   get 3, 5, 6 and 9. The sum of these multiples is 23.

   Find the sum of all the multiples of 3 or 5 below 1000."
  []
  (let [threesy? (fn [num] (= (mod num 3) 0))
        fivesy?  (fn [num] (= (mod num 5) 0))]
    (reduce + (filter #(or (threesy? %) (fivesy? %)) (range 1 1000)))))