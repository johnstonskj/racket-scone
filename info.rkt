#lang info
(define collection "scone")
(define pkg-desc "SCheme Object Notation (Economized)")
(define version "0.1")
(define pkg-authors '(johnstonskj))
(define license '(Apache-2.0 OR MIT))

(define deps '("base"))
(define build-deps '("sandbox-lib" "scribble-lib" "racket-doc" "rackunit-lib"))

(define scribblings '(("scribblings/scone.scrbl" (multi-page))))
