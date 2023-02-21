#lang racket/base

(provide
 select
 pivot
 describe

 order-by-direction/c)

(require
 racket/bool
 racket/contract
 racket/list

 "./main.rkt")

;; -------------------------------------------------------------------------------------
;; Private Stuff
;; -------------------------------------------------------------------------------------

(define order-by-direction/c
  (flat-named-contract 'order-by-direction (lambda (v) (or (eq? v 'asc) (eq? v 'desc)))))

(define/contract
  (check-order-by-direction v)
  (-> order-by-direction/c order-by-direction/c)
  v)

(define (symbol<? lhs rhs) (string<? (symbol->string lhs) (symbol->string rhs)))

(define (symbol>? lhs rhs) (string>? (symbol->string lhs) (symbol->string rhs)))

(define (sort-rows table rows order-by index dir)
  (let-values ([(_ column) (table-column-def table order-by)])
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
       (map (λ (c) (let-values ([(_ column) (tabledef-column-def tabledef c)]) column)) columns))
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

(define (query [columns #t] #:from from #:where [where #f] #:order-by [order-by #f])
  (unless (table? from)
    (error "need to select from a sdf-table" from))
  (let ([projection (make-projection from columns)])
    (let ([selection (filter-map
                      (λ (row) (select-where row projection where))
                      (table-rows from))])
      (values
       (projection->tabledef from columns)
       (cond
         ((false? order-by) selection)
         ((symbol? order-by)
          (sort-rows
           from
           selection
           order-by
           (order-by-column-index
            from
            (if (list? projection)
                projection
                (range (table-column-count from)))
            order-by)
           (default-order-by-direction)))
         ((and (pair? order-by) (symbol? (car order-by)) (symbol? (cdr order-by)))
          (sort-rows
           from
           selection
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
     (displayln ")\nSTORED AS SDF\nWITH HEADER ROW;" out))

;; -------------------------------------------------------------------------------------
;; Public Stuff
;; -------------------------------------------------------------------------------------

(define default-order-by-direction
  (make-parameter 'asc check-order-by-direction))

(define (select [columns #t]
                #:from from
                #:where [where #f]
                #:order-by [order-by #f]
                #:as [as-table-name #f])
  (let-values ([(def rows) (query columns #:from from #:where where #:order-by order-by)])
    (make-table (make-tabledef
                 (if (symbol? as-table-name) as-table-name (next-table-name))
                 def)
                rows)))

(define (pivot table)
  ;; TODO: pivot columnar-table -> table
  (unless (table? table)
    (error "can only pivot a sdf-table" table))
  (make-columnar-table
   (table-def table)
   (list->vector
    (foldl
     (λ (in-row rows) (map (λ (v lst) (cons v lst)) (vector->list in-row) rows))
     (make-list (table-column-count table) '())
     (table-rows table)))))

(define (describe table [out (current-output-port)])
  (cond
    ((columnar-table? table) (describe-tablelike (columnar-table-def table) #t) out)
    ((table? table) (describe-tablelike (table-def table) #f) out)
    (else (error "describe: can't describe a non-table" table))))
