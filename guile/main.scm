#!/usr/bin/env -S guile -e main -s
!#
(add-to-load-path (dirname (current-filename)))
(use-modules ((lib)
              #:prefix l.))

(define (main args)
  (l.start-blocking-server 6379 l.echo-handler))
