(module who-list (graph-who)
 (import chicken)
 (import scheme)
 (import srfi-1)
 (use srfi-13) ; string-join
 (import srfi-69) ; hash-table
 (use listicles)
 (use fmt-better)
 (use loops)
 (use sql-de-lite)
;  (use extras) ; sprintf
 (use data-structures) ; flatten

 (define (graph-who args db)
   (let ((people->interrupts (make-hash-table equal?))
         (people->tags       (make-hash-table equal?))
         (last-person "")
         (last-event 0)
         (rows (query fetch-rows (sql db
    "select p.name, t.name, ep.event_id

from people p
inner join events_people ep on ep.person_id = p.id
left outer join events_tags et on et.event_id = ep.event_id
left outer join tags t on et.tag_id = t.id
order by p.name, ep.event_id;")) )
         )
    (let ((names (sort-strings< (delete-duplicates
                  (map car rows)
                  ))))

      ; (hash-table-set! (hash-table-ref people->interrupts (first row) 0)))
      ; (hash-table-set! (hash-table-ref people->tags (first row) '()))
      (do-list name names
        (let ((filtered-rows (filter
                                    (lambda (x)
                                      (equal? (first x) name))
                                    rows)))
          (hash-table-set! people->interrupts
                           name
                           (count-interrupts-for-name name filtered-rows 0))
          (hash-table-set! people->tags 
                           name
                           (extract-tags-for-name name filtered-rows))

        )
      )

      (fmt-rows (append 
                  (list '("Who" "Interrupts" "Tags" ))
                  (stringify-interrupt-counts
                    (sort-rows-by-interrupts
                      (data-hashes-to-rows people->interrupts people->tags names)))
                  ) " | ")
    ); end let names
  ); end let hashes
) ;end define

(define (sort-rows-by-interrupts rows)
  (sort rows (lambda(a b)
               (< (second a) (second b)))))

(define (stringify-interrupt-counts rows)
  (map (lambda(row)(list (first row) 
                         (number->string (second row))
                         (third row))) rows))

(define (data-hashes-to-rows people->interrupts people->tags names)
  (map (lambda(name)
          (list 
            name
            (hash-table-ref people->interrupts name)
            (string-join
              (hash-table-ref people->tags name) ", ")
           )
       ) 
       names))

(define (row-has-name? row name)
  (equal? name (first row)))

; efficient? no. easy? yes
(define (count-interrupts-for-name name rows count)
  (if (not (null? rows))
    (count-interrupts-for-name name (cdr rows) (if (row-has-name?
                                                (first rows)
                                                name)
                                                (+ 1 count)
                                                count))
    count
  )
)
(define (extract-tags-for-name name rows)
  (sort-strings< 
    (delete-duplicates 
      (flatten 
        (map (lambda(row)(second row)) rows)))))

)
