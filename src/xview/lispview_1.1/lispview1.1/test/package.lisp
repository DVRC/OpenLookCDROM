;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)package.lisp	1.6 10/17/91


(in-package "USER")

(LCL:defpackage "LISPVIEW-TEST"
  (:use "LISP" "CLOS" "LISPVIEW" "FOREIGN-FUNCTION-INTERFACE")
  (:nicknames "LVT")
  
  #+lucid
  (:import-from "LUCID-COMMON-LISP"
   "HANDLER-CASE"
   "CONDITION"
   "XOR"
   "PWD"
   "CD"
   "*LOAD-PATHNAME*")

  (:import-from "XVIEW"
    "XV-GET")

  (:import-from "LISPVIEW"
    "XVIEW-OBJECT-ID"
    "XVIEW-OBJECT-XID"
    "XVIEW-OBJECT-DSP")
  
  (:export
   "TEST-LISPVIEW"))

