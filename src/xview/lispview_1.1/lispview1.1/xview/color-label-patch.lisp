;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;; Patch so that LispView (with OpenWindows V2 XView-related libraries)
;;;; can run under OpenWindows V3 and still correctly show pixmap labels for
;;;; buttons and settings.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 

(in-package :user)

(let ((*load-verbose* nil)
      (*redefinition-action* nil))
  (load-foreign-files
    (merge-pathnames "lispview/xview/ol_pixmap_label.o" *load-pathname*)))
