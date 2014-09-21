(ns euler.problem_4 (:require [clojure.math.numeric-tower :as math]))

(defn solve
  "A palindromic number reads the same both ways. The largest palindrome made
   from the product of two 2-digit numbers is 9009 = 91 × 99.

   Find the largest palindrome made from the product of two 3-digit numbers."
  []
  (last (sort (generator))))

(defn generator []
  (loop [x 999 y 999 coll []]
    (let [testval (* x y)
          newcoll (if (= (str testval) (clojure.string/join "" (reverse (str testval))))
                    (conj coll testval)
                    coll)]
      (cond
       (< x 101) newcoll
       (< y 101) (recur (dec x) 999 newcoll)
       :else     (recur x (dec y) newcoll)))))