(use testament)
(import /kv/resp :as r)
(import /kv/cache :as c)

(defmacro with-test [name & body]
  ~(deftest ,(->> name (string/replace-all " " "-") symbol) 
     ,;body))

(with-test "should parse COMMAND DOCS correctly"
  (def expected @["COMMAND" "DOCS"])
  (def actual (r/resp-parse "*2\r\n$7\r\nCOMMAND\r\n$4\r\nDOCS\r\n"))
  (is (== expected actual)))

(with-test "should dump SET LIFE 42 correctly"
  (is (==
       "*3\r\n+SET\r\n+LIFE\r\n:42\r\n"
       (r/resp-dump [:SET :LIFE 42]))))

(with-test "should SET and GET a key"
  (def expected 42)
  (def actual (let [cache (c/make-cache)]
                (c/dispatch cache ["SET" "life" 42])
                (c/dispatch cache ["GET" "life"])))
  (is (== expected actual)))

(with-test "should have case-insensitive commands"
  (def expected 42)
  (def actual (let [cache (c/make-cache)]
                (c/dispatch cache ["sEt" "life" 42])
                (c/dispatch cache ["GeT" "life"])))
  (is (== expected actual)))

(with-test "should delete a key with negative EXPIRE"
  (def expected nil)
  (def actual (let [cache (c/make-cache)]
                (c/dispatch cache ["SET" "life" 42])
                (c/dispatch cache ["EXPIRE" "life" -1])
                (c/dispatch cache ["GET" "life"])))
  (is (== expected actual)))

(with-test "should not set EXPIRE on empty key"
  (def expected 0)
  (def actual (let [cache (c/make-cache)]
                (c/dispatch cache ["EXPIRE" "life" -1])))
  (is (== expected actual)))

(with-test "should set TTL with a positive EXPIRE"
  (def expected 1)
  (def actual (let [cache (c/make-cache)]
                (c/dispatch cache ["SET" "life" 42])
                (c/dispatch cache ["EXPIRE" "life" 1])
                (c/dispatch cache ["TTL" "life"])))
  (is (== expected actual)))

(with-test "should clear ttl on SET"
  (is (==
       -1
       (let [cache (c/make-cache)]
         (c/dispatch cache ["SET" "life" 42])
         (c/dispatch cache ["EXPIRE" "life" 1])
         (c/dispatch cache ["SET" "life" 100])
         (c/dispatch cache ["TTL" "life"])))))

(with-test "should clear ttl on DEL"
  (is (==
       -2
       (let [cache (c/make-cache)]
         (c/dispatch cache ["SET" "life" 42])
         (c/dispatch cache ["EXPIRE" "life" 1])
         (c/dispatch cache ["DEL" "life"])
         (c/dispatch cache ["TTL" "life"])))))

(with-test "should not clear ttl on INCR"
  (is (==
       1
       (let [cache (c/make-cache)]
         (c/dispatch cache ["SET" "life" 42])
         (c/dispatch cache ["EXPIRE" "life" 1])
         (c/dispatch cache ["INCR" "life"])
         (c/dispatch cache ["TTL" "life"])))))

(with-test "should gracefully handle a string-y EXPIRE"
  (is (==
       1
       (let [cache (c/make-cache)]
         (c/dispatch cache ["SET" "life" 42])
         (c/dispatch cache ["EXPIRE" "life" "1"])
         (c/dispatch cache ["TTL" "life"])))))

(with-test "should remove ttl upon PERSIST"
  (let [cache (c/make-cache)]
    (c/dispatch cache ["SET" "life" 42])
    (c/dispatch cache ["EXPIRE" "life" 1])
    (is (== 1 (c/dispatch cache ["PERSIST" "life"])))
    (is (== -1 (c/dispatch cache ["TTL" "life"])))))

(with-test "should return updated value on INCR"
  (let [cache (c/make-cache)]
    (c/dispatch cache ["SET" "life" 42])
    (is (== 43 (c/dispatch cache ["INCR" "life"])))
    (is (== 43 (c/dispatch cache ["GET" "life"])))))

(with-test "should delete after expiration is reached"
  (is (==
       nil
       (let [cache (c/make-cache)]
         (c/dispatch cache ["SET" "life" 42])
         (c/dispatch cache ["EXPIRE" "life" 1])
         (ev/sleep 2)
         (c/dispatch cache ["GET" "life"])))))

(with-test "should always return a string from GET"
  (let [cache (c/make-cache)]
    (c/dispatch cache ["SET" "life" 42])
    (is (== "42" (c/dispatch cache ["GET" "life"])))))

(run-tests!)
