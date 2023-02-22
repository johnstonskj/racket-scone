#lang scribble/manual

@(require racket/sandbox

          (rename-in
            scribble/core
            (make-table make-html-table)
            (struct:table struct:html-table)
            (table? html-table?)
            (table-columns html-table-columns))
          scribble/examples
          
          scone
          
          (for-label racket/base
                     racket/contract
                     
                     scone
                     scone/query))
                     
@;{============================================================================}

@(define example-eval (make-base-eval
                      '(require racket/string
                                scone scone/io scone/query)))

@;{============================================================================}

@title{Table Queries}
@defmodule[scone/query]

@section{Select}

@defproc[
  (select
   [columns (or/c (listof column-name/c) #t)]
   [#:from from table?]
   [#:where where (or/c procedure? #f) #f]
   [#:order-by order-by
               (or/c column-name/c (cons/c column-name/c order-by-direction/c) #f)
               #f]
   [#:limit limit (or/c exact-positive-integer? #f) #f]
   [#:as as-table-name (or/c table-name/c #f) #f])
  table?]{
  ...

@bold{Example 1 - select all}

In this case the SQL @tt{'*'} is represented as the value @racket[#t] as the value
for @racket[columns]. As this is the default value for the parameter it can
simply be ommited.

@verbatim|{
SELECT * FROM names_list;
}|

Note that the @racket[from] parameter is always required.

@racketblock[
(select #:from names-list)
]

@bold{Example 2 - projection}

Projection, the alteration of the table structure, can be achieved by providing
a list of @racket[column-name/c]s.

@verbatim|{
SELECT name, code_point FROM names_list;
}|

@racketblock[
(select '(name code-point) #:from names-list)
]

@bold{Example 3 - selection}

Selection, the filtering of the table rows, is achieved by providing a filter
predicate. It is called with the values of the row as individual parameters
and will ignore the row if the predicate returns @racket[#f].

@verbatim|{
SELECT name, code_point
  FROM names_list
 WHERE code_point < 256;
}|

Note that the parameters to the predicate are the complete, pre-projection,
list in the same order.

@racketblock[
(select '(name code-point)
        #:from names-list
        #:where (λ (cp . __) (< cp 256)))
]

@bold{Example 4 - sorting}

Sorting the projection and selection results is simple, adding an order-by
clause.

@verbatim|{
  SELECT name, code_point
    FROM names_list
ORDER BY name;
}|

Right now the implementation only supports sorting by a single column.

@racketblock[
(select '(name code-point)
        #:from names-list
        #:order-by 'name)
]

@bold{Example 4 - sorting with explicit ordering}

The need to sort by either ascending or descending order is similar except
that the @racket[select] procedure now takes a @racket[pair] rather than
a single @racket[column-name/c].

@verbatim|{
  SELECT name, code_point
    FROM names_list
ORDER BY name DESC;
}|
 
@racketblock[
(select '(name code-point)
        #:from names-list
        #:order-by '(name . desc))
]

@bold{Example 4 - create table as}

In SQL the results of a select statement are a temporary value that has to
be explicitly converted to be treated as a table.

@verbatim|{
CREATE TABLE ascii
AS (SELECT name, code_point
      FROM names_list
  ORDER BY name DESC);
}|

Scone uses the same table structure for stored tables and in-memory values;
therefore, the results of a @racket[select] procedure are already a table.
To provide a meaningful name for the table the @racket[#:as] keyword sets
the @racket[name] property of the result's table definition.

@racketblock[
(select '(name code-point)
        #:from names-list
        #:order-by '(name . desc)
        #:as 'ascii)
]

}

@section{Pivot}

@defproc[
  (pivot-table->columnar [table table?])
  columnar-table?]{
  ...
}

@defproc[
  (pivot-columnar->table [table columnar-table?])
  table?]{
  ...
}

@section{Describe}

@defproc[
  (describe
   [table table-type/c]
   [out output-port? (current-output-port)])
  any]{
  ...

@bold{Example}

@examples[
#:label #f
#:eval example-eval
(define names-list
        (read-table-from-file "./tests/names-list.scone"))

(describe names-list)
]

}

@section{Query Contracts}

@defproc[
  #:kind "contract"
  (order-by-direction/c [maybe-order-by-direction any/c])
  boolean?]{
  ...
  @racket['asc] or @racket['desc].
}

@section{Query Defaults}

@defparam[
  default-order-by-direction
  order-by-direction
  order-by-direction/c
  #:value 'asc]{
  ...
}
