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
                     scone/io))

@;{============================================================================}
@;{============================================================================}

@title{Table I/O}
@defmodule[scone/io]

@;{============================================================================}

@section{Reading}

@defproc[
  (read-table
   [table-definition read-definition/c 'none]
   [in input-port? (current-input-port)])
  table?]{
  ...
}

@defproc[
  (read-table-from-file
   [file-name path-string?]
   [table-definition read-definition/c 'none]
   [#:mode mode-flag (or/c 'binary 'text) 'binary])
  table?]{
  ...
}


@;{============================================================================}

@section{Writing}

@defproc[
  (write-table
   [table table?]
   [out output-port? (current-output-port)])
   any]{
  ...
}

@defproc[
  (write-table-to-file
   [file-name (or/c path-string? #f)]
   [#:mode mode-flag (or/c 'binary 'text) 'binary]
   [#:exists exists-flag (or/c 'error 'append 'update 'can-update
      'replace 'truncate
      'must-truncate 'truncate/replace) 'error]
   [#:permissions permissions (integer-in 0 65535) #o666])
   any]{
  ...
}

@;{============================================================================}

@section{I/O Contracts}

@defproc[
  #:kind "contract"
  (file-extension/c [maybe-file-extension any/c])
  boolean?]{
  ...
}

@defproc[
  #:kind "contract"
  (read-definition/c [maybe-read-definition any/c])
  boolean?]{
  ...
  @itemlist[
    @item{@racket['none], }
    @item{@racket['first], }
    @item{@racket['infer], }
    @item{@racket[tabledef], }
  ]
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
