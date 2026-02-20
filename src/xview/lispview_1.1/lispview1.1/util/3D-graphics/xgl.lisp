;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;%W% %G%


(in-package "XGL" :use '("LISP" "FOREIGN-FUNCTION-INTERFACE"))


(export '(with-xgl-lock))


(defmacro with-xgl-lock (&body body)
  `(XV:with-xview-lock ,@body))

