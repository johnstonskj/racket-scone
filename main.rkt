#lang racket/base

(require racket/contract/base)

(provide
 (contract-out
  [data-type/c contract?]
  [table-type/c contract?]
  [table-name/c contract?]
  [column-name/c contract?]
  [value/c contract?]
  [row/c contract?]
  [columndef-from/c contract?]
 
  [default-column-prefix (parameter/c column-name/c)]
  [default-column-data-type (parameter/c data-type/c)]
  [default-table-name (parameter/c table-name/c)]

  [make-columndef (->* (column-name/c) (data-type/c boolean?) columndef?)]
  [make-columndef-from (-> value/c exact-nonnegative-integer? columndef?)]
  [columndef? predicate/c]
  [columndef-name (-> columndef? column-name/c)]
  [columndef-data-type (-> columndef? data-type/c)]
  [columndef-is-list (-> columndef? boolean?)]

  [make-tabledef (->* ((listof columndef-from/c)) (table-name/c) tabledef?)]
  [make-tabledef-from (-> row/c tabledef?)]
  [tabledef? predicate/c]
  [tabledef-name (-> tabledef? table-name/c)]
  [tabledef-columns (-> tabledef? (listof columndef?))]
  [tabledef-column-count (-> tabledef? (or/c exact-nonnegative-integer? #f))]
  [tabledef-has-column? (-> tabledef? column-name/c boolean?)]
  [tabledef-column-def
   (-> tabledef?
       column-name/c
       (or/c (cons/c exact-nonnegative-integer? columndef?) #f))]
  [tabledef-column-index
   (-> tabledef? column-name/c exact-nonnegative-integer?)]

  [make-table (-> tabledef? (listof row/c) table?)]
  [table? predicate/c]
  [table-def (-> table? tabledef?)]
  [table-rows (-> table? (listof row/c))]

  [make-columnar-table (-> tabledef? (listof row/c) columnar-table?)]
  [columnar-table? predicate/c]
  [columnar-table-def (-> columnar-table? tabledef?)]
  [columnar-table-columns (-> columnar-table? (vectorof (listof value/c)))]
  
  [table-name (-> table-type/c table-name/c)]
  [table-columns (-> table-type/c (listof columndef?))]
  [table-column-count (-> table-type/c exact-nonnegative-integer?)]
  [table-has-column? (-> table-type/c column-name/c boolean?)]
  [table-column-def
   (-> table-type/c
       column-name/c
       (or/c (cons/c exact-nonnegative-integer? columndef?) #f))]
  [table-column-index
   (-> table-type/c column-name/c (or/c exact-nonnegative-integer? #f))]
  [table-row-count (-> table-type/c exact-nonnegative-integer?)]
  
  [next-table-name (-> table-name/c)]

  [row-validate (-> tabledef? row/c row/c)]))

(require
 racket/bool
 racket/contract
 racket/list)

;; -------------------------------------------------------------------------------------
;; Parameters
;; -------------------------------------------------------------------------------------

(define data-type/c
  (flat-named-contract 'data-type (or/c 'boolean 'number 'string 'symbol)))

(define (next-table-counter)
  (let ([i table-counter])
    (set! table-counter (add1 i))
    i))

(define table-name/c
  (flat-named-contract 'table-name symbol?))

;; Public ------------------------------------------------------------------------------

(define default-column-prefix
  (make-parameter
   'column
   (λ (p) (if (symbol? p) p (error "invalid type column prefix, expecting a symbol" p)))))

(define default-column-data-type
  (make-parameter 'string))

(define default-table-name
  (make-parameter 'unnamed))

(define table-counter 1)

;; -------------------------------------------------------------------------------------
;; The Column Definition type
;; -------------------------------------------------------------------------------------

(define column-name/c (flat-named-contract 'column-name symbol?))

(define (value->data-type value)
  (cond
    ((boolean? value) 'boolean)
    ((number? value) 'number)
    ((string? value) 'string)
    ((symbol? value) 'symbol)
    (else (error "invalid type for value in row" value))))

;; Public ------------------------------------------------------------------------------

(struct columndef (name data-type is-list) #:transparent)

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

(define (next-table-name)
  (string->symbol (format "~a_~a" (default-table-name) (next-table-counter))))

;; Public ------------------------------------------------------------------------------

(struct tabledef (name columns) #:transparent)

(define columndef-from/c
  (or/c
   columndef?
   symbol?
   (list/c symbol?)
   (list/c symbol? data-type/c)
   (list/c symbol? data-type/c boolean?)))

(define (make-tabledef column-defs [name #f])
  (tabledef
   (or name (next-table-name))
   (for/list ([column column-defs])
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

(define (tabledef-has-column? def name)
    (if (tabledef-column-def def name) #t #f))

(define (tabledef-column-def def name)
  (let next-column ([columns (tabledef-columns def)] [index 0])
    (cond
      ((null? columns) (error "table does not contain column" def name))
      ((symbol=? (columndef-name (first columns)) name) (cons index (first columns)))
      (else (next-column (rest columns) (add1 index))))))

(define (tabledef-column-index def name)
  (let ([column-def (tabledef-column-def def name)])
    (if column-def (car column-def) #f)))

;; -------------------------------------------------------------------------------------
;; The Table data type
;; -------------------------------------------------------------------------------------

(struct table (def rows) #:transparent)

(define make-table table)

;; -------------------------------------------------------------------------------------
;; The Columnar Table data type
;; -------------------------------------------------------------------------------------

(struct columnar-table (def columns) #:transparent)

(define make-columnar-table columnar-table)

;; -------------------------------------------------------------------------------------
;; Common Table/Cable procedures
;; -------------------------------------------------------------------------------------

(define table-type/c
  (flat-named-contract 'table-type (or/c table? columnar-table?)))

(define/contract (check-table-type v) (-> table-type/c table-type/c) v)

(define (table-name table)
  (cond
    ((columnar-table? table) (tabledef-name (columnar-table-def table)))
    ((table? table) (tabledef-name (table-def table)))
    (else (error "unreachable"))))

(define (table-columns table)
  (cond
    ((columnar-table? table) (tabledef-columns (columnar-table-def table)))
    ((table? table) (tabledef-columns (table-def table)))
    (else (error "table-columns: expecting either table or cable" table))))

(define (table-column-count table)
  (cond
    ((columnar-table? table) (length (tabledef-columns (columnar-table-def table))))
    ((table? table) (length (tabledef-columns (table-def table))))
    (else (error "table-column-count: expecting either table or cable" table))))

(define (table-has-column? table name)
  (cond
    ((columnar-table? table) (tabledef-has-column? (columnar-table-def table) name))
    ((table? table) (tabledef-has-column? (table-def table) name))
    (else (error "table-has-column?: expecting either table or cable" table))))

(define (table-column-def table name)
  (cond
    ((columnar-table? table) (tabledef-column-def (columnar-table-def table) name))
    ((table? table) (tabledef-column-def (table-def table) name))
    (else (error "table-column-def: expecting either table or cable" table))))

(define (table-column-index table name)
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

(define value/c
  (or/c
   boolean? number? string? symbol?
   (listof boolean?) (listof number?) (listof string?) (listof symbol?)))

(define row/c (vectorof value/c))

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
