;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)tty.lisp	1.2 10/21/91

(in-package "LISPVIEW")


;;; The macros belwo define the following accessors:
;;;
;;; tty-left-margin accessor
;;; tty-right-margin accessor
;;; tty-bottom-margin accessor
;;; tty-top-margin accessor
;;; tty-margin accessor
;;; tty-rows accessor
;;; tty-columns accessor
;;; tty-font accessor
;;; tty-console writer
;;; tty-page-mode accessor
;;; tty-pid accessor
;;; tty-quit-on-child-death writer
;;; tty-tty-fd reader

(macrolet
 ((def-accessor (name type supports-get supports-set)
    (let ((driver (intern (format nil "DD-~A" name)))
	  (type (if (eq type 'boolean) t type)))
      (cond
       ((and supports-get supports-set)
	`(def-solo-accessor ,name tty-window :type ,type :driver ,driver))
       (supports-get
	`(def-solo-reader ,name tty-window :type ,type :driver ,driver))
       (supports-set 
	`(def-solo-writer ,name tty-window :type ,type :driver ,driver)))))

  (def-accessors ()
    `(progn
       ,@(mapcan #'(lambda (entry)
		     (let* ((get (xview-tty-attribute-proc-p entry :get))
			    (set (xview-tty-attribute-proc-p entry :set)))
		       (when (or get set)
			 `((def-accessor ,(car entry) ,(cadr entry) ,get ,set)))))
		 xview-tty-attributes))))

 (def-accessors))
		 

(defmethod tty-input ((x tty-window) string)
  (check-arglist (string string))
  (dd-tty-input (platform x) x string))

(defmethod tty-output ((x tty-window) string)
  (check-arglist (string string))
  (dd-tty-output (platform x) x string))


#+ignore
(defun print-tty-interface-table ()
  (let* ((entries 
	  (append
	   '(("LispView Attribute" "XView Attribute" "Type" ("Usage"))
	     ("------------------" "---------------" "----" ("-----")))
	   (mapcar #'(lambda (x)
		       (list 
			 (string-downcase (car x))
			 (substitute #\_ #\- (string (xview-tty-attribute x)))
			 (string-downcase (prin1-to-string (xview-tty-attribute-type x)))
			 (let ((get (xview-tty-attribute-proc-p x :get))
			       (set (xview-tty-attribute-proc-p x :set)))
			   (append 
			    (if (xview-tty-attribute-proc-p x :create) 
				(if (or get set) '("initarg,") '("initarg")))
			    (cond 
			     ((and get set) '("accessor"))
			     (get '("reader"))
			     (set '("writer")))))))
		   xview-tty-attributes)))

	 (format-string
	  (format nil "~~~DA   ~~~DA   ~~~DA  ~~{ ~~A~~}~%"
		  (apply #'max (mapcar #'length (mapcar #'car entries)))
		  (apply #'max (mapcar #'length (mapcar #'cadr entries)))
		  (apply #'max (mapcar #'length (mapcar #'caddr entries))))))

    (dolist (x entries)
      (apply #'format t format-string x))))



