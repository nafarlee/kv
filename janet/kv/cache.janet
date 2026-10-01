(import ./error :prefix "")
(import ./util :prefix "")
(import ./resp :as r)


(defn make-cache []
  {:data @{}})


(defn cache-get [{:data data} k &opt de]
  (get data k de))


(defn cache-has? [cache k]
  (not= nil (cache-get cache k)))


(defn cache-set! [{:data data} k v]
  (put data k v)
  v)
           

(defn execute [cache command]
  (match command
    ["EXISTS" & ks]
    (length (filter |(cache-has? cache $) ks))

    ["INCR" k]
    (if-let [n (as-number (cache-get cache k 0) 10)]
      (cache-set! cache k (+ n 1))
      (:new Error (string/format "Key does not contain a number '%V'" k)))

    ["SET" k v]
    (do
      (cache-set! cache k v)
      "OK")
    
    ["GET" k]
    (cache-get cache k)

    ["DEL" & ks]
    (reduce
     (fn :del-reducer [c k]
       (if (cache-has? cache k)
         (do
           (cache-set! cache k nil)
           (+ c 1))
         c))
     0
     ks)

    ["COMMAND" "DOCS"]
    "OK"
    
    [c]
    (:new Error (string/format "Unknown command '%V'" c))))


(defn accept [t input]
  (->> input
       r/resp-parse
       (execute t)
       r/resp-dump))
