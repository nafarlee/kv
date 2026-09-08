#!/usr/bin/env janet

(def BUFFER_SIZE 4096)
(def PORT 4096)

(def RESP
 '{:main        :value
   :return      "\r\n"
   :value       :aggregate
   :aggregate   (+ :array :bulk-string)
   :d+          (some (range "09"))
   :bulk-string (% (* "$" (lenprefix (* (number :d+) :return) (<- 1)) :return))
   :array       (group (* "*" (lenprefix (* (number :d+) :return) :value)))})

(defn handler [connection]
  (defer (:close connection)
    (def id (gensym))
    (defn lp [in]
      (when in
        (when-let ([parsed] (peg/match RESP in))
          (print (string/format "%s< %n" id parsed)))
        (:write connection "+OK\r\n")
        (print (string/format "%s> \"+OK\"" id))
        (lp (:read connection BUFFER_SIZE))))
    (lp (:read connection BUFFER_SIZE))))

(defn serve []
  (print "Listening on port " PORT "...")
  (net/server "127.0.0.1" PORT handler))

(defn main [& args]
  (serve))
