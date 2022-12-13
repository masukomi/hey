(module uri-tools 
  (generate-graph-url 
    json->uri-string 
    json->string open-url
    post-graph-data)
 (import scheme)

 (import chicken.file.posix)
 (import chicken.io)
 (import chicken.base)
 (import chicken.process)
 (import http-client)
 (import listicles)
 (import chicken.format)
 (import uri-common)
 (import json)

  ;; Perform a POST of the key "test" with value "value" to an echo service:
  ;; (with-input-from-request "http://localhost/echo-service"
  ;;                        '((test . "value")) read-string)

  (define (post-graph-data graph-type labels series title)
    (let ((labels-string (json->string labels))
          (series-string (json->string series)))
      ; (print (sprintf "graph-type: ~A" graph-type))
      ; (print (sprintf "title: ~A" title))
      ; (print (sprintf "labels-string: ~A" labels-string))
      ; (print (sprintf "series-string: ~A" series-string))
      (with-input-from-request
        "https://interrupttracker.com/graph.cgi"
        (list 
          (cons "graph_type" graph-type)
          (cons "title"      title)
          (cons "labels"     labels-string)
          (cons "series"     series-string))
        read-string
      )
    )
  )

 (define (generate-graph-url graph-type labels series title)
  (let ((encoded-labels (json->uri-string (mflatten labels)))
        (encoded-series (json->uri-string (mflatten series))))
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
