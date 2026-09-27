(def Error
  {:prototype @{}
   :new (fn [self message]
          (table/setproto @{:message message} (:prototype self)))})


(defn error? [e]
  (and (table? e) (= (getproto e) (:prototype Error))))
