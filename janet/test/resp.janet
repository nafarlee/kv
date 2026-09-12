(import spork/test)
(import /init :as i)

(defmacro with-test [name & body]
  ~(do
     (test/start-suite ,name)
     ,;body 
     (test/end-suite)))

(defn assert-equal [e a]
  (if (deep= e a)
    (test/assert true)
    (do
      (eprintf "Expected: %n\n  Actual: %n" e a)
      (test/assert false))))

(with-test "should parse COMMAND DOCS correctly"
  (def expected @[@["COMMAND" "DOCS"]])
  (def actual (peg/match i/RESP "*2\r\n$7\r\nCOMMAND\r\n$4\r\nDOCS\r\n"))
  (assert-equal expected actual))
