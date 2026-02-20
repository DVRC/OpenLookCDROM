;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.


(in-package "LISPVIEW")


;;; IMAGE VIEWER - (image-viewer-demo)
;;; 
;;; Demonstrates simple use of list-viewer with varying height choices.  The code has
;;; not been optimized at all - there are several places that repeatedly compute
;;; values that could easily be cached.  
;;;
;;; Note that we've used an :around method to initialize the slots that choice-height
;;; depends on.  Choice-height is called by the initialize-instance method for viewer.

(defclass image-file (image)
  ((filename :initarg :filename)))
  

(defclass image-viewer (exclusive-list-viewer)
  ((images :type list)
   (gc :type graphics-context)
   (font :type font)))
   
    
(defmethod initialize-instance :around ((iv image-viewer)
					&rest initargs
					&key
					  (directory "/usr/include/images/")
					  (extensions '("pr" "cursor" "image" "icon"))
					  (format :sun-icon)
					  (max-choices 32)
					  (max-width 64)
					  (max-height 64)
					&allow-other-keys)
  (let ((files (mapcan #'(lambda (path)
			   (if (member (pathname-type path) extensions :test #'equal)
			       (list path)))
		       (directory directory)))
	(n-choices 0))
    (flet 
     ((maybe-load-image (path)
	(when (< n-choices max-choices)
	  (let* ((image (make-instance 'image-file :filename path :format format))
		 (br (bounding-region image)))
	    (if (and (<= (region-width br) max-width)
		     (<= (region-height br) max-height))
		(progn
		  (incf n-choices)
		  (princ ".") (force-output)
		  (list image))
	      (progn
		(format t " Skipping ~A " path)
		nil))))))
     (format t ";;; Scanning ~D Images: " max-choices)
     (with-slots (images gc font) iv
	(setf images (mapcan #'maybe-load-image files)
	      gc (make-instance 'graphics-context)
	      font (make-instance 'font :family "Lucida" :point-size 12))
	(format t "OK~%")
	(apply #'call-next-method iv :n-choices (length images) initargs)))))
				 

(defmethod lv-nth-choice ((iv image-viewer) row)
  (nth row (slot-value iv 'images)))


(defmethod lv-choice-height ((iv image-viewer) image-file)
  (with-slots (font) iv
    (max (+ 6 (region-height (bounding-region image-file)))
	 (+ 6 (font-ascent font) (font-descent font)))))



(defmethod lv-draw-choice ((iv image-viewer) drawable x y image-file row)
  (declare (ignore row))
  (with-slots (gc font) iv
    (let ((br (bounding-region image-file)))
      (copy-area image-file drawable 
		 0 0 (region-width br) (region-height br) (+ x 3) (+ y 3)
		 :gc gc)
      (draw-string drawable 
		   (+ x 6 (region-width br)) (+ y 3 (font-ascent font))
		   (namestring (pathname-name (slot-value image-file 'filename)))
		   :gc gc))))


(defmethod (setf status) ((value (eql :destroyed)) (iv image-viewer))
  (call-next-method)
  (with-slots (font gc images) iv
    (destroy gc) 
    (destroy font)
    (map nil #'destroy images)))


(defun image-viewer-demo (&rest initargs)
  (let* ((w (make-instance 'base-window :label "Image Viewer" :mapped nil))
	 (br (bounding-region w)))
    (prog1
	(apply #'make-instance 'image-viewer
	  :parent w
	  :width (region-width br)
	  :height (region-height br)
	  initargs)
      (setf (mapped w) t))))



;;; STRING VIEWER - (string-viewer-demo)
;;;
;;; This is a more realistic example of how one might use a list viewer as the basis for
;;; a utility class.  String-viewer, if refined some more, would make a good utility class.
;;; Here are a few of these refinements:
;;; - Setf methods for choices, font, convert-to-string, numbered-rows-p, left-margin.
;;; - Integrity checks for all initargs in initialize-instance
;;; - More flexible line numbering scheme - support arbitrary padding, initial value


(defclass string-viewer (non-exclusive-list-viewer)
  ((choices :initarg :choices)
   (font :initarg :font :type font :reader font)
   (convert-to-string :initarg :convert-to-string :type function)
   (numbered-rows-p :initarg :numbered-rows-p)
   (left-margin :initarg :left-margin)
   (leading :initarg :leading)
   (gc :type graphics-context)
   (baseline :type (integer 0 *))
   (string-height :type (integer 0 *)))
  (:default-initargs
   :convert-to-string #'string
   :numbered-rows-p t
   :left-margin 3))


(defmethod initialize-instance :around ((sv string-viewer)
					&rest initargs
					&key
					  (display (default-display))
					  choices
					  font
					  leading
					&allow-other-keys)
  (with-slots (font leading gc baseline string-height) sv
    (unless (slot-boundp sv 'font)
      (setf font (make-instance 'font :family :LucidaTypewriter :point-size 12)))
    (setf gc (make-instance 'graphics-context :display display :font font))
    (let ((ascent (font-ascent font))
	  (descent (font-descent font)))
      (unless (slot-boundp sv 'leading)
	(setf leading (ceiling (* (+ ascent descent) 0.2))))
      (setf baseline (+ leading ascent)
	    string-height (+ baseline descent))))

  (apply #'call-next-method sv :n-choices (length choices) initargs))


(defmethod lv-nth-choice ((v string-viewer) row)
  (nth row (slot-value v 'choices)))


(defmethod lv-draw-choice ((v string-viewer) drawable x y choice row)
  (with-slots (gc convert-to-string numbered-rows-p left-margin baseline) v
    (let ((string (funcall convert-to-string choice)))
      (draw-string drawable (+ x left-margin) (+ y baseline)
		   (if numbered-rows-p 
		       (format nil "~4A ~A" row string)
		     string)
		   :gc gc))))


(defmethod lv-choice-height ((v string-viewer) choice)
  (declare (ignore choice))
  (slot-value v 'string-height))


(defmethod (setf status) ((value (eql :destroyed)) (sv string-viewer))
  (call-next-method)
  (with-slots (font gc) sv
    (destroy gc) 
    (destroy font)))


(defun string-viewer-demo (&rest initargs)
  (let* ((w (make-instance 'base-window :label "String Viewer: LispView Symbols" :mapped nil))
	 (br (bounding-region w))
	 (symbols 
	  (let ((l nil)) 
	    (do-external-symbols (s (find-package :lispview) (nreverse l))
	      (push s l))))
	 (viewer
	  (apply #'make-instance 'string-viewer
	     :parent w
	     :width (region-width br)
	     :height (region-height br)
	     :choices symbols
	     :convert-to-string #'string-capitalize
	     initargs)))

    (defmethod (setf bounding-region) (new-br (window (eql w)))
      (call-next-method)
      (setf (bounding-region viewer) (make-region :width (region-width new-br)
						  :height (region-height new-br))))
    
    (setf (mapped w) t)
    viewer))



;;; CLASS VIEWER - (class-viewer-demo)
;;;
;;; This viewer demonstrates how one can make relatively fundamental changes to 
;;; the basic viewer class by adding application specific interests to the 
;;; viewers display window.  In this case we track mouse movements and highlight
;;; whatever choice subfield the mouse is positioned over.
;;;
;;; Note: each choice is drawn 3 pixels from the left.  This is hardwired because
;;; I'm lazy.


(defclass text-item ()
  ((object :initarg :object)
   (string :type string :initarg :string)
   (bounding-region :type region :initarg :bounding-region :reader bounding-region)
   (baseline :type integer :initarg :baseline)
   (font :type font :initarg :font)))

(defmethod print-object ((x text-item) stream)
  (format stream "#<~S ~S ~X>" 
	  (type-of x)
	  (if (slot-boundp x 'string) (slot-value x 'string) "")
	  (SYS:%pointer x)))

(defclass text ()
  ((items :type list :initarg :items)
   (gc :type graphics-context :initarg :gc)
   (bounding-region :type region :reader bounding-region)))


(defmethod initialize-instance :after ((x text) &rest initargs)
  (declare (ignore initargs))
  (setf (slot-value x 'bounding-region)
	(apply #'region-bounding-region (mapcar #'bounding-region (slot-value x 'items)))))


(defmethod draw-text (drawable x y (o text))
  (with-slots (items gc) o
    (let ((gc-font (font gc)))
      (dolist (item items)
        (with-slots ((br bounding-region) baseline string font) item
	  (unless (eq font gc-font)
	    (setf gc-font (setf (font gc) font)))
          (draw-string drawable (+ x (region-left br)) (+ y baseline) string :gc gc))))))


(defclass class-name-item (text-item) ())
(defclass super-name-item (text-item) ())

(defun make-class-text (class gc plain bold)
  (let* ((items nil)
	 (space-width (string-width plain " "))
	 (x 0)
	 (ascent (font-ascent plain))
	 (descent (font-descent plain))
	 (y ascent)
	 (linefeed-height (let ((h (+ ascent descent)))
			    (+ h (ceiling (* h 0.2))))))
    (flet 
     ((push-text-item (class object symbol font)
	(let* ((string (princ-to-string symbol))
	       (width (string-width font string)))
	  (push (make-instance class
		  :object object 
		  :string string
		  :baseline y
		  :font font
		  :bounding-region (make-region 
				     :left x 
				     :top (- y ascent) 
				     :width width 
				     :height linefeed-height))
		items)
	  (incf x (+ width space-width)))))

     (let ((*print-case* :downcase))
       (push-text-item 'class-name-item class (class-name class) bold)
       (dolist (super (CLOS:class-direct-superclasses class))
	 (push-text-item 'super-name-item super (class-name super) plain))))

     (make-instance 'text
       :gc gc
       :items (nreverse items))))



(defclass update-current-text-item (mouse-interest)
  ((current :initform nil)
   dx
   dy)
  (:default-initargs
   :event-spec '(() :move)))


(defmethod receive-event (viewport (interest update-current-text-item) event)
  (let* ((viewer (viewer viewport))
	 (gc (slot-value viewer 'gc))
	 (choices (lv-viewable-choices viewer))
	 (x (mouse-event-x event))
	 (y (mouse-event-y event)))
    (multiple-value-bind (new new-dx new-dy)
	(block text-item-at-xy
	  (dolist (c choices)
	    (let* ((r (viewer-choice-region c))
		   (x (- x (region-left r)))
		   (y (- y (region-top r))))
	      (dolist (item (slot-value (viewer-choice-object c) 'items))
		(when (region-contains-xy-p (bounding-region item) x y)
		  (return-from text-item-at-xy 
			       (values item (region-left r) (region-top r))))))))

      (flet 
       ((highlight-text-item (item dx dy fg)
	 (let ((br (bounding-region item)))
	   (draw-rectangle viewport 
			   (+ 2 dx (region-left br)) (+ 3 dy (region-top br))
			   (+ 2 (region-width br)) (region-height br)
			   :gc gc 
			   :foreground fg))))

	(with-slots (current dx dy) interest
	  (unless (eq current new)
	    (when current 
	      (highlight-text-item current dx dy (background viewport)))
	    (setf current new dx new-dx dy new-dy)
	    (when new
	      (highlight-text-item current dx dy (foreground viewport)))))))))



;;; The current-item keeps track of the currently selected object.  Current-item
;;; is a update-current-text-item interest, it appears on the interest list of
;;; the viewers viewport and as a slot in the class-viewer.

(defclass class-viewer (exclusive-list-viewer)
  ((gc :type graphics-context)
   (plain :type font :initarg plain)
   (bold :type font :initarg bold)
   (choices :type simple-vector)
   (current-item :type update-current-item)))  

(defmethod current-item ((v class-viewer))
  (slot-value (slot-value v 'current-item) 'current))


(defmethod initialize-instance :around ((cv class-viewer) &rest initargs &key classes &allow-other-keys)
  (with-slots (gc plain bold italic choices current-item) cv
    (setf gc (make-instance 'graphics-context)
          plain (make-instance 'font :family "Lucida" :slant :roman :weight :medium)
	  bold  (make-instance 'font :family "Lucida" :slant :roman :weight :bold)
	  choices (apply #'vector classes)
	  current-item (make-instance 'update-current-text-item))

    (apply #'call-next-method cv 
	   :choices choices 
	   :n-choices (length choices) 
	   :interests (list current-item)
	   initargs)))


(defmethod lv-nth-choice ((cv class-viewer) row)
  (with-slots (gc plain bold choices) cv
    (let ((choice (svref choices row)))
      (if (typep choice 'text)
	  choice
	(setf (svref choices row)
	      (make-class-text choice gc plain bold))))))

(defmethod lv-draw-choice ((cv class-viewer) drawable x y choice row)
  (declare (ignore row))
  (draw-text drawable (+ x 3) (+ y 3) choice))

(defmethod lv-choice-height ((cv class-viewer) choice)
  (+ 6 (region-height (bounding-region choice))))

(defmethod (setf status) ((value (eql :destroyed)) (cv class-viewer))
  (call-next-method)
  (with-slots (gc plain bold) cv
    (dolist (x (list gc plain bold))
      (destroy x))))

(defmethod lv-highlight-choice ((v class-viewer) viewport region choice row operation)
  (declare (ignore viewport region choice row operation)))

(defmethod lv-select-choice ((v class-viewer) canvas x y choice row)
  (declare (ignore canvas choice x y))
  (let ((item (current-item v)))
    (when (and item (typep item 'super-name-item))
      (setf (lv-first-viewable-row v) 
	    (or (position (slot-value item 'object) (slot-value v 'choices))
		row)))))


(defun class-viewer-demo (&rest initargs)
  (let* ((w (make-instance 'base-window :label "Class Viewer" :mapped nil))
	 (br (bounding-region w)))
    (prog1
	(apply #'make-instance 'class-viewer
	  :parent w
	  :width (region-width br)
	  :height (region-height br)
	  :classes (LCL:list-all-classes)
	  initargs)
      (setf (mapped w) t))))
      

