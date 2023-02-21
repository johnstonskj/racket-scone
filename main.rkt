#lang racket/base

(provide
 data-type/c
 table-type/c
 table-name/c
 column-name/c
 
 default-column-prefix
 default-column-data-type
 default-table-name

 (except-out (struct-out columndef) columndef)
 make-columndef
 make-columndef-from

 (except-out (struct-out tabledef) tabledef)
 make-tabledef
 make-tabledef-from
 tabledef-column-count
 tabledef-column-def
 tabledef-column-index

 (except-out (struct-out table) table)
 (rename-out (table make-table))

 (except-out (struct-out columnar-table) columnar-table)
 (rename-out (columnar-table make-columnar-table))

 table-name
 table-columns
 table-column-count
 table-column-def
 table-column-index
 table-row-count
 next-table-name

 row-validate)

(require
 racket/bool
 racket/contract
 racket/list)

;; -------------------------------------------------------------------------------------
;; Parameters
;; -------------------------------------------------------------------------------------

(define data-type/c
  (flat-named-contract
   'data-type
   (lambda (v) (or (eq? v 'boolean) (eq? v 'number) (eq? v 'string) (eq? v 'symbol)))))

(define/contract
  (check-column-data-type type)
  (-> data-type/c data-type/c)
  type)

(define (next-table-counter)
  (let ([i table-counter])
    (set! table-counter (add1 i))
    i))

