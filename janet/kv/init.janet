#!/usr/bin/env janet
(import ./resp :prefix "")
(import ./cache :prefix "")


(def BUFFER_SIZE 4096)
(def PORT 6379)


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
