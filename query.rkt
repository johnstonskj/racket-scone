#lang racket/base

(require racket/contract/base)

(provide
 (contract-out
  [order-by-direction/c contract?]
  
  [from-clause/c contract?]
  [projection-clause/c contract?]
  [selection-clause/c contract?]
  [order-by-clause/c contract?]
  [limit-clause/c contract?]
  [offset-clause/c contract?]
  [as-table-clause/c contract?]
  
  [default-order-by-direction (parameter/c order-by-direction/c)]
    
  [select
   (->* (#:from from-clause/c)
        (projection-clause/c
         #:where selection-clause/c
         #:order-by order-by-clause/c
         #:limit limit-clause/c
         #:offset offset-clause/c
         #:as as-table-clause/c)
        table?)]
  
  [pivot-table->columnar (-> table? columnar-table?)]
  
  [pivot-columnar->table (-> columnar-table? table?)]
  
  [describe
   (->* (table-type/c) (output-port?) any/c)]))

(require
 racket/bool
 racket/contract
 racket/list

 "./main.rkt")

;; -------------------------------------------------------------------------------------
;; Private Stuff
;; -------------------------------------------------------------------------------------

(define order-by-direction/c
  (flat-named-contract 'order-by-direction (or/c 'asc 'desc)))

(define (symbol<? lhs rhs) (string<? (symbol->string lhs) (symbol->string rhs)))

(define (symbol>? lhs rhs) (string>? (symbol->string lhs) (symbol->string rhs)))

(define (sort-rows table rows order-by index dir)
  (let ([column (cdr (table-column-def table order-by))])
    (sort
     rows
     #:key (λ (row) (vector-ref row index))
     (let ([data-type (columndef-data-type column)])
       (cond
         ((columndef-is-list column) (error "cannot sort lists"))
         ((symbol=? data-type 'symbol) (if (symbol=? dir 'asc) symbol<? symbol>?))
         ((symbol=? data-type 'string) (if (symbol=? dir 'asc) string<? string>?))
         ((symbol=? data-type 'number) (if (symbol=? dir 'asc) < >))
         (else (error "invalid sort data type")))))))

(define (select-where row projection where)
  (if (or (false? where)  (apply where (vector->list row)))
      (if (eq? projection #t)
          row
          (for/vector ([col projection])
            (vector-ref row col)))
      #f))

(define (make-projection table columns)
  (cond
    ((eq? columns #t) #t)
    ((and (list? columns) (for/and ([column columns]) (symbol? column)))
     (map (λ (c) (table-column-index table c)) columns))
    (else
     (error "projection is either a list of column names or #t" columns))))

(define (projection->tabledef table columns)
  (let ([tabledef (table-def table)])
    (cond
      ((eq? columns #t) tabledef)
      ((and (list? columns) (for/and ([column columns]) (symbol? column)))
       (map (λ (c) (let ([column (cdr (tabledef-column-def tabledef c))]) column)) columns))
      (else
       (error "projection is either a list of column names or #t" columns)))))

(define (member-index v lst)
  (let next ([lst lst] [index 0])
    (cond
      ((null? lst) #f)
      ((equal? (first lst) v) index)
      (else (next (rest lst) (add1 index))))))

(define (order-by-column-index table projection order-by)
  (let ([order-by-index (table-column-index table order-by)])
    (member-index order-by-index projection)))

(define (query [columns #t]
               #:from from
               #:where [where #f]
               #:order-by [order-by #f]
               #:limit [limit #f]
               #:offset [offset 0])
  (let ([projection (make-projection from columns)])
    (let* ([selection (filter-map
                       (λ (row) (select-where row projection where))
                       (table-rows from))]
           [offset (cond
                    ((= offset 0) selection)
                    ((>= offset (length selection)) '())
                    (else (drop selection offset)))]
           [limited (if (or (false? limit) (> limit (length offset)))
                        offset
                        (take offset limit))])
      (values
       (projection->tabledef from columns)
       (cond
        ;; done.
        ((false? order-by) limited)
        ;; sort by column, default order
         ((symbol? order-by)
          (sort-rows
           from
           limited
           order-by
           (order-by-column-index
            from
            (if (list? projection)
                projection
                (range (table-column-count from)))
            order-by)
           (default-order-by-direction)))
         ;; sort by column and order
         ((and (pair? order-by) (symbol? (car order-by)) (symbol? (cdr order-by)))
          (sort-rows
           from
           limited
           (car order-by)
           (order-by-column-index
            from
            (if
             (list? projection)
             projection
             (range (table-column-count from)))
            (car order-by))
           (cdr order-by)))
         (else (error "invalid order-by clause" order-by))))
      )))

(define (describe-tablelike table columnar? out)
  (displayln (format
              "CREATE EXTERNAL ~aTABLE ~a ("
              (if columnar? "COLUMNAR " "")
              (tabledef-name table)) out)
     (for ([column (tabledef-columns table)])
       (displayln (format "    ~a~a~a,"
                          (columndef-name column)
                          (if (columndef-is-list column) " LISTOF " " ")
                          (columndef-data-type column)) out))
     (displayln ")\nSTORED AS scone\nWITH HEADER ROW;" out))

;; -------------------------------------------------------------------------------------
;; Public Stuff
;; -------------------------------------------------------------------------------------

(define default-order-by-direction (make-parameter 'asc))

(define from-clause/c table?)

(define projection-clause/c (or/c (listof column-name/c) #t))

(define selection-clause/c (or/c procedure? #f))

(define order-by-clause/c (or/c column-name/c
               (cons/c column-name/c order-by-direction/c)
               #f))

(define limit-clause/c (or/c exact-positive-integer? #f))

(define offset-clause/c exact-nonnegative-integer?)

(define as-table-clause/c (or/c table-name/c #f))

(define (select [columns #t]
                #:from from
                #:where [where #f]
                #:order-by [order-by #f]
                #:limit [limit #f]
                #:offset [offset 0]
                #:as [as-table-name #f])
  (let-values ([(def rows)
                (query columns #:from from #:where where #:order-by order-by #:limit limit #:offset offset)])
    (make-table (make-tabledef
                 def
                 (if (symbol? as-table-name) as-table-name (next-table-name)))
                rows)))

(define (pivot-table->columnar table)
  (unless (table? table)
    (error "can only pivot a sdf-table" table))
  (make-columnar-table
   (table-def table)
   (list->vector
    (foldl
     (λ (in-row rows) (map (λ (v lst) (cons v lst)) (vector->list in-row) rows))
     (make-list (table-column-count table) '())
     (table-rows table)))))

(define (pivot-columnar->table table)
  (error "not implemented yet"))

(define (describe table [out (current-output-port)])
  (cond
    ((columnar-table? table) (describe-tablelike (columnar-table-def table) #t out))
    ((table? table) (describe-tablelike (table-def table) #f out))
    (else (error "describe: can't describe a non-table" table))))
