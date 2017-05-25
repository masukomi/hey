; commands that must be supported
; hey <person(s)>
; hey
; hey tag <id>
; hey retag <id>
; hey delete <id>
; hey data
(import listicles)
(require-extension sql-de-lite)
(require-extension srfi-13)
(require-extension srfi-1)
(require-extension pathname-expand)
(require-extension numbers)
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
;TODO: combine find-or-create-tag with find-or-create-person
(define (find-or-create-tag name db)
	(let (( id (query 
				 fetch-value 
				 (sql db "SELECT id FROM tags WHERE name=? limit 1;") name)))
		(if (not (equal? id #f))
		  id
		  (create-tag name db))
	  )
  )
;TODO: combine create-tage with create-person
(define (create-tag name db)
	(define s (prepare db "insert into tags (name) values (?);"))
	(bind-parameters s name)
	(step s)
	(finalize s)
	(find-or-create-tag name db)
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

(define (find-event-by-id id db)
	(query fetch-value (sql db "SELECT id FROM events where id = ?;") id)
)

(define (open-db)
	; look for it in dropbox
	; look for it in local storage location
	; if you don't find it, create it
	(let ((dropbox-path (pathname-expand "~/Dropbox/apps/hey/database/hey.db")))
		; test if dropbox-path exists
			; open it
			(open-database dropbox-path)
		; elsif local storage location exists
			; open it
		; else create it
	)
)
(define (join-tag-to-event tag-id event-id db)
	(define s (prepare db "insert into events_tags (event_id, tag_id) values (?, ?);"))
	(bind-parameters s tag-id event-id )
	(step s)
	(finalize s)
  )

(define (join-tags-to-event tag-ids event-id db)
	(do-list tag-id tag-ids
			 (lambda()(join-tag-to-event tag-id event-id db))))

(define (tag-event tags event-id db)
    (let ((tag-ids '()))
		(do-list tag tags
			 	 (set! tag-ids (cons
			 				 	 (find-or-create-tag tag db)
			 				 	 tag-ids)))
		(join-tags-to-event tag-ids event-id db)
	)
  )
(define (downcase-list items)
	(map (lambda (item) (string-downcase item)) items)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INSTRUCTION PARSING
(define (tag id args)
	(let ((db (open-db)))
		(let ((event-id (find-event-by-id db)))
			(if (not (equal? event-id #f))
		  	  (print "found event now need to tag it")
		  	  (sprintf "I couldn't find an event with the id ~A" id)

			)

		)
	)
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
(define (list-events)
	(display (query fetch-rows (sql db 
		"SELECT e.id, e.created_at FROM events e order by e.created_at asc;")))
  )
(define (process-command command args)
	(case command
		('("list")  (list-events))
		('("tag")   (tag          (string->number (car args)) (cdr args)))
		('("retag") (retag        (string->number (car args)) (cdr args)))
		('("delete")(delete-entry (string->number (car args))))
		('("data")  (data (car args)))
	)
  )


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; exec 
(if (not (equal? 'nil (argv)))
	(lambda()(
		(define downcased-args (downcase-list (argv)))
		(define first-arg (nth 1 downcased-args))

		; (print (display downcased-args))
		; (print (display first-arg))

		(define recognized-commands '("tag" "retag" "delete" "data" "list"))

		(if (list-includes recognized-commands first-arg)
  	  	  (process-command first-arg (cdr downcased-args))
  	  	  (create-entry (cdr downcased-args) (open-db))
  	  	  )
  	))
)

