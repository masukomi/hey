(module interrupt-database
  (
   find-id-of-person
   find-id-of-tag
   create-person
  )
  (import chicken)
  (import scheme)
  (require-extension sql-de-lite)

  (define (find-id-of-tag name db)
    (query 
      fetch-value 
      (sql db "SELECT id FROM tags WHERE name=? limit 1;") name))

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
)
