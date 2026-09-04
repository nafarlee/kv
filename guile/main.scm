(import
  (scheme base)
  (only (scheme process-context) command-line)
  (prefix (lib) l.))

(define (main args)
  (l.start-blocking-server 6379 l.echo-handler))

(main (command-line))
