(define-module (lib)
  #:export (parse

            create-tcp-socket))

(define (parse command)
  "Hello, World!")

(define (start-blocking-server sock handler)
  (listen sock 128)
  (let loop ()
    (let ((client (car (accept sock))))
      (handler client)
      (loop))))

(define (create-tcp-socket port)
  (let ((sock (socket PF_INET SOCK_STREAM 0)))
    (setsockopt sock SOL_SOCKET SO_REUSEADDR 1)
    (bind sock AF_INET INADDR_LOOPBACK port)
    sock))
