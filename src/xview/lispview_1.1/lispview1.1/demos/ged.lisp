;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.


;;;@(#)ged.lisp	1.3 6/27/90 10:58:10

;;; USAGE:
;;; Load this file and then type: (make-instance 'demo:ged)
;;;
;;; This is the LispView response to Brad Myers "How fast can you implement this 
;;; graphical editor?" paper.  The paper specifies the simple boxes and arrows 
;;; graphical editor implemented here.  The implementation is incomplete in 
;;; that boxes can't be stretched and arrows can't be selected (or deleted).


(in-package 'demo :use '("LISP" "CLOS" "LISPVIEW"))

(export '(ged))

(defclass interactive-region ()
  ((x1 :initarg :x1 :initform 0)
   (y1 :initarg :y1 :initform 0)
   (x2 :initarg :x2 :initform 0)
   (y2 :initarg :y2 :initform 0)
   (gc :initarg :gc)
   (status :initform :incomplete)))

(defclass rubber-region (interactive-region) ())

(defclass rigid-region (interactive-region)
  ((x0 :initarg :x0)
   (y0 :initarg :y0)))


(defclass rubber-graphics-context (graphics-context)
  ()
  (:default-initargs
   :line-width 0
   :operation boole-xor
   :foreground (make-instance 'color :name "blue")))


(defclass interactive-region-interest (mouse-interest)
  ((interactive-region :initarg :interactive-region)))
    
(defclass anchor-region (interactive-region-interest) ()
  (:default-initargs 
   :event-spec '(() (:left :down))))

(defclass stretch-region (interactive-region-interest) ()
  (:default-initargs
   :event-spec '((:left) :move)))
  
(defclass finish-region (interactive-region-interest) ()
  (:default-initargs 
   :event-spec '(() (:left :up))))



(defmethod receive-event (window (i anchor-region) event)
  (declare (ignore window))
  (with-slots (x1 y1 x2 y2) (slot-value i 'interactive-region)
    (setf x1 (mouse-event-x event)
	  y1 (mouse-event-y event)
	  x2 x1
	  y2 y1)))


(proclaim '(inline draw-rubber-rectangle))

(defun draw-rubber-rectangle (window x1 y1 x2 y2 gc)
  (draw-rectangle window (min x1 x2) (min y1 y2) (abs (- x1 x2)) (abs (- y1 y2)) :gc gc))


(defmethod receive-event (window (i stretch-region) event)
  (with-slots (x1 y1 x2 y2 gc) (slot-value i 'interactive-region)
    (with-output-buffering (display window)
      (draw-rubber-rectangle window x1 y1 x2 y2 gc)
      (setf x2 (mouse-event-x event)
	    y2 (mouse-event-y event))
      (draw-rubber-rectangle window x1 y1 x2 y2 gc))))


(defmethod receive-event (window (i finish-region) event)
  (declare (ignore event))
  (with-slots (x1 y1 x2 y2 gc status) (slot-value i 'interactive-region)
    (draw-rubber-rectangle window x1 y1 x2 y2 gc)
    (setf status :finished))
  (setf (interests window) 
	(delete-if #'(lambda (x) 
		       (typep x 'interactive-region-interest)) 
		   (interests window))))


(defun get-region (window &key (gc (make-instance 'rubber-graphics-context)))
  (let ((rr (make-instance 'rubber-region :gc gc)))
    (setf (interests window)
	  (append (mapcar #'(lambda (class)
			      (make-instance class :interactive-region rr))
			  '(anchor-region stretch-region finish-region))
		  (interests window)))
    (when (typep window 'base-window)
      (setf (left-footer window)
	    "Drag the select mouse button to define a box"))

    (LCL:process-wait "Waiting for rubber band box"
		      #'(lambda ()
			  (or (member (slot-value rr 'status) '(:finished :aborted))
			      (eq (status window) :destroyed))))

    (when (typep window 'base-window)
      (setf (left-footer window) ""))

    (with-slots (x1 y1 x2 y2 status) rr
      (if (eq status :finished)
	  (make-region :left (min x1 x2)
		       :top (min y1 y2)
		       :width (abs (- x1 x2))
		       :height (abs (- y1 y2)))))))


(defun draw-roundtangle (window gc x y w h r)
  (let ((2r (* 2 r)))
    (draw-arc window x y 2r 2r 90 90 :gc gc)
    (draw-line window (+ x r) y (- (+ x w) r) y :gc gc)
    (draw-arc window (- (+ x w) 2r) y 2r 2r 0 90 :gc gc)
    (draw-line window (+ x w) (+ y r) (+ x w) (- (+ y h) r) :gc gc)
    (draw-line window x (+ y r) x (- (+ y h) r) :gc gc)
    (draw-arc window x (- (+ y h) 2r) 2r 2r 180 90 :gc gc)
    (draw-line window (+ x r) (+ y h) (- (+ x w) r) (+ y h) :gc gc)
    (draw-arc window (- (+ x w) 2r) (- (+ y h) 2r) 2r 2r 270 90 :gc gc)))


(defun draw-arrow (window gc x1 y1 x2 y2 r1 r2)
  (let* ((dx (- x2 x1))
	 (dy (- y2 y1))
	 (l (sqrt (+ (expt dx 2) (expt dy 2))))
	 (uvx (/ dx l))
	 (uvy (/ dy l))
	 (xa (+ x1 (truncate (* uvx (- l r1)))))
	 (ya (+ y1 (truncate (* uvy (- l r1)))))
	 (xa1 (truncate (+ xa (* uvy r2))))
	 (ya1 (truncate (+ ya (* (- uvx) r2))))
	 (xa2 (truncate (+ xa (* (- uvy) r2))))
	 (ya2 (truncate (+ ya (* uvx r2)))))
    (draw-line window x1 y1 xa ya :gc gc)
    (draw-line window xa1 ya1 xa2 ya2 :gc gc)
    (draw-line window xa1 ya1 x2 y2 :gc gc)
    (draw-line window xa2 ya2 x2 y2 :gc gc)))


(defclass repaint-ged (damage-interest) ())

(defclass select-gro (mouse-interest) ()
  (:default-initargs
   :event-spec '(() (:left :down))))
  
(defclass drag-gro (mouse-interest) ()
  (:default-initargs
   :event-spec '((:left) :move)))
  
(defclass finish-gro (mouse-interest) ()
  (:default-initargs
   :event-spec '(() (:left :up))))
  

(defclass graphical-editor-base-window (base-window)
  ((graphical-editor :initarg :graphical-editor)
   (mode :initarg mode :initform nil :type '(member nil :drag :stretch))
   (interactive-region :initarg :interactive-region))
  (:default-initargs
   :mapped nil
   :left-footer ""
   :interests (mapcar #'make-instance '(repaint-ged 
					select-gro 
					drag-gro 
					finish-gro))))

(defclass ged ()
  (window 
   panel 
   gc
   rubber-gc
   line-style
   new-box
   delete
   (n :initform 0)
   (display-list :initform nil)))

(defclass graphical-object ()
  ((gc :initarg :gc)
   (style :initarg :style)
   (status :initform :open :accessor status)
   (handles :initform nil)))

(defvar *box-min-width* 50)
(defvar *box-min-height* 50)

(defclass box (graphical-object)
  ((x :initarg :x)
   (y :initarg :y)
   (w :initarg :w)
   (h :initarg :h)
   (r :initform 20)
   (margin :initform 10)
   min-r
   max-r
   (label :initarg :label)))

(defclass arrow (graphical-object)
  ((from :initarg :from)
   (to :initarg :to)
   (r1 :initform 15)
   (r2 :initform 8)))

(defstruct line-style-choice
  style
  chip)

(defmethod label ((x line-style-choice)) (line-style-choice-chip x))

(defun make-line-style-choices (gc w)
  (let ((depth (depth w))
	(background (background w))
	(styles 
	 (list #'(lambda (gc)
		   (setf (solo::line-width gc) 0
			 (line-style gc) :solid))
	       #'(lambda (gc)
		   (setf (solo::line-width gc) 2
			 (line-style gc) :solid))
	       #'(lambda (gc)
		   (setf (solo::line-width gc) 4
			 (line-style gc) :solid))
	       #'(lambda (gc)
		   (setf (solo::line-width gc) 0
			 (line-style gc) :dash)))))
    (mapcar #'(lambda (style)
		(let ((chip (make-instance 'image :width 25 :height 11 :depth depth)))
		  (draw-rectangle chip 0 0 25 11 :foreground background :fill-p t)
		  (funcall style gc)
		  (draw-line chip 2 5 22 5 :gc gc)
		  (make-line-style-choice :style style :chip chip)))
	    styles)))
		      

(defmethod initialize-gro ((gro box))
  (with-slots (x y w h margin min-r max-r handles) gro
    (setf max-r (make-region :left (- x margin) :top (- y margin)
			     :right (+ x w margin) :bottom (+ y h margin))
	  min-r (make-region :left (+ x margin) :top (+ y margin)
			     :right (- (+ x w) margin) :bottom (- (+ y h) margin)))
    (let ((w/2 (truncate w 2))
	  (h/2 (truncate h 2)))
      (setf handles (list (cons x y) (cons (+ x w) y)
			  (cons x (+ y h)) (cons (+ x w) (+ y h))
			  (cons (+ x w/2) y) (cons (+ x w/2) (+ y h))
			  (cons x (+ h/2 y)) (cons (+ x w) (+ h/2 y)))))))

(defmethod initialize-gro ((gro arrow)))


(defmethod initialize-instance :after ((gro graphical-object) &rest initargs)
  (declare (ignore initargs))
  (initialize-gro gro))


(defmethod draw :around (gro window)
  (unless (eq (status gro) :destroyed)
    (with-output-buffering (display window)
      (with-slots (gc style) gro
	(funcall style gc)
	(call-next-method)))))


(defun draw-handles (window gc handles)
  (dolist (handle handles)
    (draw-rectangle window (- (car handle) 4) (- (cdr handle) 4) 8 8 :gc gc :fill-p t)))


(defmethod draw ((gro box) window)
  (with-slots (gc x y w h r handles label status) gro
    (draw-roundtangle window gc x y w h r)
    (let ((font (font gc)))
      (draw-string window 
		   (+ x (truncate (- w (string-width font label)) 2))
		   (+ y (truncate (* 1.5 (font-ascent font))))
		   label
		   :gc gc))
    (when (eq status :selected)
      (draw-handles window gc handles))))


(defmethod draw ((gro arrow) window)
  (with-slots (gc from to r1 r2) gro
    (unless (or (eq (status from) :destroyed) (eq (status to) :destroyed))
      (flet 
       ((center (box)
	  (with-slots (x y w h) box
	    (values (+ x (truncate w 2)) (+ y (truncate h 2))))))

       (multiple-value-call #'draw-arrow window gc (center from) (center to) r1 r2)))))
    

(defun get-new-ged-box (ged rubber-gc)
  (with-slots (window line-style gc n display-list) ged
    (let* ((r (get-region window :gc rubber-gc))
	   (style (line-style-choice-style (value line-style)))
	   (box (make-instance 'box
		  :gc gc
		  :style style
		  :x (region-left r)
		  :y (region-top r)
		  :w (max *box-min-width* (region-width r))
		  :h (max *box-min-height* (region-height r))
		  :label (format nil "Box ~D" (incf n)))))
      (when display-list
	(push (make-instance 'arrow
		:gc gc
		:style style
		:from (car display-list)
		:to box)
	      display-list))
      (push box display-list)
      (send-event window 
		  (make-damage-event
		    :regions (list (bounding-region (or (cadr display-list) 
							(car display-list)))))))))


(defmethod bounding-region ((gro box)) 
  (copy-region (slot-value gro 'max-r)))

(defmethod bounding-region ((gro arrow))
  (with-slots (from to) gro
    (region-bounding-region (slot-value from 'max-r) (slot-value to 'max-r))))


(defmethod gro-selected-p :around (gro x y)
  (declare (ignore x y))
  (unless (eq (status gro) :destroyed)
    (call-next-method)))

(defmethod gro-selected-p ((gro box) x y)
  (with-slots (min-r max-r) gro
     (and (region-contains-xy-p max-r x y)
	  (not (region-contains-xy-p min-r x y)))))

(defmethod gro-selected-p ((gro arrow) x y)
  (declare (ignore x y)))


(defmethod display-list ((window graphical-editor-base-window))
  (slot-value (slot-value window 'graphical-editor) 'display-list))

(defmethod receive-event (window (i repaint-ged) event)
  (declare (ignore event))
  (with-output-buffering (display window)
    (clear window)
    (dolist (gro (display-list window))
      (draw gro window))))



(defmethod receive-event (window (i select-gro) event)
  (let* ((dl (display-list window))
	 (x (mouse-event-x event))
	 (y (mouse-event-y event))
	 (damage nil)
	 (old-sel (find-if #'(lambda (gro) (eq (status gro) :selected)) dl))
	 (new-sel (find-if #'(lambda (gro) (gro-selected-p gro x y)) dl)))
    (if (and (eq old-sel new-sel) old-sel)
	(with-slots (mode interactive-region) window
	  (setf mode :drag)
	  (with-slots (x1 y1 x2 y2 x0 y0 gc) interactive-region
	    (let ((region (bounding-region old-sel)))
	      (setf x1 (region-left region)
		    y1 (region-top region)
		    x2 (region-right region)
		    y2 (region-bottom region)
		    x0 x
		    y0 y)
	      (draw-rubber-rectangle window x1 y1 x2 y2 gc)))
	  (setf (left-footer window) "Drag the select mouse button to move the box"))
      (progn
	(setf (slot-value window 'mode) nil)
	(when old-sel
	  (setf (status old-sel) :open)
	  (push (bounding-region old-sel) damage))
	(when new-sel 
	  (setf (status new-sel) :selected)
	  (push (bounding-region new-sel) damage))
	(send-event window (make-damage-event :regions damage))))))


(defmethod receive-event (window (i drag-gro) event)
  (when (slot-value window 'mode)
    (with-slots (x0 y0 x1 y1 x2 y2 gc) (slot-value window 'interactive-region)
      (with-output-buffering (display window)
	(draw-rubber-rectangle window x1 y1 x2 y2 gc)
	(let ((dx (- (mouse-event-x event) x0))
	      (dy (- (mouse-event-y event) y0)))
	  (setf x0 (mouse-event-x event)
		y0 (mouse-event-y event)
		x1 (incf x1 dx)
		y1 (incf y1 dy)
		x2 (incf x2 dx)
		y2 (incf y2 dy)))
	(draw-rubber-rectangle window x1 y1 x2 y2 gc)))))


(defmethod receive-event (window (i finish-gro) event)
  (declare (ignore event))
  (with-slots (mode interactive-region) window 
    (when mode
      (setf mode nil
	    (left-footer window) "")
      (with-slots (x0 y0 x1 y1 x2 y2 gc) interactive-region
	(draw-rubber-rectangle window x1 y1 x2 y2 gc)
	(let ((sel (find-if #'(lambda (gro) 
				(eq (status gro) :selected)) 
			    (display-list window))))
	  (when sel
	    (with-slots (x y) sel
	      (setf x x1
		    y y1)
	      (initialize-gro sel)
	      (send-event window (make-damage-event :regions (bounding-region window))))))))))


(defun delete-ged-selections (ged)
  (with-slots (window display-list) ged
    (let ((old-sel (find-if #'(lambda (gro) (eq (status gro) :selected)) display-list)))
      (if old-sel
	  (progn
	    (setf (status old-sel) :destroyed)
	    (send-event window (make-damage-event :regions (bounding-region window))))
	(setf (left-footer window) "Select a box or an arrow first")))))



(defmethod initialize-instance :after ((ged ged)
				       &key
				         (label "Graphical Editor Challenge"))
  (with-slots (window 
	       panel
	       gc
	       rubber-gc
	       line-style
	       new-box
	       delete) ged
    (setf gc (make-instance 'graphics-context)

	  rubber-gc (make-instance 'rubber-graphics-context)

	  window 
            (make-instance 'graphical-editor-base-window 
	      :interactive-region (make-instance 'rigid-region :gc rubber-gc)
	      :graphical-editor ged
	      :label label 
	      :icon 
	      (make-instance 'icon 
			     :background (lv:find-color :name "lightsteelblue")
			     :label (if (probe-file "lispview-app.icon")
					(list " GED"
					 (make-instance 'image 
						:filename "lispview-app.icon"))
					" GED")))

	  panel (make-instance 'panel :parent window :height 40)
	  
	  line-style
	    (make-instance 'exclusive-setting
	      :top 10
	      :parent panel
	      :label "Line Style:"
	      :choices (make-line-style-choices gc window))

	  new-box 
	    (make-instance 'command-button
	      :left 275
              :parent panel
	      :label "New Box"
              :command #'(lambda () 
			   (MP:make-process :function #'(lambda () 
							  (get-new-ged-box ged rubber-gc)))))

	  delete
	    (make-instance 'command-button
              :parent panel
	      :label "Delete "
	      :command #'(lambda () (delete-ged-selections ged))))

    (setf (mapped window) t)))



(format t "~%To start this demo type: (make-instance 'demo:ged)~%")

