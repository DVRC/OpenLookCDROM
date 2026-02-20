;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)ffi.lisp	3.8 10/11/91



(in-package "FOREIGN-FUNCTION-INTERFACE" :use '(lisp) :nicknames '("FFI"))


;;; Foreign Function Interface
;;;
;;; This file defines a complete Foreign Function Interface (FFI) based on the Lucid
;;; FFI.  Some of the defining forms contain a few new features, e.g. def-foreign-function
;;; allows types to be specified with synonyms rather than just primitive types, the bulk
;;; of the Lucid FFI is just imported from the LCL package and exported from here.

;;; The 2 locals defined below, lcl-exports and ffi-exports, define the symbols 
;;; that are just imported from LCL and exported from FFI and the symbols that
;;; are defined in the FFI package respectively.

(eval-when (load eval compile)
  (let ((lcl-exports
	 '(LCL:def-foreign-callable
	   LCL:def-foreign-struct
	   LCL:def-foreign-synonym-type
	   LCL:def-foreign-function      
	   LCL:load-foreign-files
	   LCL:load-foreign-libraries
	   LCL:defined-foreign-type-p	  
	   LCL:foreign-aref
	   LCL:typed-foreign-aref
	   LCL:foreign-string-value
	   LCL:foreign-pointer-address
	   LCL:foreign-pointer
	   LCL:foreign-pointer-p
	   LCL:foreign-pointer-type
	   LCL:foreign-size-of
	   LCL:foreign-typep
	   LCL:foreign-type-size
	   LCL:foreign-value
	   LCL:foreign-variable-p 
	   LCL:foreign-variable-address
	   LCL:foreign-variable-pointer
	   LCL:free-foreign-pointer
	   LCL:make-foreign-pointer
	   LCL:malloc-foreign-pointer
	   LCL:copy-foreign-pointer
	   LCL:stationary-object-p
	   LCL:with-static-area
	   LCL:run-program))
	(ffi-exports
	 '(C-id-to-lisp-id     
	   lisp-symbol-to-C-id
	   malloc-foreign-string
	   maybe-malloc-foreign-string 
	   free-foreign-string-at
	   primitive-type
	   def-foreign-macro
	   def-foreign-struct-function
	   lookup-callback-address
	   def-foreign-interface
	   def-exported-constant
	   def-exported-foreign-synonym-type
	   def-exported-foreign-struct
	   def-exported-foreign-function
	   def-exported-foreign-macro
	   def-exported-foreign-struct-function
	   make-null-foreign-pointer
	   foreign-pointer-to-array
	   foreign-array-to-pointer
	   map-foreign-vector
	   def-foreign-function         ;; local redefinitions
	   def-foreign-callable
	   load-foreign-files
	   load-foreign-libraries)))
    (import (set-difference lcl-exports ffi-exports 
			    :key #'symbol-name :test #'string=))
    (export (mapcar #'intern 
		    (mapcar #'symbol-name 
			    (union lcl-exports ffi-exports 
				   :key #'symbol-name :test #'string=))))))

;;; All characters are uppercased and embedded underscores are converted 
;;; to dashes, a string is returned.

(defun C-id-to-lisp-id (string)
  (substitute #\- #\_ (string-upcase string) :start 1 :end (max 1 (1- (length string)))))


;;; Return the print name of the symbol in lower case with dashes to converted to 
;;; underscores and an underscore prefix.

(defun lisp-symbol-to-C-id (symbol)
  (format nil "_~A" (substitute #\_ #\- (string-downcase (string symbol)))))




(defun malloc-foreign-string (s)
  (if (null s)
      (LCL:make-foreign-pointer :address 0 :type '(:pointer :character))
    (let ((fs (LCL:malloc-foreign-pointer 
	       :type `(:pointer (:array :character (,(1+ (length s))))))))
      (setf (LCL:foreign-string-value fs) s
	    (LCL:foreign-pointer-type fs) '(:pointer :character))
      fs)))


;;; If s is a foreign pointer make sure that it has the correct type
;;; and then just return it, if s is a string then allocate a foreign
;;; string, if it is an integer we'll assume that the application knows what it's
;;; doing and - the integer represents the address of a static foreign string, otherwise 
;;; signal an error.

(defun maybe-malloc-foreign-string (attr s)
  (flet ((string-error (string)
	    (error "Attribute ~S value element ~S must be a ~
                    string or a (:pointer :character) type foreign pointer"
		    attr string)))
     (cond
      ((LCL:foreign-pointer-p s)
       (if (LCL:foreign-typep s '(:pointer :character))
	   s
	 (string-error s)))
      ((or (null s) (stringp s))
       (malloc-foreign-string s))
      ((integerp s)
       s)
      (t 
       (string-error s)))))


;;; Free the foreign string at the specified address.  Obviously this function should 
;;; be used with extreme care since there is no easy way (at this point) to check if 
;;; string-addr is really the address of space allocated my malloc.

(defun free-foreign-string-at (string-addr)
  (free-foreign-pointer 
   (make-foreign-pointer :type '(:pointer :character)
			 :address string-addr)))

							      

;;; Map a type synonym or a compound type like (:array (:pointer int) (2 3))
;;; to a Lucid FFI "primitive type".  For example (:array (:pointer int) (2 3))
;;; maps to (:array (:pointer :signed-32bit) (2 3)).

(defun primitive-type (type)
  (cond
   ((symbolp type)  
    (let ((primitive (LUCID::foreign-type-name (LUCID::foreign-type type))))
      (if (consp primitive) 
	  (primitive-type primitive)
	primitive)))
   ((and (consp type) (eq (car type) :pointer))
    (list :pointer (primitive-type (cadr type))))
   ((and (consp type) (eq (car type) :array))
    (list* :array (primitive-type (cadr type)) (cddr type)))
   (t 
    type)))



;;; Convert the types in a foreign argument list to their "primitive" 
;;; equivalents, e.g. ((a int) (b char)) => ((a :signed-32bit) (b :character)).

(defun primitive-foreign-arglist (args)
  (mapcar #'(lambda (arg)
	      (if (consp arg)
		  (list (car arg) (primitive-type (cadr arg)))
		arg))
	  args))



;;; All synonym types are mapped to their Lucid foreign function interface "primitive
;;; type" equivalents.  The fact that this isn't done automatically is a bug in 
;;; the Lucid foreign function interface.

(defmacro def-foreign-function (name-and-options &body args)
  (let ((name (if (consp name-and-options) 
		  (car name-and-options) 
		name-and-options))
	(options (if (consp name-and-options) 
		     (cdr name-and-options))))
    (when (and options (assoc :return-type options))
      (let ((return-type (primitive-type (cadr (assoc :return-type options)))))
	(setq options 
	      (substitute `(:return-type ,return-type) :return-type options :key #'car))))
    `(LCL:def-foreign-function ,(if options
				    `(,name ,@options) 
				  `,name)
        ,@(primitive-foreign-arglist args))))


;;; Macros exported by the Sunview interface are wrapped by C functions named
;;; macro_<original macro name>, see macros.c.  

(defmacro def-foreign-macro (spec &body args)
  (let* ((spec (if (consp spec) (copy-list spec) (list spec)))
	 (name (or (cadr (assoc :name (cdr spec))) 
		   (lisp-symbol-to-C-id (car spec))))
	 (macro-name (format nil "_macro~A" name)))
    (if (assoc :name (cdr spec))
	(setf (cadr (assoc :name (cdr spec))) macro-name)
      (setf spec (append spec (list (list :name macro-name)))))
    `(def-foreign-function (,@spec) ,@args)))



;;; Functions that return structures by value are wrapped by C functions named
;;; struct_<original macro name>.  Note that the :return-type for structure
;;; valued foreign functions must be specified and it should be the type actually returned
;;; by the C function.  The return type is converted to (:pointer return-type) here.

(defmacro def-foreign-struct-function (name-and-options &body args)
  (unless (consp name-and-options)
    (error ":return-type must be specified for structure valued function ~S" name-and-options))
  (let* ((name-and-options (copy-list name-and-options))
	 (return-type (assoc :return-type (cdr name-and-options)))
	 (function-name (format nil "_struct~A" (lisp-symbol-to-C-id (car name-and-options)))))
    (unless return-type 
      (error ":return-type must be specified for structure valued function ~S" (car name-and-options)))
    (setf (cadr return-type) (list :pointer (cadr return-type)))
    `(def-foreign-function (,@name-and-options (:name ,function-name)) ,@args)))




;;; This version of def-foreign-callable supports synonym types for :return-type and 
;;; argument types.  Function arguments that are specified by symbols rather than (<name> <type>)
;;; are replaced by (<name> :signed-32bit).  For example a definition like:
;;;     (FFI:def-foreign-callable (foo (:return-type FFI:int)) a b (c FFI:char))
;;; would be transformed to:
;;;     (LCL:def-foreign-callable (foo (:return-type :signed-32bit)) 
;;;          ((a :signed-32bit) (b :signed-32bit) (c :character)))
;;;
;;; Additionally we put a foreign pointer to the C callable function on the plist
;;; of the symbol that names the foreign-callable function under 'foreign-function-pointer.
;;; This property is used by lookup-callback-address.

(defmacro def-foreign-callable (name-and-options (&rest args) &body body)
  (let ((name (if (consp name-and-options) 
		  (car name-and-options) 
		name-and-options))
	(options (if (consp name-and-options) 
		     (cdr name-and-options))))
    (when (and options (assoc :return-type options))
      (let ((return-type (primitive-type (cadr (assoc :return-type options)))))
	(setq options 
	      (substitute `(:return-type ,return-type) :return-type options :key #'car))))
    `(progn
       (LCL:def-foreign-callable ,(if options
				     `(,name ,@options) 
				   `,name)
	,(mapcar #'(lambda (arg)
		     (if (consp arg)
			 arg
		       (list arg :signed-32bit)))
		 (primitive-foreign-arglist args))
	,@body)
       (setf (get ',name 'foreign-function-pointer)
	     (LCL:foreign-variable-pointer (lisp-symbol-to-C-id ',name))))))



;;; LOAD-FOREIGN-FILES and LOAD-FOREIGN-LIBRARIES
;;;
;;; Local versions of these functions add any libraries found on the LD_LIBRARY_PATH
;;; environment variable to the library search path.  This is consistent with the current
;;; Unix loader.

(defun library-search-path ()
  (let ((ld-search-path (LCL:environment-variable "LD_LIBRARY_PATH")))
    (if ld-search-path
	(let ((search-path (copy-list lucid::*default-archive-directories*))
	      (n0 0))
	  (loop
	   (let* ((n1 (position #\: ld-search-path :start n0))
		  (path (cond 
			 (n1
			  (subseq ld-search-path n0 n1))
			 ((< n0 (length ld-search-path))
			  (subseq ld-search-path n0)))))
	     (when path
	       (pushnew (format nil "~A/lib" path) search-path :test #'string=))
	     (unless n1
	       (return search-path))
	     (setq n0 (1+ n1)))))
      lucid::*default-archive-directories*)))


(defun load-foreign-files (&rest args)
  (let ((LUCID::*default-archive-directories* (library-search-path)))
    (apply 'LCL:load-foreign-files args)))
	  

(defun load-foreign-libraries (&rest args)
  (let ((LUCID::*default-archive-directories* (library-search-path)))
    (apply 'LCL:load-foreign-libraries args)))




;;; Symbol must name a function defined with def-foreign-callable, we assume that the 
;;; name of the foreign function wasn't defined to be something other than the default.
;;; Nil is translated to 0 - one should be careful that the recipient of the function
;;; address can handle it.

(defun lookup-callback-address (symbol)
  (check-type symbol symbol)
  (if symbol
      (let ((fp (get symbol 'foreign-function-pointer)))
	(or (and fp (LCL:foreign-pointer-address fp))
	    (error "~S does not represent a valid callback function" symbol)))
    0))


;;; The macros below are versions of defconstant, def-foreign-synonym-type, def-foreign-struct, 
;;; def-foreign-function, etc that export the symbols that they define.  Symbol names that 
;;; begin with a leading underscore are not exported, this is consistent with conventional
;;; C practice.
;;;
;;; The DEF-FOREIGN-INTERFACE macro can be used to limit the size of an image with foreign
;;; structs and functions loaded (from xlib.lisp, functions.lisp, types.lisp, globals.lisp)
;;; by eliding definitions that aren't needed.  The body of a def-foreign-interface form
;;; specifies the names of the constants, foreign structs and foreign functions that are 
;;; to be loaded.  The def-exported-{constant,foreign-function} macros expand into NIL for
;;; definitions that aren't needed, def-exported-foreign-struct expands into a 
;;; def-foreign-synonym-type: (def-foreign-synonym-type <struct-name> unused-foreign-struct). 
;;; This makes it possible for the type (:pointer <struct-name>) to appear as a 
;;; function argument or as the type of another foreign slot.

(defvar *foreign-interface-packages* nil)

(defmacro def-foreign-interface (&rest definitions)
  `(eval-when (load eval compile)
     (progn
        (def-foreign-synonym-type unused-foreign-struct :unsigned-16bit)
	(pushnew *package* *foreign-interface-packages*)
	(do-symbols (s)
	  (dolist (type '(foreign-function foreign-struct constant)) 
	    (remprop s type)))
	(dolist (def ',definitions)
	  (let ((type (intern (string (car def)) (find-package :ffi)))) 
	    (dolist (symbol (cdr def))
	      (setf (get symbol type) T)))))))
     

(defun required-foreign-definition (symbol type)
  (if (member (symbol-package symbol) *foreign-interface-packages* :test #'eq)
      (get symbol type)
    T))


(eval-when (load eval compile)
  (defun leading-underscore-p (name)
    (eql (aref (symbol-name name) 0) #\_))
  (defun name-and-options-name (name-and-options)
    (if (consp name-and-options) 
	(car name-and-options) 
      name-and-options)))


(defmacro def-exported-constant (name &rest args)
  (when (required-foreign-definition name 'constant)
    `(progn 
       ,(unless (leading-underscore-p name)
	  `(export '(,name)))
       (defconstant ,name ,@args))))

(defmacro def-exported-foreign-synonym-type (synonym &rest args)
  `(progn 
     ,(unless (leading-underscore-p synonym)
	`(export '(,synonym)))
     (def-foreign-synonym-type ,synonym ,@args)))

(defmacro def-exported-foreign-struct (name-and-options &rest slots)
  (let ((name (name-and-options-name name-and-options)))
    (if (required-foreign-definition name 'foreign-struct)
	(let ((slot-names (mapcan #'(lambda (slot)
				      (unless (leading-underscore-p (car slot))
					(list (intern (format nil "~S-~S" name (car slot))))))
				  slots)))
	 `(progn
	    ,(unless (leading-underscore-p name)
	      `(export '(,name 
			 ,(intern (format nil "MAKE-~S" name)) 
			 ,(intern (format nil "~S-P" name))
			 ,@slot-names)))
	    (def-foreign-struct ,name-and-options ,@slots)))
      `(def-foreign-synonym-type ,name unused-foreign-struct))))

(defmacro def-exported-foreign-function (name-and-options &rest args)
  (let ((name (name-and-options-name name-and-options)))
    (when (required-foreign-definition name 'foreign-function)
      `(progn
	 ,(unless (leading-underscore-p name)
	    `(export '(,name)))
	 (def-foreign-function ,name-and-options ,@args)))))

(defmacro def-exported-foreign-macro (name-and-options &body args)
  (let ((name (name-and-options-name name-and-options)))
    (when (required-foreign-definition name 'foreign-function)
      `(progn
	 ,(unless (leading-underscore-p name)
	    `(export '(,name)))
	 (def-foreign-macro ,name-and-options ,@args)))))

(defmacro def-exported-foreign-struct-function (name-and-options &body args)
  (let ((name (name-and-options-name name-and-options)))
    (when (required-foreign-definition name 'foreign-function)
      `(progn
	 ,(unless (leading-underscore-p name)
	    `(export '(,name)))
	 (def-foreign-struct-function ,name-and-options ,@args)))))



(defun make-null-foreign-pointer (type)
  (make-foreign-pointer :type `(:pointer ,type) :address 0))


;;; Make a new foreign-pointer whose type is (:pointer (:array elt-type (length)))
;;; and whose address is the the same as foreign-pointer fp.  The default value
;;; for elt-type is the name of fp's foreign-pointer-type .

(defun foreign-pointer-to-array (fp dimensions &optional elt-type)
  (check-type fp foreign-pointer)
  (check-type dimensions (or cons (integer 0 *)))
  (check-type elt-type (or null (satisfies LCL:defined-foreign-type-p)))
  (let ((elt-type
	 (or elt-type (cadr (LUCID::foreign-type-name (foreign-pointer-type fp))))))
    (make-foreign-pointer 
     :address (foreign-pointer-address fp)
     :type `(:pointer (:array ,elt-type ,(if (consp dimensions) dimensions `(,dimensions)))))))


;;; Make a new foreign pointer whose type is (:pointer elt-type) and whose
;;; address is the same as the foreign-pointer vector.  The default value
;;; for elt-type is the name of the foreign-type of the elements of vector.

(defun foreign-array-to-pointer (array &optional elt-type)
  (check-type array foreign-pointer)
  (check-type elt-type (or null (satisfies LCL:defined-foreign-type-p)))
  (let ((elt-type
	 (or elt-type (cadadr (LUCID::foreign-type-name (foreign-pointer-type array))))))
    (make-foreign-pointer 
      :address (foreign-pointer-address array)
      :type `(:pointer ,elt-type))))



;;; Make a new foreign array with the same length as sequence and
;;; initialize its elements with the results of mapping function over the
;;; sequence.  To handle multi-argument functions, just use map to create
;;; one sequence, and then map-foreign-vector with #'identity.

(defun map-foreign-vector (elt-type function sequence)
  (check-type elt-type (satisfies LCL:defined-foreign-type-p))
  (let* ((length (length sequence))
	 (vec (malloc-foreign-pointer :type `(:pointer (:array ,elt-type (,length))))))
    (dotimes (i length vec)
      (setf (foreign-aref vec i) (funcall function (elt sequence i))))))



;;; Synonym types for all of the primitive C types

(def-exported-foreign-synonym-type char :character)
(def-exported-foreign-synonym-type unsigned-char :unsigned-8bit)
(def-exported-foreign-synonym-type short  :signed-16bit)
(def-exported-foreign-synonym-type unsigned-short :unsigned-16bit)
(def-exported-foreign-synonym-type int :signed-32bit)
(def-exported-foreign-synonym-type unsigned-int :unsigned-32bit)
(def-exported-foreign-synonym-type long :signed-32bit)
(def-exported-foreign-synonym-type unsigned-long :unsigned-32bit)
(def-exported-foreign-synonym-type float :single-float)
(def-exported-foreign-synonym-type double  :double-float)
(def-exported-foreign-synonym-type void :signed-32bit)
(def-exported-foreign-synonym-type short-int short)
(def-exported-foreign-synonym-type long-int long)
(def-exported-foreign-synonym-type unsigned unsigned-int)
(def-exported-foreign-synonym-type long-float double)


;;; Some of the standard C type synonyms from /usr/include/sys/types.h

(def-exported-foreign-synonym-type caddr-t int)
(def-exported-foreign-synonym-type u-char unsigned-char)
(def-exported-foreign-synonym-type u-short unsigned-short)
(def-exported-foreign-synonym-type u-int unsigned-int)
(def-exported-foreign-synonym-type u-long unsigned-long)
(def-exported-foreign-synonym-type fd-mask long)




