;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)version.lisp	1.9 10/11/91

(in-package "LISPVIEW")


;;; The value of this variable is a plist that documents a good deal about
;;; the version of LispView you're running.  It's bound in the file ../init.lisp 
;; which is created during the build by build.lisp.  

(defvar *lispview-version*)  

     
(defmacro def-lispview-patch (name &body body)
  (flet 
   ((patch-exists-p ()
      (and (boundp '*lispview-version*)
	   (find-if #'(lambda (change)
			(string-equal (getf change :name) name))
		    (getf *lispview-version* :changes)))))

   (if (patch-exists-p)
       (warn "Patch ~S is obsolete, LispView already contains comparable changes")
     `(progn ,@body))))


(defun print-lispview-version ()
  (labels
   ((glv (keyword)  
      (getf *lispview-version* keyword))

    (time-string (x)
      (multiple-value-bind (i1 minute hour)
	  (decode-universal-time x)
	(declare (ignore i1))
	(format nil "~D:~D ~A"
		(if (<= hour 12) hour (mod hour 12))
		minute
		(cond ((< hour 12) "AM") ((= hour 12) "Noon") (t "PM")))))

    (date-string (x)
      (multiple-value-bind (i1 i2 i3 date month year)
	  (decode-universal-time x)
	(declare (ignore i1 i2 i3))
	(format nil "~D/~D/~D" month date (mod year 100))))


    (time-difference (x1 x2)
      (multiple-value-bind (i0 m1 h1 d1)
	  (decode-universal-time x1)
	(declare (ignore i0))
	(multiple-value-bind (i1 m2 h2 d2)
	    (decode-universal-time x2)
	  (declare (ignore i1))
	  (truncate (- (+ m2 (* 60 (if (> d2 d1) (+ 24 h2) h2)))
		       (+ m1 (* 60 h1)))
		    60))))

    (print-duration (operation start finish)
      (let ((start (glv start))
	    (finish (glv finish)))
	(if (and start finish)
	    (format t ";;; ~A started at ~A on ~A, finished at ~A, (~A)~%"
		      operation 
		      (time-string start)
		      (date-string start)
		      (time-string finish)
		      (multiple-value-bind (hours minutes)
			  (time-difference start finish)
			(if (= hours 0)
			    (format nil "~D minute~:P" minutes)
			  (format nil "~D hour~:P, ~D minute~:P" hours minutes))))
	  (format t ";;; Incomplete start/finish time information for ~A~%" operation)))))

      
   (format t ";;; LispView Version ~A~%" (glv :release))
   (format t ";;; Built with ~A~%" (glv :lisp-image-name))
   (print-duration "Build" :build-started :build-finished)
   (when (glv :disksave-started)
     (let ((start (glv :disksave-started)))
       (format t ";;; Disksave start at ~A on ~A~%" (time-string start) (date-string start))))
   (format t ";;; Host ~S a ~A, ~A~%" 
	   (glv :machine-name) 
	   (glv :machine-type)
	   (glv :operating-system))

   (let ((changes (glv :changes)))
     (when changes
       (format t ";;;~%;;; This version of LispView incorporates the following changes: ~%")
       (dolist (change changes)
	 (format t ";;;~%;;; - ~S, first appeared in ~A, ~A~%" 
		 (getf change :name) 
		 (getf change :lispview-version)
		 (getf change :date))
	 (let* ((l nil)
		(desc (getf change :description)))
	   (when desc
	     (loop
	      (let* ((nl (position #\newline desc))
		     (s (subseq desc 0 (or nl (length desc)))))
		(push (format nil ";;;   ~A~%" s) l)
		(if nl 
		    (setf desc (string-left-trim '(#\space #\tab #\newline)
						 (subseq desc nl)))
		  (return))))
	     (princ (apply #'concatenate 'string (nreverse l))))))))))


