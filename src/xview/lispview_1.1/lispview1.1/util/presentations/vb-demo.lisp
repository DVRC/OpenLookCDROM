;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.


;;; Example use of the presentation framework.  We've defined a subclass of 
;;; presentation called visibox, drawn as a rectangle with an arbitrary border-width, 
;;; that highlights when entered and unhighlights when exited.


(in-package "LISPVIEW")


(defclass visibox (presentation)
  ((region :initarg :region)
   (border-width :initarg :border-width)
   (highlight :initform nil))
  (:default-initargs 
   :border-width 3))

(defmethod contains-xy-p ((vb visibox) x y)
  (region-contains-xy-p (slot-value vb 'region) x y))

(defmethod overlaps-region-p ((vb visibox) r)
  (regions-intersect-p (slot-value vb 'region) r))


(defun draw-visibox (vb)
  (with-slots (canvas region (bw border-width) highlight) vb
     (let ((x (region-left region))
	   (y (region-top region))
	   (width (region-width region))
	   (height (region-height region)))
       (with-output-buffering (display canvas)
         (draw-rectangle canvas x y width height :line-width bw)
	 (draw-rectangle canvas 
			 (+ x bw 3) (+ y bw 3) (- width bw bw 6) (- height bw bw 6)
			 :foreground (if highlight 
					 (foreground canvas) 
				       (background canvas)))))))

(defmethod redraw ((vb visibox))
  (draw-visibox vb))

(defmethod enter ((vb visibox))
  (setf (slot-value vb 'highlight) t)
  (draw-visibox vb))

(defmethod exit ((vb visibox))
  (setf (slot-value vb 'highlight) nil)
  (draw-visibox vb))


;;; Trivial demo for the visibox; returns the presntation-canvas.  
;;; Try 
;;;   (accept presentation-canvas)
;;; or 
;;;   (accept presentation-canvas :predicate #'(lambda (vb) (= (slot-value vb 'border-width) 1)))

(defun vb-demo (&optional (n 100))
  (let* ((window 
	  (make-instance 'base-window 
	    :label "Visibox Hordes"
	    :icon (make-instance 'icon 
			     :background (lv:find-color :name "lightsteelblue")
			     :label (if (probe-file "lispview-app.icon")
					(list "Visibox"
					 (make-instance 'image 
					      :filename "lispview-app.icon"))
					"Visibox List"))
	    :background (find-color :name "bg1" 
				    :if-not-found (find-color :name "white"))
	    :mapped nil))
	 (br (bounding-region window))
	 (width (region-width br))
	 (height (region-height br))
	 (canvas
	  (make-instance 'presentation-canvas
	    :parent window
	    :container-region (make-region :width width :height height)
	    :output-region (make-region :width 2000 :height 2000))))

    (setf (mapped window) t)
    
    (defmethod (setf bounding-region) (new-br (w (eql window)))
      (setf (container-region canvas)
	    (make-region :width (region-width new-br) :height (region-height new-br)))
      (call-next-method))

    (dotimes (i n canvas)
      (insert (make-instance 'visibox 
	        :region (make-region :width (+ 25 (random 75))
				     :height (+ 25 (random 75))
				     :left (random 2000)
				     :top (random 2000))
		:border-width (1+ (random 5)))
	      :at 0 canvas))))







