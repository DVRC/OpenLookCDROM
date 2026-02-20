;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)platforms.lisp	3.3 10/11/91


(in-package "LISPVIEW")

(defconstant xview (make-instance 'XView))

(defvar *default-platform* xview)



