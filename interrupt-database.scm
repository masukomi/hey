(module interrupt-database 
  (load-db-at-path
    create-tag
    find-id-of-person
    create-person
    find-person-by-name
    find-id-of-tag
    create-event
    find-event-by-id
    get-last-event-id
    join-tag-to-event
    join-tags-to-event
    event-has-tag?
    join-person-to-event
    comment-on-event)
 (import chicken)
 (import scheme)

 (require-extension sql-de-lite)
 (use loops)

 ;----------------------------------------------------------------------------
 ; core
 (define (load-db-at-path path)
  (open-database path))

 ;----------------------------------------------------------------------------
 ; tags
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

 (define (find-id-of-person name db)
  (query fetch-value
         (sql db "SELECT id FROM people WHERE name=? limit 1;")
         name))

 (define (find-person-by-name name db)
  (query fetch-value (sql db "SELECT id FROM people where name = ?;") name))

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
  (finalize s)))
