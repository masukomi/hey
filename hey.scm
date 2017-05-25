; commands that must be supported
; hey <person(s)>
; hey
; hey tag <id>
; hey retag <id>
; hey delete <id>
; hey data
(load "listicles.import.scm")
(require-extension sql-de-lite)
(require-extension srfi-13)
(require-extension srfi-1)
; (require-extension mdcd)
(use loops)
(use listicles)
; SET UP FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; CORE FUNCTIONALITY
(define (find-or-create-person name db)
	; returns (name, id) list
	
	(let (( id (query 
				 fetch-value 
				 (sql db "SELECT id FROM people WHERE name=? limit 1;") name)))
		(if (not (equal? id #f))
		  id
		  (create-person name db))
	  )
)

(define (create-person name db)
	(define s (prepare db "insert into people (name) values (?);"))
	(bind-parameters s name)
	(step s)
	(finalize s)
	(find-or-create-person name db)
  )

(define (create-entry people db)
	(let ((people-ids '()))
		(do-list name people 
			(set! people-ids (cons 
						(find-or-create-person name db)
						people-ids)))
		; we now have a list of people ids
		(create-event people-ids db)
	)
)

(define (create-event people-ids db)
	(define s (prepare db "INSERT INTO events DEFAULT VALUES"))
	(exec s)
	(let ((event-id (get-last-event-id db)))
		(do-list pid people-ids 
			(join-person-to-event pid event-id db)
		)
	)
)

(define (join-person-to-event pid eid db)
	(define s (prepare db "insert into events_people (event_id, person_id) values (?, ?);"))
	(bind-parameters s eid pid )
	(step s)
	(finalize s)
)

(define (get-last-event-id db)
	(query fetch-value (sql db "SELECT id FROM events order by id desc limit 1;"))
)

(define (open-db)
	; look for it in dropbox
	; look for it in local storage location
	; if you don't find it, create it

	; (open-database "~/Dropbox/apps/hey/database/hey.db")
	(open-database "/Users/masukomi/Dropbox/apps/hey/database/hey.db")
)

(define (downcase-list items)
	(map (lambda (item) (string-downcase item)) items)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INSTRUCTION PARSING
(define (tag id args)
	(sprintf "asked to tag ~A with ~A" id (display args))
  )
(define (retag id args)
	(sprintf "asked to retag ~A with ~A" id (display args))
  )
(define (delete-entry id)
	(sprintf "asked to delete ~A" id )
  )
(define (data)
	(print "asked to provide data")
  )
(define (process-command command args)
	(case command
		('("tag")   (tag (car args) (cdr args)))
		('("retag") (retag (car args) (cdr args)))
		('("delete")(delete-entry (car args)))
		('("data")  (data (car args)))
	)
  )


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; exec 
(define downcased-args (downcase-list (argv)))
(define first-arg (nth 1 downcased-args))

; (print (display downcased-args))
; (print (display first-arg))

(define recognized-commands '("tag" "retag" "delete" "data"))

(if (list-includes recognized-commands first-arg)
  (process-command first-arg (cdr downcased-args))
  (create-entry (cdr downcased-args) (open-db))
  )
