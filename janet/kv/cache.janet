(import ./error :prefix "")
(import ./util :prefix "")

(defn execute [ht command]
  (match command
    ["EXISTS" & ks]
    (length (filter |(has-key? ht $) ks))

    ["INCR" k]
    (if-let [n (as-number (get ht k 0) 10)]
      (put-new ht k (+ n 1))
      (:new Error (string/format "Key does not contain a number '%V'" k)))

    ["SET" k v]
    (do
      (put ht k v)
      "OK")
    
    ["GET" k]
    (get ht k)

    ["DEL" & ks]
    (reduce
     (fn :del-reducer [c k]
       (if (has-key? ht k)
         (do
           (put ht k nil)
           (+ c 1))
         c))
     0
     ks)

    ["COMMAND" "DOCS"]
    "OK"
    
    [c]
    (:new Error (string/format "Unknown command '%V'" c))))
