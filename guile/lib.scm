(define-module (lib)
  #:use-module ((ice-9 rdelim)
                #:select (read-line))
  #:export (parse
            create-tcp-socket
            start-blocking-server
            echo-handler))

(define (parse command)
  "Hello, World!")

(define (echo-handler client)
  (let loop ()
    (let ((line (read-line client)))
      (unless (eof-object? line)
        (display line client)
        (newline client)
        (force-output client)
        (loop))))
  (close-port client))

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
