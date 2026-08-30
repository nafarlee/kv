(use-modules (srfi srfi-64)
             ((lib) #:prefix l.))

(test-group "parse"
  (test-equal "SET:basic" '(set life 42) (l.parse "set life 42")))
