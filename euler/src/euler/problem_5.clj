(ns euler.problem_5 (:require [clojure.math.numeric-tower :as math]))

(defn solve
  "2520 is the smallest number that can be divided by each of the numbers from
   1 to 10 without any remainder.

   What is the smallest positive number that is evenly divisible by all of the
   numbers from 1 to 20?"
  []
  (let [
        div20? (fn [num] (= (rem num 20) 0))
        div19? (fn [num] (= (rem num 19) 0))
        div18? (fn [num] (= (rem num 18) 0))
        div17? (fn [num] (= (rem num 17) 0))
        div16? (fn [num] (= (rem num 16) 0))
        div15? (fn [num] (= (rem num 15) 0))
        div14? (fn [num] (= (rem num 14) 0))
        div13? (fn [num] (= (rem num 13) 0))
        div12? (fn [num] (= (rem num 12) 0))
        div11? (fn [num] (= (rem num 11) 0))
        div10? (fn [num] (= (rem num 10) 0))
        div9?  (fn [num] (= (rem num 9) 0))
        div8?  (fn [num] (= (rem num 8) 0))
        div7?  (fn [num] (= (rem num 7) 0))
        div6?  (fn [num] (= (rem num 6) 0))
        div5?  (fn [num] (= (rem num 5) 0))
        div4?  (fn [num] (= (rem num 4) 0))
        div3?  (fn [num] (= (rem num 3) 0))
        div2?  (fn [num] (= (rem num 2) 0))
        ]
    (loop [current 1]
      (if (and (div20? current)
               (div19? current)
               (div18? current)
               (div17? current)
               (div16? current)
               (div15? current)
               (div14? current)
               (div13? current)
               (div12? current)
               (div11? current)
               (div10? current)
               (div9? current)
               (div8? current)
               (div7? current)
               (div6? current)
               (div5? current)
               (div4? current)
               (div3? current)
               (div2? current))
        current
        (recur (inc current))))))