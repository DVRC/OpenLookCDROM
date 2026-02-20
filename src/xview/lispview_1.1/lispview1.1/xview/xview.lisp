;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)xview.lisp	3.9 10/11/91



(in-package "XVIEW" :nicknames '("XV") :use '("LISP" "FFI" "MP"))

(export '(enum-case
	  keyword-enum
	  with-xview-lock
	  xview-package-address))

;;; Macros and defining forms that the rest of the XView interface is based on.

(defun translate-attribute-keyword (attr)
  (let ((n (get attr 'attribute-value)))
    (if (integerp n)
	n
      (error "Unrecognized attribute ~S" attr))))


;;; Boolean attributes can be 0, 1, nil or (not (member 0 1 nil)).  nil and 0 
;;; get mapped to FALSE (that's 0), the others are mapped to TRUE (that's 1).

(defun translate-boolean-attribute (attr value)
  (declare (ignore attr))
  (if value
      (progn
	#+ignore
	(when (or (eql value 1) (eql value 0))
	  (warn "Attribute ~S paired with ~S, use T or NIL instead" attr value))
	(if (eql value 0) 0 1))
    0))



;;; Similar to the case macro except that the keylist parts of the clauses must
;;; be keywords that represent XView attributes.

(defmacro enum-case (value &rest clauses)
  `(case ,value 
     ,@(mapcar #'(lambda (clause)
		   (if (eq (car clause) t)
		       clause
		     (let ((key (if (consp (car clause))
				    (mapcar #'translate-attribute-keyword (car clause))
				  (list (translate-attribute-keyword (car clause))))))
		       (if (every #'numberp key)
			   (cons key (cdr clause))
			 (error "Unrecognized keyword in enum-case ~S" (car clause))))))
	       clauses)))


;;; Convert an a keyword that represents an enumerated type into the corresponding C 
;;; integer value.  

(defmacro keyword-enum (keyword)
  (if (keywordp keyword)
      (translate-attribute-keyword keyword)
    `(translate-attribute-keyword ,keyword)))



;;; Translate the value of a list attribute, e.g. :menu-strings, into
;;; a list of objects that can be passed to C.  At minimum this function
;;; makes a copy of value (which must be a list).  The elements of the list
;;; are transformed if the attribute keywords attribute-type property specifies
;;; that some of the list elements are strings, callbacks, or attributes.
;;; To improve performance a little we handle a few special cases: none of
;;; the list elements need to be transformed (so just copy it), the list may
;;; only contain strings (so transform each string to a foreign string).
;;;
;;; The type of a list valued attribute, stored under the 'attribute-type
;;; property is a list of types.  If the attributes value is a fixed length
;;; list then the type list will have the same length as the value list; 
;;; if the attributes value is an arbitrary length list then the type list
;;; is treated like a template that gets repeated as many times as neccessary.
;;; For example the type list for a fixed length list valued attribute 
;;; like :win-mouse-xy  is (int int), the type list for an arbitrary length
;;; list valued attribute like :panel-strings is (string).  The type of a list 
;;; valued attribute that was supposed to be alternating integers and strings
;;; would be (int string).

(defun translate-list-attribute-value (attr value)
  (check-type value list)
  (let ((type (get attr 'attribute-type)))
    (cond
     ((null type) 
      (error "Unrecognized list valued attribute ~S" attr))
     ((notany #'(lambda (element-type) 
		  (member element-type '(string callback attribute boolean) :test #'eq))
	      type)
      (copy-list value))
     ((every #'(lambda (element-type) 
		 (eq element-type 'string)) 
	     type)
      (mapcar #'(lambda (s) (maybe-malloc-foreign-string attr s)) value))
     (t
      (let ((translated-value nil))
	(do ((element-type-cdr type (if (null (cdr element-type-cdr))
					type
				      (cdr element-type-cdr)))
	     (value-cdr value (cdr value-cdr)))
	    ((null value-cdr) (nreverse translated-value))
	  (push (case (car element-type-cdr)
		   (string
		    (maybe-malloc-foreign-string attr (car value-cdr)))
		   (callback 
		    (lookup-callback-address (car value-cdr)))
		   (attribute
		    (translate-attribute-keyword (car value-cdr)))
		   (boolean
		    (translate-boolean-attribute attr (car value-cdr)))
		   (t
		    (car value-cdr)))
		translated-value)))))))
	    
	    

;;; Return a form that will yield the attributes value when evaluated.

(defun translate-attribute-value-later (attr value)
  (typecase attr
     (callback-attribute
      (list 'lookup-callback-address value))
     (list-attribute 
      (let ((length (get attr 'list-attribute-length)))
	(if length
	    (list 'translate-list-attribute-value attr value)
	  (list 'nconc (list 'translate-list-attribute-value attr value) 
		       '(list 0)))))
     (avlist-attribute
      (list 'eval (list 'list* ''list (list 'expand-attribute-value-list value))))
     (string-attribute
      (list 'maybe-malloc-foreign-string attr value))
     (attribute-attribute
      (list 'translate-attribute-keyword value))
     (boolean-attribute
      (cond
       ((or (eq value T) (keywordp value)) 1)
       ((eq value NIL) 0)
       (t (list 'translate-boolean-attribute attr value))))
     (t
      value)))


;;; Return value as a list.

(defun translate-attribute-value-now (attr value)
  (typecase attr
     (callback-attribute
      (list (lookup-callback-address value)))
     (list-attribute 
      (let ((length (get attr 'list-attribute-length)))
	(if length
	    (if (/= (length value) (length length))
		(error "List value, ~S for attribute ~S should be ~S"
		       value
		       attr
		       length)
	      (translate-list-attribute-value attr value))
	  (nconc (translate-list-attribute-value attr value) (list 0)))))
     (avlist-attribute
      (expand-attribute-value-list value))
     (string-attribute
      (list (maybe-malloc-foreign-string attr value)))
     (attribute-attribute
      (list (translate-attribute-keyword value)))
     (boolean-attribute
      (list (translate-boolean-attribute attr value)))
     (t
      (list value))))


(defun expand-attribute-value-pair (attr value)
  (if (keywordp attr) 
      (if (typep attr 'flag-attribute)
	  (list (list 'if value (translate-attribute-keyword attr)))
	(list (translate-attribute-keyword attr) 
	      (translate-attribute-value-later attr value)))
    (let ((attr-var (gensym)))
      `(let ((,attr-var ,attr))
	 (if (typep ,attr-var 'flag-attribute)
	     (list (list 'if ,value (translate-attribute-keyword ,attr-var)))
	   (list* (translate-attribute-keyword ,attr-var)
		  (translate-attribute-value-now ,attr-var ,value)))))))


(defun expand-attribute-value-pair-now (attr value)
  (if (typep attr 'flag-attribute)
      (if value
	  (list (translate-attribute-keyword attr)))
    (list* (translate-attribute-keyword attr) 
	   (translate-attribute-value-now attr value))))




;;; EXPAND-ATTRIBUTE-VALUE-LIST
;;;
;;; The simple case is a keyword value list where the keywords represent XView
;;; attributes that have single values (i.e. NOT something like :panel-choice-strings).
;;; Given a keyword value list like:
;;;
;;;   (:canvas-width 10 :canvas-height 20)
;;;
;;; return a C attribute value list with a terminating 0
;;;
;;;   (1275398209 10 1275725953 20 0)
;;;
;;; The keywords are replaced by the values of the C enumeration constants 
;;; CANVAS_WIDTH and CANVAS_HEIGHT, these values are stored on the keywords plist
;;; under 'attribute-value (see make-xview-attribute). 
;;;
;;; If the keyword value list contains list valued attrributes like 
;;; :panel-choice-strings we return a form that, when evaluated, will create
;;; the appropriate C argument list.  For example given:
;;;
;;;  (:canvas-width 10 :panel-choice-xs '(1 2 3) :canvas-height 20)
;;; 
;;; return a form that yields a C attribute value list with the list embedded 
;;; and terminated by a 0:
;;;
;;;  ((nconc (list 1275398209 10) (list* 1093175361 '(1 2 3 0)) (list 1275725953 20) (list 0)))
;;;
;;; If a variable (not a literal keyword) appears in a keywords position it is replaced 
;;; by an expression that computes the value of the keyword at runtime 
;;; (see translate-attribute-keyword).  In this case we must assume that the variable will
;;; evaluate to a list valued attribute.  For example given:
;;;
;;;  (panel-choice-xs (1 2 3))
;;;
;;; return a form that yields a C attribute value list:
;;;
;;;  ((nconc (let ((attr-keyword panel-choice-xs))
;;;            (list* (translate-attribute-keyword attr-keyword)
;;;                   (translate-attribute-value attr-keyword '(1 2 3))))))
;;;
;;; BUGS
;;; - Not checking for the attribute list length limit of 250 (see ATTR_STANDARD_SIZE in 
;;;  <xview/attr.h>)

(defun expand-attribute-value-list (avlist)
  (unless (evenp (length avlist))
    (error "uneven attribute value list ~S" avlist))
  (if (do ((attr-cdr avlist (cddr attr-cdr)))
	  ((null attr-cdr) nil)
	(when (or (typep (car attr-cdr) '(or multiple-valued-attribute
					     flag-attribute))
		  (not (keywordp (car attr-cdr))))
	  (return t)))

      ;; General case
      (let ((expanded-avlist nil)
	    (sub-avlist nil))
	(do ((attr-cdr avlist (cddr attr-cdr))
	     (value-cdr (cdr avlist) (cddr value-cdr)))
	    ((null value-cdr) 
	     (values (list (cons 'nconc (append (nreverse expanded-avlist) 
						(list '(list 0)))))
		     'apply))
	  (let ((attr (car attr-cdr))
		(value (car value-cdr)))
	    (setq sub-avlist (nconc sub-avlist (expand-attribute-value-pair attr value)))
	    (when (or (null (cdr value-cdr))
		      (typep attr 'multiple-valued-attribute)
		      (not (keywordp attr)))
	      (if (keywordp attr)
		  (push (cons (if (typep attr 'multiple-valued-attribute) 'list* 'list)
			      sub-avlist)
			expanded-avlist)
		(push sub-avlist expanded-avlist))
	      (setq sub-avlist nil)))))
    
    ;; Simple case
    (let ((expanded-avlist nil))
      (do ((attr-cdr avlist (cddr attr-cdr))
	   (value-cdr (cdr avlist) (cddr value-cdr)))
	  ((null value-cdr) 
	   (values (nconc expanded-avlist (list 0)) 'funcall))
	(setq expanded-avlist 
	      (nconc expanded-avlist 
		     (expand-attribute-value-pair (car attr-cdr) (car value-cdr))))))))


;;; Translate the attribute-value-list to a C argument list.  This is equivalent but
;;; more efficient than using expand-attribute-value-list to generate an expression
;;; that will yield the argument list and then eval'ing that.

(defun translate-attribute-value-list (avlist)
  (unless (evenp (length avlist))
    (error "uneven attribute value list ~S" avlist))
  (let ((translated-avlist nil))
    (do ((attr-cdr avlist (cddr attr-cdr))
	 (value-cdr (cdr avlist) (cddr value-cdr)))
	((null value-cdr) 
	 (apply #'nconc (nreverse (nconc (list (list 0)) translated-avlist))))
      (push (expand-attribute-value-pair-now (car attr-cdr) (car value-cdr))
	    translated-avlist))))



;;; Given a foreign function arglist return a form that when evaluated will return an 
;;; arglist where attribute arguments have been replaced by (translate-attribute-keyword arg).  
;;; For example:
;;;
;;; (executable-foreign-arglist '((object xv-object) (attr xv-generic-attr))) => 
;;; '(object (list 'translate-attribute-keyword attr))
;;;
;;; Warning: this function can't handle foreign function arglists that contain
;;; &rest or &key
;;;
;;; BUGS: - should handle string and callback type arguments as well as
;;;         attribute arguments.

(defun executable-foreign-arglist (arglist)
  (mapcar #'(lambda (arg)
	      (if (not (consp arg))
		  arg
		(let ((name (if (consp (car arg)) (caar arg) (car arg)))
		      (type (cadr arg)))
		  (if (typep type 'attribute) 
		      (list 'list ''translate-attribute-keyword name)
		    name))))
	  (remove '&optional arglist)))


;;; Similar to executable-foreign-arglist except the return value is not 
;;; evaluated.

(defun translate-foreign-arglist (arglist)
  (mapcar #'(lambda (arg)
	      (if (not (consp arg))
		  arg
		(let ((name (if (consp (car arg)) (caar arg) (car arg)))
		      (type (cadr arg)))
		  (if (typep type 'attribute) 
		      (list 'translate-attribute-keyword name)
		    name))))
	  (remove '&optional arglist)))



;;; Convert the foreign arglist to an arglist suitable for defmacro or defun, e.g.
;;; ((arg0 char) (arg1 int) &optional ((arg2 7) int)) => (arg0 arg1 &optional (arg2 7))

(defun lisp-foreign-arglist (arglist)
  (mapcar #'(lambda (arg)
	      (if (consp arg)
		  (car arg)
		arg))
	  arglist))


;;; Defines an exported function with FFI:def-foreign-function.  
;;; 
;;; If the type of the last foreign function argument is 'attr-avlist then a function, 
;;; compiler macro, AND a foreign function are defined.  The macro calls the foreign 
;;; function which is renamed %<foreign-function-name>.  The macro transforms its attr-avlist 
;;; arguments to a form suitable for passing to the foreign function, as much as possible 
;;; of this transformation is done at compile time.  The function is similar except that it 
;;; does the arglist transformation entirely at run time.
;;; 
;;; If the type of any required argument is 'attribute then it is converted to an integer
;;; enum value at run time.

(defmacro def-xview-foreign-function (name-and-options &body args)
  (let ((name (if (consp name-and-options) 
		  (car name-and-options) 
		name-and-options))
	(options (if (consp name-and-options) 
		     (cdr name-and-options))))
    (flet ((foreign-name-and-options (%foreign-function-name)
	     (if (assoc :name options)
		 (list* %foreign-function-name options)
	       (list* %foreign-function-name
		      (list :name (lisp-symbol-to-C-id name))
		      options))))
       (cond
	((eq (cadar (last args)) 'attr-avlist)
	 (let ((%foreign-function-name (intern (format nil "%~A" name)))
	       (lisp-arglist (nbutlast (lisp-foreign-arglist args))))
	   `(progn
	      (def-foreign-function 
	       ,(foreign-name-and-options %foreign-function-name)
	       ,@(butlast args)
	       &rest attr-avlist)
	      (export '(,name))
	      (LCL:def-compiler-macro ,name (,@lisp-arglist &rest attr-avlist)
		(multiple-value-bind (expanded-avlist exec)
		    (expand-attribute-value-list attr-avlist)
		  (list* exec
			 (list 'function ',%foreign-function-name)
			 ,@(nbutlast (executable-foreign-arglist args))
			 expanded-avlist)))
	      (defun ,name (,@lisp-arglist &rest attr-avlist)
		(apply (function ,%foreign-function-name)
		       ,@(nbutlast (translate-foreign-arglist args))
		       (translate-attribute-value-list attr-avlist))))))
	((some #'(lambda (type) (typep type 'attribute))
	       (mapcar #'(lambda (arg) (if (consp arg) (cadr arg) arg)) args))
	 (let ((%foreign-function-name (intern (format nil "%~A" name))))
	   `(progn
	      (def-foreign-function 
	       ,(foreign-name-and-options %foreign-function-name)
	       ,@(copy-list args))
	      (export '(,name))
	      (defun ,name ,(lisp-foreign-arglist args) 
		(,%foreign-function-name ,@(translate-foreign-arglist args))))))
	(t
	 `(def-exported-foreign-function (,name ,@options) ,@args))))))



(defun xview-package-address (package-keyword)
  (check-type package-keyword xview-package)
  (let ((fp (get package-keyword 'package-address)))
    (if fp 
	(foreign-pointer-address fp)
      (error "Uninitialized XView package ~S" package-keyword))))


;;; XView Locking
;;; 
;;; XView and Xlib are not reentrant conseqeuntly only one Lisp process can
;;; run an XView/Xlib functions at a time.  Applications must wrap any code that 
;;; uses XView/Xlib functions with "with-xview-lock".  This wrapper acquires a 
;;; lock (or blocks until the lock is available) that prevents other Lisp processes 
;;; from running XView code until the lock is released.

(defvar *xview-lock* nil)


;;; Low overhead, non consing, version of:
;;; 
;;; (defmacro with-xview-lock (&body body)
;;;   `(with-process-lock (*xview-lock*) ,@body))

#|
(defmacro with-xview-lock (&body body)
  `(macrolet
    ((wait-for-lock ()
       `(if (null *xview-lock*)
	    (setf *xview-lock* *current-process*))))
    
    (let ((lock-already-mine  (eq *current-process* *xview-lock*)))
      (SYS:interruptions-inhibited-unwind-protect
	 (progn
	   (unless lock-already-mine
	     (with-scheduling-inhibited
	       (or (wait-for-lock) 
		   (with-scheduling-allowed
		     (process-wait "Waiting for XView Lock"
				   #'(lambda () (wait-for-lock)))))))
	   ,@body)
       (unless lock-already-mine
	 (setf *xview-lock* nil))))))
|#

(defmacro with-xview-lock (&body body)
  `(let ((lock-already-mine  (process-owns-xview-lock-p)))
    (SYS:interruptions-inhibited-unwind-protect
     (progn
       (unless lock-already-mine
	 (grab-xview-lock))
       ,@body)
     (when (and (not lock-already-mine) (process-owns-xview-lock-p))
       (free-xview-lock)))))


(defmacro without-xview-lock (&body body)
  `(let ((lock-is-mine  (process-owns-xview-lock-p)))
     (when lock-is-mine (free-xview-lock))
     (SYS:interruptions-inhibited-unwind-protect     
      (progn . ,body)
      (when lock-is-mine
	(grab-xview-lock)))))


(defmacro process-owns-xview-lock-p (&optional (process '*current-process*))
  `(eq ,process *xview-lock*))


(defmacro grab-xview-lock ()
  `(with-scheduling-inhibited
    (or (if (null *xview-lock*)
	    (setf *xview-lock* *current-process*)) 
	(with-scheduling-allowed
	 (process-wait "Waiting for XView Lock"
		       #'(lambda () (if (null *xview-lock*)
					(setf *xview-lock* *current-process*))))))))
    

(defmacro free-xview-lock ()
  `(setf *xview-lock* nil))


