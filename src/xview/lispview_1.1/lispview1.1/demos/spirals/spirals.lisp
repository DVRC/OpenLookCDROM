;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;%W% %G% %U%


;;; LispView Lines Demo
;;; 
;;; USAGE: 
;;; Load this file and then type (make-instance 'demo:line-demo)
;;; Mouse left and drag in the display area to specify the size and orientation 
;;; of a spiral.  Best to set the "Separation" slider to 10 first.  Pressing the 
;;; "Clear" button updates the window background to whatever the value of the 
;;; "Background" setting is.


(in-package "DEMO" :use '("LISP" "CLOS" "LISPVIEW"))

(export '(line-demo))


(defvar spirals-load-directory 
  (make-pathname :directory (pathname-directory LCL:*load-pathname*)))


(defun make-spirals-stipple (data)
  (make-array (list (length data) (length (car data))) :initial-contents data))


(defvar background-colors 
 (list (list :white :black :gray)
       (list (make-array '(4 4) :initial-element 0)
	     (make-array '(4 4) :initial-element 1)
	     (make-spirals-stipple '(#*0111 #*1101 #*1011 #*1110)))))

(defvar foreground-colors
 (list (list :magenta :cyan :blue :green :red)
       (list (make-spirals-stipple '(#*0111 #*1111 #*1101 #*1111)) 
	     (make-spirals-stipple '(#*0111 #*1010 #*1101 #*1010)) 
	     (make-spirals-stipple '(#*1000 #*0101 #*0010 #*0101)) 
	     (make-spirals-stipple '(#*1000 #*0000 #*0010 #*0000)))))


(defclass anchor-spiral (mouse-interest) ()
  (:default-initargs 
   :event-spec '(() (:left :down))))

(defclass drag-spiral-direction (mouse-interest) ()
  (:default-initargs
   :event-spec '((:left) :move)))
  
(defclass draw-spiral (mouse-interest) ()
  (:default-initargs 
   :event-spec '(() (:left :up))))

(defclass repaint-spirals (damage-interest) ())

(defclass line-demo-base-window (base-window)
  ((line-demo :initarg :line-demo))
  (:default-initargs
   :interests (mapcar #'make-instance '(anchor-spiral 
					drag-spiral-direction 
					draw-spiral
					repaint-spirals))))


;;; Each cycle in the spiral is represented as four points, one point
;;; in each of the four vectors - l r u d i.e. "left" "right" "up" "down".

(defstruct spiral 
  npoints
  l r u d ;; vectors of points, points are represented by conses: (x . y)
  line-width
  foreground
  fill-style
  stipple)


(defclass line-demo ()
  (window
   panel
   clear
   foreground
   background
   line-style
   line-width
   gc
   (x-dir :initform 0)
   (y-dir :initform 1)
   (x :initform 0)
   (y :initform 0)
   separation
   (width :initform 100)
   (spirals :initform nil)))

(defstruct (color-choice (:constructor 
			  make-color-choice (color chip fill-style stipple)))
  color 
  chip
  fill-style
  stipple)
  
(defmethod label ((x color-choice)) (color-choice-chip x))


(defun compute-spiral (ld)
  (with-slots ((x-off x) (y-off y) x-dir y-dir foreground line-width separation width) ld
    (let* ((k (sqrt (+ (* x-dir x-dir) (* y-dir y-dir))))
	   (x (/ x-dir k))
	   (y (/ y-dir k))
	   (gap (float (value separation)))
	   (npoints (truncate width gap)))
      (flet 
       ((compute-endpoints (x y)
	  (let ((v (make-array npoints))
		(scale gap))
	    (dotimes (i npoints v)
	      (setf (svref v i) (cons (+ x-off (truncate (* scale x)))
				      (+ y-off (truncate (* scale y)))))
	      (incf scale gap)))))

       (let* ((fg (value foreground))
	      (s (make-spiral 
		   :foreground (color-choice-color fg)
		   :fill-style (color-choice-fill-style fg)
		   :stipple (color-choice-stipple fg)
		   :line-width (value line-width)
		   :npoints npoints
		   :l (compute-endpoints (- y) x)       
		   :u (compute-endpoints x y)	   
		   :r (compute-endpoints y (- x))
		   :d (make-array npoints)))
	      (d (spiral-d s))
	      (scale gap)
	      (dx (* gap (/ (+ (- x) (- y)) 2.0)))
	      (dy (* gap (/ (+ (- y) x) 2.0))))
	   (dotimes (i npoints s)
	     (setf (svref d i) (cons (+ x-off (truncate (+ (* scale (- x)) dx)))
				     (+ y-off (truncate (+ (* scale (- y)) dy)))))
	     (incf scale gap)))))))


(defun draw-spiral (ld spiral)
  (declare (LCL:type-reduce number fixnum))
  (let ((l (spiral-l spiral))
	(r (spiral-r spiral))
	(u (spiral-u spiral))
	(d (spiral-d spiral)))
    (with-slots ((w window) gc background line-width) ld
      (setf (foreground gc) (spiral-foreground spiral)
	    (operation gc) boole-1
	    (fill-style gc) (spiral-fill-style spiral)
	    (stipple gc) (spiral-stipple spiral)
	    (line-width gc) (spiral-line-width spiral))
      (dotimes (i (1- (length l)))
	(draw-line w (car (svref l i)) (cdr (svref l i))
		     (car (svref u i)) (cdr (svref u i)) :gc gc)
	(draw-line w (car (svref u i)) (cdr (svref u i))
		     (car (svref r i)) (cdr (svref r i)) :gc gc)
	(draw-line w (car (svref r i)) (cdr (svref r i))
		     (car (svref d i)) (cdr (svref d i)) :gc gc)
	(draw-line w (car (svref d i)) (cdr (svref d i))
		     (car (svref l (1+ i))) (cdr (svref l (1+ i))) :gc gc)))))


(defun clear-spirals (ld)
  (with-slots ((w window) background gc spirals) ld
    (let ((bg (value background)))
      (with-output-buffering (display w)
        (setf (background w) (color-choice-color bg)
	      (foreground gc) (color-choice-color bg)
	      (operation gc) boole-1
	      (fill-style gc) (color-choice-fill-style bg)
	      (stipple gc) (color-choice-stipple bg)
	      spirals nil)
	(let ((br (bounding-region w)))
	  (draw-rectangle w 0 0 (region-width br) (region-height br) :fill-p t :gc gc))))))


(defun make-color-choices (panel gc color-names stipple-patterns)
  (let* ((display (display panel))
	 (depth (depth panel))
	 (fill-style (setf (fill-style gc) (if (= depth 1) :opaque-stippled :solid))))
    (flet 
     ((create-color-choice (name stipple-pattern)
	(let ((color (find-color :name name :display display))
	      (chip (make-instance 'image :width 16 :height 16 :depth depth))
	      (stipple (make-instance 'image :data stipple-pattern)))
	  (draw-rectangle chip 0 0 16 16 :fill-p t 
			  :gc gc 
			  :foreground color 
			  :stipple stipple)
	  (make-color-choice color chip fill-style stipple))))

     (mapcar #'create-color-choice color-names stipple-patterns))))



(defun spirals-icon ()
  (let ((file (merge-pathnames spirals-load-directory "spiral.icon")))
    (make-instance 'icon 
      :background (lv:find-color :name "lightsteelblue")
      :label (if (probe-file file)
		 (make-instance 'image :filename file :format :sun-icon)
	       "Spirals"))))


(defun spirals-cursor ()
  (let ((image-file (merge-pathnames spirals-load-directory "spiral.cursor"))
	(mask-file (merge-pathnames spirals-load-directory "spiral-mask.cursor")))
    (when (and (probe-file image-file) (probe-file mask-file))
      (make-instance 'cursor
        :image (make-instance 'image :filename image-file :format :sun-icon)
	:mask (make-instance 'image :filename mask-file :format :sun-icon)))))



(defmethod initialize-instance :after ((ld line-demo) &key &allow-other-keys)
  (with-slots (window 
	       panel
	       draw-spiral
	       clear
	       foreground
	       background
	       line-style
	       line-width
	       separation
	       x y
	       gc) ld
	       
     (setf window 
	     (make-instance 'line-demo-base-window 
	       :line-demo ld
	       :label "Draw Spirals"
	       :mapped nil
	       :width 556 :height 436 
	       :icon (spirals-icon))
	       

	   panel 
	     (make-instance 'panel 
	       :parent window 
	       :height 100 
	       :mapped t)

	   gc 
	     (make-instance 'graphics-context
	       :display (display window)
	       :cap-style :projecting
	       :line-width 0)

	   clear
	      (make-instance 'command-button
	        :parent panel 
		:left 102 :top 73 
		:label "Clear"
		:command #'(lambda () (clear-spirals ld)))

	   foreground 
	      (make-instance 'exclusive-setting
		:parent panel
		:label "Foreground:"
		:left 14 :top 6 
		:choices (apply #'make-color-choices panel gc foreground-colors))

	   background 
	      (make-instance 'exclusive-setting
		:parent panel
		:label "Background:"
		:left 11 :top 39 
		:update-value #'(lambda (v)
				  (declare (ignore v))
				  (clear-spirals ld))
		:choices (apply #'make-color-choices panel gc background-colors))

	   line-style
	       (make-instance 'exclusive-setting
		 :parent panel
		 :left 253 :top 6
		 :label "Line Style:"
		 :choices '("Solid" "Dash")
		 :value "Solid"   ;; added by d.w. April 11, 1991
		 :update-value 
		    #'(lambda (v)
			(let ((dash-length (1+ (* 2 (value line-width)))))
			  (setf (line-style gc) (intern (string-upcase v) :keyword)
				(dashes gc) (list dash-length dash-length)))))

	   line-width 
	        (make-instance 'horizontal-slider
		  :parent panel
		  :left 282 :top 44 
		  :label "Width:"
		  :show-value t 
		  :value 13
		  :min-value 0
		  :max-value 25)

	   separation
	        (make-instance 'horizontal-slider
		  :label "Separation:"
		  :parent panel
		  :left 247 :top 73 
		  :show-value t 
		  :value 35
		  :min-value 1
		  :max-value 80))

     (setf (cursor window) (spirals-cursor))
     (clear-spirals ld)

     (make-instance 'message
       :label "pixels" 
       :parent panel
       :left 495 :top 44)
			      
     (make-instance 'message
       :label "Action:" 
       :parent panel
       :label-bold t 
       :left 48 :top 75)
			      
     (make-instance 'message
       :label "pixels" 
       :parent panel
       :left 495 :top 71)
	       
     (setf (mapped window) t)))


(defmethod receive-event (w (i anchor-spiral) e)
  (with-slots (x y x-dir y-dir foreground gc) (slot-value w 'line-demo)
    (with-output-buffering (display w)
      (setf x (mouse-event-x e)
	    y (mouse-event-y e)
	    x-dir x
	    y-dir y
	    (line-width gc) 1
	    (foreground gc) (color-choice-color (value foreground))
	    (fill-style gc) :solid
	    (operation gc) boole-xor))))


(defmethod receive-event (w (i drag-spiral-direction) e)
  (with-slots (x y x-dir y-dir gc) (slot-value w 'line-demo)
    (with-output-buffering (display w)
      (draw-line w x y x-dir y-dir :gc gc)
      (setf x-dir (mouse-event-x e)
	    y-dir (mouse-event-y e))
      (draw-line w x y x-dir y-dir :gc gc))))


(defmethod receive-event (w (i draw-spiral) e)
  (let ((ld (slot-value w 'line-demo)))
    (with-slots (x y x-dir y-dir gc width spirals) ld
      (let* ((dx (- x (mouse-event-x e)))
	     (dy (- y (mouse-event-y e)))
	     (d (sqrt (+ (* dx dx) (* dy dy)))))
	(when (> d 4.0)
	  (setf width (if (> d 5) d 300))
	  (draw-line w x y x-dir y-dir :gc gc)
	  (decf x-dir x)
	  (decf y-dir y)
	  (let ((s (compute-spiral ld)))
	  (push s spirals)
	  (with-output-buffering (display w)
	    (draw-spiral ld s))))))))


(defmethod receive-event (w (i repaint-spirals) e)
  (declare (ignore e))
  (let ((ld (slot-value w 'line-demo)))
    (with-output-buffering (display w)
      (dolist (s (nreverse (copy-list (slot-value ld 'spirals))))
	(draw-spiral ld s)))))


(defmethod (setf bounding-region) (new-br (w line-demo-base-window))
  (with-output-buffering (display w)
    (call-next-method)
    (let ((ld (slot-value w 'line-demo)))
      (when (slot-boundp ld 'panel)
	(with-slots (panel) ld
	  (let ((r (bounding-region panel)))
	    (setf (region-width r) (region-width new-br)
		  (bounding-region panel) r)))))))


(defmethod (setf status) ((value (eql :destroyed)) (w line-demo-base-window))
  (call-next-method)
  (with-slots (gc foreground background) (slot-value w 'line-demo)
    (destroy gc)
    (dolist (choice (append (choices foreground) (choices background)))
      (destroy (color-choice-stipple choice))
      (destroy (color-choice-chip choice)))))


(format t "~%To start this demo type: (make-instance 'demo:line-demo)~%")
