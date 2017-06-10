(module uri-tools (generate-graph-url json->uri-string json->string open-url)
 (import chicken)
 (import scheme)

 (use posix)
 (use ports)
 (use extras)

 (require-extension uri-common)
 (require-extension json)

 (define (generate-graph-url graph-type labels series title)
  (let ((encoded-labels (json->uri-string labels))
        (encoded-series (json->uri-string series)))
   (sprintf "https://interrupttracker.com/~A.html?title=~A&labels=~A&series=~A"
            graph-type
            (uri-encode-string title)
            encoded-labels
            encoded-series)))
 
 (define (json->string data)
  (let ((output-port (open-output-string)))
   (json-write data output-port)
   (get-output-string output-port)))

 (define (json->uri-string data)
  (uri-encode-string (json->string data)))

 (define (open-url url)
  ; (print url)
  (system (sprintf "open \"~A\"" url))))
