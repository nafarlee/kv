(import spork/test)
(import /kv/resp :as i)
(import /kv/cache :as c)

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
   "*3\r\n+SET\r\n+LIFE\r\n:42\r\n"
   (i/resp-dump [:SET :LIFE 42])))

(with-test "should SET and GET a key"
  (def expected 42)
  (def actual (let [cache (c/make-cache)]
                (c/dispatch cache ["SET" "life" 42])
                (c/dispatch cache ["GET" "life"])))
  (assert-equal expected actual))

(with-test "should delete a key with negative EXPIRE"
  (def expected nil)
  (def actual (let [cache (c/make-cache)]
                (c/dispatch cache ["SET" "life" 42])
                (c/dispatch cache ["EXPIRE" "life" -1])
                (c/dispatch cache ["GET" "life"])))
  (assert-equal expected actual))

(with-test "should not set EXPIRE on empty key"
  (def expected 0)
  (def actual (let [cache (c/make-cache)]
                (c/dispatch cache ["EXPIRE" "life" -1])))
  (assert-equal expected actual))

(with-test "should set TTL with a positive EXPIRE"
  (def expected 10)
  (def actual (let [cache (c/make-cache)]
                (c/dispatch cache ["SET" "life" 42])
                (c/dispatch cache ["EXPIRE" "life" 10])
                (c/dispatch cache ["TTL" "life"])))
  (assert-equal expected actual))

(with-test "should clear ttl on SET"
  (assert-equal
   -1
   (let [cache (c/make-cache)]
     (c/dispatch cache ["SET" "life" 42])
     (c/dispatch cache ["EXPIRE" "life" 10])
     (c/dispatch cache ["SET" "life" 100])
     (c/dispatch cache ["TTL" "life"]))))

(with-test "should clear ttl on DEL"
  (assert-equal
   -2
   (let [cache (c/make-cache)]
     (c/dispatch cache ["SET" "life" 42])
     (c/dispatch cache ["EXPIRE" "life" 10])
     (c/dispatch cache ["DEL" "life"])
     (c/dispatch cache ["TTL" "life"]))))

(with-test "should not clear ttl on INCR"
  (assert-equal
   10
   (let [cache (c/make-cache)]
     (c/dispatch cache ["SET" "life" 42])
     (c/dispatch cache ["EXPIRE" "life" 10])
     (c/dispatch cache ["INCR" "life"])
     (c/dispatch cache ["TTL" "life"]))))

(with-test "should delete after expiration is reached"
  (assert-equal
   nil
   (let [cache (c/make-cache)]
     (c/dispatch cache ["SET" "life" 42])
     (c/dispatch cache ["EXPIRE" "life" 1])
     (ev/sleep 2)
     (c/dispatch cache ["GET" "life"]))))
