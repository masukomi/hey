
(module listicles
  (
   nth
   range
   split-by
   list-includes
   flatten
   pairs-list-to-hash
   replace-nth
   last-index
   sort-strings>
   sort-strings<
  )
  (import chicken)
  (import scheme)
  (import srfi-1)
  (import srfi-69)
  (use extras)
  ; (doc-fun "nth" 
  ;   "## Public: 
  ;   returns the \"nth\" item of a list
  ;
  ;   ### Parameters:
  ;   * n - the 0 based index into the list
  ;   * lst - the list you wish to receive the nth element from
  ;
  ;   ### Returns:
  ;   The nth item of a list (if available)
  ;
  ;   ### Exceptions:
  ;   If n is outside of the bounds of the list then an 
  ;   \"Index out of bounds\" error will be thrown")
  (define (nth n lst)
    (if (or (> n (- (length lst) 1)) (< n 0))
      (error 'nth "Index out of bounds.")
      (if (eq? n 0)
        (car lst)
        (nth (- n 1) (cdr lst)))))

  (define (last-index lst)
    (if (eq? (length lst) 0)
      0
      (- (length lst) 1))
    )


  (define (replace-nth n replacement lst)
    (cond 
      ((null? lst) '())
      ((eq? n 0) (cons replacement (replace-nth (- n 1) '() (cdr lst))))
      (else
        (cons (car lst) (replace-nth (- n 1) replacement (cdr lst))))
    ))

  ; found on stack overflow
  ; https://stackoverflow.com/a/4542458/13973
  (define (find-replace a b list)
   (cond
    ((null? list) '())
    ((list? (car list)) (cons (find-replace a b (car list)) (find-replace a b (cdr list))))
    ((eq? (car list) a) (cons b (find-replace a b (cdr list))))
    (else
     (cons (car list) (find-replace a b (cdr list))))))


  ; (doc-fun "range"
  ;   "### Public:
  ;   creates a range from a to b in steps.
  ;
  ;   ### Parameters:
  ;   * a - the starting number
  ;   * b - the maximum number
  ;   * increment (optional) - the number that will be added at each step from 
  ;     a to b. Defaults to 1
  ;   * existing (optional) - a starting list to add to. Defaults to `'()`
  ;
  ;   ### Returns:
  ;   A list of numbers from a to b in steps of increment
  ;
  ;   ### Example:
  ;       (range 1 5)                  ;=> (1 2 3 4 5)
  ;       (range 5 1 -1)               ;=> (5 4 3 2 1)
  ;       (range 1 10 2)               ;=> (1 3 5 7 9)
  ;       (range 1 5 1 (range 6 10 2)) ;=> (1 2 3 4 5 6 8 10)
  ;
  ;   ### Notes:
  ;   Mathematically impossible instructions will result in an infinite loop. E.g.
  ;   going from 1 to 5 in steps of -1.
  ;   ")
  (define (range a b #!optional (increment 1) (existing '()))
    (if (if (> increment 0) (<= a b) (>= a b))
      (cons a (range (+ increment a) b increment existing) )
      existing))

  ; (doc-fun "split-by" 
  ; "## Public: split-by
  ; splits an list into multiple lists of n length (or smaller).
  ; ### Parameters:
  ;  * n - the size of the lists it should be broken into.
  ;  * lst - the list to be split
  ;    If the provided list can not be evenly divisible
  ;    by n then the last returned list will contain
  ;    the remaining elements.
  ; ### Returns:
  ; A list of smaller list of the specified length (or smaller).
  ; ### Examples:
  ;    (split-by 2 '(1 2 3 4)) ; => ((1 2) (3 4))
  ;    (split-by 2 '(1 2 3)) ; => ((1 2) (3)) ; not evenly divisible")
  (define (split-by n lst)
     (let ( (list-size (length lst)) )
       (if (not (eq? 0 (modulo list-size n)))
         (error (sprintf "list is not evenly divisible by ~A: ~A" n lst)))
       (if (not (eq? list-size 0))
           (cons (take lst n) (split-by n (drop lst n)))
           '() )))

; ### Public:
; 	Tests if the provided list includes the specified item
; ### Paramaters:
; * a-list - the list to be inspected
; * an-item - the item to be searched for
;
; ### Returns:
; \#t or \#f indicating the presence of the item in the list.
;
; ### Example:
; (list-includes '(1 2 3) 2) ;=> #t
; (list-includes '(1 2 3) 4) ;=> #f
  (define (list-includes a-list an-item)
    (let ((index (list-index (lambda(x)(equal? an-item x)) a-list)))
      (if (eq? index #f)
        #f #t)))

  (define (flatten a-list)
    (cond ((null? a-list) '())
          ((pair? a-list) (append (flatten (car a-list)) (flatten (cdr a-list))))
          (else (list a-list))))

  (define (pairs-list-to-hash pairs-list)
    (let ((h (make-hash-table equal?)))
      (map (lambda (pair) (hash-table-set! h (car pair) (cdr pair))) pairs-list)
      h
      ))

  (define (sort-strings> lst)
    (cond
      ((null? lst) '())
      (else (insert-string> (first lst) (sort-strings> (cdr lst))))))
  (define (sort-strings< lst)
    (reverse (sort-strings> lst))) ; cheat!


(define (insert-string> s lst)
  (cond
    ((null? lst) (cons s '()))
    (else
      (if (string>=? s (first lst))
              (cons s lst)
              (cons (first lst) (insert-string> s (cdr lst)))))))

)
