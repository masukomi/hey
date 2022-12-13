(module interrupts-by-day-report (graph-interrupts-by-day)
 (import chicken)
 (import scheme)
 (import srfi-1)
 (import srfi-69)

 (import sql-de-lite)
 (import extras)
 (import loops)
 (import listicles)
 (import uri-tools)
 (import data-structures)

 

 (define (graph-interrupts-by-day args db)
  (begin
   ; generate the only supported graph type people-by-hour
   ; TODO modify query to use this where clause 
   ; once i figure out how to generate a the date at midnight yesterday
   ; where e.created_at BETWEEN '2017-05-25' AND 'now'
   (let ((labels '())
         (series-data '())
         (rows (query
                fetch-rows
                (sql
                 db
                 "select 
  strftime( \"%Y-%m-%d\",  e.created_at) label,  round(julianday(e.created_at) - 0.5) day, count(*) interrupts
from 
  events e 
where e.created_at > date('now', '-30 days')
group by 1
order by day asc;"))))
    ; that looks like
    ; label      | day        | interrupts
    ; 2017-05-26 | 2457900.0  | 4
    ; 2017-05-27 | 2457904.0  | 2
    ;
    ; OR 
    ; ( ("2017-05-26" 2457900.0  4)
    ;   ("2017-05-27" 2457904.0 2))
    (do-list row rows
     (begin
      (let (
            (label (car row))
            (hour (car (cdr row)))
            (interrupts (last row)))
          
       (set! series-data (cons series-data interrupts))
       (set! labels (cons labels label))

      )
     )
    )
    ; data's built
    ; let's generate the report
    (open-url (post-graph-data "line_chart"
                            (mflatten labels)
                            (list (mflatten series-data))
                            "Interrupts By Day"
                            ))
    )))
)
