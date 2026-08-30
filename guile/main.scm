#!/usr/bin/env -S guile -e main -s
!#
(add-to-load-path (dirname (current-filename)))
(use-modules ((lib)
              #:prefix l.))

(define (main args)
  (l.start-blocking-server (l.create-tcp-socket 12345) l.echo-handler))
