(declare-project
  :name "kv"
  :description ```Toy kv service ```
  :version "0.0.0"
  :dependencies [{:repo "https://github.com/pyrmont/testament"
                  :tag "c3a7f380b3ac5a3174c96eeed971ef71622df684"}])

(declare-executable
  :name "kv"
  :entry "kv/init.janet")

(task "run" ["build"]
  (os/execute ["./build/kv"] :p))
