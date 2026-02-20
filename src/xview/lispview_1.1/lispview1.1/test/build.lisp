;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

(in-package :USER)


(let ((build-dir 
       (make-pathname :directory (pathname-directory  *load-pathname*)))
      (pwd (pwd))
      (files 
       '("package"
	 "defs"
	 "basic"
	 "bugs"
	 "image-array"
	 "keyboard-focus"
	 "colors"
	 "click")))

  (unwind-protect
      (progn 
       (cd build-dir)

       (when (probe-file "SCCS")
	 (when (probe-file "Makefile.sccs")
	   (delete-file "Makefile.sccs"))
	 (with-open-file (stream "Makefile.sccs" :direction :output)
	   (format stream "getsccsfiles: ~{~A.lisp ~}~%~T~%" files))
	 (run-program "make" :arguments (list "-f" "Makefile.sccs" "getsccsfiles")))

       (with-deferred-warnings
	(dolist (file files)
	  (load file :if-source-only :compile :if-source-newer :compile))))

    (cd pwd)))



