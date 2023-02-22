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
   [columns projection-clause/c]
   [#:from from from-clause/c]
   [#:where where selection-clause/c #f]
   [#:order-by order-by order-by-clause/c #f]
   [#:limit limit limit-clause/c #f]
   [#:offset offset offset-clause/c 0]
   [#:as as-table-name as-table-clause/c #f])
  table?]{
  Perform a SQL-like select operation on the provided table. This form @italic{does
  not} support joins or aggregates but is a higher-level way to filter data.

  The @racket[columns] value defines the resulting projection and is either a
  list of column names to include, or @racket[#t] which returns all rows.

  The @racket[from] value (the only required value) is the source table to
  query.

  The @racket[where] value is a procedure that takes a number of @racket[value/c]
  values and returns a @racket[boolean?]. The number of arguments is equal to the
  number of columns in the table and are provided in-order. This means that even
  the @racket[columns] projects a subset of columns all the original columns are
  available to the filter function.

  The @racket[order-by] value is either the name of a column or a pair of column
  name and @racket[order-by-direction/c] that determines the sort operation to
  apply to the results.

  The @racket[limit] value provides a maximum number of rows to return in the
  results.

  The @racket[offset] value determines the number of rows that will be excluded
  in the results.

  The @racket[as-table-name] value is used as the name of the resulting table.

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

@bold{Example 5 - sorting with explicit ordering}

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

@bold{Example 6 - create table as}

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

@bold{Example 7 - paginated results}

The @racket[offset] (where to start) and @racket[limit] (number of rows)
together are useful in producing pages of results.

@verbatim|{
  SELECT name, code_point
    FROM names_list
ORDER BY name DESC
   LIMIT 25
  OFFSET 50;
}|
 
@racketblock[
(define page-limit 25)
(define (page-offset page-num) (* (sub1 page-num) page-size))

(select '(name code-point)
        #:from names-list
        #:order-by '(name . desc)
        #:limit page-limit
        #:offset (page-offset 3))
]
}

@section{Pivot}

@defproc[
  (pivot-table->columnar [table table?])
  columnar-table?]{
  Convert the input @racket[table] from row-oriented to column-oriented.
}

@defproc[
  (pivot-columnar->table [table columnar-table?])
  table?]{
  Convert the input @racket[table] from column-oriented to row-oriented.
}

@section{Describe}

@defproc[
  (describe
   [table table-type/c]
   [out output-port? (current-output-port)])
  any]{
  Describe the table in a SQL-like DDL form.

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
  (order-by-direction/c [value any/c])
  boolean?]{
  This defines the ordering operation, either
  ascending (@racket['asc]) or descending (@racket['desc]).
}

@defproc[
  #:kind "contract"
  (from-clause/c [value any/c])
  boolean?]{
  For @racket[select]; the table to select from.
}

@defproc[
  #:kind "contract"
  (projection-clause/c [value any/c])
  boolean?]{
  For @racket[select]; the set of columns to return in the resulting table.
}

@defproc[
  #:kind "contract"
  (selection-clause/c [value any/c])
  boolean?]{
  For @racket[select]; the filter procedure to determine rows to include
  in the resulting table.
}

@defproc[
  #:kind "contract"
  (order-by-clause/c [value any/c])
  boolean?]{
  For @racket[select]; the name, or name and direction pair, that determines
  the order of the resulting table.
}

@defproc[
  #:kind "contract"
  (limit-clause/c [value any/c])
  boolean?]{
  For @racket[select]; the maximum number of rows to include in the resulting
  table.
}

@defproc[
  #:kind "contract"
  (offset-clause/c [value any/c])
  boolean?]{
  For @racket[select]; the number of rows to drop from the start of the 
  resulting table.
}

@defproc[
  #:kind "contract"
  (as-table-clause/c [value any/c])
  boolean?]{
  For @racket[select]; the name to assign to the resulting table.
}

@section{Query Defaults}

@defparam[
  default-order-by-direction
  order-by-direction
  order-by-direction/c
  #:value 'asc]{
  The default ordering operation.
}
