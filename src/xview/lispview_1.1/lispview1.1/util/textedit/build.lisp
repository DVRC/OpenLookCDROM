;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)build.lisp	1.3 10/21/91


;;; Loading this file recompiles and reloads the textedit interface
;;; 
;;; This file assumes that the initial lisp image contains LispView

(in-package :USER) 

#-lispview
(error "This file can only be loaded into an image that has LispView")

(let ((pwd (LCL:pwd))
      (build-dir 
       (make-pathname :directory (pathname-directory LCL:*load-pathname*)))
      (files
       '("textedit-defs"
	 "textedit"
	 "xview-textedit")))

  (cd build-dir)

  (when (probe-file "SCCS")
    (when (probe-file "Makefile.sccs")
      (delete-file "Makefile.sccs"))
    (with-open-file (stream "Makefile.sccs" :direction :output)
      (format stream "getsccsfiles: ~{~A.lisp ~}~%~T~%" files))
    (LCL:run-program "make" :arguments (list "-f" "Makefile.sccs" "getsccsfiles")))

  (LCL:with-deferred-warnings
   (dolist (file files)
     (load (compile-file file))))
  
  (LCL:cd pwd))









