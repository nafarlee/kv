#!/usr/bin/env -S guile -e main -s
!#
(add-to-load-path (dirname (current-filename)))
(use-modules ((lib)
              #:prefix lib:))

(define (main args)
  (display (lib:create-tcp-socket 12345))
  (newline))
