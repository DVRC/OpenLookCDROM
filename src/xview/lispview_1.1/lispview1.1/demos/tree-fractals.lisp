;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;; USAGE: To start the demo, type: (make-instance 'demo:tree-fractals)


(in-package :demo :use '(lisp clos lispview))

(export '(tree-fractals tree draw-tree))



(defvar tree-fractals-load-directory 
  (make-pathname :directory (pathname-directory LCL:*load-pathname*)))



(defclass tree-frac-mouse-event
          (lv:mouse-interest)
          ((menu :initarg :menu))
          (:default-initargs :event-spec
                             '(nil (:right :down))))

(defmethod lv:receive-event
           (w (i tree-frac-mouse-event)
              event)
           (menu-show (slot-value i 'menu)
                           w
                           :x
                           (mouse-event-x event)
                           :y
                           (mouse-event-y event)))

(defun tree-factory-setting (tree-fractals)
  (setf 
   (value (slot-value tree-fractals 'slider1)) 20
   (value (slot-value tree-fractals 'slider2)) 22
   (value (slot-value tree-fractals 'slider3)) 90
   (value (slot-value tree-fractals 'slider4)) 77
   (value (slot-value tree-fractals 'slider5)) 73
   (value (slot-value tree-fractals 'setting1)) "cadetblue"   
   (value (slot-value tree-fractals 'setting2)) "plum"
   (value (slot-value tree-fractals 'textfield3)) 10
   ))

(defun draw-tree (tree-fractals)
  (apply 'tree (cons (window1 tree-fractals) (list-all-values tree-fractals))))

(defun list-all-values (tree-fractals)
  (let (temp)
  (mapcan #'(lambda(x y)
	      (list y (if (stringp (setq temp (value 
					       (slot-value tree-fractals x))))
			  (read-from-string temp)
			  temp)))
	  '(slider1 slider2 slider3 slider4 slider5 
		    setting1 setting2 textfield3)
	  '(:direction-left :direction-right :direction :growth-left
			   :growth-right
			   :bark-color :leaf-color :leaf-size))))

(defparameter *x-pos* 0)
(defparameter *y-pos* 0)
(proclaim '(type fixnum *x-pos* *y-pos*))

(proclaim '(inline sind cosd))    
(defun sind (degrees)
  (declare (float degrees))
  (sin (* degrees (/ pi 180.0))))

(defun cosd (degrees)
  (declare (float degrees))
  (cos (* degrees (/ pi 180.0))))

(defparameter *last-leaf-gc* nil)
(defparameter *last-bark-gc* nil)
(defparameter *last-leaf-color* nil)
(defparameter *last-bark-color* nil)

;; This is the original definition without optimization
;; which can be automated in most cases with the utility "with-fast-output"
;; found in the util/with-fast-output directory.
#+ignore(defun tree (canvas &key
		   (bark-color :brown)
		   (leaf-color :green)
		   (leaf-size 5)
		   initial-stem 
		   stem-width
		   (growth-left 70)
		   (growth-right 70)
		   (direction 90)
		   (direction-left 15)
		   (direction-right 15)
		   &allow-other-keys)
  (let* ((b (bounding-region canvas))
	 (width (region-width b))
	 (height (region-height b))
	 (stem-thickness (or stem-width (- (isqrt width) 3)))
	 (bark-gc (if (eq bark-color *last-bark-color*)
		      *last-bark-gc*
		      (setq *last-bark-gc* 
			    (make-instance 'graphics-context 
				 :line-width stem-thickness
				 :foreground 
				 (find-color :name (setq *last-bark-color*
							 bark-color))))))
	 (leaf-gc (if (eq leaf-color *last-leaf-color*)
		      *last-leaf-gc*
		      (setq *last-leaf-gc* 
			    (make-instance 'graphics-context 
				 :foreground 
				 (find-color :name (setq *last-leaf-color* 
							 leaf-color)))))))
    (go-back (round width 2) (- height 10))
    (with-output-buffering (display canvas)
	(clear canvas)
	(drawfrac canvas
		  (float (or initial-stem (* (min width height) 0.25)))
		  (/ growth-left 100.0) 
		  (/ growth-right 100.0)
		  (float stem-thickness)
		  (+ 90.0 (- 180.0 direction)) 
		  (float direction-left) (float direction-right)
		  (float (max leaf-size 1)) 
		  bark-gc 
		  leaf-gc 
		  0 0)
	)))


;; This is the original definition without optimization
#+ignore(defun drawfrac (canvas initial-stem growth-left growth-right
		 stem-width direction direction-left direction-right
		 leaf-size bark-gc leaf-gc x y)
  (declare (float leaf-size initial-stem stem-width growth-left growth-right
		  direction direction-left direction-right)
	   (fixnum x y)
	   (function sind (float) float)
	   (function cosd (float) float)
	   (inline sind cosd)
	   (function round (float) fixnum))
  (cond ((< initial-stem leaf-size) nil)
        (t (setq x *x-pos*) 
           (setq y *y-pos*)
	   ;  Assume the current position for *x-pos* & *y-pos* in the
	   ;  canvas to be correct.
	   ;  After drawing, updates the position to reflect the 
	   ;  point that has just been drawn to.
	   
	   (when (> stem-width 2.0) 
	     (setq stem-width (* stem-width .66))
	     (setf (line-width bark-gc) (round stem-width)))
	   (when (< stem-width 2.0)
	     (setq bark-gc leaf-gc)
	     (setq stem-width 2.0))
	   (draw-line canvas *x-pos* *y-pos*
			   (setq *x-pos* (+ *x-pos*
					    (round (* initial-stem 
						      (sind direction)))))
			   (setq *y-pos*  (+ *y-pos*
					     (round (* initial-stem 
						       (cosd direction)))))
			   :gc bark-gc)	   
	   (drawfrac canvas (* initial-stem growth-left) 
		     growth-left growth-right
                     stem-width
                     (+ direction direction-left) 
                     direction-left direction-right
		     leaf-size
                     bark-gc leaf-gc x y)
	   (drawfrac canvas (* initial-stem growth-right) 
		     growth-left growth-right
                     stem-width
                     (- direction direction-right) 
                     direction-left direction-right
		     leaf-size
                     bark-gc leaf-gc x y)
           (go-back x y))))

(defun tree (canvas &key
		   (bark-color :brown)
		   (leaf-color :green)
		   (leaf-size 5)
		   initial-stem 
		   stem-width
		   (growth-left 70)
		   (growth-right 70)
		   (direction 90)
		   (direction-left 15)
		   (direction-right 15)
		   &allow-other-keys)
  (let* ((b (bounding-region canvas))
	 (width (region-width b))
	 (height (region-height b))
	 (stem-thickness (or stem-width (- (isqrt width) 3)))
	 (bark-gc (if (eq bark-color *last-bark-color*)
		      *last-bark-gc*
		      (setq *last-bark-gc* 
			    (make-instance 'graphics-context 
				 :line-width stem-thickness
				 :foreground 
				 (find-color :name (setq *last-bark-color*
							 bark-color))))))
	 (leaf-gc (if (eq leaf-color *last-leaf-color*)
		      *last-leaf-gc*
		      (setq *last-leaf-gc* 
			    (make-instance 'graphics-context 
				 :foreground 
				 (find-color :name (setq *last-leaf-color* 
							 leaf-color))))))
	 (xvo (lispview::device canvas))
	 (dsp (lispview::xview-object-dsp xvo))
	 (xid (lispview::xview-object-xid xvo))
	 (bark-xgc (lispview::xview-object-xid (device bark-gc)))
	 (leaf-xgc (lispview::xview-object-xid (device leaf-gc)))
	 )



    (go-back (round width 2) (- height 10))
    (xv:with-xview-lock
     (with-output-buffering (display canvas)
       (clear canvas)
	 (drawfrac xid
		    dsp
		  (float (or initial-stem (* (min width height) 0.25)))
		  (/ growth-left 100.0) 
		  (/ growth-right 100.0)
		  (float stem-thickness)
		  (+ 90.0 (- 180.0 direction)) 
		  (float direction-left) (float direction-right)
		  (float (max leaf-size 1))
		  bark-gc
		  leaf-gc
		  bark-xgc 
		  leaf-xgc 
		  0 0)
	))))



(defun drawfrac (xid dsp initial-stem growth-left growth-right
		 stem-width direction direction-left direction-right
		 leaf-size bark-gc leaf-gc bark-xgc leaf-xgc x y)
  (declare (float leaf-size initial-stem stem-width growth-left growth-right
		  direction direction-left direction-right)
	   (fixnum x y)
	   (function sind (float) float)
	   (function cosd (float) float)
	   (inline sind cosd)
	   (function round (float) fixnum))
  (cond ((< initial-stem leaf-size) nil)
        (t (setq x *x-pos*) 
           (setq y *y-pos*)
	   ;  Assume the current position for *x-pos* & *y-pos* in the
	   ;  canvas to be correct.
	   ;  After drawing, updates the position to reflect the 
	   ;  point that has just been drawn to.
	   
	   (when (> stem-width 2.0) 
	     (setq stem-width (* stem-width .66))
	     (setf (line-width bark-gc) (round stem-width)))
	   (when (< stem-width 2.0)
	     (setq bark-gc leaf-gc
		   bark-xgc leaf-xgc)
	     (setq stem-width 2.0))

	   (x11:xdrawline dsp xid bark-xgc
			  *x-pos* *y-pos*
			   (setq *x-pos* (+ *x-pos*
					    (round (* initial-stem 
						      (sind direction)))))
			   (setq *y-pos*  (+ *y-pos*
					     (round (* initial-stem 
						       (cosd direction)))))
			  )	   
	   (drawfrac xid dsp (* initial-stem growth-left) 
		     growth-left growth-right
                     stem-width
                     (+ direction direction-left) 
                     direction-left direction-right
		     leaf-size
                     bark-gc leaf-gc bark-xgc leaf-xgc x y)
	   (drawfrac xid dsp (* initial-stem growth-right) 
		     growth-left growth-right
                     stem-width
                     (- direction direction-right) 
                     direction-left direction-right
		     leaf-size
                     bark-gc leaf-gc bark-xgc leaf-xgc x y)
           (go-back x y))))


(defun go-back (a b)
  (setq *x-pos* a)
  (setq *y-pos* b))


(format t "To begin this demo, type:
  (make-instance 'demo:tree-fractals)~%")

;;; This file produced by GLV

(defclass tree-fractals
          nil
          ((window1 :accessor window1) (menu1 :accessor menu1)
                                       (popup1 :accessor popup1)
                                       (controls2 :accessor controls2)
                                       (slider3 :accessor slider3)
                                       (message1 :accessor message1)
                                       (slider1 :accessor slider1)
                                       (message2 :accessor message2)
                                       (slider2 :accessor slider2)
                                       (message3 :accessor message3)
                                       (slider4 :accessor slider4)
                                       (message7 :accessor message7)
                                       (slider5 :accessor slider5)
                                       (message8 :accessor message8)
                                       (setting1 :accessor setting1)
                                       (setting2 :accessor setting2)
                                       (textfield3 :accessor textfield3)
                                       (message6 :accessor message6)
                                       (button3 :accessor button3)
                                       (button4 :accessor button4)))


(defun tree-fractals-icon ()
  (let ((file (merge-pathnames tree-fractals-load-directory "fractal.icon")))
    (make-instance 'icon
		   :background (lv:find-color :name "lightsteelblue")
		   :label (if (probe-file file)
			      (make-instance 'image :filename file)
			      "Trees"))))


(defmethod initialize-instance
           :after
           ((tree-fractals tree-fractals) &rest args)
           (with-slots
             (window1 menu1
                      popup1
                      controls2
                      slider3
                      message1
                      slider1
                      message2
                      slider2
                      message3
                      slider4
                      message7
                      slider5
                      message8
                      setting1
                      setting2
                      textfield3
                      message6
                      button3
                      button4)
             tree-fractals
             (setf 
                   menu1
                   (make-instance 'menu
                                  :choices
                                  (list
                                    (make-instance 'command-menu-item
                                                   :label
                                                   "Draw Tree"
                                                   :command
                                                   #'(lambda ()
						       (draw-tree tree-fractals)))
                                    (make-instance 'command-menu-item
                                                   :label
                                                   "Props..."
                                                   :command
                                                   #'(lambda nil
                                                      (setf (mapped popup1) t))))
                                  :choices-ncols
                                  1
                                  :pushpin
                                  nil)
		   window1
                   (make-instance 'base-window
                                  :mapped
                                  nil
                                  :closed
                                  nil
                                  :show-resize-corners
                                  t
                                  :icon (tree-fractals-icon)
                                  :interests
                                  (list (make-instance 
					 'tree-frac-mouse-event
					 :menu menu1))
                                  :width
                                  364
                                  :height
                                  262
                                  :label
                                  "Tree Fractals")
                   popup1
                   (make-instance 'popup-window
                                  :mapped
                                  nil
                                  :show-resize-corners
                                  nil
                                  :pushpin
                                  :in
                                  :owner
                                  window1
                                  :width
                                  366
                                  :height
                                  313
                                  :label
                                  "Tree Fractals: Properties")
                   controls2
                   (make-instance 'panel
                                  :left
                                  0
                                  :top
                                  0
                                  :width
                                  366
                                  :height
                                  313
                                  :parent
                                  popup1)
                   slider3
                   (make-instance 'horizontal-slider
                                  :value
                                  90
                                  :min-value
                                  9
                                  :max-value
                                  140
                                  :slider-length
                                  100
                                  :show-endboxes
                                  nil
                                  :show-range
                                  nil
                                  :show-value
                                  t
                                  :nticks
                                  0
                                  :left
                                  33
                                  :top
                                  16
                                  :width
                                  258
                                  :height
                                  15
                                  :layout
                                  :horizontal
                                  :label
                                  "Direction Up:"
                                  :parent
                                  controls2)
                   message1
                   (make-instance 'message
                                  :label-bold
                                  nil
                                  :left
                                  295
                                  :top
                                  16
                                  :width
                                  47
                                  :height
                                  13
                                  :label
                                  "degrees"
                                  :parent
                                  controls2)
                   slider1
                   (make-instance 'horizontal-slider
                                  :value
                                  20
                                  :min-value
                                  5
                                  :max-value
                                  50
                                  :slider-length
                                  100
                                  :show-endboxes
                                  nil
                                  :show-range
                                  nil
                                  :show-value
                                  t
                                  :nticks
                                  0
                                  :left
                                  92
                                  :top
                                  43
                                  :width
                                  199
                                  :height
                                  15
                                  :layout
                                  :horizontal
                                  :label
                                  "Left:"
                                  :parent
                                  controls2)
                   message2
                   (make-instance 'message
                                  :label-bold
                                  nil
                                  :left
                                  295
                                  :top
                                  43
                                  :width
                                  47
                                  :height
                                  13
                                  :label
                                  "degrees"
                                  :parent
                                  controls2)
                   slider2
                   (make-instance 'horizontal-slider
                                  :value
                                  22
                                  :min-value
                                  5
                                  :max-value
                                  50
                                  :slider-length
                                  100
                                  :show-endboxes
                                  nil
                                  :show-range
                                  nil
                                  :show-value
                                  t
                                  :nticks
                                  0
                                  :left
                                  83
                                  :top
                                  70
                                  :width
                                  208
                                  :height
                                  15
                                  :layout
                                  :horizontal
                                  :label
                                  "Right:"
                                  :parent
                                  controls2)
                   message3
                   (make-instance 'message
                                  :label-bold
                                  nil
                                  :left
                                  295
                                  :top
                                  70
                                  :width
                                  47
                                  :height
                                  13
                                  :label
                                  "degrees"
                                  :parent
                                  controls2)
                   slider4
                   (make-instance 'horizontal-slider
                                  :value
                                  77
                                  :min-value
                                  50
                                  :max-value
                                  85
                                  :slider-length
                                  100
                                  :show-endboxes
                                  nil
                                  :show-range
                                  nil
                                  :show-value
                                  t
                                  :nticks
                                  0
                                  :left
                                  40
                                  :top
                                  108
                                  :width
                                  251
                                  :height
                                  15
                                  :layout
                                  :horizontal
                                  :label
                                  "Growth Left:"
                                  :parent
                                  controls2)
                   message7
                   (make-instance 'message
                                  :label-bold
                                  nil
                                  :left
                                  295
                                  :top
                                  108
                                  :width
                                  46
                                  :height
                                  13
                                  :label
                                  "percent"
                                  :parent
                                  controls2)
                   slider5
                   (make-instance 'horizontal-slider
                                  :value
                                  73
                                  :min-value
                                  50
                                  :max-value
                                  85
                                  :slider-length
                                  100
                                  :show-endboxes
                                  nil
                                  :show-range
                                  nil
                                  :show-value
                                  t
                                  :nticks
                                  0
                                  :left
                                  83
                                  :top
                                  132
                                  :width
                                  208
                                  :height
                                  15
                                  :layout
                                  :horizontal
                                  :label
                                  "Right:"
                                  :parent
                                  controls2)
                   message8
                   (make-instance 'message
                                  :label-bold
                                  nil
                                  :left
                                  295
                                  :top
                                  132
                                  :width
                                  46
                                  :height
                                  13
                                  :label
                                  "percent"
                                  :parent
                                  controls2)
                   setting1
                   (make-instance 'abbreviated-exclusive-setting
                                  :value
                                  "cadetblue"
                                  :choices-nrows
                                  1
                                  :choices-ncols
                                  0
                                  :choices
                                  (list "red"
                                        "blue"
                                        "magenta"
                                        "green"
                                        "cyan"
                                        "cadetblue"
                                        "plum")
                                  :left
                                  30
                                  :top
                                  168
                                  :width
                                  197
                                  :height
                                  23
                                  :layout
                                  :horizontal
                                  :label
                                  "Color of Bark:"
                                  :parent
                                  controls2)
                   setting2
                   (make-instance 'abbreviated-exclusive-setting
                                  :value
                                  "plum"
                                  :choices-nrows
                                  1
                                  :choices-ncols
                                  0
                                  :choices
                                  (list "red"
                                        "blue"
                                        "magenta"
                                        "green"
                                        "cyan"
                                        "cadetblue"
                                        "plum")
                                  :left
                                  89
                                  :top
                                  192
                                  :width
                                  138
                                  :height
                                  23
                                  :layout
                                  :horizontal
                                  :label
                                  "Leaf:"
                                  :parent
                                  controls2)
                   textfield3
                   (make-instance 'numeric-field
                                  :value
                                  10
                                  :displayed-value-length
                                  4
                                  :stored-value-length
                                  80
                                  :min-value
                                  5
                                  :max-value
                                  25
                                  :left
                                  38
                                  :top
                                  220
                                  :width
                                  166
                                  :height
                                  15
                                  :layout
                                  :horizontal
                                  :label
                                  "Leaf Length:"
                                  :parent
                                  controls2)
                   message6
                   (make-instance 'message
                                  :label-bold
                                  nil
                                  :left
                                  215
                                  :top
                                  220
                                  :width
                                  36
                                  :height
                                  13
                                  :label
                                  "pixels"
                                  :parent
                                  controls2)
                   button3
                   (make-instance 'command-button
                                  :command
                                  #'(lambda ()
				      (draw-tree tree-fractals))
                                  :left
                                  96
                                  :top
                                  268
                                  :width
                                  81
                                  :height
                                  19
                                  :label
                                  "Draw Tree"
                                  :parent
                                  controls2)
                   button4
                   (make-instance 'command-button
                                  :command
                                  #'(lambda() 
				      (tree-factory-setting tree-fractals))
                                  :left
                                  184
                                  :top
                                  268
                                  :width
                                  109
                                  :height
                                  19
                                  :label
                                  "Factory Setting"
                                  :parent
                                  controls2))
             (setf (mapped popup1) t)
             (setf (mapped window1) t)))
