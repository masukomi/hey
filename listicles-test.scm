#!/usr/local/bin/csi

(use test)
(load "listicles.scm")
(import (prefix listicles l:))

(test-group "convert-rows-to-cols"
   (test "should have right number of columns" 
         3; expected
         (length (l:convert-rows-to-cols 
                   (list (list 1 2 3) (list 4 5 6))  )))
   (test "should have items from first col in first element"
         (list 1 4)
         (car (l:convert-rows-to-cols 
                (list (list 1 2 3) (list 4 5 6))  )))
)

; (test-group "extract-cols"
;   (test "should have right number of items" 
;         (l:extract-cols 
; )


(test-exit)

