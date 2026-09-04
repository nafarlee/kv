(import (scheme base)
        (srfi 64)
        (prefix (lib) l.))

(define-syntax test
  (syntax-rules ()
    ((_ name body ...)
     (begin
       (test-begin name)
       body ...
       (test-end name)))))

(test "parse"
  (test-equal '(set life 42) (l.parse "set life 42")))
