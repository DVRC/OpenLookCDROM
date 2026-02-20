;;; -*- Mode: Lisp; Package: FFI -*-
;;;
;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.
;;;
;;; Created:       Tue May 28 15:10:11 1991 by Conal Elliott
;;; Last Modified: Wed May 29 13:16:10 1991 by Conal Elliott
;;;
;;; Extensions to :FFI.
;;;
;;; Sccs Id %W% %G%
;;;

(in-package :FFI)

(export '(def-exported-c-struct foreign-struct-field))

(defmacro def-exported-c-struct (name &rest other-stuff)
  "Just like def-exported-foreign-struct, but allows nesting."
  (let* ((saved-defs ())
	 (real-field-specs
	  ;; Stash away the nested defs.
	  (mapcan #'(lambda (field-spec)
		      (ecase (first field-spec)
			(def-exported-c-struct
			    (push field-spec saved-defs)
			    '())
			(foreign-struct-field
			 `( (,(second field-spec) :type ,(third field-spec)
			     ,@(if (fourth field-spec)
				   `(:overlays ,(fourth field-spec))
				   `())) ))))
		  other-stuff)))
    `(progn
      (progn ,@saved-defs)
      (def-exported-foreign-struct ,name
	  ,@real-field-specs))))
