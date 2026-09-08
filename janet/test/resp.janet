(import spork/test)
(import /init :as i)

(test/start-suite :RESP)
(test/assert
 (do
   (def expected @["COMMAND" "DOCS"])
   (def [actual] (peg/match i/RESP "*2\r\n$7\r\nCOMMAND\r\n$4\r\nDOCS\r\n"))
   (deep= expected actual))
 "should parse COMMAND DOCS correctly")
(test/end-suite)
