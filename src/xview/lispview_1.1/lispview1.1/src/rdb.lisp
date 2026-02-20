;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;%W% %G%

;;; Minimal interface for the X11 "Resource Manager"


(in-package "LISPVIEW")


(defstruct resource-db xid)


(defun read-resource-db (path)
  (let ((db nil))
    (assert (let ((filename (malloc-foreign-string (namestring (truename path)))))
	      (setf db (XV:with-xview-lock 
			(prog1 
			    (X11:XrmGetFileDatabase filename)
			  (free-foreign-pointer filename))))
	      (/= 0 db))
	    (path)
	    "XrmGetFileDatabase failed for resource database file ~S" path)
    (make-resource-db :xid db)))


(defun write-resource-db (path db)
  (let ((filename (malloc-foreign-string (namestring path)))
	(xid (resource-db-xid db)))
    (when (integerp xid)
      (X11:XrmPutFileDatabase xid filename))
    (free-foreign-pointer filename)))


(defun read-resource-db-from-string (s)
  (flet 
   ((string-error ()
       (error "~S must be a string or a (:pointer :character) foreign pointer" s)))

   (let* ((fp (cond
	       ((typep s 'foreign-pointer)
		(if (foreign-typep s '(:pointer :character))
		    s
		  (string-error)))
	       ((or (null s) (stringp s))
		(malloc-foreign-string s))
	       ((integerp s)
		(make-foreign-pointer :address s :type '(:pointer :character)))
	       (t 
		(string-error)))))
     (make-resource-db :xid (X11:XrmGetStringDatabase fp)))))
     
     


(defvar x11-get-resource-value 
  (make-foreign-pointer :type '(:pointer X11:XrmValue) :static t))

(defvar x11-get-resource-value-str 
  (make-foreign-pointer :type '(:pointer :character) :address 0 :static t))

(defvar x11-get-resource-type
  (make-foreign-pointer :type '(:pointer (:pointer :character)) :static t))

(defmethod resource-value ((db resource-db) name class)
  (let ((name-str (malloc-foreign-string (princ-to-string name)))
	(class-str  (malloc-foreign-string (princ-to-string class)))
	(xid (resource-db-xid db)))
    (unwind-protect
	(when (integerp xid)
	  (XV:with-xview-lock 
	    (let ((status (X11:XrmGetResource xid name-str class-str 
					      x11-get-resource-type
					      x11-get-resource-value)))
	      (if (/= 0 status)
		  (progn
		    (setf (foreign-pointer-address x11-get-resource-value-str)
			  (X11:XrmValue-addr x11-get-resource-value))
		    (values 
		     (foreign-string-value x11-get-resource-value-str)
		     (foreign-string-value (foreign-value x11-get-resource-type))))))))
      (progn
	(free-foreign-pointer name-str)
	(free-foreign-pointer class-str)))))



(defvar x11-rdb-pointer 
  (make-foreign-pointer :type '(:pointer X11:XrmDatabase) :static t))

(defvar x11-put-resource-value 
  (make-foreign-pointer :type '(:pointer X11:XrmValue) :static t))


(defmethod (setf resource-value) (value (db resource-db) specifier &optional type)
  (let ((value-str (malloc-foreign-string (princ-to-string value)))
	(specifier-str (malloc-foreign-string (princ-to-string specifier)))
	(type-str (if type (malloc-foreign-string (princ-to-string type))))
	(xid (resource-db-xid db)))
    (unwind-protect
	(XV:with-xview-lock 
	  (if (integerp xid)
	      (setf (foreign-value x11-rdb-pointer) xid)
	    (setf (foreign-value x11-rdb-pointer) 0))
	  (if type
	      (progn 
		(setf (X11:XrmValue-addr x11-put-resource-value) (foreign-pointer-address value-str)
		      (X11:XrmValue-size x11-put-resource-value) (foreign-size-of value-str))
		(X11:XrmPutResource x11-rdb-pointer specifier-str type-str x11-put-resource-value))
	    (X11:XrmPutStringResource x11-rdb-pointer specifier-str value-str))
	  (unless (integerp xid)
	    (setf (resource-db-xid db) (foreign-value x11-rdb-pointer))))
      (progn
	(free-foreign-pointer value-str)
	(free-foreign-pointer specifier-str)
	(when type (free-foreign-pointer type-str)))))
  value)



;;; Return a new resource database that contains the union of the entries in dbs.
;;; The source databases are destroyed.

(defun merge-resource-dbs (&rest dbs)
  (XV:with-xview-lock 
    (let ((merge-xid (X11:XrmGetStringDatabase (malloc-foreign-string nil))))
      (setf (foreign-value x11-rdb-pointer) merge-xid)
      (dolist (db dbs)
	(let ((xid (resource-db-xid db)))
	  (when (integerp xid)
	    (X11:XrmMergeDatabases xid x11-rdb-pointer))))
      (make-resource-db :xid merge-xid))))



(defun load-initial-resources (display)
  (let ((xdefaults 
	 (probe-file (format nil "~A/.Xdefaults" (or (environment-variable "HOME") "")))))
    (apply #'merge-resource-dbs 
	   (read-resource-db-from-string
	    (X11:display-xdefaults (xview-display-dsp (device display))))
	   (if xdefaults
	       (read-resource-db xdefaults)))))
