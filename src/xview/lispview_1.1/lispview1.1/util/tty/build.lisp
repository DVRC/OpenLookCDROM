;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)build.lisp	1.3 10/21/91


;;; Loading this file recompiles and reloads the tty interface
;;; 
;;; This file assumes that the initial lisp image contains LispView

(in-package :USER) 

#-lispview
(error "This file can only be loaded into an image that has LispView")

(let ((pwd (LCL:pwd))
      (build-dir 
       (make-pathname :directory (pathname-directory LCL:*load-pathname*)))
      (files
       '("notifier"
	 "tty-defs"
	 "tty"
	 "xview-tty")))

  (LCL:cd build-dir)

  (when (probe-file "SCCS")
    (when (probe-file "Makefile.sccs")
      (delete-file "Makefile.sccs"))
    (with-open-file (stream "Makefile.sccs" :direction :output)
      (format stream "getsccsfiles: ~{~A.lisp ~}~%~T~%" files))
    (LCL:run-program "make" :arguments (list "-f" "Makefile.sccs" "getsccsfiles")))

  (when (and (boundp 'LV:*default-display*) 
	     (typep LV:*default-display* 'LV:display)
	     (not (fboundp 'LV::xview-notifier-fds)))
    (warn "LispView tty package being loaded too late: notifier already started"))

  (LCL:with-deferred-warnings
   (dolist (file files)
     (load (load file :if-source-only :compile :if-source-newer :compile))))

  (LCL:cd pwd))









