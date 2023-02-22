#lang racket/base

(require racket/contract/base)

(provide
 (contract-out 
  [file-extension/c contract?]
  [read-definition/c contract?]
  [row-validator/c contract?]
 
  [read-table
   (->* ()
        (read-definition/c (or/c row-validator/c #f) input-port?)
        table?)]
  
  [read-table-from-file
   (->* (path-string?)
        (read-definition/c
         (or/c row-validator/c #f)
         #:mode (or/c 'binary 'text))
        table?)]
 
  [write-table
   (->*(table?)
       (output-port?)
       any/c)]
  
  [write-table-to-file
   (->* (table?)
        ((or/c path-string? #f)
         #:mode (or/c 'binary 'text)
         #:exists (or/c 'error 'append 'update 'can-update 'replace
                        'truncate 'must-truncate 'truncate/replace)
         #:permissions (integer-in 0 65535))
        any/c)]

  [display-table (->* (table?) (output-port?) any/c)]))

(require
 racket/bool
 racket/contract
 racket/format
 racket/string

 text-table
 
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
  (flat-named-contract 'read-definition (or/c tabledef? 'none 'first 'infer)))

(define row-validator/c (-> row/c row/c))

;; -------------------------------------------------------------------------------------

(define (read-table [table-definition 'first]
                    [ext-validator #f]
                    [in (current-input-port)])
  (let ([validator (if (false? ext-validator)
                       row-validate
                       (lambda (td row) (ext-validator (row-validate td row))))])
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
                      (values #t (make-tabledef-from (list->vector datum))))
                     (else
                      (error "invalid table definition" table-definition)))])
               (next-datum
                table-definition
                (read in)
                (if new
                    rows
                    (cons (row-validate table-definition (list->vector datum)) rows))))))))))

(define (read-table-from-file file-name
                              [table-definition 'first]
                              [ext-validator #f]
                              #:mode [mode-flag 'binary])
  (with-input-from-file file-name
    (lambda () (read-table table-definition ext-validator))
    #:mode mode-flag))

;; -------------------------------------------------------------------------------------

(define (mk-textualize-row lists)
  (lambda (row)
    (for/list ([value row] [is-list lists])
      (if is-list
          (string-join (map ~s value) ", ")
          value))))
    

(define (textualize table)
  (let* ([lists (map columndef-is-list (tabledef-columns (table-def table)))]
         [textualize-row (mk-textualize-row lists)])
    (append
     (list (map columndef-name (tabledef-columns (table-def table))))
     (map textualize-row (table-rows table)))))

(define (alignment table)
  (map (lambda (cd) (cond
                ((symbol=? (columndef-data-type cd) 'boolean) 'center)
                ((symbol=? (columndef-data-type cd) 'number) 'right)
                (else 'left)))
          (tabledef-columns (table-def table))))

(define (display-table table [out (current-output-port)])
  (parameterize ([current-output-port out])
    (print-table
     (textualize table)
     #:border-style 'single
     #:row-sep? '(#t #f ...)
     #:align (alignment table))))

;; -------------------------------------------------------------------------------------

(define (write-table table [out (current-output-port)])
  (if (table-type/c table)
      (begin (writeln (tabledef->list (table-def table)) out)
      (for-each (λ (row) (writeln (vector->list row) out)) (table-rows table)))
      (error "invalid table type" table)))

(define (write-table-to-file table
                             [file-name #f]
                             #:mode [mode-flag 'binary]
                             #:exists [exists-flag 'error]
                             #:permissions [permissions #o666])
  (with-output-to-file
    (if (false? file-name)
        (format "~a.~a" (table-name table) (default-file-extension))
        file-name)
    (lambda () (write-table table))
    #:mode mode-flag
    #:exists exists-flag
    #:permissions permissions))

