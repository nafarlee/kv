(import ./error :prefix "")

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
    (nil? x)     "$-1\r\n"
    (error? x)   (string "-" (get x :message) "\r\n")
    (indexed? x) (string "*" (length x) "\r\n" ;(map resp-dump x))
    (int? x)     (string ":" x "\r\n")
    (buffer? x)  (string "$" (length x) "\r\n" x "\r\n")
    (bytes? x)   (string "+" x "\r\n")))
