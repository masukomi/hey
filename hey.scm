; commands that must be supported
; hey <person(s)>
; hey
; hey tag <id>
; hey retag <id>
; hey delete <id>
; hey data
(require-extension sql-de-lite)
(require-extension srfi-13)
(require-extension srfi-1)
(require-extension pathname-expand)
(require-extension numbers)
(require-extension json-abnf)
; (require-extension mdcd)
(use loops)
(use posix)
(use listicles)
(use fmt)
(use extras)
(use utils)
; SET UP FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; CORE FUNCTIONALITY
(define (find-or-create-person name db)
	; returns (name, id) list
	; (print (sprintf "find-or-create-person ~A" name))
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
	; (print (sprintf "in create-entry for ~A" people))
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

(define (env-or-default-db-path)
	(let ((env-db (get-environment-variable "HEY_DB") ))
		; (print (sprintf "env-db: ~A    || expanded: ~A" env-db (pathname-expand env-db)))
		(if (or (not env-db) (equal? "" env-db))
			(pathname-expand "~/Dropbox/apps/hey/database/hey.db")
			(pathname-expand env-db))))

(define (get-config)
	(let (	(config-path (pathname-expand "~/.config/hey/config.json"))
			(env-db (get-environment-variable "HEY_DB") ))
		(if (file-exists? config-path) 
			; TODO: handle exception from badly formed config files
			(let ((h (pairs-list-to-hash (parser (read-all config-path)))))
				(if (or (not (hash-table-ref h "HEY_DB"))
						(equal? "" (hash-table-ref h "HEY_DB")))
					(hash-table-set! h "HEY_DB" (env-or-default-db-path)))
				h
				)
			(let ((h (make-hash-table equal?)))
				(hash-table-set! h "HEY_DB" (env-or-default-db-path))
				h
			)
		)
	)
)

(define (open-db)
	; look for it in dropbox
	; look for it in local storage location
	; if you don't find it, create it
	(let ((config (get-config)))
		(let ((hey-db (hash-table-ref config "HEY_DB")))
			; (print (sprintf "config-says db at: ~A " hey-db))
			(open-database (pathname-expand hey-db))
		)
	)
)
(define (event-has-tag? event-id tag-id db)
	(let ((count 
			 (query 
			 	 fetch-value
			 	(sql db "SELECT count(*) FROM events_tags where event_id = ? and tag_id = ?;") 
			 	event-id tag-id)))
		(> count 0))
  )
(define (join-tag-to-event tag-id event-id db)
	(if (not (event-has-tag? event-id tag-id db))
		(begin 
			(define s (prepare db "insert into events_tags (event_id, tag_id) values (?, ?);"))
			(bind-parameters s event-id tag-id)
			(step s)
			(finalize s)
		)
	)
  )

(define (join-tags-to-event tag-ids event-id db)
	(do-list tag-id tag-ids
			 (join-tag-to-event tag-id event-id db)))

(define (tag-event tags event-id db)
    (let ((tag-ids '()))
		(do-list tag tags
			 	 (set! tag-ids (cons
			 				 	 (find-or-create-tag tag db)
			 				 	 tag-ids)))
		(join-tags-to-event tag-ids event-id db)
	)
  )
(define (comment-on-event comment-string event-id db)
			(define s (prepare db "update events set description=? where id = ?;"))
			(bind-parameters s comment-string event-id)
			(step s)
			(finalize s)
  )
(define (downcase-list items)
	(map (lambda (item) (string-downcase item)) items)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INSTRUCTION PARSING
(define (tag id tags)
	; (print (sprintf "asked to tag ~A with ~A" id tags))
	(let ((db (open-db)))
		(let ((event-id (find-event-by-id id db)))
			(if (not (equal? event-id #f))
			(tag-event tags id db)
			(print (sprintf "I couldn't find an event with the id ~A" id))
			)
		)
	)
  )
(define (comment id comment-string)
	; (print (sprintf "asked to tag ~A with ~A" id tags))
	(let ((db (open-db)))
		(let ((event-id (find-event-by-id id db)))
			(if (not (equal? event-id #f))
			(comment-on-event comment-string id db)
			(print (sprintf "I couldn't find an event with the id ~A" id))
			)
		)
	)
  )
(define (retag id args)
	(sprintf "asked to retag ~A with ~A" id args)
  )
(define (delete-entry id)
	(sprintf "asked to delete ~A" id )
  )
(define (data)
	(print "asked to provide data")
  )

(define (list-events)
	(print "Recent interruptions in Chronological order\n")
	(let ((row-data '())
		  (db (open-db)))
		(do-list row (query fetch-rows (sql db 
			"SELECT e.id, e.created_at FROM events e order by e.created_at desc;"))
			; desc because the consing reverses the list. :/
			(set! row-data (cons
							 (get-event-display-data row db)
							 row-data)))
		; (print (sprintf "all row-data: ~A~%~%" row-data))
		(let ((event-column  (map (lambda(x)(sprintf "~A" (nth 0 x))) row-data ))
			  (people-column (map (lambda(x)(sprintf "~A" (nth 1 x))) row-data ))
			  (tags-column   (map (lambda(x)(sprintf "~A" (nth 2 x))) row-data ))
			  (row-count (length row-data)))

			(print (fmt #t (tabular 
					  "|" 
					  (dsp (string-join event-column  "\n")) 
					  "|" 
					  (dsp (string-join people-column "\n")) 
					  "|" 
					  (dsp (string-join tags-column   "\n" )) 
					  "|")))
		; (do-list row row-data
		; 		 (print (flatten row)))

		)
	)
)
(define (get-event-display-data event-data db)
	(let ((names (get-names-for-event (car event-data) db))
		  (tags (get-tags-for-event (car event-data) db)))
	  ; (print (sprintf "~%names ~A~%" names))
	  ; (print (sprintf "~%tags ~A~%" tags))
	  ; (let ((result

	  	(append '() (list event-data) (list names) (list tags))

	  	; ))
	  	; (print "\nrow_data:")
		; (display result)
		; )
	; (cons 
	;   (cons event-data 
	;   		(get-names-for-event (car event-data) db))
	;   (get-tags-for-event (car event-data) db))

	)
  )
(define (get-names-for-event eid db)
	(flatten (query fetch-rows (sql db 
			"select p.name from events e inner join events_people ep on ep.event_id = e.id inner join people p on ep.person_id = p.id where e.id=?;") eid))
  )
(define (get-tags-for-event eid db)
	(flatten (query fetch-rows (sql db 
			"select t.name from events e inner join events_tags et on et.event_id = e.id inner join tags t on et.tag_id = t.id where e.id=?;") eid))
  )

(define (process-command command args)
	; (print (sprintf "process-command args: ~A" args))
	(cond
		((equal? command "list")   (list-events))
		((equal? command "tag")    (tag          (string->number (nth 1 args)) (cdr (cdr args))))
		((equal? command "comment")(comment      (string->number (nth 1 args)) (string-join (cdr (cdr args)) " ")))
		((equal? command "retag")  (retag        (string->number (nth 1 args)) (cdr (cdr args))))
		((equal? command "delete") (delete-entry (string->number (car args))))
		((equal? command "data")   (data (car args)))
		(else (sprintf "Unknown command ~A" command))
	)
  )


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define recognized-commands '("tag" "retag" "delete" "data" "list" "comment"))
(define (main args)
	; (print (sprintf "main args: ~A" args))
	(let (	(downcased-args (downcase-list args)))
		(let ((first-arg (nth 1 downcased-args)))
			(if (list-includes recognized-commands first-arg)
				(process-command first-arg (cdr downcased-args))
				(create-entry (cdr downcased-args) (open-db))
				;(sprintf "List didn't include ~A" first-arg)
			)
		)
	)
)
; exec 
(if (not (equal? 'nil (argv)))
	(main (argv))
)

