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
                     scone/io))

                     
@;{============================================================================}

@(define example-eval (make-base-eval
                      '(require racket/string
                                scone scone/io scone/query)))

@;{============================================================================}

@title{Table I/O}
@defmodule[scone/io]

The header row is a serialized form of the @racket[tabledef] struct but for
ease of authoring it accepts simplified forms according to the
@racket[columndef-from/c] contract. Note that the name of the table is not
included in the serialized form.

@racketblock[
(define tabledef-from/c (listof columndef-from/c))
]

The following are both legal serialized table definitions.

@racketblock[
(code-point name decomposition)

((code-point number) name (decomposition number #t)) 
]

Rows in the serial form are separate datum, there is no enclosing @racket[list]
or @racket[vector] so that a file can be read and processed row-by-row using
the standard Racket @italic{reader} (see 
@secref["reader" #:doc '(lib "scribblings/reference/reference.scrbl")]). The
following is a legal serialized table.

@racketblock[
((code-point number) name (decomposition number #t)) 
(0 "NULL" ())
(1 "START OF HEADING" ())
(2 "START OF TEXT" ())
(3 "END OF TEXT" ())
]

@;{============================================================================}

@section{Reading}

@defproc[
  (read-table
   [table-definition read-definition/c 'first]
   [ext-validator (or/c row-validator/c #f) #f]
   [in input-port? (current-input-port)])
  table?]{
  Read a table from the provided @racket[input-port?].

  The @racket[table-definition] is used to determine how to construct the
  table's @racket[tabledef] struct. See @racket[read-definition/c] for
  options.

  The @racket[ext-validator] may be used to provide an external validation
  procedure for each row as it is read. The procedure is passed the row
  after validation against the table's @racket[tabledef] allowing the
  procedure to perform any context-specific validation.
}

@defproc[
  (read-table-from-file
   [file-path path-string?]
   [ext-validator (or/c row-validator/c #f) #f]
   [table-definition read-definition/c 'first]
   [#:mode mode-flag (or/c 'binary 'text) 'binary])
  table?]{
  Read a table from the file at @racket[file-path]; this is equivalent to the
  following:

@racketblock[
(with-input-from-file
  file-path
  (lambda () (read-table table-definition ext-validator))
  #:mode mode-flag)
]
}

@;{============================================================================}

@section{Display}

@defproc[
  (display-table
   [table table?]
   [out output-port? (current-output-port)])
   any]{
  This procedure will print the table as formatted output using the
  @other-doc['(lib "text-table/scribblings/text-table.scrbl")] module. By
  default numeric values are right-aligned, strings and symbols are left-
  aligned and booleans are centered.

@bold{Example}

@examples[
#:label #f
#:eval example-eval

(display-table
 (select '(code_point name syntax)
          #:from (read-table-from-file "./tests/names-list.scone")
          #:where (λ (cp __ syn . ___)
                     (and (< cp 128) (eq? syn 'control)))))
]

}

@;{============================================================================}

@section{Writing}

@defproc[
  (write-table
   [table table?]
   [out output-port? (current-output-port)])
   any]{
  Write the in-memory table in @italic{scone} form to the provided output port.
}

@defproc[
  (write-table-to-file
   [table table?]
   [file-name (or/c path-string? #f)]
   [#:mode mode-flag (or/c 'binary 'text) 'binary]
   [#:exists exists-flag (or/c 'error 'append 'update 'can-update
      'replace 'truncate
      'must-truncate 'truncate/replace) 'error]
   [#:permissions permissions (integer-in 0 65535) #o666])
   any]{
  Write the in-memory table in @italic{scone} form to the provided file path.

  Note that the values for @racket[mode-flag], @racket[exists-flag], and
  @racket[permissions] are the same as for the standard library's
  @racket[with-output-to-file] procedure.
  
  If @racket[file-name] is @racket[#f] the procedure will synthesize a file
  name from the table name in @racket[tabledef] and the value of
  @racket[default-file-extension].
}

@;{============================================================================}

@section{I/O Contracts}

@defproc[
  #:kind "contract"
  (file-extension/c [value any/c])
  boolean?]{
  ...
}

@defproc[
  #:kind "contract"
  (read-definition/c [value any/c])
  boolean?]{
  A contract that describes how @racket[read] and @racket[read-from-file]
  are to create the new table's definition.
  
  @itemlist[
    @item{@racket[tabledef], a complete existing definition}
    @item{@racket['first], the first row is a serialized @racket[tabledef]}
    @item{@racket['infer], infer a @racket[tabledef] from the first data row}
    @item{@racket['none], assume all columns have the type in the
      @racket[default-column-data-type] parameter}
  ]
}

@defproc[
  #:kind "contract"
  (row-validator/c [value row row/c])
  row/c]{
  A contract that defines a procedure which will take a row (@racket[row/c])
  and return row if it succeeds. If the procedure fails it is expected to
  signal an error.
}

@;{============================================================================}

@section{I/O Defaults}

@defparam[
  default-file-extension
  file-extension
  file-extension/c
  #:value 'scone]{
  ...
}
