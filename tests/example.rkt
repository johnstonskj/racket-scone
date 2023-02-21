#lang racket/base

(require
 scone
 scone/io
 scone/query)


(define names-list (read-table-from-file "names-list.scoff"))

(describe names-list)

(define (has-decomposition cp name syntax dc . rest) (not (null? dc)))

(define selected
  (select
   '(code_point decomposition name)
   #:from     names-list
   #:where    has-decomposition
   #:order-by '(name . desc)
   #:as       'names-with-dc))

;;(write-table-to-file selected #:exists 'replace)

(define pivoted (pivot selected))

(describe pivoted)

