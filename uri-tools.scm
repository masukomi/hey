(module uri-tools
  (
    json->uri-string
    json->string
    open-url
  )
  (import chicken)
  (import scheme)
  (use posix)
  (use ports)
  (use extras)
  (require-extension uri-common)
  (require-extension json)
  
  (define (json->uri-string data)
    (uri-encode-string (json->string data)))

  (define (json->string data)
    (let ((output-port (open-output-string)))
      (json-write data output-port)
      (get-output-string output-port)))
  
  (define (open-url url)
    ; (print url)
    (system (sprintf "open \"~A\"" url)))
)
