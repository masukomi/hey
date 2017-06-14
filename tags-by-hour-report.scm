(module tags-by-hour-report (graph-tags-by-hour)
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


 (define (graph-tags-by-hour args db)
  (begin
   ; generate the only supported graph type tags-by-hour
   ; TODO modify query to use this where clause 
   ; once i figure out how to generate a the date at midnight yesterday
   ; where e.created_at BETWEEN '2017-05-25' AND 'now'
   (let ((bars-or-lines (if (null? args)
                            "stacked_bar_chart"
                            (car args)))
         (series-data '())
         (hours-hash (make-hash-table equal?))
         (tag->hour->value (make-hash-table equal?))
         (previous-name "")
         (rows (query
                fetch-rows
                (sql
                 db
"select 
  t.name,
  strftime('%H', e.created_at) hour, count(*) interrupts
from 
  events e 
  inner join events_tags et on et.event_id = e.id
  inner join tags t on et.tag_id = t.id
where e.created_at > date('now', '-7 days')
group by 2, 1
order by t.name asc;")

      )))
    ; that looks like
    ; name | hour | interrupts
    ; this  | 11   | 4
    ; that | 13   | 2
    ;
    ; OR 
    ; ( ("this"  11 4)
    ;   ("that" 13 2))
    (do-list row rows
     (begin
      ; make the new hash
      ;(print (sprintf "graph row: ~A - car: ~A" row (car row)))
      (let ((row-hash (make-hash-table equal?))
            (tag (car row))
            (hour (car (cdr row)))
            (interrupts (last row)))
       ; and the new entry
       (hash-table-set! row-hash "meta" tag)
       (hash-table-set! row-hash "value" interrupts)
       (if (not (list-includes (hash-table-keys tag->hour->value) tag))
        (hash-table-set! tag->hour->value tag (make-hash-table equal?)))
       (hash-table-set! (hash-table-ref tag->hour->value tag)
                        hour
                        interrupts)
       (hash-table-set! hours-hash hour #t))))

    ; OK Now we have the hashes for everyone's time
    ; let's fill in the hours they don't have
    (do-list tag (sort-strings< (hash-table-keys tag->hour->value))
     (do-list hour (sort-strings< (hash-table-keys hours-hash))
      (let ((value (if (list-includes
                        (hash-table-keys
                         (hash-table-ref tag->hour->value tag))
                        hour)
                    (hash-table-ref (hash-table-ref tag->hour->value tag)
                                    hour)
                    0)))
       (let ((row-hash (make-hash-table equal?)))
        (hash-table-set! row-hash "meta" tag)
        (hash-table-set! row-hash "value" value)
        (if (not (equal? tag previous-name))
         (begin
          (set! series-data (append series-data (list (list row-hash))))
          (set! previous-name tag))
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
    (open-url (generate-graph-url bars-or-lines
                            (sort-strings< (hash-table-keys hours-hash))
                            series-data
                            "Interruptions by tag by hour."))))))
