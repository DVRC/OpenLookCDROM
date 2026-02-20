;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)interface.lisp	3.3 10/11/91



(in-package 'xview :use '(lisp))

(export '(xv-create
	  xv-find
	  event-action/code
	  xv-client-data
	  defcallback 
	  xview-object-rect
	  with-xview-object-rect
	  load-xview-foreign-interface))


;;; The XView functions xv-create and xv-find are defined here so that we
;;; can handle the owner and package arguments specially without introducing another
;;; special case into def-xview-foreign-function.

(LCL:def-compiler-macro xv-create (owner package &rest attributes)
  `(ff-xv-create (or ,owner 0) (xview-package-address ,package) ,@attributes))

(LCL:def-compiler-macro xv-find (owner package &rest attributes)
  `(ff-xv-find (or ,owner 0) (xview-package-address ,package) ,@attributes))


(defun xv-create (owner package &rest attributes)
  (apply #'ff-xv-create (or owner 0) (xview-package-address package) attributes))

(defun xv-find (owner package &rest attributes)
  (apply #'ff-xv-find (or owner 0) (xview-package-address package) attributes))


(defmacro event-action/code (e)
  (let ((event-var (gensym))
	(action-var (gensym)))
    `(let* ((,event-var ,e)
	    (,action-var (event-action ,event-var)))
       (if (= ,action-var ACTION-NULL-EVENT)
	   (event-ie-code ,event-var)
	 ,action-var))))


;;; Special interface for storing lisp objects in the *_CLIENT_DATA slot of
;;; an XVIEW object.  To set client data slot of an XVIEW object use
;;; (setf (xv-client-data object attribute) lisp-value) where attribute must
;;; be one of :menu-client-data, :panel-client-data, :panel-list-client-data,
;;; :textsw-client-data, or :win-client-data.  xv-client-data returns NIL 
;;; of the objects client data slot has not been set.
;;;
;;; The implementation of xv-client-data stores a 1 element stationary vector 
;;; in the objects client data slot, the lisp value is store in this vector.

(defun xv-client-data (object attribute &optional (arg 0))
  (check-type attribute client-data-attribute)
  (let ((a (ff-xv-get-client-data object (translate-attribute-keyword attribute) arg)))
    (if (and (typep a '(array T (1))) (LCL:stationary-object-p a))
	(svref a 0))))

(defun set-xv-client-data (object attribute value arg)
  (check-type attribute client-data-attribute)
  (check-type arg (or null integer))
  (let* ((attr (translate-attribute-keyword attribute))
	 (a (ff-xv-get-client-data object attr (or arg 0))))
    (if (and (typep a '(array T (1))) (LCL:stationary-object-p a))
	(setf (svref a 0) value)
      (let ((a (with-static-area (make-array 1 :initial-contents (list value)))))
	(if arg
	    (ff-xv-set-client-data2 object attr arg a)
	  (ff-xv-set-client-data1 object attr a)))))
  value)
	
(defsetf xv-client-data (object attribute &optional arg) (value)
  `(set-xv-client-data ,object ,attribute ,value ,arg))
  
  

;;; Defines a foreign callable function.  The syntax is the same as def-foreign-callable
;;; except an additional "name-and-options" option, :abort-value, is supported.  The :abort-value
;;; option must be used for callbacks whose return value is important.  If an abort-value is
;;; specified then the value of the function body will be returned from the callback
;;; unless the application tries to make a non-local exit.  Non-local exits are
;;; caught by an unwind-protect and the function is forced to return :abort-value.
;;; If :abort-value is not specified then the callback always returns 0; non-local
;;; exit or not.

(defmacro defcallback (name-and-options (&rest args) &body body &environment env)
   (let* ((abort-value (if (consp name-and-options)
			   (assoc :abort-value (cdr name-and-options))))
	  (name-and-options (if abort-value
				(cons (car name-and-options)
				      (remove :abort-value (cdr name-and-options) :key #'car))
			      name-and-options))
	  (callback-block (gensym))
	  (returned-p (gensym)))
     (multiple-value-bind (body declarations doc-string)
	 (LCL:parse-body body env)
       `(def-foreign-callable ,name-and-options (,@args)
	  ,@(if doc-string `(,doc-string) nil)
	  ,@declarations
	  (let ((,returned-p nil))
	    (block ,callback-block
	       (unwind-protect
		   (prog1
		       (progn (with-xview-lock ,@body) ,@(if abort-value nil `(0)))
		     (setq ,returned-p t))
		 (unless ,returned-p 
		   (return-from ,callback-block ,(if abort-value 
						     (cadr abort-value) 
						   0))))))))))


;;;; Signal Handling

#|

(def-foreign-function ndet-signal-catcher signal code sigcontext)
   
(defun lisp-ndet-signal-catcher (signal code)
  (declare (ignore code))
  (SYS:with-all-signals-blocked (ndet-signal-catcher signal 0 0)))

(defvar *signal-handlers* (make-array 32 :initial-element :default))

(def-foreign-callable (lisp-ndet-enable-sig (:return-type :fixnum))
                      ((signal :fixnum))
   (setf (svref *signal-handlers* signal) (SYS:get-lisp-interrupt-handler signal))
   (SYS:setup-interrupt-handler signal 'lisp-ndet-signal-catcher) 
   0)

(def-foreign-callable (lisp-ndet-disable-sig (:return-type :fixnum))
		      ((signal :fixnum))
   (unless (eq (SYS:get-lisp-interrupt-handler signal) 'lisp-ndet-signal-catcher)
     (warn "Unexpected signal handler for signal ~S" signal))
   (SYS:setup-interrupt-handler signal (svref *signal-handlers* signal))
   0)

|#



(defun xview-object-rect (object &optional copy)
  (let ((rect (FFI:make-foreign-pointer 
	         :address (XV:with-xview-lock (XV:xv-get object :xv-rect))
		 :type '(:pointer XV:rect))))
    (if copy
	(let ((rect-copy (FFI:malloc-foreign-pointer :type '(:pointer XV:rect))))
	  (setf (XV:rect-r-left rect-copy) (XV:rect-r-left rect) 
		(XV:rect-r-top rect-copy) (XV:rect-r-top rect)
		(XV:rect-r-width rect-copy) (XV:rect-r-width rect) 
		(XV:rect-r-height rect-copy) (XV:rect-r-height rect))
	  rect-copy)
      rect)))


(defmacro with-xview-object-rect ((object rect &optional copy) &body body)
  (let ((copy-var (gensym)))
    `(let* ((,copy-var ,copy)
	    (,rect (xview-object-rect ,object ,copy-var)))
       (unwind-protect 
	   ,@body
	 (if ,copy-var
	     (FFI:free-foreign-pointer ,rect))))))
	 


(defun load-xview-foreign-interface ()
  (let* ((arch #+sparc "sun4" #+mc68000 "sun3")
	 (libraries 
	  (list (format nil "libxview.~A.a" arch) 
		(format nil "libolgx.~A.a" arch) 
		(format nil "libxloadimage.~A.a" arch)
		(format nil "libX11.~A.a" arch) 
		"-lm" 
		"-lc")))
    (format t ";;; Loading libraries ~{~A ~}...~%" libraries)
    (load-foreign-files (list (format nil "macros.~A.o" arch)) libraries)
    (load-foreign-libraries (mapcar #'cdr (append *xview-globals* *xview-packages*)) libraries))

  (dolist (x *xview-globals*)
    (set (car x) (FFI:make-foreign-pointer 
		   :address (FFI:foreign-variable-address (cdr x))
		   :type '(:pointer :unsigned-32bit)
		   :static t)))

  (dolist (x *xview-packages*)
    (setf (get (car x) 'package-address)
	  (make-foreign-pointer 
	   :address (foreign-variable-address (cdr x))
	   :static t))))



