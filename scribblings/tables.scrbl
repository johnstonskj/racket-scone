#lang scribble/manual

@(require racket/file
          racket/sandbox
          
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
                     
                     scone))
                     
@;{============================================================================}

@(define example-eval (make-base-eval
                      '(require racket/string
                                scone)))

@;{============================================================================}
@;{============================================================================}

@title{Tables}
@defmodule[scone]

Tables are the core data type in scone, they represent simple tabular data in
a similar manner to CSV files. There are two table types, row-oriented and
column-oriented, although the former has more support at this time than the
latter. Tables are intended to be as light-weight as possible with very simple
schema-like @italic{definitions} and to use a mix of lists and vectors for the
main data.

@;{============================================================================}

@section{Table Types}

@defstruct[
  table
  ([def tabledef?]
   [rows (listof row/c)])
  #:transparent
  #:omit-constructor]{
  Construct a row-oriented table from the given @secref["Table_Definition"] and
  list of rows. Each row @bold{must} have the same number of columns as the
  definition and each value @bold{must} conform to the corresponding
  @secref["Column_Definition"]. 

@bold{Layout}

@verbatim|{
,-------------------------------------------------------------------,
| vector          | columndef | columndef  | columndef  | columndef |
|-----------------+-----------+------------+------------+-----------|
| list   | vector | value     | value      | value      | value     |
|        | vector | value     | value      | value      | value     |
|        | vector | value     | value      | value      | value     |
|        | vector | value     | value      | value      | value     |
'-------------------------------------------------------------------'
}|
}

