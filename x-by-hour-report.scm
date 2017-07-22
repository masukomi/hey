(module x-by-hour-report (graph-x-by-hour)
 (import chicken)
 (import scheme)
 (import srfi-1)
 (import srfi-69)

 (require-extension sql-de-lite)
 (use extras)
 (use loops)
 (use listicles)
 (use uri-tools)
 (use hey-dates)
 (use data-structures)
 (use files)
 (use posix)


 (define (graph-x-by-hour report-on args db)
  (begin
   (let ((bars-or-lines (if (null? args)
                            "stacked_bar_chart"
                            (car args)))
         (rows (query
                fetch-rows
                (sql
                 db (query-for report-on)))))
    (if (not (equal? "feedgnuplot" bars-or-lines))
      (graph-all-data-points bars-or-lines report-on rows)
      (simple-data-output report-on rows)))))
  
  (define (simple-data-output report-on rows)
    (let (
           (hours-hash (make-hash-table equal?))
           (previous-name "")
           (total-events 
             (apply + (map (lambda(row)(last row)) rows))
           )
         )
          
      ; rows looks like
      ; hour | interrupts
      ; 8    | 2
      ; 10   | 1
      (do-list row rows
        (begin
          (let (
              (hour (string->number (car row)))
              (interrupts (last row)))
            (hash-table-set! hours-hash hour 
                             (/ interrupts (/ total-events 100))
                             )



          )
        )
      )
      (let ((temp-file (create-temporary-file)))
        (with-output-to-file temp-file 
          (lambda ()
            (do-list hour-key (range 0 24)
              (if (not (list-includes (hash-table-keys hours-hash) hour-key))
                (print "0")
                (print (sprintf "~A"  (hash-table-ref hours-hash hour-key)))
              )
            )
          )
        )
        ; (print (sprintf "temp-file: ~A" temp-file))
      (system (sprintf "cat ~A | feedgnuplot --lines --points --title '~A' --y2 1 --terminal 'dumb ~A,~A' --exit ; rm ~A" 
                       temp-file 
                       (title-for-report report-on) 
                       80 ;(get-environment-variable "COLUMNS")
                       20 ;(get-environment-variable "LINES") 
                       temp-file ))
      )
    )
  )
  (define (graph-all-data-points bars-or-lines report-on rows)
    (let ((series-data '())
         (hours-hash (make-hash-table equal?))
         (x->hour->value (make-hash-table equal?))
         (previous-name ""))
                ; rows looks like
                ; name | hour | interrupts
                ; bob  | 11   | 4
                ; mary | 13   | 2
                ;
                ; OR 
                ; ( ("bob"  11 4)
                ;   ("mary" 13 2))
                ;---------
                ; END let vars

      (do-list row rows
       (begin
        ; make the new hash
        ;(print (sprintf "graph row: ~A - car: ~A" row (car row)))
        (let ((row-hash (make-hash-table equal?))
              (x (car row))
              (hour (car (cdr row)))
              (interrupts (last row)))
         ; and the new entry
         (hash-table-set! row-hash "meta" x)
         (hash-table-set! row-hash "value" interrupts)
         (if (not (list-includes (hash-table-keys x->hour->value) x))
          (hash-table-set! x->hour->value x (make-hash-table equal?)))
         (hash-table-set! (hash-table-ref x->hour->value x)
                          hour
                          interrupts)
         (hash-table-set! hours-hash hour #t))))
      ; OK Now we have the hashes for everyone's time
      ; let's fill in the hours they don't have
      (do-list x (sort-strings< (hash-table-keys x->hour->value))
       (do-list hour (sort-strings< (hash-table-keys hours-hash))
        (let ((value (if (list-includes
                          (hash-table-keys
                           (hash-table-ref x->hour->value x))
                          hour)
                      (hash-table-ref (hash-table-ref x->hour->value x)
                                      hour)
                      0)))
         (let ((row-hash (make-hash-table equal?)))
          (hash-table-set! row-hash "meta" x)
          (hash-table-set! row-hash "value" value)
          (if (not (equal? x previous-name))
           (begin
            (set! series-data (append series-data (list (list row-hash))))
            (set! previous-name x))
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
      ; (open-url (generate-graph-url bars-or-lines
      ;                             (sort-strings< (hash-table-keys hours-hash))
      ;                             series-data
      ;                             (title-for-report report-on)))
      (print (post-graph-data 
        bars-or-lines 
        (sort-strings< (hash-table-keys hours-hash))
        series-data
        (title-for-report report-on)))
    )
  )

  (define (title-for-report x)
    (cond
      ((equal? x "tags") "Interruptions by tag by, by hour.")
      ((equal? x "summary") "Interruptions by hour.")
      ((equal? x "people") "Interruptions by person, by hour.")
      ))
  
  (define (query-for x)
    (cond
      ((equal? x "tags")
       "select 
  t.name,
  strftime('%H', datetime(e.created_at, 'localtime')) hour, count(*) interrupts
from 
  events e 
  inner join events_tags et on et.event_id = e.id
  inner join tags t on et.tag_id = t.id
where e.created_at > date('now', '-7 days')
group by 2, 1
order by t.name asc;")
      ((equal? x "people")
       "select 
  p.name,
  strftime('%H', datetime(e.created_at, 'localtime')) hour, count(*) interrupts
from 
  events e 
  inner join events_people ep on ep.event_id = e.id
  inner join people p on ep.person_id = p.id
where e.created_at > date('now', '-7 days')
group by 2, 1
order by p.name asc;")
      ((equal? x "summary")
       "select 
  strftime('%H', datetime(e.created_at, 'localtime')) hour, count(*) interrupts
from 
  events e 
group by 1
order by hour asc;")
       
    )
  )
  
)
