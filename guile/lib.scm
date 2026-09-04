(define-library (lib)
  (export parse
          start-blocking-server
          echo-handler)
  (import (scheme base)
          (only (scheme write)
                display)
          (only (srfi 28)
                format)
          (only (srfi 106)
                socket-accept
                make-server-socket
                call-with-socket
                socket-output-port
                socket-input-port))
  (begin
    (define (parse command)
      "Hello, World!")

    (define (call-with-output-bytevector proc)
      (let ((bv (open-output-bytevector)))
        (proc bv)
        (get-output-bytevector bv)))

    (define (create-tcp-socket port)
      (make-server-socket (number->string port)))

    (define (read-line port)
      (utf8->string
       (call-with-output-bytevector
         (lambda (out)
           (let loop ((b (read-u8 port)))
             (case b
               ((#xA) #t)
               ((#xD) (loop (read-u8 port)))
               (else (write-u8 b out)
                     (loop (read-u8 port)))))))))

    (define (start-blocking-server port handler)
      (call-with-socket (create-tcp-socket port)
        (lambda (sock)
          (display (format "Starting kv server on port ~a...~%" port))
          (let loop ()
            (handler (socket-accept sock))
            (loop)))))

    (define (echo-handler client)
      (let ((in (socket-input-port client))
            (out (socket-output-port client)))
        (let loop ()
          (let ((line (read-line in)))
            (unless (eof-object? line)
              (display (format "< ~s~%" line))
              (write-bytevector (string->utf8 (string-append line "\n")) out)
              (display (format "> ~s~%" line))
              (flush-output-port out)
              (loop))))))))
