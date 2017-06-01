(module interrupt-database
  (
   find-id-of-person
   find-id-of-tag
   create-person
   create-tag
   create-event
   get-last-event-id
   join-person-to-event
  )
  (import chicken)
  (import scheme)
  (require-extension sql-de-lite)
  (use loops)

  (define (find-id-of-tag name db)
    (query 
      fetch-value 
      (sql db "SELECT id FROM tags WHERE name=? limit 1;") name))

  (define (create-tag name db)
    (define s (prepare db "insert into tags (name) values (?);"))
    (bind-parameters s name)
    (step s)
    (finalize s)
    (find-id-of-tag name db)
    )

  (define (find-id-of-person name db)
    (query 
         fetch-value 
         (sql db "SELECT id FROM people WHERE name=? limit 1;") 
           name))
  
  (define (create-person name db)
    (define s (prepare db "insert into people (name) values (?);"))
    (bind-parameters s name)
    (step s)
    (finalize s)
    (find-id-of-person name db))

  (define (create-event people-ids db)
    (define s (prepare db "INSERT INTO events DEFAULT VALUES"))
    (exec s)
    (let ((event-id (get-last-event-id db)))
      (do-list pid people-ids 
        (join-person-to-event pid event-id db))))

  (define (get-last-event-id db)
    (query fetch-value (sql db "SELECT id FROM events order by id desc limit 1;")))

  (define (join-person-to-event pid eid db)
    (define s (prepare db "insert into events_people (event_id, person_id) values (?, ?);"))
    (bind-parameters s eid pid )
    (step s)
    (finalize s))

)
