#!/usr/bin/env janet
(import ./cache :prefix "")


(def BUFFER_SIZE 4096)
(def PORT 6379)


(defn handler [t connection]
  (defer (:close connection)
    (def id (gensym))
    (defn lp [in]
      (when in
        (printf "%n" {:_client id :_type :request :in in})
        (def out (accept t in))
        (printf "%n" {:_client id :_type :response :out out})
        (:write connection out)
        (lp (:read connection BUFFER_SIZE))))
    (lp (:read connection BUFFER_SIZE))))

(defn serve []
  (print "Listening on port " PORT "...")
  (def t @{})
  (net/server "127.0.0.1" PORT |(handler t $))) 

(defn main [& args]
  (serve))
