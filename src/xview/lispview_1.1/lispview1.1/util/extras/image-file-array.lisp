;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;; Here is a small utility to convert icon files to arrays.
;;; There may be some advantage in not having to track separate files
;;; containing icons, but the performance hit is not currently known.
;;; 
;;; The example below converts two icon files (one x-bitmap and one Sun icon)
;;; into a lisp array and saves the result in a "newfile.lisp"
;;; 
;;; > (convert '("foo.xbm" "bar.icon") "newfile.lisp")
;;; 

(in-package :user)

(defun convert (icon-filenames save-filename)
  (let ((*print-array* t) outfile)
    (with-open-file (outfile save-filename :direction :output)
      (format outfile "(in-package ~A)~%~%" (package-name *package*))
      (mapcar #'(lambda(f)
		  (format outfile "(defparameter *~A*~%~A)~%~%" f
			  (lv:image-array 
			   (make-instance 'lv:image :filename f)))
		  (format t "*~A* " f))
	      icon-filenames)
      save-filename)
    ))

