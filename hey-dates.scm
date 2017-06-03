(module hey-dates
 (
  date-at-midnight
  date-at-midnight-x-days-ago
  seconds-at-midnight
  seconds-at-midnight-minus-days
  subtract-days-from-epoch
  date->sqlite-string
  )
  (import chicken)
  (import scheme)
  (use srfi-19)
  (use posix)
  (use ports)

  ; (date->sqlite-string (date-at-midnight (subtract-days-from-epoch 1 (current-seconds)))
  ; now is (current-seconds)
  (define (date-at-midnight epoch-seconds)
    (seconds->date (seconds-at-midnight epoch-seconds)))
  (define (date-at-midnight-x-days-ago days epoch-seconds)
    (date-at-midnight (subtract-days-from-epoch days (current-seconds)))
    )

  (define (seconds-at-midnight epoch-seconds)
    (let ((epoch-v (seconds->local-time epoch-seconds)))
      (vector-set! epoch-v 0 0)
      (vector-set! epoch-v 1 0)
      (vector-set! epoch-v 2 0)
      (local-time->seconds epoch-v)
    )
  )
  (define (seconds-at-midnight-minus-days days epoch-seconds)
    (seconds-at-midnight
      (subtract-days-from-epoch 1 epoch-seconds)))

  (define (subtract-days-from-epoch days epoch-seconds)
    (let ((day-seconds (* days 86400))) ; seconds in a day
          (- epoch-seconds day-seconds)
    )
  )


  (define (date->sqlite-string date)
    (let ((output-port (open-output-string)))
     (format-date output-port "~Y-~m-~d" date)
     (get-output-string output-port)))
) 
