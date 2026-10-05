(defn as-number [x & args]
  (if (number? x)
    x
    (scan-number x ;args)))
