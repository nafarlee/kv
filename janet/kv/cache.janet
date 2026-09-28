(import ./error :prefix "")
(import ./util :prefix "")
(import ./resp :as r)


(defn make-cache []
  {:data @{}})
           

(defn execute [{:data data} command]
  (match command
    ["EXISTS" & ks]
    (length (filter |(has-key? data $) ks))

    ["INCR" k]
    (if-let [n (as-number (get data k 0) 10)]
      (put-new data k (+ n 1))
      (:new Error (string/format "Key does not contain a number '%V'" k)))

    ["SET" k v]
    (do
      (put data k v)
      "OK")
    
    ["GET" k]
    (get data k)

    ["DEL" & ks]
    (reduce
     (fn :del-reducer [c k]
       (if (has-key? data k)
         (do
           (put data k nil)
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
