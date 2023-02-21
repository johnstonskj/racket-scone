#lang scribble/manual

@(require racket/sandbox
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
                     scone
                     scone/query))

@;{============================================================================}

@title{Table Queries}
@defmodule[scone/query]

@section{Select}

@defproc[
  (select
   [columns (or/c (listof column-name/c) #t)]
   [#:from from table-name/c]
   [#:where where (or/c procedure? #f) #f]
   [#:order-by order-by
               (or/c column-name/c (cons/c column-name/c order-by-direction/c) #f)
               #f]
   [#:as as-table-name (or/c table-name/c #f) #f])
  table?]{
  ...
}

@section{Pivot}

@defproc[
  (pivot [table table-type/c])
  table-type/c]{
  ...
}

@section{Describe}

@defproc[
  (describe
   [table table-type/c]
   [out output-port? (current-output-port)])
  any]{
  ...
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
