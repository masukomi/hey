(module fmt-better

  (
   fmt-rows
  )
  (import chicken)
  (import scheme)
  (import fmt)
  (import listicles)
  (import srfi-13) ; string-join
  ; (import extras) ; sprintf
  (import data-structures) ; flatten

  (define (fmt-rows rows divider)
    (let ((columns 
            (flatten 
              (combine-cols-with-divider
                (cols-to-procedures
                  (convert-rows-to-cols rows))
                divider))
            ))
          (fmt #t
           (apply tabular
            columns))))
      ; (fmt #t (apply tabular (list "|" (dsp (string-join (list "a1" "a2" "a3") "\n")))))

  (define (cols-to-procedures cols)
    (map (lambda(c)(dsp (string-join c "\n"))) cols))
  (define (combine-cols-with-divider cols divider)
    (append
      (map (lambda(c)(list divider c)) cols)
      (list divider)))
  
)
