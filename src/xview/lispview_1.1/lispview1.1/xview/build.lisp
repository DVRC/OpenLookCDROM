;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)build.lisp	2.1 6/13/90


;;; Loading this file recompiles and loads the XView and Xlib interfaces,
;;; and then creates one file, build-binaries.sbin, which is all of
;;; the binaries concatenated in a specified order.  Subsequently
;;; the individual binary files are removed.
;;; 
;;; This file assumes that the initial Lisp image contains CLOS and all
;;; relevant patches.  It also assumes that the current directory contains
;;; all of the files we need.
;;;
;;; Normally this file is not used directly, but via the build.lisp file
;;; in the top-level directory of the LispView source distribution.

(in-package :USER) 

(let ((files
       '("ffi"
	 "mp"
	 ;; "ffi-def"     ;; don't load this to get the complete Xlib and XView foreign interfaces
	 "xlib"
	 "x11-keysym"
	 "xloadimage"
	 "xview"
	 "globals"
	 "attributes"
	 "types"
	 "functions"
	 "interface")))

  (LCL:run-program "make")

  (when (probe-file "SCCS")
    (when (probe-file "Makefile.sccs")
      (delete-file "Makefile.sccs"))
    (with-open-file (stream "Makefile.sccs" :direction :output)
      (format stream "getsccsfiles: ~{~A.lisp ~}~%~T~%" files))
    (LCL:run-program "make" :arguments (list "-f" "Makefile.sccs" "getsccsfiles")))

  (LCL:with-deferred-warnings
   (dolist (file files)
     (load (compile-file file))))

  (when (probe-file "init.lisp")
    (delete-file "init.lisp"))
  (with-open-file (stream "init.lisp" :direction :output)
		  (format stream "(in-package :USER) 
                    (pushnew :x11 *features*)
                    (pushnew :xview *features*)~%"))
  (compile-file "init.lisp")

  (let* ((ext (car LCL:*load-binary-pathname-types*))
	 (bin-files (mapcar #'(lambda (file)
				(format nil "~A.~A" file ext))
			    (append files '("init"))))
	 (build-binaries.bin (format nil "build-binaries.~A" ext)))
    (when (probe-file build-binaries.bin)
      (LCL:run-program "rm" :arguments (list build-binaries.bin)))
    (LCL:run-program "cat" 
      :arguments bin-files
      :output build-binaries.bin)
    (LCL:run-program "rm" :arguments (cons "init.lisp" bin-files))))

(pushnew :x11 *features*)
(pushnew :xview *features*)








