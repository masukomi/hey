;;;; interrupt-database.import.scm - GENERATED BY CHICKEN 4.11.0 -*- Scheme -*-

(eval '(import chicken scheme sql-de-lite loops))
(##sys#register-compiled-module
  'interrupt-database
  (list)
  '((load-db-at-path . interrupt-database#load-db-at-path)
    (create-tag . interrupt-database#create-tag)
    (find-id-of-person . interrupt-database#find-id-of-person)
    (create-person . interrupt-database#create-person)
    (find-person-by-name . interrupt-database#find-person-by-name)
    (find-id-of-tag . interrupt-database#find-id-of-tag)
    (create-event . interrupt-database#create-event)
    (find-event-by-id . interrupt-database#find-event-by-id)
    (get-last-event-id . interrupt-database#get-last-event-id)
    (join-tag-to-event . interrupt-database#join-tag-to-event)
    (join-tags-to-event . interrupt-database#join-tags-to-event)
    (event-has-tag? . interrupt-database#event-has-tag?)
    (join-person-to-event . interrupt-database#join-person-to-event)
    (comment-on-event . interrupt-database#comment-on-event))
  (list)
  (list))

;; END OF FILE
