;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)xview-tty.lisp	1.3 10/21/91


(in-package "LISPVIEW")


(defstruct (XVIEW-TTY-WINDOW (:include xview-window))
  pty-fd)


;;; Given a sequence of strings create a foreign vector of pointers to strings.

(defun make-tty-argv (s) 
  (unless (and (typep s 'sequence) (every #'stringp s))
    (error "the value of argv should be a sequence of strings"))
  (let* ((n (length s))
	 (v (malloc-foreign-pointer 
	     :type `(:pointer (:array (:pointer :character) (,(1+ n)))))))
    (dotimes (i n v)
      (setf (foreign-aref v i) (malloc-foreign-string (elt s i))))
    (setf (foreign-aref v n) (make-null-foreign-pointer :character))))


(defun free-tty-argv (v)
  (let ((i 0))
    (loop
     (let ((fp (foreign-aref v i)))
       (cond 
	((not (typep fp 'foreign-pointer)) (return))
	((= 0 (foreign-pointer-address fp)) (return (free-foreign-pointer fp)))
	(t (free-foreign-pointer fp))))
     (incf i))))


(defmethod dd-initialize-canvas ((p XView) (w tty-window) &rest initargs)
  (declare (dynamic-extent initargs))
  (xview-initialize-canvas w #'make-xview-tty-window initargs))

(macrolet
 ((def-realize-xview-tty ()
    (let* ((create-attributes 
	    (mapcan #'(lambda (entry)
			(when (xview-tty-attribute-proc-p entry :create)
			  (list entry)))
		    xview-tty-attributes))
	   (initargs
	    (mapcar #'(lambda (entry)
			(intern (string (tty-accessor-initarg entry))))
		    create-attributes))

	   (key-arglist
	    (mapcar #'(lambda (initarg)
			(list initarg nil (intern (format nil "~A-P" initarg))))
		    initargs))

	   (xview-attr-initforms
	    (mapcar #'(lambda (initarg entry)
			(let ((initarg-p 
			       (intern (format nil "~A-P" initarg)))
			      (xview-attr 
			       (xview-tty-attribute entry))
			      (type
			       (xview-tty-attribute-type entry)))
			  `(if ,initarg-p
			       ,(cond
				 ((subtypep type 'argv-sequence)
				  `(let ((argv (make-tty-argv ,initarg)))
				     (push argv argvs)
				     (list ,xview-attr argv)))
				 ((subtypep type 'display-device-status)
				  `(let ((id (xview-object-id (device ,initarg))))
				     (if id (list ,xview-attr id))))
				 ((or (eq type 'boolean) (subtypep type 'integer))
				  `(list ,xview-attr ,initarg))))))
		    initargs
		    create-attributes)))

      `(defun REALIZE-XVIEW-TTY (w xvo al &key ,@key-arglist &allow-other-keys)
	 (let ((argvs nil))
	   (prog1
	       (apply #'realize-xview-canvas w xvo al (nconc ,@xview-attr-initforms))
	     (map nil #'free-tty-argv argvs)))))))

  (def-realize-xview-tty))


(defmethod dd-realize-canvas ((p xview) (w tty-window))
  (XV:with-xview-lock 
    (let* ((xvo (device w))
	   (initargs 
	    (prog1
		(xview-object-initargs xvo)
	      (setf (xview-object-initargs xvo) nil))))

      (using-resource (al xview-attr-list-resource (xview-canvas-owner w) :tty)
	(apply-xview-opaque-canvas-inits w xvo al initargs)
	(apply #'init-xview-window w xvo al initargs)
	(apply #'realize-xview-tty w xvo al initargs))
      (push (setf (xview-tty-window-pty-fd xvo) (XV:xv-get (xview-object-id xvo) :tty-pty-fd))
	    (xview-notifier-fds)))))


(defmethod dd-destroy-canvas ((p XView) (w tty-window))
  (XV:with-xview-lock 
    (let ((fd (xview-tty-window-pty-fd (device w))))
      (call-next-method)
      (when fd
	(setf (xview-notifier-fds) (delete fd (xview-notifier-fds) :test #'=))))))




(defmethod dd-tty-input ((p XView) w string)
  (XV:with-xview-lock 
    (let* ((xvo (device w))
	   (id (xview-object-id xvo)))
      (when id
	(let ((buf (malloc-foreign-string string)))
	  (XV:ttysw-input id buf (length string))
	  (free-foreign-pointer buf))))))


(defmethod dd-tty-output ((p XView) w string)
  (XV:with-xview-lock 
    (let* ((xvo (device w))
	   (id (xview-object-id xvo)))
      (when id
	(let ((buf (malloc-foreign-string string)))
	  (XV:ttysw-output id buf (length string))
	  (free-foreign-pointer buf))))))



(defmethod dd-tty-font ((p XView) w)
  (XV:with-xview-lock 
    (let* ((xvo (device w))
	   (id (xview-object-id xvo)))
      (if id
	  (xview-id-to-font (XV:xv-get id :xv-font) (display w))
	(getf (xview-canvas-initargs xvo) :font)))))


(defmethod (setf dd-tty-font) (font (p XView) w)
  (XV:with-xview-lock 
    (let* ((xvo (device w))
	   (w-id (xview-object-id xvo))
	   (font-id (xview-object-id (device font))))
      (if w-id
	  (when font-id 
	    (XV:xv-set w-id :xv-font font-id))
	(setf (getf (xview-canvas-initargs xvo) :font) font)))))

	      

;;; The macros below define the following driver methods:
;;;
;;; dd-tty-left-margin accessor
;;; dd-tty-right-margin accessor
;;; dd-tty-bottom-margin accessor
;;; dd-tty-top-margin accessor
;;; dd-tty-margin accessor
;;; dd-tty-rows accessor
;;; dd-tty-columns accessor
;;; dd-tty-console writer
;;; dd-tty-page-mode accessor
;;; dd-tty-pid accessor
;;; dd-tty-quit-on-child-death writer
;;; dd-tty-tty-fd reader
;;;
;;; Each of these gets/sets the integer or boolean XView ttysw attribute whose
;;; name is the same - modulo the dd-tty prefix.  

(macrolet
 ((def-accessor (entry type supports-get supports-set)
    (let ((driver (intern (format nil "DD-~A" (car entry))))
	  (attr (xview-tty-attribute entry))
	  (initarg (tty-accessor-initarg entry)))
      (cond
       ((and supports-get supports-set)
	`(def-xview-initarg-accessor ,driver ,attr ,initarg :type ,type))
       (supports-get
	`(def-xview-initarg-reader ,driver ,attr ,initarg :type ,type))
       (supports-set 
	`(def-xview-initarg-writer ,driver ,attr ,initarg :type ,type)))))

  (def-accessors ()
    `(progn
       ,@(mapcan #'(lambda (entry)
		     (let ((type (xview-tty-attribute-type entry))
			   (get (xview-tty-attribute-proc-p entry :get))
			   (set (xview-tty-attribute-proc-p entry :set)))
		       (when (and (or (eq type 'boolean)
				      (subtypep type 'integer))
				  (or get set))
			 `((def-accessor ,entry ,type ,get ,set)))))
		 xview-tty-attributes))))

 (def-accessors))

