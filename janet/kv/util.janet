(defn put-new [x k v]
  (put x k v)
  v)


(defn as-number [x & args]
  (if (number? x)
    x
    (scan-number x ;args)))
