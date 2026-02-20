;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)build.lisp	3.10 10/25/91


;;; Loading this file recompiles and loads LispView, and then creates one
;;; file, build-binaries.sbin, which is all of the binaries
;;; concatenated in order.  Subsequently the individual binary files are
;;; removed.
;;; 
;;; This file assumes that the Lisp image contains CLOS, the XView
;;; interface, and all relevant patches.  It also assumes that the current
;;; directory contains all of the files we need.
;;;
;;; Normally this file is not used directly, but via the build.lisp file
;;; in the top-level directory of the LispView source distribution.
;;; [In particular that top-level build.lisp uses "xview/build.lisp"
;;; to compile and load the XView interface before loading the present
;;; file.]

(in-package :USER) 

(let ((files
       '("package"
	 "debug"
	 "defs"
	 "region"
	 "platforms"
	 "display"
	 "input"
	 "canvas"
	 "cursor"
	 "font"
	 "output"
	 "image"
	 "color"
	 "item"
	 "menu"
	 "scroll"
	 "xview-defs"
	 "rdb"
	 "print-object"
	 "xview-display"
	 "xview-canvas"
	 "xview-cursor"
	 "xview-color"
	 "xview-image"
	 "xview-font"
	 "xview-output"
	 "xview-input"
	 "xview-item"
	 "xview-menu"
	 "xview-scroll"
	 "version")))

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
                    (pushnew :lispview *features*)~%"))
  (compile-file "init.lisp")

  (let* ((ext (car LCL:*load-binary-pathname-types*))
	 (bin-files (mapcar #'(lambda (file)
				(format nil "~A.~A" file ext))
			    (append files '("init"))))
	 (build-binaries.bin (format nil "build-binaries.~A" ext)))
    (when (probe-file build-binaries.bin)
      (delete-file build-binaries.bin))
    (LCL:run-program "cat" 
      :arguments bin-files
      :output build-binaries.bin)
    (LCL:run-program "rm" :arguments bin-files)))

(pushnew :lispview *features*)


  






