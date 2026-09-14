#!/usr/bin/env janet

(def BUFFER_SIZE 4096)
(def PORT 6379)


(def Error
  {:prototype @{}
   :new (fn [self message]
          (table/setproto @{:message message} (:prototype self)))})


(defn error? [e]
  (and (table? e) (= (getproto e) (:prototype Error))))


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
    (nil? x)     "_\r\n"
    (error? x)   (string "-" (get x :message) "\r\n")
    (indexed? x) (string "*" (length x) "\r\n" ;(map resp-dump x))
    (int? x)     (string ":" x "\r\n")
    (bytes? x)   (string "$" (length x) "\r\n" x "\r\n")))


(defn put-new [x k v]
  (put x k v)
  v)


(defn as-number [x & args]
  (if (number? x)
    x
    (scan-number x ;args)))


(defn execute [ht command]
  (match command
    ["EXISTS" & ks]
    (length (filter |(has-key? ht $) ks))

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
