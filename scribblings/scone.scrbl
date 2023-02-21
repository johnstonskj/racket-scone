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

@title[#:version "1.0"]{Package Scone}
@author[(author+email "Simon Johnston" "johnstonskj@gmail.com")]

Package Description Here

@local-table-of-contents[]

@include-section["tables.scrbl"]

@include-section["io.scrbl"]

@include-section["query.scrbl"]

@section{License}

@subsection{Apache}

@verbatim|{|@file->string["LICENSE-APACHE"]}|

@subsection{MIT}

@verbatim|{|@file->string["LICENSE-MIT"]}|
