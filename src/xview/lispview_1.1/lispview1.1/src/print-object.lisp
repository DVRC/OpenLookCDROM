;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)print-object.lisp	1.14 10/11/91

(in-package "LISPVIEW")


(defun print-lispview-object-start (object stream &optional (type (type-of object)))
  (format stream "#<~S ~A" type
	  (if (slot-boundp object 'status) 
	      (case (status object) 
		(:initialized "+ ")
		(:realized "* ")
		(:destroyed "-destroyed-"))
	    "-")))


(defun print-lispview-object-finish (object stream)
  (format stream " ~X>" (SYS:%pointer object))
  object)


(defmacro def-lispview-print-object (((object class) stream) &body body)
  `(defmethod print-object ((,object ,class) ,stream)
     (print-lispview-object-start ,object ,stream)
     (when (and (slot-boundp ,object 'status) (not (eq (status ,object) :destroyed)))
       ,@body)
     (print-lispview-object-finish ,object ,stream)))



(def-lispview-print-object ((x COLOR) stream)
  (format stream "~A ~A"
	  (cond
	   ((slot-boundp x 'name)
	    (name x))
	   ((or (and (slot-boundp x 'red) (slot-boundp x 'green) (slot-boundp x 'blue))
		(and (slot-boundp x 'hue) (slot-boundp x 'saturation) (slot-boundp x 'intensity)))
	    (format nil "(~4,3F ~4,3F ~4,3F)" (red x) (green x) (blue x)))
	   (t 
	    ""))
	  (if (slot-boundp x 'pixel)
	      (format nil "[~S]" (pixel x))
	    "")))


(def-lispview-print-object ((x GRAPHICS-CONTEXT) stream)
  (flet 
   ((color-name (color)
      (cond 
       ((slot-boundp color 'name) (name color))
       ((slot-boundp color 'pixel) (format nil "[~D]" (pixel color)))
       (t ""))))

   (format stream "~A ~A,~A"
	   (string-downcase 
	    (find (operation x) boole-constants :key #'symbol-value :test #'=))
	   (color-name (foreground x))
	   (color-name (background x)))))


(defmethod describe-object ((gc graphics-context) stream)
  (format stream  "~S is an instance of ~A~%" gc (class-name (class-of gc)))
  (if (eq (status gc) :destroyed)
      (format stream "~S has been destroyed.~%" gc)
    (progn
      (format t "   status ~S~%" (status gc))
      (let ((op (find (operation gc) boole-constants :key #'symbol-value :test #'=)))
	(format stream "   operation ~A (~D)~%" (string-downcase op) (symbol-value op)))
      (dolist (slot (remove 'operation graphics-context-slot-names))
	(format stream "   ~A ~S~%" (string-downcase slot) (funcall slot gc))))))
    
(defun xview-locked-p ()
  (and xview::*xview-lock* (not (eq xview::*xview-lock* lcl:*current-process*))))

(defun print-lispview-bounding-region (object stream)
  (if (xview-locked-p)
      (format stream "<XView info locked>")
    (let ((br (bounding-region object)))
      (when br
	(format stream "~Sx~S at (~S,~S)"
		(region-width br) (region-height br)
		(region-left br) (region-top br))))))
      

(def-lispview-print-object ((x CANVAS) stream)
  (print-lispview-bounding-region x stream))


(def-lispview-print-object ((x SCROLLBAR) stream)
  (print-lispview-bounding-region x stream))



(def-lispview-print-object ((x TOP-LEVEL-WINDOW) stream)
  (let ((label (label x)))
    (print-lispview-bounding-region x stream)
    (when label
      (if (> (length label) 10)
	  (format stream " \"~A...\"" (subseq label 0 7))
	(format stream " ~S" label)))))


(def-lispview-print-object ((x ITEM) stream)
  (let ((label (if (and (typep x 'label) (slot-boundp x 'label)) (label x))))
    (print-lispview-bounding-region x stream)
    (when (and label (stringp label))
      (if (> (length label) 10)
	  (format stream " \"~A...\"" (subseq label 0 7))
	(format stream " ~S" label)))))


(def-lispview-print-object ((x IMAGE) stream)
  (let ((br (bounding-region x)))
    (format stream "~Dx~Dx~D" (region-width br) (region-height br) (depth x))))


(defmethod print-object ((object keyboard-interest) stream)
  (format stream "#<~S ~A" 
	  (type-of object) 
	  (if (slot-boundp object 'event-spec)
	      (prin1-to-string (slot-value object 'event-spec))
	    ""))
  (format stream " ~X>" (SYS:%pointer object))
  object)
