#!/usr/bin/env janet
(import ./error :prefix "")
(import ./resp :prefix "")
(import ./util :prefix "")


(def BUFFER_SIZE 4096)
(def PORT 6379)


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


(defn handler [t connection]
  (defer (:close connection)
    (def id (gensym))
    (defn lp [in]
      (when in
        (def parsed (resp-parse in))
        (printf "%n" {:_client id :_type :request :rin in :in parsed})
        (def output (execute t parsed))
        (def dumped (resp-dump output))
        (printf "%n" {:_client id
                      :_type :response
                      :rin in
                      :in parsed
                      :rout dumped
                      :out output})
        (:write connection dumped)
        (lp (:read connection BUFFER_SIZE))))
    (lp (:read connection BUFFER_SIZE))))

(defn serve []
  (print "Listening on port " PORT "...")
  (def t @{})
  (net/server "127.0.0.1" PORT |(handler t $))) 

(defn main [& args]
  (serve))