@defstruct[
  columnar-table
  ([def tabledef?]
   [columns (vectorof list?)])
  #:transparent
  #:omit-constructor]{
  Construct a column-oriented table from the given @secref["Table_Definition"] 
  and vector of column data. The vector of column data @bold{must} have the same
  number of values as the definition has columns and each value is a list where
  every value @bold{must} conform to the corresponding
  @secref["Column_Definition"]. 

@bold{Layout}

@verbatim|{
,----------------------------------------------------------,
| vector | columndef | columndef  | columndef  | columndef |
|--------+-----------+------------+------------+-----------|
| vector | list      | list       | list       | list      |
|        |-----------+------------+------------+-----------|
|        | value     | value      | value      | value     |
|        | value     | value      | value      | value     |
|        | value     | value      | value      | value     |
'----------------------------------------------------------'
}|
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
  (table-has-column?
  [table table-type/c]
  [name column-name/c])
  boolean?]{
  Return @racket[#t] if this table has a column named @racket[name],
  else @racket[#f].
}

@defproc[
  (table-column-def
   [table table-type/c]
   [name column-name/c])
  (or/c (cons/c exact-nonnegative-integer? columndef?) #f)]{
  Find the @racket[columndef] for the column named @racket[name]. If found
  return the @racket[columndef] and the index of the column in the
  @racket[tabledef]. If not found return @racket[#f].
}

@defproc[
  (table-column-index
   [table table-type/c]
   [name column-name/c])
  (or/c exact-nonnegative-integer? #f)]{
  Find the @racket[columndef] for the column named @racket[name]. If found
  return the index of the column in the @racket[tabledef]. If not found
  return @racket[#f].
}

@defproc[
  (table-row-count
   [table table-type/c])
  exact-nonnegative-integer?]{
  Returns the number of rows in this table.
}

@subsection{Rows and Values}

@defproc[
  (row-validate
   [tabledef tabledef?]
   [row row/c])
  row/c]{
  Validate the values in the row with the column definitions for the given
  table.
}

@;{============================================================================}

@section{Table Definition}

A table definition structure, @racket[tabledef], acts as the schema for a
@racket[table] or @racket[columnar-table].

@defstruct[
  tabledef
  ([name column-name/c]
   [columns (listof columndef?)])
  #:transparent
  #:omit-constructor]{
  The table definition contains the table's name and a vector of
  @racket[columndef] values.
}

@defproc[
  #:kind "constructor"
  (make-tabledef
   [columns (listof columndef-from/c)]
   [name table-name/c (next-table-name)])
  tabledef?]{
  Construct a new @racket[tabledef], if no name is supplied one will be
  generated using @racket[next-table-name].
}

@defproc[
  #:kind "constructor"
  (make-tabledef-from
  [row row/c])
  tabledef?]{
  Given a row from a table, infer a table definition from the values in the row.
}

@defproc[
  (tabledef-column-count
  [def tabledef?])
  exact-nonnegative-integer?]{
  Return the number of columns in this table definition.
}

@defproc[
  (tabledef-has-column?
  [def tabledef?]
  [name column-name/c])
  boolean?]{
  Return @racket[#t] if this table definition has a column named
  @racket[name], else @racket[#f].
}

@defproc[
  (tabledef-column-def
  [def tabledef?]
  [name column-name/c])
  (or/c (cons/c exact-nonnegative-integer? columndef?) #f)]{
  Find the @racket[columndef] for the column named @racket[name]. If found
  return the @racket[columndef] and the index of the column in the
  table definition. If not found return @racket[#f].
}

@defproc[
  (tabledef-column-index
  [def tabledef?]
  [name column-name/c])
  (or/c exact-nonnegative-integer? #f)]{
  Find the @racket[columndef] for the column named @racket[name]. If found
  return the index of the column in the table definition. If not found
  return @racket[#f].
}

@defproc[(next-table-name) (table-name/c)]{
  Return a newly created table name using the value of the parameter
  @racket[default-table-name] with a suffix of the form @racket{"_❬nn❭"}.
}

@;{============================================================================}

@section{Column Definition}

A column definition structure, @racket[columndef], acts as the schema for a
single column within a table's @racket[tabledef].

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
  [value value/c]
  [index exact-nonnegative-integer?])
  columndef?]{
  ...
}

@;{============================================================================}

@section{Table Contracts}

@defproc[
  #:kind "contract"
  (columndef-from/c [value any/c])
  boolean?]{
  Returns @racket[#t] if the provided data @racket[value] conforms to the
  following contract.

@racketblock[
(or/c
   column-name/c
   (list/c column-name/c)
   (list/c column-name/c data-type/c)
   (list/c column-name/c data-type/c boolean?))
]
}

@defproc[
  #:kind "contract"
  (column-name/c [value any/c])
  boolean?]{
  Returns @racket[#t] if the provided @racket[value] is a valid column name. 
}

@defproc[
  #:kind "contract"
  (data-type/c [value any/c])
  boolean?]{
  Returns @racket[#t] if the provided @racket[value] is a valid column data
  type. Valid values are currently: 

  @itemlist[
    @item{@racket['boolean], accepts the standard boolean values @racket[#t] and
      @racket[#f]}
    @item{@racket['number], accepts any numeric value}
    @item{@racket['string], accepts any string value}
    @item{@racket['symbol], accepts any symbol value}
  ]
}

@defproc[
  #:kind "contract"
  (row/c [value any/c])
  boolean?]{
  Returns @racket[#t] if the provided @racket[value] is a vector where
  each value is a @racket[value/c].
}

@defproc[
  #:kind "contract"
  (table-name/c [value any/c])
  boolean?]{
  Returns @racket[#t] if the provided @racket[value] is a valid table name. 
}

@defproc[
  #:kind "contract"
  (table-type/c [value any/c])
  boolean?]{
  Returns @racket[#t] if the provided @racket[value] is a valid type of table --
  currently either @racket[table] or @racket[columnar-table].
}

@defproc[
  #:kind "contract"
  (value/c [value any/c])
  boolean?]{
  Returns @racket[#t] if the provided data @racket[value] corresponds to the
  types in @racket[data-type/c], and may be individual values or homogeneous
  lists.
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
