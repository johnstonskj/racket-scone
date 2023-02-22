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
                                scone scone/io scone/query)))

@;{============================================================================}

@title[#:version "1.0"]{Package Scone}
@author[(author+email "Simon Johnston" "johnstonskj@gmail.com")]

SCONE - SCheme Object Notation (Economized) is a simple file format that is a
strict subset of the Scheme language and is intended to be parsed directly by
the Scheme reader. The intent is to be a Scheme-friendly replacement for file
types such as CSV or JSON where simple tabular data is stored or exchanged.

This package provides the core data types as well as read and write
capabilities and simple query over the in-memory representation.

@bold{Example}

@examples[
#:eval example-eval
#:label #f
(define names-list (read-table-from-file "./tests/names-list.scone"))
(describe names-list)

(define (has-decomposition __1 __2 __3 dc . ___) (not (null? dc)))
(define selected
  (select
   '(code_point decomposition name)
   #:from     names-list
   #:where    has-decomposition
   #:order-by '(name . desc)
   #:as       'names-with-dc))

(describe selected)
]

@local-table-of-contents[]

@include-section["tables.scrbl"]

@include-section["io.scrbl"]

@include-section["query.scrbl"]

@section{License}

@subsection{Apache}

@verbatim|{|@file->string["LICENSE-APACHE"]}|

@subsection{MIT}

@verbatim|{|@file->string["LICENSE-MIT"]}|
