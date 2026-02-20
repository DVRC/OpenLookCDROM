;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;%W% %G%

;;; Please review the README.build file in this directory; it includes
;;; important details omitted from the following brief summary.

;;; Loading this file recompiles and loads LispView and creates one binary
;;; file, lispview.sbin, that contains all of the compiled LispView files.
;;; This file assumes that the current directory is the root [top-level]
;;; directory for the LispView distribution, i.e. that there are "src",
;;; and "xview" subdirectories.
;;; To make a Lisp image that contains LispView, ensure that the CLOS
;;; module has been loaded, load lispview.sbin, and then disksave.
;;; Most applications should evaluate (CLOS::precompile-generic-functions)
;;; before disksaving.

(in-package "USER")


#-(and lcl4.0 sparc)
(warn "This release of LispView was designed for Sun or Lucid Common Lisp 4.0 for the Sun-4")

#-clos
(error "LispView requires the CLOS submodule")


(defvar *lispview-release* "1.1.20")

    
(defun make-lispview-version (build-directory)
  (let* 
    ((operating-system
      (with-open-file (s "/etc/motd" :if-does-not-exist nil)
	(loop
	 (let* ((line (read-line s nil nil))
		(match 
		 (or (search "SunOS" line) (search "Sun UNIX" line))))
	   (when (or (null line) match)

	     (return line))))))

     (machine-type
      (let* ((hostid
	      (with-open-stream (s (LCL:run-program "hostid" :output :stream :wait nil))
		(read-line s)))
	     (n (parse-integer (or (subseq hostid 0 2) "-1"))))
	(case n 
	 (21 "4/260,280")
	 (22 "4/110")
	 (23 "4/330")
	 (51 "4/60")
	 (t ""))))

     (command-line-args
      (let ((args nil)
	    (i 1))
	(loop
	  (let ((arg (LCL:command-line-argument i)))
	    (if arg
		(push arg args)
	      (return (nreverse args)))
	    (incf i))))))
    (list*
     :release *lispview-release*
     :build-directory build-directory
     :build-started (get-universal-time)
     :lisp-image-name (LCL:lisp-image-name)
     :lisp-command-line-args command-line-args
     :compiler-options (LCL:compiler-options)
     :operating-system operating-system
     :machine-name (machine-instance)
     :machine-type machine-type
     (if (boundp 'LUCID::*clos-repacking-date*)
	 (list :clos-repack LUCID::*clos-repacking-date*)
       nil))))


(LCL:let-globally  
 ((LCL:*record-source-files* nil)
  (LCL:*redefinition-action* nil))
 (let* ((pwd (LCL:pwd))
	(build-dir 
	 (make-pathname :directory (pathname-directory LCL:*load-pathname*)))
	(lispview-version
	 (make-lispview-version build-dir)))
	   
   (cd build-dir)

   ;; Compile and load all of LispView

   (flet ((subdir-load (dir file)
	   (cd dir) 
	   (load file)
	   (cd build-dir)))

     (subdir-load "xview" "build.lisp")
     (subdir-load "src" "build.lisp"))

   (setf (getf lispview-version :build-finished) (get-universal-time))

   ;; Create a file, init.lisp, that when loaded will bind *lispview-version* and
   ;; load all of the foreign interfaces with (load-xview-foreign-interface).

   (when (probe-file "init.lisp")
     (delete-file "init.lisp"))
   (with-open-file (stream "init.lisp" :direction :output)
     (format stream 
	     "(in-package \"USER\")
              (setq LV:*lispview-version* '~S)
	      (let ((pwd (LCL:pwd))
                    (xview-dir 
                      (merge-pathnames 
                        \"lispview/xview/\"
                        (make-pathname 
                          :directory (pathname-directory LCL:*load-pathname*)))))
                (LCL:cd xview-dir)
		(XV:load-xview-foreign-interface)
		(LCL:cd pwd))~%"
	     lispview-version))
   (compile-file "init.lisp")

   ;; Create one big binary file, lispview.sbin, by concatenating the concatenated 
   ;; binaries, called "build-binaries.sbin", from each subdirectory.  Once lispview.sbin
   ;; has been created all of the component binaries are removed.
   ;; Added 27-sep-91:
   ;; Certain (Lisp binary) patch files may be appended also; these
   ;; components are assumed to have been precompiled and are not removed
   ;; afterward.
   ;; color-label-patch fixes an olgx bug; it must load foreign
   ;; code after the foreign loading done by "init".  [This bug exists
   ;; in XView 2.0, but is fixed in Version 3.0; the color-label-patch
   ;; should be removed when LispView is ported to Version 3.0.]

   (let* ((ext (car LCL:*load-binary-pathname-types*))
	  (bin-files (mapcar #'(lambda (file)
				 (format nil "~A.~A" file ext))
			     '("xview/build-binaries"
			       "src/build-binaries"
			       "init")))
	  (pat-files (list (format nil "xview/color-label-patch.~A" ext)))
	  (lispview.bin (format nil "lispview.~A" ext)))
     (when (probe-file lispview.bin)
       (delete-file lispview.bin))
     (LCL:run-program "cat" :arguments (append bin-files pat-files)
		       	    :output lispview.bin)
     (LCL:run-program "rm" :arguments (cons "init.lisp" bin-files)))

   (cd pwd)))







