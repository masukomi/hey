(module people-by-hour-report (graph-people-by-hour)
 (import chicken)
 (import scheme)
 (import srfi-1)
 (import srfi-69)

 (require-extension sql-de-lite)
 (use extras)
 (use loops)
 (use listicles)
 (use uri-tools)

 (define (generate-url graph-type labels series)
  (let ((encoded-labels (json->uri-string labels))
        (encoded-series (json->uri-string series)))
   (sprintf "https://interrupttracker.com/~A.html?labels=~A&series=~A"
            graph-type
            encoded-labels
            encoded-series)))

 (define (graph-people-by-hour args db)
  (begin
   ; generate the only supported graph type people-by-hour
   ; TODO modify query to use this where clause 
   ; once i figure out how to generate a the date at midnight yesterday
   ; where e.created_at BETWEEN '2017-05-25' AND 'now'
   (let ((bars-or-lines (if (null? args)
                            "stacked_bar_chart"
                            (car args)))
         (series-data '())
         (hours-hash (make-hash-table equal?))
         (person->hour->value (make-hash-table equal?))
         (previous-name "")
         (rows (query
                fetch-rows
                (sql
                 db
                 "select \n  p.name,\n  strftime('%H', e.created_at) hour, count(*) interrupts\nfrom \n  events e \n  inner join events_people ep on ep.event_id = e.id\n  inner join people p on ep.person_id = p.id\ngroup by 2, 1\norder by p.name asc;"))))
    ; that looks like
    ; name | hour | interrupts
    ; bob  | 11   | 4
    ; mary | 13   | 2
    ;
    ; OR 
    ; ( ("bob"  11 4)
    ;   ("mary" 13 2))
    (do-list row rows
     (begin
      ; make the new hash
      ;(print (sprintf "graph row: ~A - car: ~A" row (car row)))
      (let ((row-hash (make-hash-table equal?))
            (person (car row))
            (hour (car (cdr row)))
            (interrupts (last row)))
       ; and the new entry
       (hash-table-set! row-hash "meta" person)
       (hash-table-set! row-hash "value" interrupts)
       (if (not (list-includes (hash-table-keys person->hour->value) person))
        (hash-table-set! person->hour->value person (make-hash-table equal?)))
       (hash-table-set! (hash-table-ref person->hour->value person)
                        hour
                        interrupts)
       (hash-table-set! hours-hash hour #t))))

    ; OK Now we have the hashes for everyone's time
    ; let's fill in the hours they don't have
    (do-list person (sort-strings< (hash-table-keys person->hour->value))
     (do-list hour (sort-strings< (hash-table-keys hours-hash))
      (let ((value (if (list-includes
                        (hash-table-keys
                         (hash-table-ref person->hour->value person))
                        hour)
                    (hash-table-ref (hash-table-ref person->hour->value person)
                                    hour)
                    0)))
       (let ((row-hash (make-hash-table equal?)))
        (hash-table-set! row-hash "meta" person)
        (hash-table-set! row-hash "value" value)
        (if (not (equal? person previous-name))
         (begin
          (set! series-data (append series-data (list (list row-hash))))
          (set! previous-name person))
         (begin
          (let ((replacement (append (last series-data) (list row-hash))))
           (set! series-data
                 (replace-nth (last-index series-data)
                              ; nth
                              replacement

                              ; replacement
                              series-data)))))))))

    ; data's built
    ; let's generate the report
    (open-url (generate-url bars-or-lines
                            (sort-strings< (hash-table-keys hours-hash))
                            series-data))))))
