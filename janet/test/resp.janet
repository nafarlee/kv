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
  (def expected @["COMMAND" "DOCS"])
  (def actual (i/resp-parse "*2\r\n$7\r\nCOMMAND\r\n$4\r\nDOCS\r\n"))
  (assert-equal expected actual))

(with-test "should dump SET LIFE 42 correctly"
  (assert-equal
   "*3\r\n$3\r\nSET\r\n$4\r\nLIFE\r\n:42\r\n"
   (i/resp-dump [:SET :LIFE 42])))
