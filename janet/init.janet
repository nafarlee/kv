#!/usr/bin/env janet

(def BUFFER_SIZE 4096)
(def PORT 6379)

(def RESP
 '{:main        :value
   :return      "\r\n"
   :value       :aggregate
   :aggregate   (+ :array :bulk-string)
   :d+          (some (range "09"))
   :bulk-string (% (* "$" (lenprefix (* (number :d+) :return) (<- 1)) :return))
   :array       (group (* "*" (lenprefix (* (number :d+) :return) :value)))})


(defn resp-parse [s]
  (first (peg/match RESP s)))


(defn resp-dump [x]
  (cond
    (indexed? x) (string "*" (length x) "\r\n" ;(map resp-dump x))
    (int? x)     (string ":" x "\r\n")
    (bytes? x)   (string "$" (length x) "\r\n" x "\r\n")))


(defn execute [ht command]
  (match command
    ["SET" k v]
    (do
      (put ht k v)
      :OK)
    
    ["GET" k]
    (get ht k)

    ["COMMAND" "DOCS"]
    :OK))


(defn handler [t connection]
  (defer (:close connection)
    (def id (gensym))
    (defn lp [in]
      (when in
        (def parsed (resp-parse in))
        (printf "%s< %n" id parsed)
        (def output (execute t parsed))
        (printf "%s> %n" id output)
        (:write connection (resp-dump output))
        (lp (:read connection BUFFER_SIZE))))
    (lp (:read connection BUFFER_SIZE))))

(defn serve []
  (print "Listening on port " PORT "...")
  (net/server "127.0.0.1" PORT (partial handler @{})))

(defn main [& args]
  (serve))
