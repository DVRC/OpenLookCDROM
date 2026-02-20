;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)textedit.lisp	1.3 10/21/91

(in-package "LISPVIEW")


(macrolet
 ((def-literal-accessor (name type)
    `(def-solo-accessor ,name textedit-window
       :type ,(if (eq type 'boolean) t type)
       :driver ,(intern (format nil "DD-~A" name))))

  (def-literal-accessors ()
    `(progn
       ,@(mapcar #'(lambda (x)
		     `(def-literal-accessor ,(car x) ,(cadr x)))
		 literal-xview-textedit-accessors))))

 (def-literal-accessors))
		 

(def-solo-reader TEXTEDIT-MODIFIED-P textedit-window
  :type t
  :driver dd-textedit-modified-p)


(def-solo-accessor TEXTEDIT-INSERTION-POINT textedit-window
  :type textedit-location
  :driver dd-textedit-insertion-point)


(defmethod textedit-contents ((x textedit-window) &key start end)
  (check-arglist (start (or null textedit-location))
		 (end (or null textedit-location)))
  (dd-textedit-contents (platform x) x start end))


(defmethod (setf textedit-contents) (value (x textedit-window))
  (check-type value (or string pathname))
  (setf (dd-textedit-contents (platform x) x) value))


(def-solo-reader TEXTEDIT-CONTENTS-LENGTH textedit-window
  :type fixnum
  :driver dd-textedit-contents-length)


(defmethod textedit-insert ((x textedit-window) value)
  (check-arglist (value (or string pathname)))
  (dd-textedit-insert (platform x) x value))


(defmethod textedit-delete ((x textedit-window) start end &key update-clipboard)
  (check-arglist (start textedit-location)
		 (end textedit-location))
  (dd-textedit-delete (platform x) x start end update-clipboard))



(defmethod textedit-visible-text-offset ((x textedit-window) &optional (unit :char))
  (check-arglist (unit (member :char :line)))
  (dd-textedit-visible-text-offset (platform x) x unit))


(defmethod (setf textedit-visible-text-offset) (value (x textedit-window) &optional (unit :char))
  (check-arglist (unit (member :char :line)
		       (value textedit-location)))
  (setf (dd-textedit-visible-text-offset (platform x) x unit) value))


(def-solo-accessor TEXTEDIT-FILENAME textedit-window
  :type (or null string pathname)
  :driver dd-textedit-filename)


(defmethod textedit-save ((x textedit-window) &key filename notice-x notice-y)
  (check-arglist (filename (or null string pathname))
		 (notice-x (or null (integer 0 *)))
		 (notice-y (or null (integer 0 *))))
  (dd-textedit-save (platform x) x filename notice-x notice-y))


(defmethod textedit-reset ((x textedit-window) &key notice-x notice-y)
  (check-arglist (notice-x (or null (integer 0 *)))
		 (notice-y (or null (integer 0 *))))
  (dd-textedit-reset (platform x) x notice-x notice-y))


(defmethod textedit-find-string ((x textedit-window) string 
				 &key 
				   (start :first) (end :last) (from-end nil))
  (check-arglist (string string)
		 (start textedit-location)
		 (end textedit-location))
  (when (or (and (numberp start) (numberp end) (> end start))
	    (eq start :last))
    (error "the value of :end ~S, is greater than :start ~S" end start))
    
  (dd-textedit-find-string (platform x) x string start end from-end))


