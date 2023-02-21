#lang scribble/manual

@(require racket/sandbox
          racket/file
          (rename-in
            scribble/core
            (make-table make-html-table)
            (struct:table struct:html-table)
            (table? html-table?)
            (table-columns html-table-columns))
          scribble/eval
          scone
          (for-label racket/base
                     racket/contract
                     scone))
                     
@;{============================================================================}

@(define example-eval (make-base-eval
                      '(require racket/string
                                scone)))

@;{============================================================================}
@;{============================================================================}

@title{Tables}
@defmodule[scone]

@;{============================================================================}

@section{Table Types}

@defstruct[
  table
  ([def tabledef?]
   [rows (listof vector?)])
  #:transparent
  #:omit-constructor]{
  Construct a row-oriented table from the given @secref["Table_Definition"] and
  list of rows.
}

@defstruct[
  columnar-table
  ([def tabledef?]
   [columns (vectorof list?)])
  #:transparent
  #:omit-constructor]{
  Construct a column-oriented table from the given @secref["Table_Definition"] 
  and list of columns.
}

@defproc[
  (table-name
   [table table-type/c])
  table-name/c]{
  Return the name of this table, from it's @racket[tabledef].
}

@defproc[
  (table-columns
   [table table-type/c])
  (listof columndef?)]{
  Return the list of columns in this table, from it's @racket[tabledef].
}

@defproc[
  (table-column-count
   [table table-type/c])
  exact-nonnegative-integer?]{
  Return the number of columns in this table, from it's @racket[tabledef].
}

@defproc[
  (table-column-def
   [table table-type/c]
   [name column-name/c])
  (or/c (values columndef? exact-nonnegative-integer?) #f)]{
 ...
}

@defproc[
  (table-column-index
   [table table-type/c]
   [name column-name/c])
  (or/c exact-nonnegative-integer? #f)]{
 ...
}

@defproc[
  (table-row-count
   [table table-type/c])
  exact-nonnegative-integer?]{
  Returns the number of rows in this table.
}

@;{============================================================================}

@section{Table Definition}

A table definition structure, @racket[tabledef], acts as the schema for a 
@defstruct[
  tabledef
  ([name column-name/c]
   [columns (listof columndef?)])
  #:transparent
  #:omit-constructor]{
  ...
}

@defproc[
  #:kind "constructor"
  (make-tabledef
   [columns (listof columndef?)]
   [name table-name/c (next-table-name)])
  tabledef?]{
  ...
}

@defproc[
  #:kind "constructor"
  (make-tabledef-from
  [row vector?])
  tabledef?]{
  ...
}

@defproc[
  (tabledef-column-count
  [def tabledef?])
  exact-nonnegative-integer?]{
  ...
}

@defproc[
  (tabledef-column-def
  [def tabledef?]
  [name column-name/c])
  (or/c (values columndef? exact-nonnegative-integer?) #f)]{
  ...
}

@defproc[
  (tabledef-column-index
  [def tabledef?]
  [name column-name/c])
  (or/c exact-nonnegative-integer? #f)]{
  ...
}

@defproc[(next-table-name) (symbol?)]{
  ...
}

@;{============================================================================}

@section{Column Definition}

@defstruct[
  columndef
  ([name column-name/c]
   [data-type data-type/c]
   [is-list boolean?])
  #:transparent
  #:omit-constructor]{
  ...
}

@defproc[
  #:kind "constructor"
  (make-columndef
   [name column-name/c]
   [data-type data-type/c (default-column-data-type)]
   [is-list? boolean/c #f])
  columndef?]{
  ...
}


@defproc[
  #:kind "constructor"
  (make-columndef-from
  [value any/c]
  [index exact-nonnegative-integer?])
  columndef?]{
  ...
}

@;{============================================================================}

@section{Table Contracts}

@defproc[
  #:kind "contract"
  (data-type/c [maybe-data-type any/c])
  boolean?]{
  ...
  @itemlist[
    @item{@racket['boolean], }
    @item{@racket['number], }
    @item{@racket['string], }
    @item{@racket['symbol], }
  ]
}

@defproc[
  #:kind "contract"
  (column-name/c [maybe-column-name any/c])
  boolean?]{
  ...
}

@defproc[
  #:kind "contract"
  (table-name/c [maybe-table-name any/c])
  boolean?]{
  ...
}

@defproc[
  #:kind "contract"
  (table-type/c [maybe-table-type any/c])
  boolean?]{
  ...
}

@;{============================================================================}

@section{Table Defaults}

@defparam[
  default-column-data-type
  data-type
  data-type/c
  #:value 'string]{
  ...
}

@defparam[
  default-column-prefix
  column-prefix
  column-name/c
  #:value 'column]{
  ...
}

@defparam[
  default-table-name
  table-name
  table-name/c
  #:value 'unnamed]{
  ...
}