(define table-name/c (flat-named-contract 'table-name symbol?))

(define/contract (check-table-name name) (-> table-name/c table-name/c) name)

;; Public ------------------------------------------------------------------------------

(define default-column-prefix
  (make-parameter
   'column
   (λ (p) (if (symbol? p) p (error "invalid type column prefix, expecting a symbol" p)))))

(define default-column-data-type
  (make-parameter 'string check-column-data-type))

(define default-table-name
  (make-parameter 'unnamed check-table-name))

(define table-counter 1)

;; -------------------------------------------------------------------------------------
;; The Column Definition type
;; -------------------------------------------------------------------------------------

(define column-name/c (flat-named-contract 'column-name symbol?))

(define/contract (check-column-name name) (-> column-name/c column-name/c) name)

(define/contract (check-column-is-list is-list) (-> boolean? boolean?) is-list)

(define (value->data-type value)
  (cond
    ((boolean? value) 'boolean)
    ((number? value) 'number)
    ((string? value) 'string)
    ((symbol? value) 'symbol)
    (else (error "invalid type for value in row" value))))

;; Public ------------------------------------------------------------------------------

(struct columndef (name data-type is-list)
  #:transparent
  #:guard (λ (name data-type is-list struct-name)
            (values
             (check-column-name name)
             (check-column-data-type data-type)
             (check-column-is-list is-list))))

(define (make-columndef name [data-type (default-column-data-type)] [is-list? #f])
  (columndef name data-type is-list?))

(define (make-columndef-from value index)
  (let ([name
         (string->symbol (format "~a_~a" (default-column-prefix) (add1 index)))])
    (cond
      ((null? value)
       (make-columndef name 'string #t))
      ((list? value)
       (make-columndef name (value->data-type (car value)) #t))
      (else (make-columndef name (value->data-type value))))))

;; -------------------------------------------------------------------------------------
;; The Table Definition type
;; -------------------------------------------------------------------------------------

(define/contract
  (check-table-columns columns)
  (-> (listof columndef?) (listof columndef?))
  columns)

(define (next-table-name)
  (format "~a_~a" (default-table-name) (next-table-counter)))

;; Public ------------------------------------------------------------------------------

(struct tabledef (name columns)
  #:transparent
  #:guard (λ (name columns struct-name)
            (values
             (check-table-name name)
             (check-table-columns columns))))

(define (make-tabledef columns [name #f])
  (tabledef
   (or name (string->symbol (next-table-name)))
   (for/list ([column columns])
     (cond
       ((columndef? column) column)
       ((symbol? column) (make-columndef column))
       ((and (list? column) (>= (length column) 1)) (apply make-columndef column))
       (else (error "invalid value for column" column))))))

(define (make-tabledef-from row)
  (tabledef
   (next-table-name)
   (for/list ([value row] [index (in-range (vector-length row))])
     (make-columndef-from value index))))

(define (tabledef-column-count def)
  (length (tabledef-columns def)))

(define (tabledef-column-def def name)
  (let next-column ([columns (tabledef-columns def)] [index 0])
    (cond
      ((null? columns) (error "table does not contain column" tabledef name))
      ((symbol=? (columndef-name (first columns)) name) (values index (first columns)))
      (else (next-column (rest columns) (add1 index))))))

(define (tabledef-column-index def name)
  (let-values ([(index _) (tabledef-column-def def name)])
    index))

;; -------------------------------------------------------------------------------------
;; The Table data type
;; -------------------------------------------------------------------------------------

(struct table (def rows)
  #:transparent
  #:guard (λ (tabledef rows struct-name)
            (values
             (if (tabledef? tabledef)
                 tabledef
                 (error "expecting a tabledef" tabledef))
             (if (list? rows)
                 rows
                 (error "expecting a list of rows" rows)))))

;; -------------------------------------------------------------------------------------
;; The Columnar Table data type
;; -------------------------------------------------------------------------------------

(struct columnar-table (def columns)
  #:transparent
  #:guard (λ (def columns struct-name)
            (values
             (if (tabledef? def)
                 def
                 (error "cable: expecting a tabledef" def))
             (if (vector? columns)
                 columns
                 (error "cable: expecting a vector of columns" columns)))))

;; -------------------------------------------------------------------------------------
;; Common Table/Cable procedures
;; -------------------------------------------------------------------------------------

(define table-type/c
  (flat-named-contract 'table-type (lambda (v) (or (table? v) (columnar-table? v)))))

(define/contract (check-table-type v) (-> table-type/c table-type/c) v)

(define (table-name table)
  (check-table-type table)
  (cond
    ((columnar-table? table) (tabledef-name (columnar-table-def table)))
    ((table? table) (tabledef-name (table-def table)))
    (else (error "unreachable"))))

(define (table-columns table)
  (check-table-type table)
  (cond
    ((columnar-table? table) (tabledef-columns (columnar-table-def table)))
    ((table? table) (tabledef-columns (table-def table)))
    (else (error "table-columns: expecting either table or cable" table))))

(define (table-column-count table)
  (check-table-type table)
  (cond
    ((columnar-table? table) (length (tabledef-columns (columnar-table-def table))))
    ((table? table) (length (tabledef-columns (table-def table))))
    (else (error "table-column-count: expecting either table or cable" table))))

(define (table-column-def table name)
  (check-table-type table)
  (check-column-name name)
  (cond
    ((columnar-table? table) (tabledef-column-def (columnar-table-def table) name))
    ((table? table) (tabledef-column-def (table-def table) name))
    (else (error "table-column-def: expecting either table or cable" table))))

(define (table-column-index table name)
  (check-table-type table)
  (check-column-name name)
  (cond
    ((columnar-table? table) (tabledef-column-index (columnar-table-def table) name))
    ((table? table) (tabledef-column-index (table-def table) name))
    (else (error "table-column-index: expecting either table or cable" table))))

(define (table-row-count table)
  (cond
    ((columnar-table? table) (length (columnar-table-columns table)))
    ((table? table) (length (table-rows table)))
    (else (error "table-columns: expecting either table or cable" table))))

;; -------------------------------------------------------------------------------------
;; The Row not-a-type
;; -------------------------------------------------------------------------------------

(define (check-value-data-type data-type data)
  (cond
    ((and (symbol=? data-type 'symbol) (symbol? data)) #t)
    ((and (symbol=? data-type 'string) (string? data)) #t)
    ((and (symbol=? data-type 'number) (number? data)) #t)
    ((and (symbol=? data-type 'boolean) (boolean? data)) #t)
    (else (error "data value does not match expected data type" data data-type))))

(define (row-value-validate columndef data)
  (cond
    ((and (list? data) (columndef-is-list columndef))
     (for/and ([value data])
       (check-value-data-type (columndef-data-type columndef) value)))
    ((or (list? data) (columndef-is-list columndef))
     (error "data-type mismatch on list" data columndef))
    (else (check-value-data-type (columndef-data-type columndef) data))))

;; Public ------------------------------------------------------------------------------

(define (row-validate tabledef row)
  (cond
    ((and (vector? row)
          (number? tabledef)
          (= (vector-length row) tabledef))
     row)
    ((and (vector? row)
          (tabledef? tabledef)
          (= (vector-length row) (tabledef-column-count tabledef)))
     (for/and ([columndef (tabledef-columns tabledef)] [data row])
       (row-value-validate columndef data))
     row)
    (else (error "row did not match table definition" tabledef row))))
