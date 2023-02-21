#lang racket/base

(provide
 read-table
 read-table-from-file
 write-table
 write-table-to-file

 file-extension/c
 read-definition/c)

(require
 racket/bool
 racket/contract
 
 "./main.rkt")

;; -------------------------------------------------------------------------------------
;; Private Stuff
;; -------------------------------------------------------------------------------------

(define file-extension/c
  (flat-named-contract
   'file-extension
   (lambda (v) (and (string? v)
               (for/and ([c (string->list v)]) (char-alphabetic? c))))))

(define/contract (check-file-extension v) (-> file-extension/c file-extension/c) v)

(define (columndef->list def)
  (list
   (columndef-name def)
   (columndef-data-type def)
   (columndef-is-list def)))

(define (tabledef->list def)
  (map columndef->list (tabledef-columns def)))

;; -------------------------------------------------------------------------------------
;; Public Stuff
;; -------------------------------------------------------------------------------------

(define default-file-extension
  (make-parameter 'scoff check-file-extension))

(define read-definition/c
  (flat-named-contract
   'read-definition
   (lambda (v) (or (tabledef? v) (eq? v 'none) (eq? v 'first) (eq? v 'infer)))))

(define (read-table [table-definition 'none] [in (current-input-port)])
  (let next-datum ([table-definition table-definition] [datum (read in)] [rows '()])
    (if (eof-object? datum)
        (make-table table-definition rows)
        (cond
         ((not (list? datum))
          (error "rows need to be lists" datum))
         ((null? datum)
          (error "empty rows not allowed" datum))
         (else
          (let-values
              ([(new table-definition) 
                (cond
                 ((or (number? table-definition)
                      (tabledef? table-definition))
                  (values #f table-definition))
                 ((symbol=? table-definition 'none)
                  (values #t (length datum)))
                 ((symbol=? table-definition 'first)
                  (values #t (make-tabledef datum)))
                 ((symbol=? table-definition 'infer)
                  (values #t (make-tabledef-from datum)))
                 (else
                  (error "invalid table definition" table-definition)))])
            (next-datum
             table-definition
             (read in)
             (if new
                 rows
                 (cons (row-validate table-definition (list->vector datum)) rows)))))))))

(define (read-table-from-file file-name [table-definition 'first] #:mode [mode-flag 'binary])
  (with-input-from-file file-name
    (lambda () (read-table table-definition))
    #:mode mode-flag))

(define (write-table table [out (current-output-port)])
  (if (table? table)
      (begin
        (writeln (tabledef->list (table-def table)))
        (for-each (λ (row) (writeln (vector->list row))) (table-rows table)))
      (error "invalid table type" table)))

(define (write-table-to-file table
                             [file-name #f]
                             #:mode [mode-flag 'binary]
                             #:exists [exists-flag 'error]
                             #:permissions [permissions #o666])
  (with-output-to-file
      (if (false? file-name) (format "~a.~a" (table-name table) (default-file-extension)) file-name)
    (lambda () (write-table table))
    #:mode mode-flag
    #:exists exists-flag
    #:permissions permissions))

