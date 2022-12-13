(module listicles
  (
   acons
   assoc-set
   alist-merge
   all?
   any?
   convert-rows-to-cols
   first-where
   insert-last
   last-index
   list-by-index
   list-includes?
   mflatten
   nth
   nth1
   pairs-list-to-hash
   range
   replace-nth
   sort-strings<
   sort-strings>
   split-by
  )
  ; (import chicken)
  (import scheme)
  (import srfi-1) ;define's first, last and list-index
  (import srfi-69)
  (import chicken.sort)
  (import chicken.format)
  (import chicken.base)

  ; (import extras)
  ; (import data-structures)
  (import simple-loops)
  ;TODO get rid of the do-list code so that we can jetison the
  ; dependency on loops


  ; constructs a new association list by adding
  ; the pair (key . datum) to the old a-list.
  ; liberated from Common Lisp:
  ; https://www.cs.cmu.edu/Groups/AI/html/cltl/clm/node153.html
  (define (acons key datum a-list)
    ;; (cons (cons key datum) a-list)
    (alist-cons key datum a-list))

  ; replaces values in the second list
  ; with the corresponding values in the first
  (define (alist-merge list-a list-b)
    ;cheat! convert them to hashes and merge those!
    ;then convert it back to an alist
    (hash-table->alist
     (hash-table-merge
      (pairs-list-to-hash list-a)
      (pairs-list-to-hash list-b))))

  ; returns a new list with the value of
  ; key set to the new value
  ; if there is more than one pair with
  ; the same key the redundant ones will
  ; be deleted.
  (define (assoc-set a-list key value)
    (alist-cons key value
      (alist-delete key a-list)))




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
  ;   ### Exapmle:
  ;   (nth 0 '(1 2 3)) ; => 1
  ;
  ;   ### Exceptions:
  ;   If n is outside of the bounds of the list then an
  ;   Error: (list-tail) out of range
  ;   will be thrown
  ;   ")
  (define (nth n lst)
    (list-ref lst n))

  ; (doc-fun "nth1"
  ;   "## Public:
  ;   returns the \"nth\" item of a list
  ;
  ;   ### Parameters:
  ;   * n - the 1 based index into the list
  ;   * lst - the list you wish to receive the nth element from
  ;
  ;   ### Returns:
  ;   The nth item of a list (if available) using normal numbering
  ;
  ;   ### Exapmle:
  ;   (nth1 1 '(1 2 3)) ; => 1
  ;
  ;   ### Exceptions:
  ;   If n is outside of the bounds of the list then an
  ;   Error: (list-tail) out of range
  ;   will be thrown
  ;   ")
  (define (nth1 n lst)
    (list-ref lst (- n 1)))

  (define (insert-last e lst)
    (let helper ((lst lst))
      (if (pair? lst)
        (cons (car lst)
              (helper (cdr lst)))
        (cons e '()))))

  (define (last-index lst)
    (if (eq? (length lst) 0)
      0
      (- (length lst) 1)))

  ; returns the first element where the test is true
  ; or '()
  (define (first-where lst test)
    (if (eq? (length lst) 0)
      '()
      (if (test (car lst))
        (car lst)
        (first-where (cdr lst) test))))

  (define (all? lst test)
    ; if there's nothing left and it hasn't failed yet
    (if (null? lst)
        #t
        (if (not (test (car lst)))
            #f
            (all? (cdr lst) test)
            )

        )
    )

  ;(any? '("foo" "bar") (lambda(x)(equal? "bar" x)))
  (define (any? lst test)
    (if (eq? (length lst) 0)
      #f
      (if (not (test (car lst)))
        (any? (cdr lst))
        #t)))

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
; (list-includes? '(1 2 3) 2) ;=> #t
; (list-includes? '(1 2 3) 4) ;=> #f
  (define (list-includes? a-list an-item)
    (let ((index (list-index (lambda(x)(equal? an-item x)) a-list)))
      (if (eq? index #f)
        #f #t)))

  (define (mflatten a-list)
    (cond ((null? a-list) '())
          ((pair? a-list) (append (mflatten (car a-list)) (mflatten (cdr a-list))))
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


  (define (convert-rows-to-cols rows)
    (let ((cols-hash (make-hash-table equal?)))
      (do-list row rows
        (extract-cols row cols-hash 0)
               )
      (let ((indexes
              (sort (hash-table-keys cols-hash) > )))
          (do-list idx indexes
            (hash-table-set!  cols-hash idx (reverse
                                              (hash-table-ref cols-hash idx))))
          ; values are now straight lists not dotted pairs
          (reverse (map (lambda (idx2)(hash-table-ref cols-hash idx2)) indexes))
        )))

  (define (list-by-index a-list #!optional map idx)
    (let ((idx (if idx idx 0))
          (map (if map map '())))
        (let ( ( new-map (cons (cons idx (car a-list)) map)) )
          (if (= (length a-list) 1 )
                  new-map
                  (list-by-index (cdr a-list) new-map (+ 1 idx))))))


; INTERNAL METHODS

  (define (insert-string> s lst)
    (cond
      ((null? lst) (cons s '()))
      (else
        (if (string>=? s (first lst))
                (cons s lst)
                (cons (first lst) (insert-string> s (cdr lst)))))))



  ; populates the hash with a reversed list for the specified idx
  ; used by convert-rows-to-cols
  (define (extract-cols row cols-hash idx)
    (if (not (null? row))
      (begin
        (hash-table-set! cols-hash idx
          (cons (car row) (hash-table-ref/default cols-hash idx '()) ))
        (extract-cols (cdr row) cols-hash (+ 1 idx)))))

)
