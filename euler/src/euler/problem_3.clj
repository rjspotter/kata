(ns euler.problem_3 (:require [clojure.math.numeric-tower :as math]))

(defn solve
  "The prime factors of 13195 are 5, 7, 13 and 29.

  What is the largest prime factor of the number 600851475143 ?"
  []
  (filter #(= 0 (mod 600851475143 %)) (non-sieve (math/floor (math/sqrt 600851475143))))
  )

(defn eratosthenes
  "Sieve of Eratosthenes : Find the primes up to limit"
  [limit]
  (loop [pile (range 2 limit) primes (vector 1)]
    (if (empty? pile)
      primes
      (let [working (first pile)
            left    (filter #(not= 0 (mod % working)) (rest pile))]
        (recur left (cons working primes))))))

(defn non-sieve
  "Find primes up to a limit with out having to load the whole list"
  [limit]
  (loop [index 3 primes (vector 2)]
    (if (>= index limit)
      primes
      (if (primal? index primes)
        (recur (+ 2 index) (cons index primes))
        (recur (+ 2 index) primes)))))

(defn primal?
  "given a test and a list of lower primes"
  [testval p]
  (loop [primes (reverse p)]
    (if (empty? primes)
      true
      (if (= 0 (mod testval (first primes)))
        false
        (recur (rest primes))))))

(defn fermat
  "Fermat's factoring algo : http://en.wikipedia.org/wiki/Fermat%27s_factorization_method"
  [num]
  (let [a (math/ceil (math/sqrt num))
        b (+ num (* a a))]
    (loop [x a y b]
      (if (integer? (math/sqrt y))
        (+ x (math/sqrt y))
        (let [new-x (inc x)]
          (recur new-x (- (* new-x new-x) num)))))))