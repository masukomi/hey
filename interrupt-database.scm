(module interrupt-database
  (
   create-tag
   find-id-of-person
   create-person
   find-person-by-name
   find-id-of-tag
   create-event
   find-event-by-id
   get-last-event-id
   join-person-to-event
  )
  (import chicken)
  (import scheme)
  (require-extension sql-de-lite)
  (use loops)
  ;----------------------------------------------------------------------------
  ; tags
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
  ;----------------------------------------------------------------------------
  ; people
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

  (define (find-person-by-name name db)
    (query fetch-value (sql db "SELECT id FROM people where name = ?;") name))

  ;----------------------------------------------------------------------------
  ; events
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
  
  (define (find-event-by-id id db)
    (if (not (equal? id "last"))
      (query fetch-value (sql db "SELECT id FROM events where id = ?;") 
        (if (string? id) (string->number id) id) )
      (get-last-event-id db)))


)
