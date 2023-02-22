# Racket Package scone

SCONE - SCheme Object Notation (Economized) is a simple file format that is a
strict subset of the Scheme language and is intended to be parsed directly by
the Scheme reader. The intent is to be a Scheme-friendly replacement for file
types such as CSV or JSON where simple tabular data is stored or exchanged.


This package provides the core data types as well as read and write
capabilities and simple query over the in-memory representation.

## Example 

``` racket
#lang racket/base

(require
 scone
 scone/io
 scone/query)

(define names-list (read-table-from-file "names-list.scone"))

(describe names-list)

(define (has-decomposition cp name syntax dc . rest) (not (null? dc)))

(define selected
  (select
   '(code_point decomposition name)
   #:from     names-list
   #:where    has-decomposition
   #:order-by '(name . desc)
   #:as       'names-with-dc))
```

## Changes

**Version 0.1**

* Initial release
