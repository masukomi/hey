(module interrupt-database 
  (load-db-at-path
    create-tag
    find-id-of-person
    create-person
    create-people
    find-or-create-person
    find-or-create-people
    join-person-to-event
    event-ids-with-person
    delete-person-from-db
    find-id-of-tag
    create-event
    find-event-by-id
    get-last-event-id
    join-tag-to-event
    join-tags-to-event
    event-has-tag?
    delete-events-from-db
    delete-events-with-person
    find-tags
    comment-on-event)
 (import chicken)
 (import scheme)

 (require-extension sql-de-lite)
 (import loops)
 (import srfi-1)
 (import srfi-13)
 (import listicles)

  (import extras)
 ;----------------------------------------------------------------------------
 ; core
 (define (load-db-at-path path)
  (open-database path))

  ; 23> (append-marks-for-binding "" 4 #f)
  ; "?, ?, ?, ?"
  ; 24> (append-marks-for-binding "" 4 #t)
  ; "(?), (?), (?), (?)"
  (define (append-marks-for-binding string number parens)
    (if (> number 0)
      (if (not (= number 1))
        (append-marks-for-binding (string-append string 
                                                 (if parens "(?), " "?, ")) 
                                  (- number 1)
                                  parens)
        (append-marks-for-binding (string-append string 
                                                 (if parens "(?)" "?"))
                                  (- number 1)
                                  parens)
        )
      string
      ))

 (define (bind-many-params s params)
  (do-list idx-param (zip (range 1 (length params)) params)
      (bind s (first idx-param) (last idx-param))))
                   
 

 ;----------------------------------------------------------------------------
 ; tags
 (define (find-tags db)
  (query fetch-column
         (sql db "SELECT distinct name from tags order by name asc;")))
 (define (create-tag name db)
  (define s (prepare db "insert into tags (name) values (?);"))
  (bind-parameters s name)
  (step s)
  (finalize s)
  (find-id-of-tag name db))

 (define (event-has-tag? event-id tag-id db)
  (let ((count (query
                fetch-value
                (sql
                 db
                 "SELECT count(*) FROM events_tags where event_id = ? and tag_id = ?;")
                event-id
                tag-id)))
   (> count 0)))

 (define (find-id-of-tag name db)
  (query fetch-value (sql db "SELECT id FROM tags WHERE name=? limit 1;") name))

 (define (join-tag-to-event tag-id event-id db)
  (if (not (event-has-tag? event-id tag-id db))
   (begin
    (let ((s (prepare
              db
              "insert into events_tags (event_id, tag_id) values (?, ?);")))
     (bind-parameters s event-id tag-id)
     (step s)
     (finalize s)))))

 (define (join-tags-to-event tag-ids event-id db)
  (do-list tag-id tag-ids
   (join-tag-to-event tag-id event-id db)))

 ;----------------------------------------------------------------------------
 ; people
 (define (create-person name db)
  (define s (prepare db "insert into people (name) values (?);"))
  (bind-parameters s name)
  (step s)
  (finalize s)
  (find-id-of-person name db))

 (define (create-people names db)
  (let ((sql 
          (append-marks-for-binding 
            "INSERT INTO people (name) values "
            (length names)
            #t)))
    (define s (prepare db (string-append sql ";")))
    (bind-many-params s names)
    (step s)
    (finalize s)
   ))

 (define (find-id-of-person name db)
  (query fetch-value
         (sql db "SELECT id FROM people WHERE name=? limit 1;")
         name))

 (define (find-id-and-name-of-people names db)
  (let ((sql-start "SELECT id, name FROM people WHERE name in (")
        (sql-end ");"))
    
    ;binding ready
    (let ((sql (string-append (append-marks-for-binding sql-start (length names) #f)
                   sql-end)))
    (define s (prepare db sql))
    (bind-many-params s names)
    (fetch-all s)
    )
  )
  )
 
 (define (find-or-create-person name db)
   (let ((id (find-id-of-person name db)))
    (if (not (equal? id #f))
     id
     (create-person name db))))

 (define (find-or-create-people names db)
   (let ((existing-ids-and-names 
           (find-id-and-name-of-people names db))
         )
     (if (= (length existing-ids-and-names) (length names))
        (map (lambda(lst)(first lst)) 
                   existing-ids-and-names)
        (begin 
         (let ((matched-names (map (lambda(lst)(last lst)) existing-ids-and-names)))
              ; double map seems terrible but it's really going to be a very small
              ; list - probably 1-3 items
              (let ((unmatched-names (lset-difference equal? names matched-names)))
                (if (> (length unmatched-names) 0) ; damn well better be
                (begin 
                  (create-people unmatched-names db)
                  (find-or-create-people names db)
                ))

              )
           )
         )
      )
   ))


 (define (event-ids-with-person person-id db)
  (query
    fetch-all
    (sql
     db
     "select e.id, \n( select count(*) from events_people  where events_people.event_id = e.id) epc\nfrom\nevents e \ninner join events_people ep on ep.event_id = e.id\ninner join people p on ep.person_id = p.id\nwhere epc = 1\nand p.id = ?\ngroup by 1;")
    person-id))
  
  (define (delete-events-with-person person-id db)
    (let ((s (prepare db "delete from events_people where person_id=?;")))
      (bind-parameters s person-id)
      (step s)
      (finalize s)
      )
    )

  (define (delete-person-from-db person-id db)
    (let ((s (prepare db "delete from people where id=?;")))
      (bind-parameters s person-id)
      (step s)
      (finalize s)
      )
    )

 ;----------------------------------------------------------------------------
 ; events
 (define (comment-on-event comment-string event-id db)
  (define s (prepare db "update events set description=? where id = ?;"))
  (bind-parameters s comment-string event-id)
  (step s)
  (finalize s))

 (define (create-event people-ids db)
  (define s (prepare db "INSERT INTO events DEFAULT VALUES"))
  (exec s)
  (let ((event-id (get-last-event-id db)))
   (do-list pid people-ids
    (join-person-to-event pid event-id db))))

 (define (find-event-by-id id db)
  (if (not (equal? id "last"))
   (query fetch-value
          (sql db "SELECT id FROM events where id = ?;")
          (if (string? id)
           (string->number id)
           id))
   (get-last-event-id db)))

 (define (get-last-event-id db)
  (query fetch-value
         (sql db "SELECT id FROM events order by id desc limit 1;")))

 (define (join-person-to-event pid eid db)
  (define s
   (prepare db
            "insert into events_people (event_id, person_id) values (?, ?);"))
  (bind-parameters s eid pid)
  (step s)
  (finalize s))
 
 (define (delete-events-from-db event-ids db)
  (let ((s (prepare db "delete from events where id in (?);")))
     (bind-parameters s (string-join event-ids ", "))
     (step s)
     (finalize s)
    )
   )
)
