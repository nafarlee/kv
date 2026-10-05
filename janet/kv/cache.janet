(import ./error :prefix "")
(import ./util :prefix "")
(import ./resp :as r)


(defn make-cache []
  {:data @{}
   :ttls @{}})


(defn cache-get [{:data data} k &opt de]
  (get data k de))


(defn cache-has? [cache k]
  (not= nil (cache-get cache k)))


(defn cache-set! [{:data data} k v]
  (put data k v)
  nil)


(defn cache-ttl-set! [{:ttls ttls} k v]
  (put ttls k v)
  nil)


(defn cache-command-expire! [cache k sec]
  (def now (os/clock :realtime :int))
  (cond
    (not (cache-has? cache k))
    0

    (neg? sec)
    (do
      (cache-set! cache k nil)
      1)
    
    (do
      (cache-ttl-set! cache k (+ now sec))
      1)))


(defn cache-command-ttl [cache k]
  (if-not (cache-has? cache k)
    -2
    (let [ttl (get-in cache [:ttls k])]
      (if-not ttl
        -1
        (- ttl (os/clock :realtime :int))))))


(defn dispatch [cache command]
  (match command
    ["EXPIRE" k sec]
    (cache-command-expire! cache k sec)

    ["TTL" k]
    (cache-command-ttl cache k)

    ["EXISTS" & ks]
    (length (filter |(cache-has? cache $) ks))

    ["INCR" k]
    (if-let [n (as-number (cache-get cache k 0) 10)]
      (cache-set! cache k (+ n 1))
      (:new Error (string/format "Key does not contain a number '%V'" k)))

    ["SET" k v]
    (do
      (cache-set! cache k v)
      (cache-ttl-set! cache k nil)
      "OK")
    
    ["GET" k]
    (cache-get cache k)

    ["DEL" & ks]
    (reduce
     (fn :del-reducer [c k]
       (if (cache-has? cache k)
         (do
           (cache-set! cache k nil)
           (cache-ttl-set! cache k nil)
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
       (dispatch t)
       r/resp-dump))
