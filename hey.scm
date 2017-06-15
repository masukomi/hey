; Welcome to Hey!
; this started out as a quick hack, and just kept growing
; as a result, it could use some SERIOUS refactoring at this point.
; Just, general cleanup, breaking functions down into smaller pieces, 
; moving functions out into separate files, and stuff like that.
;
; If you're looking for something more specific to work on 
; check out the Issues Tracker: https://github.com/masukomi/hey/issues
; and drop me a line on Twitter. I'm @masukomi
; Se vi parolas esperanton mi estas @praktiku sur la Twitter.
;
; Copyright 2017 Kay Rhodes. Distributed under the MIT License
; https://github.com/masukomi/hey/blob/master/LICENSE.md
(require-extension sql-de-lite)
(require-extension srfi-13)
(require-extension srfi-1)
(require-extension pathname-expand)
(require-extension numbers)
(require-extension json-abnf)
(require-extension json)
(require-extension uri-common)

; (require-extension mdcd)
(use loops)
(use posix)
(use fmt)
(use extras)
(use utils)
(use ports)
(use listicles)
(use hey-dates)
(use interrupt-database)
(use x-by-hour-report)
(use interrupts-by-day-report)

; SET UP FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; CORE FUNCTIONALITY
(define (find-or-create-person name db)
 (let ((id (find-id-of-person name db)))
  (if (not (equal? id #f))
   id
   (create-person name db))))

(define (create-entry people-and-tags db)
 (let ((people '())
       (people-ids '())
       (includes-tags #f)
       (tags '()))
  (do-list name people-and-tags
   (if (and (not (equal? "+tag" name))
            (not includes-tags))
    (begin
     (set! people-ids (cons (find-or-create-person name db) people-ids))
     (set! people (cons name people)))
    (if (not (equal? "+tag" name))
     (set! tags (cons name tags))
     (set! includes-tags #t))))
  (create-event people-ids db)
  (print (sprintf "Gotcha. New ~A event" (string-join people ", ")))
  (if (not (null? tags))
   (let ((event-id (get-last-event-id db)))
    (tag-event tags event-id db)))))

(define (downcase-list items)
 (map (lambda (item)
       (string-downcase item))
      items))

(define (env-or-default-db-path)
 (let ((env-db (get-environment-variable "HEY_DB")))
  (if (or (not env-db)
          (equal? "" env-db))
   (pathname-expand "~/Dropbox/apps/hey/database/hey.db")
   (pathname-expand env-db))))

(define (find-or-create-tag name db)
 (let ((id (find-id-of-tag name db)))
  (if (not (equal? id #f))
   id
   (create-tag name db))))

(define (get-config)
 (let ((config-path (pathname-expand "~/.config/hey/config.json"))
       (env-db (get-environment-variable "HEY_DB")))
  (if (file-exists? config-path)
   ; TODO: handle exception from badly formed config files
   (let ((h (pairs-list-to-hash (parser (read-all config-path)))))
    (if (or (not (hash-table-ref h "HEY_DB"))
            (equal? "" (hash-table-ref h "HEY_DB")))
     (hash-table-set! h "HEY_DB" (env-or-default-db-path)))
    h)
   (let ((h (make-hash-table equal?)))
    (hash-table-set! h "HEY_DB" (env-or-default-db-path))
    h))))

(define (open-db)
 (let ((config (get-config)))
  (let ((hey-db (hash-table-ref config "HEY_DB"))
    (show-db-path (hash-table-ref/default config "show_db_path" #f)))
    (if show-db-path
      (print (sprintf "loading db at ~A" hey-db)))
   (load-db-at-path (pathname-expand hey-db)))))

(define (tag-event tags event-id db)
 (let ((tag-ids '()))
  (do-list tag tags
   (set! tag-ids (cons (find-or-create-tag tag db) tag-ids)))
  (join-tags-to-event tag-ids event-id db))
 (print (sprintf "Gotcha. Tagged with ~A" (string-join tags ", "))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INSTRUCTION PARSING
(define (comment id comment-string)
 (let ((db (open-db)))
  (let ((event-id (find-event-by-id id db)))
   (if (not (equal? event-id #f))
    (comment-on-event comment-string id db)
    (print (sprintf "I couldn't find an event with the id ~A" id))))))

(define (retag id args)
 (sprintf "asked to retag ~A with ~A" id args))

(define (list-tags)
  (print (sprintf "current tags: ~A" (string-join (find-tags (open-db)) ", ") )))

(define (tag id tags)
 (let ((db (open-db)))
  (let ((event-id (find-event-by-id id db)))
   (if (not (equal? event-id #f))
    (tag-event tags event-id db)
    (print (sprintf "I couldn't find an event with the id ~A" id))))))

; TODO: delete person and delete event are almost identical. Refactor them
(define (data)
 (print "asked to provide data"))

(define (delete-entry event-id)
 (let ((db (open-db)))
  (let ((event-id (find-event-by-id event-id db)))
   (if (not (equal? event-id #f))
    (begin
     ; TODO: stick this in a transaction
     (let ((s (prepare db "delete from events_people where event_id=?;")))
      (bind-parameters s event-id)
      (step s)
      (finalize s)
      (set! s (prepare db "delete from events where id=?;"))
      (bind-parameters s event-id)
      (step s)
      (finalize s)))
    (print (sprintf "I couldn't find an event with the id ~A" event-id))))))

(define (delete-person name)
 (let ((db (open-db)))
  (let ((person-id (find-person-by-name name db)))
   (if (not (equal? person-id #f))
    (begin
     ; TODO: stick this in a transaction
     (let ((persons-events (query
                            fetch-all
                            (sql
                             db
                             "select e.id, \n( select count(*) from events_people  where events_people.event_id = e.id) epc\nfrom\nevents e \ninner join events_people ep on ep.event_id = e.id\ninner join people p on ep.person_id = p.id\nwhere epc = 1\nand p.id = ?\ngroup by 1;")
                            person-id))
           (s (prepare db "delete from events_people where person_id=?;")))
      (bind-parameters s person-id)
      (step s)
      (finalize s)
      (set! s (prepare db "delete from people where id=?;"))
      (bind-parameters s person-id)
      (step s)
      (finalize s)
      (if (> (length persons-events) 0)
       (begin
        (let ((event-ids (map (lambda (x)
                               (number->string (car x)))
                              persons-events)))
         (set! s (prepare db "delete from events where id in (?);"))
         (bind-parameters s (string-join event-ids ", "))
         (step s)
         (finalize s)))
       (print (sprintf "found no events involving just ~A" name))))
     (print (sprintf "~A is dead. Long live ~A!" name name)))
    (print (sprintf "I couldn't find a person with the name ~A" name))))))

(define (get-event-display-data event-data db)
 (let ((names (get-names-for-event (car event-data) db))
       (tags (get-tags-for-event (car event-data) db)))
  (append '() (list event-data) (list names) (list tags))))

(define (get-names-for-event eid db)
 (flatten
  (query
   fetch-rows
   (sql
    db
    "select p.name from events e inner join events_people ep on ep.event_id = e.id inner join people p on ep.person_id = p.id where e.id=?;")
   eid)))

(define (get-tags-for-event eid db)
 (flatten
  (query
   fetch-rows
   (sql
    db
    "select t.name from events e inner join events_tags et on et.event_id = e.id inner join tags t on et.tag_id = t.id where e.id=?;")
   eid)))

(define (graph args)
 (let ((known-report-types (list "people-by-hour" 
 								 "tags-by-hour"
 								 "interrupts-by-day"
 								 "interrupts-fgp")))
  (if (null? args)
   (print
    "No graph type specified.
    Available graph types:
    * people-by-hour [stacked_bar_chart|line_chart]
    * tags-by-hour [stacked_bar_chart|line_chart]
    * interrupts-by-day
      * A stacked bar chart of the number of interrupts, by person, by hour
        for the past 24hrs. Defaults to stacked_bar_chart
    * interrupts-fgp
      * generates a terminal graph of interrupts by hour.
      * requires feedgnuplot to be installed")
   (cond
    ((equal? "people-by-hour" (car args))
     (graph-x-by-hour "people" (cdr args) (open-db)))
    ((equal? "interrupts-fgp" (car args))
     (graph-x-by-hour "summary" '("feedgnuplot") (open-db)))
    ((equal? "tags-by-hour" (car args))
     (graph-x-by-hour "tags" (cdr args) (open-db)))
    ((equal? "interrupts-by-day" (car args))
     (graph-interrupts-by-day (cdr args) (open-db))) ;
    (else
     (print (sprintf "Unknown report type: ~A~%Available report types: ~A"
                     (car args)
                     (string-join known-report-types ", "))))))))

(define (help)
 (print
  "Usage instructions are at https://interrupttracker.com/usage.html\nGeneral info is available at https://interrupttracker.com/\n\nI'm @masukomi on Twitter and happy to help there."))

(define (list-events)

 (let ((days-ago 3))
   (let ((row-data '())
         (midnight-yesterday 
           (date->sqlite-string 
             (date-at-midnight-x-days-ago 3 (current-seconds))))
         (db (open-db)))
    (print (sprintf "Last ~A day's interruptions in chronological order...\n" days-ago))
    (do-list row (query fetch-rows (sql db 
      "SELECT e.id, e.created_at FROM events e where created_at > ? order by e.created_at desc;")
                        midnight-yesterday)
     (set! row-data (cons (get-event-display-data row db) row-data)))
    (let ((id-column (map (lambda (x)
                           (sprintf "~A" (car (nth 0 x))))
                          row-data))
          (event-column (map (lambda (x)
                              (sprintf "~A" (nth 1 (nth 0 x))))
                             row-data))
          (people-column (map (lambda (x)
                               (sprintf "~A" (string-join (nth 1 x) ", ")))
                              row-data))
          (tags-column (map (lambda (x)
                             (sprintf "~A" (string-join (nth 2 x) ", ")))
                            row-data))
          (row-count (length row-data)))
     (fmt #t
          (tabular " | "
                   (dsp (string-join (append '("ID") id-column) "\n"))
                   " | "
                   (dsp (string-join (append '("When") event-column) "\n"))
                   " | "
                   (dsp (string-join (append '("Who") people-column) "\n"))
                   " | "
                   (dsp (string-join (append '("Tags") tags-column) "\n"))
                   " | "))))))

(define (process-command command args)
 ; sometimes there's nothing passed after the command
 ; in which case args is a string not a list
 ; but some commands work with and without params... 
 ; so we need to make sure it's always a list
 (let ((args (if (not (string? args))
              args
              '(args))))
  (cond
   ((null? command)
    (list-events))
   ((equal? command "list")
    (list-events))
   ((equal? command "--version")
    (version))
   ((equal? command "-v")
    (version))
   ((equal? command "help")
    (help))
   ((equal? command "tag")
    (tag (second args) (cdr (cdr args))))
   ((equal? command "tags")
    (list-tags))
   ((equal? command "comment")
    (comment (second args) (string-join (cdr (cdr args)) " ")))
   ((equal? command "retag")
    (retag (second args) (cdr (cdr args))))
   ((equal? command "delete")
    (delete-entry (second args)))
   ((equal? command "kill")
    (delete-person (second args)))
   ((equal? command "data")
    (data (car args)))
   ((equal? command "graph")
    (graph (cdr args)))
   (else
    (sprintf "Unknown command ~A" command)))))

(define (version)
 (print
  "Hey version 0.7.0\nCopyright 2017 Kay Rhodes\nDistributed under the MIT License.\nWritten in Chicken Scheme."))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define recognized-commands
 '("tag" "retag" "delete" "kill" "data" "list" "comment" "graph" "--version" "-v" "help" "tags"))
(define (main args)
 (let ((downcased-args (downcase-list args)))
  (if (> (length downcased-args) 1)
   (let ((first-arg (nth 1 downcased-args)))
    (if (list-includes recognized-commands first-arg)
     (process-command first-arg (cdr downcased-args))
     (create-entry (cdr downcased-args) (open-db))))
   (process-command '() '()))))

(if (and (not (null? (argv)))
         (not (equal? (car (argv)) "csi")))
 (main (argv)))
