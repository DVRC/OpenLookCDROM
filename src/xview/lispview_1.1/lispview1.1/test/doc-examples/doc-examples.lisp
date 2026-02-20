;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;; Example code from the LispView Documentation

(in-package 'LV)

(defparameter *alltests-doc* '(intro-doc
			       draw-stuff
			       draw-button
			       create-doc
			       regions-doc 
			       display-doc
			       canvases-doc
			       cursors-doc 
			       fonts-doc
			       images-doc
			       color-doc
			       input-doc
			       input-2-doc
			       output-doc
			       toolkit-doc
			       windows-doc 
			    ;;  scrolling-windows-doc  ;; obsolete
			       buttons-menus-doc
			       cmd-menu-doc
			       settings-doc
			       text-doc
			       appendix-a
			       draw-a))

(defun test (&optional (test-list *alltests-doc*))
  (mapcar #'(lambda(f) 
	      (format t "~%************* ~A *************~%" f)
	      (funcall f))
	  test-list)
  (format t "~%Done~%"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chapter 1  Introduction
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun intro-doc ()

  (make-instance 'LV:display :host "defun")
  (setq first-window (make-instance 'LV:base-window
				    :label "Open the Pod Bay Doors, Hal..."
				    :left-footer "Transcendental"
				    :right-footer "Dental Rental"))
  (setf (LV:label first-window) "I can't do that, Dave.")
  (setf (LV:left-footer first-window) "Mental"
	(LV:right-footer first-window) "Cheap Thrill")
  
  (let ((br (LV:bounding-region first-window)))
    (format t "~S is ~Dx~D; its edges are ~D, ~D, ~D, ~D%"
	    first-window
	    (LV:region-width br)
	    (LV:region-height br)
	    (LV:region-left br)
	    (LV:region-right br)
	    (LV:region-top br)
	    (LV:region-bottom br)
	    ))
)

(defun draw-stuff ()
  (let* ((br (LV:bounding-region first-window))
	 (x (truncate (LV:region-width br) 2))
	 (y (truncate (LV:region-height br) 2)))
    (LV:clear first-window)
    (LV:draw-rectangle first-window (- x 50) (- y 50) 100 100
		       :line-style :dash :dashes '(3 3))
    (LV:draw-arc first-window (- x 50) (- y 50) 100 100 0 360)
    (LV:draw-arc first-window (- x 40) (- y 40) 80 80 0 360 :line-width 5)
    (LV:draw-arc first-window (- x 20) (- y 20) 40 40 0 360 :fill-p t)))


(defun draw-button ()
  (let ((br (LV:bounding-region first-window)))
    (setq control-panel
	  (make-instance 'LV:panel
			 :parent first-window
			 :left 0
			 :top 0
			 :width (LV:region-width br)
			 :height (truncate (LV:region-height br) 4))))

  (setq doit-button (make-instance 'LV:command-button
				   :parent control-panel
				   :command 'draw-stuff
				   :label "Just Do It"))

  (setf (LV:command doit-button)
	#'(lambda () (draw-stuff) (print "Done it.")))

  (setq doit-more (make-instance 'LV:menu-button
				 :parent control-panel
				 :label "Just Do It Over and Over"
				 :menu (make-instance 'LV:menu
						      :menu-spec
						      '(("Do" draw-stuff)
							("Do" draw-stuff)
							("Do" draw-stuff)
							("Da" draw-stuff)
							("Da" draw-stuff))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chapter 2  Rapid Prototyping
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;  (defun report-val (win sl)
;;    (draw-string win 40 80
;;  	       (format nil "Slider value is ~A" (value sl)))) 
;;  
;;  (report-val window1 slider1)
;;  runs with DevGuide


(defclass my-exclusive-setting (exclusive-setting) () )
(defmethod initialize-instance :after
  ((x my-exclusive-setting)
   &rest initargs)
  (declare (ignore initargs))
  (let ((choices (choices x)))
    (setf (value x) (nth (truncate (length choices) 2) choices))))


;; user-data (:class my-exclusive-setting)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chapter 3 Creating and Destroying Lisp View Objects
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun create-doc ()
  (setq base-window (make-instance 'base-window
				   :label "Example Base Window"
				   :bounding-region (make-region :width 400 :height 200)
				   :mapped t))

  (setf (label base-window) "Sample Example Base Window")

  (defclass labeled-base-window (base-window) ()
	(:default-initargs :label "Canonical Sample Example Label"))
 
  (defmethod initialize-instance :after	((w labeled-base-window) 
					 &key (x 0) (y 0) (w 100) (h 100)
					 &allow-other-keys)
    (setf (bounding-region w) (make-region :left x :top y :width w :height h))
    (setf (bounding-region w) (make-region :left 10 :top 10 :width 80 :height 80)))
  
  (defmethod initialize-instance :around (object &key status &allow-other-keys)
    (call-next-method)                         ;; initialization
    (when (eq status :realized) 
      (setf (status object) :realized)))       ;; realization

  (defmethod (setf status) ((value (eql :realized)) (object base-window))
    (call-next-method)
    (format t "~s is realized~%" object))
)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chapter 4  Regions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun regions-doc ()
  (setq r (make-region :left 10 :top 10 :width 100 :height 100))
  (region-bottom r)
  (setf (region-bottom r :move) 120)
  (setf (region-bottom r :stretch) 200)
  )

;; eval  r
;;  (- (region-right r) (region-left r))
;;  (region-width r)
;;  (region-height r) 
;;  (- (region-bottom r) (region-top r))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chapter 5 Display
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun display-doc ()
  (if *default-display*
      (format t ";;; displays-doc must be run before creating a display")
      (progn
	(setq ilanga-display
	      (make-instance 'display 
			     :platform XView 
			     :host "defun" 
			     :screen 0))

	(setq *window* (make-instance 'window :display ilanga-display :mapped t))
	
	(supported-depths *default-display*)
	
       	(setq my-display (display *window*))
	(with-output-buffering my-display
	  (dotimes (i 100)
	    (draw-line *window* 0 0 (- 100 i) i)))

	(clear *window*)

	(with-output-buffering my-display
	  (dotimes			(i 100)
	    (draw-line *window* 0 0 (- 100 i) i)
	    (when (= 0 (mod i 10))
	      (flush-output-buffer my-display))))

	(let ((root (root-canvas *default-display*)))
	  (setq foo (make-instance 'window 
			 :parent root
			 :bounding-region (bounding-region root)))
	  (sleep 1)
	  (destroy foo)
	))))



(defun print-panic-message (canvas message x y)
	(without-output-buffering (display canvas)
		(draw-string canvas x y message)))

;; eval (print-panic-message *window* "message" 100 100)
;;      (flush-output-buffer *default-display*)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chapter 6  Canvases
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun canvases-doc ()
  (setq parent (make-instance 'base-window))
  (setq child1 (make-instance 'window :parent parent))
  (setq child3 (make-instance 'window :parent parent))

  (print (insert child3 :before child1 parent))
  (print (withdraw child3 parent))
  (setq canvas parent)
  (let ((r (bounding-region canvas)))
	(setf (region-left r) 0
	      (region-top r) 0
	      (bounding-region canvas) r))

  (setq c (make-instance 'opaque-canvas 
			 :background (find-color :name :black)
			 :parent (make-instance 'base-window 
						:width 100 :height 100
						:label "Flicker" :mapped t)))
 
  (dotimes (i 20)
    (setf (mapped c) nil) 
    (setf (mapped c) t))

  (defun expose (canvas) (insert canvas :after nil (parent canvas)))

  (defun bury (canvas) (insert canvas :before nil (parent canvas)))

)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chapter 7  Cursors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun cursors-doc ()
  (setq canvas (make-instance 'base-window :label "Cursors" 
			    :width 200 :height 200))
  (setq hourglass-cursor-image
	(make-instance 'image
		       :filename "/usr/include/images/hglass.cursor" 
		       :format :sun-icon))

  (setq hour-glass-cursor
	(make-instance 'cursor :image hourglass-cursor-image))
 
  (setq gumby-cursor
	(make-instance 'cursor :name "xc-gumby"))
  (setf (cursor canvas) gumby-cursor)

  (setq hour-glass-cursor
	(make-instance 'cursor :image hourglass-cursor-image
		       :foreground :red
		       :background :blue)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chapter 8  Font
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun fonts-doc ()
  (setq font (make-instance 'font))
  (char-metrics font (char-code #\g))
  (char-width (char-metrics font (char-code #\g)))



    (let ((cache (make-array 256)))
  	(dotimes (code 256 cache)
  	  (multiple-value-bind (cm exists)
  	       (char-metrics font code)
  	     (setf (svref cache code) (if exists (char-width cm) 0)))))) 

;;    (apply #'+ (mapcar #'(lambda(c)
;;  			  (char-width (char-metrics font (char-code c))))
;;  		     (subseq string start end)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chapter 9  Images
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun images-doc ()
  (setq shine 
	(make-instance 'image 
		       :data (make-array '(8 9) 
					 :element-type 'bit
					 :initial-contents
					 '(#*000110011
					   #*001100110
					   #*011001100
					   #*110011000
					   #*000110011
					   #*001100110
					   #*011001100
					   #*110011000))))


  (setq *icon* (make-instance 'image
			      :filename "/usr/include/images/compose.icon"
			      :format :sun-icon))

  (setq *rhine* (make-instance 'image
			       :filename "rhine.xbm"
			       :format :x-bitmap))

  (setq *image-window* (make-instance 'base-window
				      :width 550
				      :height 350
				      :label "Image View"
				      :mapped t))
  
  (let ((ibr (bounding-region *rhine*))
	(wbr (bounding-region *image-window*)))
    (copy-area *rhine* *image-window*
	        ;; adjust coords for new image [deviation from manual]
	        ;; (- (region-width ibr) (region-width wbr)) 0
	        0 0
		(region-width wbr) (region-height wbr)
		0 0))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chapter 10 Color
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun color-doc ()
  (setq canvas (make-instance 'base-window :label "Color"
			      :bounding-region (make-region :width 150 :height 50)))
  (setq *red* (make-instance 'color :name :red))

  (setq gc (make-instance 'graphics-context :foreground *red*))
  (draw-line canvas 10 10 100 100 :gc gc)
  (draw-line canvas 10 10 100 100 :foreground *red*))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chapter 11   Input
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun input-doc ()
  (setq canvas (make-instance 'window :width 150 :height 50))

  (setq button-left-down 
	(make-instance 'mouse-interest
		:event-spec '(() (:left :down))))
 
  (push button-left-down (interests canvas))



  (defmethod receive-event (canvas (interest (eql button-left-down)) event)
    (format t "button left down on canvas ~S" canvas))

  (setq *button-name-synonyms* 
	(append *button-name-synonyms* '((:red .  :button0)
					 (:blue .  :button1)
					 (:yellow .  :button2))))

;;    (defmethod deliver-event (object interest event)
;;      (setf (event-object event) object
;;  	  (event-interest event) interest)
;;      (queue-put (event-handler object) event))
  
  (defclass drawing (canvas) ())

  (defclass toggle-mode (mouse-interest) ()
    (:default-initargs
     :event-spec '(() (:left :down))))
 
  (defmethod initialize-instance :after ((d drawing) &rest args)
    (push (make-instance 'toggle-mode) (interests d)))
 
  (defmethod receive-event (drawing (interest toggle-mode) event)
	(print 'hello))
)

(defun send-event (object event)
  (let ((interest (match-event object event)))
      (when interest
	(deliver-event object interest event))))

(defun input-2-doc ()
  (defstruct (info-event (:include event)) information)
  (defmethod match-event (object (event info-event))
	:info-event-interest)
  (defmethod receive-event (object (i (eql :info-event-interest)) event)
    (format t "~S received the following: ~S"
	    object
	    (info-event-information event)))
  
;;    (defstruct (damage-event (:include event))
;;      regions)
;;   
;;    (defstruct (keyboard-event (:include event))
;;      x y char)
;;   
;;    (defstruct (mouse-event (:include event))
;;      x y gesture)
;;  
;;    (setf (keyboard-focus from-canvas) to-canvas)

  (defclass update-cursor (keyboard-focus-interest) ())

  (defclass test (base-window) ()
    (:default-initargs
     :keyboard-focus-mode :globally-active
     :interests (mapcar #'make-instance
			'(keyboard-interest update-cursor))))



  (defmethod receive-event (canvas (i update-cursor) event)
    (case (keyboard-focus-event-focus event)
      (:in
       (draw-rectangle canvas 20 20 30 30
		       :fill-p t
		       :foreground (foreground canvas)))
      (:out
       (draw-rectangle canvas 21 21 28 28
		       :fill-p t
		       :foreground (background canvas)))
      (:take
       ;; Setting the keyboard focus here generates new keyboard-focus-events
       (setf (keyboard-focus (display canvas)) canvas))))

;;  (deliver-event (virtual-keyboard-focus window-system-focus) interest event)

  (setq i (make-instance 'mouse-interest
			 :event-spec '(((:others (or :up :down)))
				       ((or :left :right :middle) (or :up :down)))))

  (push i (interests canvas))


  (defmethod receive-event (window (interest (eql i)) event)
    (print (multiple-value-list (MOUSE-EVENT-GESTURE event)))))



(defun poll-mouse (window)
  (loop
   (multiple-value-bind (x y modifiers)
       (mouse-state *default-display* window)
     (when (member :control modifiers)
       (return))
     (draw-rectangle window x y 10 10)))


  (defmethod virtual-keyboard-focus ((x canvas))
    (if (eq (keyboard-focus x) x)
	x
	(virtual-keyboard-focus (keyboard-focus x))))

  (defmethod virtual-keyboard-focus ((x display))
    (let ((display-focus (keyboard-focus display)))
      (if display-focus
	  (virtual-keyboard-focus display-focus))))
)



;; (poll-mouse canvas)
;; press the Control Key to stop the poll-mouse function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chapter 12  Output
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun output-doc ()
  (setq drawable (make-instance 'window :width 550 :height 550))

  (setq gc (make-instance 'graphics-context))
  (with-graphics-context (gc
			  :line-width 4
			  :dashes '(5 10 5 15)
			  :line-style :dash)
    (draw-line drawable 10 20 30 90 :gc gc)
    (incf (line-width gc) 2)
    (draw-line drawable 20 50 30 10 :gc gc))

  (graphics-context (display drawable))
  (setq my-canvas drawable)

  (draw-rectangles my-canvas '((10 10 100 100) (60 60 100 100)) #'values-list)



  (with-graphics-context (gc :line-width 5
				:join-style :round)
    (dotimes (i 500) 
      (draw-rectangle my-canvas i i 50 50 :gc gc)))

  (dotimes (i 500) 
    (draw-rectangle my-canvas i i 50 50
		    :gc gc
		    :line-width 5
		    :join-style :round))
  
  (clear my-canvas)

  (draw-rectangles my-canvas 
		   (let ((l nil))
		     (dotimes (i 500 (nreverse l))
		       (push (list i i 50 50) l)))
		   #'values-list
		   :gc gc 
		   :line-width 5 
		   :join-style :round)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chapter 13  Toolkit Overview
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun toolkit-doc ()
  (let* ((bw (make-instance 'base-window :label "Overview" :height 300))
	 (p (make-instance 'panel :parent bw)))
    (defstruct color-choice name (r 0.0) (g 0.0) (b 0.0))
    (defmethod label ((x color-choice)) (color-choice-name x))
    (make-instance 'exclusive-setting :parent p
		 :choices (list (make-color-choice :name "red" :r 1.0)
				(make-color-choice :name "blue" :b 1.0)
				(make-color-choice :name "green" :g 1.0)))

;;      (defmethod label ((x T) (princ-to-string x)))
;;      (defmethod label ((x string)) x)
;;      (defmethod label ((x image)) x)

    (setq scrolling-list (make-instance 'exclusive-scrolling-list :parent p))
    (setf (choices scrolling-list) '("just one choice"))
    (setq button (make-instance 'command-button :label "Top Button" :parent p))
    (setf (mapped button) nil)
    (setf (state button) :inactive)
  
    (setq w (make-instance 'base-window)
	  p (make-instance 'panel :parent w)
	  b1 (make-instance 'command-button
			    :label "Top Button"
			    :parent p)
	  b1-br (bounding-region b1)
	  b2 (make-instance 'command-button
			    :parent p
			    :label "Bottom Button"
			    :left (region-left b1-br) 
			    :top (+ 10 (region-bottom b1-br))))
))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chapter 14  Windows and Icons
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun windows-doc ()
  (setq bw (make-instance 'base-window 
			  :parent (root-canvas *default-display*)
			  :label "Bass Rattles Base Window"
			  :left-footer "left over here"
			  :right-footer "right over here"))

  (setq pw1 (make-instance 'popup-window :width 20 :height 20))
  (setq pw2 (make-instance 'popup-window :width 20 :height 20))
  (setq pw3 (make-instance 'popup-window :width 20 :height 20))
  (setq pw4 (make-instance 'popup-window :width 20 :height 20))
  (setq pw5 (make-instance 'popup-window :width 20 :height 20))
  (dolist (w (list pw1 pw2 pw3 pw4 pw5)) (setf (owner w) bw))

  (setq foo (make-instance 'base-window 
			   :label "My Base Window Confirms Quits"
			   :mapped t
			   :confirm-quit #'(lambda (w)
					    (MP:with-scheduling-inhibited
					     (yes-or-no-p (format nil "Really quit ~S?" w))))))
  
  (setq icon (make-instance 'icon :label "My Icon"))

  (setq w (make-instance 'base-window 
			 :icon icon 
			 :label "This window has an icon"
			 :width 500 :height 200 ))

  (setf (icon w) (make-instance 'icon :label "New Icon"))


)

#|  ############
The following example is obsolete.  In LispView 1.1, use viewports
with scrollbars instead of scrolling windows.
[See "doc-additional-examples.lisp"]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chapter 15  Scrolling Windows
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun scrolling-windows-doc ()
  (setq sw 
	(make-instance 'scrolling-window
		:parent (make-instance 'base-window
				       :label "Scrolling Window Example"
				       :width 272 :height 122)
		:output-region (make-region :width 1000 :height 1000) 
		:view-region (make-region :width 250 :height 100) 
		:vertical-scrollbar (make-instance 'vertical-scrollbar)
		:horizontal-scrollbar (make-instance 'horizontal-scrollbar)))

  (setq vp (car (viewports sw)))

  (view-region vp)

  (setf	(repaint vp)
	#'(lambda (vp &rest regions)
	    (let ((r (output-region vp)))
	      (draw-string vp (truncate (region-width r) 2)
			   (truncate (region-height r) 2)
			   "The view is great from here."))))

 
  (let ((vr (view-region vp)))	  ;; Programmatically scroll to a point 
	(setf (region-top vr) 450 ;; where the entire message will be visible
	      (region-left vr) 450 
	      (view-region vp) vr))

  (defmethod view-min ((vp viewport) (sb vertical-scrollbar))
    (region-top (output-region vp)))


  (let ((r (view-region vp)))
    (setf (region-top r) 100
	  (view-region vp) r))


;;;(defun my-repainter (viewport &rest damaged-regions) ...)


  (defclass text-viewport (viewport)
    ((line-height :initform 25)))



  (defmethod compute-view-start ((client text-viewport)
				 (scrollbar vertical-scrollbar)
				 (motion (eql :line-forward))
				 point)
    (declare (ignore point))
    (+ (view-start client scrollbar) (slot-value client 'line-height)))


  (defmethod scroll (client scrollbar motion new-view-start)
    (declare (ignore motion))
    (setf (view-start client scrollbar) new-view-start))

  (defclass line-master (base-window)
    ((scrollbar :type vertical-scrollbar)
     (line-height :initform 20)
     (first-line :initform 0)
     (last-line :initform 300)
     (n-lines :initform 20))
    (:default-initargs
     :width 300
     :label "Line Meister"
     :left-footer "Initializing..."))


  (defmethod initialize-instance :after ((lm line-master) &rest initargs)
    (with-slots (scrollbar line-height n-lines) lm
		(let ((height (* line-height n-lines))
		      (width (region-width (bounding-region lm))))
		  (setf scrollbar (make-instance 'vertical-scrollbar
						 :top 0  :right width
						 :height height
						 :client lm
						 :parent lm
						 :mapped t)
			(bounding-region lm)
			(make-region :width width :height height)))))


  
  (defmethod view-start ((lm line-master) (sb vertical-scrollbar))
    (slot-value lm 'first-line))

  (defmethod view-length ((lm line-master) (sb vertical-scrollbar))
    (slot-value lm 'n-lines))

  (defmethod view-min ((lm line-master) (sb vertical-scrollbar))
    0)

  (defmethod view-max ((lm line-master) (sb vertical-scrollbar))
    (slot-value lm 'last-line))

  (defmethod (setf view-start) (value (lm line-master)(sb vertical-scrollbar))
    (clear lm)
    (with-slots (line-height first-line n-lines) lm
		(setf first-line value)
		(dotimes (n (1+ n-lines))
		  (draw-string lm 10 (* n line-height)
			        (format nil "Line ~D" (+ first-line n))))
		(setf (left-footer lm)
				(format nil "Aligned ~D to ~D."
					first-line
					(1- (+ first-line n-lines))))))
;;    (defmethod receive-event (canvas interest (event scroll-event))
;;      (declare (ignore interest))
;;      (scroll canvas (scroll-event-scrollbar event)
;;  	    (scroll-event-motion event)
;;  	    (scroll-event-view-start event)))

  (setq sw 
	(make-instance 'scrolling-window
		       :parent (make-instance 'base-window
					      :width 272 :height 122
					      :label "Scrolling Window Example")
		       :output-region (make-region :width 1000 :height 1000) 
		       :view-region (make-region :width 250 :height 100) 
		       :vertical-scrollbar (make-instance 'vertical-scrollbar)
		       :horizontal-scrollbar (make-instance 'horizontal-scrollbar)
		       :repaint #'(lambda (viewport &rest ignore)
				    (draw-string viewport 500 500 "Hello World"))))
  
  (setq font (make-instance 'font :family "Courier" :point-size 24))
  (setq vp (viewport sw))
  (draw-string vp 400 400 "This is a bigger font" :font font)
  (setf (repaint vp) #'(lambda (viewport &rest ignore)
			 (draw-string viewport 500 500 "Hello World" :font font)))
  (view-region vp)
  (setq r (output-region vp))
  (setf (region-width r) 500 (output-region vp) r)
)

############### |#

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Chapter 16 Buttons and Menus
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun buttons-menus-doc ()
  (setq bw (make-instance 'base-window :width 256 :height 130 :mapped t)
	p (make-instance 'panel :parent bw :width 256 :height 130 :mapped t)
	cmd-button1 (make-instance
		     'command-button :parent p :label "Push Me" :mapped t))

  (setf (command cmd-button1) #'(lambda () (print "I'm Impressed")))
  (setq menu-button1 (make-instance 'menu-button :parent p :label "Reveal Menu"))



    (setq cmd-menu1 (make-instance 'menu :menu-spec
  				 '(("choice1" (lambda () (print "one")))
  				   ("choice2" (lambda () (print "two")))
  				   ("choice3" (lambda () (print "free"))))))
    (setf (menu menu-button1) cmd-menu1)
    (setq submenu1 
  	(make-instance 'submenu-item 
  		       :label "sub menu"
  		       :menu (make-instance 'menu :choices
  					    (list (first (choices cmd-menu1))))))
  (setq cmd-menu2 
  	(make-instance 'menu :choices (cons submenu1 (rest (choices cmd-menu1)))))
    (setf (menu menu-button1) cmd-menu2)
  )
  

(defun cmd-menu-doc ()
  (let ((b1 (make-instance 'command-button :parent p :label " Activate "))
	(b2 (make-instance 'command-button :parent p :label "Dummy"
			   :state :inactive)))
    (setf (command b1) #'(lambda ()
			   (if (eq (state b2) :active)
			       (progn 
				 (setf (state b2) :inactive)
				 (setf (label b1) " Activate "))
			       (progn 
				 (setf (state b2) :active)
				 (setf (label b1) "Deactivate"))))))
  (make-instance 'menu :menu-spec
		 '(("free-food" free-food)
		   ("free-drinks" free-drinks)
		   ("free-money" free-money)
		   ("free-dumb" freedom)))
  
  (make-instance 'menu :menu-spec
		 '(("submenu" :menu (("submenu1.1" :menu
				      (("cmd1.1.1" (lambda () (print "1.1.1")))))))))
  

  (defclass popup-my-menu (mouse-interest) ()
    (:default-initargs
     :event-spec '(() (:right :down))))
 
  (defun bf () (print "TubbaBubba"))
 

  (setf window (make-instance 'base-window 
			      :label "Menu On The Right"
			      :interests (list (make-instance 'popup-my-menu)))
	*my-menu* (make-instance 'menu
				 :label "Right Menu" 
				 :menu-spec '(("Bubba" bf) ("NuthaBubba" bf)
					      ("RubbaBubba" bf))))


 
  (defmethod receive-event (window (i popup-my-menu) event)
    (menu-show *my-menu* window
	       :x (mouse-event-x event)
	       :y (mouse-event-y event)))



  (defvar *switch* :off)

  (let ((on-choices
	 (list (make-instance 'command-menu-item
			      :label "on"
			      :command #'(lambda () (setq *switch* :on)))))
	(off-choices (list (make-instance 'command-menu-item
					  :label "off"
					  :command #'(lambda () (setq *switch* :off))))))
    (make-instance 'menu
		   :label "Toggle *switch*"
		   :choices #'(lambda ()
				(if (eq *switch* :on)
				    off-choices
				    on-choices)))))


(defun prompts ()
  (notice-prompt :message "Are you sure you want to Quit?"
		 :choices '(("Confirm" t) ("Cancel" t)))

  (notice-prompt :message "Remove this annoying notice"
		 :choices '((:yes "Yes, of course" t) (:no "No" nil)))



  (setq window (make-instance 'base-window :label "Notice Me"))

  (notice-prompt :choices '(("Whinny" :in) ("Outing" :out))
		 :owner window
		 :x 50 :y 100))



;;  eval (prompts)  needs confirmation

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chapter 17  Settings, Sliders, and Scrolling Lists
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun settings-doc ()
  (setq bw (make-instance 'base-window)
		p (make-instance 'panel :parent bw)
		excl-setting (make-instance 'exclusive-setting :parent p
					    :label "Stumbling Down"
					    :choices '("Stairs" "Chairs" "Pianos"))
		slider (make-instance 'horizontal-slider
				      :parent p
				      :min-value 5 :max-value 95)
		scrolling-list (make-instance 'non-exclusive-scrolling-list 
					      :parent p
					      :choices *features*))
  (value excl-setting)
  (value slider)
  (value scrolling-list)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chapter 18  Text, Numeric Fields, and Messages
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun text-doc ()
  (setq bw (make-instance 'base-window :width 300 :height 100 :mapped t)
		p (make-instance 'panel :parent bw :width 300 :height 100)
		message (make-instance 'message :parent p :label "Massage")
		text-field (make-instance 'text-field :parent p :label "Anything")
		numeric-field (make-instance 'numeric-field :parent p :label "Number")))



;; eval the following after input has been typed
;;  (value text-field)
;;  (value numeric-field))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Appendix A   A Complete Example
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun appendix-a ()

  (defclass demo ()
    ((base-window :accessor demo-base-window)
     (control-panel :accessor demo-control-panel)
     (drawing-window :accessor demo-drawing-window)
     (line-cmd-button :accessor demo-line-cmd-button)
     (line-width-typein :accessor demo-line-width-typein))
    (:default-initargs
     :label (format nil "Solo Demo on ~A" (machine-instance))
     :base-window-class 'base-window
     :control-panel-class 'panel
     :drawing-window-class 'window
     :top 100
     :left 100
     :width 333
     :height 333))


  (defmethod initialize-instance :after ((d demo) 
					 &rest initargs
					 &key
                                         base-window-class
                                         control-panel-class
                                         drawing-window-class 
					 &allow-other-keys)
  
    (let* ((bw (setf (demo-base-window d)
		     (apply #'make-instance base-window-class
			    :mapped nil
			    initargs)))
	 
	   (br (bounding-region bw))
	   (cp (setf (demo-control-panel d)
		     (make-instance control-panel-class
				    :parent bw
				    :mapped t       
				    :width (region-width br)
				    :height 33))))

      (setf (demo-drawing-window d)
	    (make-instance drawing-window-class
			   :parent bw
			   :parent bw
			   :mapped t
			   :top 35
			   :left 0
			   :border-width 1
			   :width (region-width br)
			   :height (- (region-height br) 33)))


      (setf (demo-line-cmd-button d)
	    (make-instance 'command-button
			   :parent cp
			   :label "Draw a Line"))

      (setf (demo-line-width-typein d)
	    (make-instance 'numeric-field
			   :parent cp
			   :min-value 1
			   :max-value 25
			   :label "Line Width"))


      (setf (mapped bw) t)))

  (setq *demo* (make-instance 'demo :platform XView)))



(defun draw-a ()
  (defmethod draw-demo-line ((d demo) window)
    (declare (ignore args))
    (clear window)
    (let ((br (bounding-region window)))
      (draw-line window
		 0 0 (region-width br) (region-height br)
		 :line-width (value (demo-line-width-typein d)))))

  (let ((d *demo*))
    (setf (command (demo-line-cmd-button d))
			#'(lambda ()
			    (draw-demo-line d (demo-drawing-window d))))

    (defclass redraw-demo-line (damage-interest)
      ((demo :accessor demo :initarg :demo)))

    #|
    (push (make-instance 'redraw-demo-line) 
	  (interests (demo-drawing-window *demo*)))
     |#
    (push (make-instance 'redraw-demo-line :demo *demo*) 
	  (interests (demo-drawing-window *demo*)))
    

    (defmethod receive-event (window (i redraw-demo-line) damage-event)
      (declare (ignore damage-event))
      (draw-demo-line (demo i) window))

    (defclass better-demo (demo)
      ((x1 :accessor demo-line-x1 :initform 0)
       (y1 :accessor demo-line-y1 :initform 0)
       (x2 :accessor demo-line-x2 :initform 0)
       (y2 :accessor demo-line-y2 :initform 0))
      (:default-initargs
       :label (format nil "A Better LispView Demo on ~A" (machine-instance))))

    (defmethod initialize-instance :after ((d better-demo) &rest args)
      (declare (ignore args))
      (setf (command (demo-line-cmd-button d))
			#'(lambda ()
			    (draw-demo-line d (demo-drawing-window d))))
      (setf (interests (demo-drawing-window d))
			(append (interests (demo-drawing-window d))
				(list (make-instance 'redraw-demo-line :demo d)
				       (make-instance 'set-demo-line-x1y1 :demo d)
				       (make-instance 'set-demo-line-x2y2 :demo d)))))

    (defmethod draw-demo-line ((d better-demo) w)
      (declare (ignore args))
      (clear w)
      (draw-line w (demo-line-x1 d) (demo-line-y1 d)
		 (demo-line-x2 d) (demo-line-y2 d)
		 :line-width (value (demo-line-width-typein d))))

    (defclass set-demo-line-x1y1 (mouse-interest)
      ((demo :accessor demo :initarg :demo))
      (:default-initargs :event-spec '(() (:left :down))))
 
    (defclass set-demo-line-x2y2 (mouse-interest)
      ((demo :accessor demo :initarg :demo))
       (:default-initargs :event-spec '(() (:middle :down))))

    (defmethod receive-event (drawing-window (i set-demo-line-x1y1) event)
      (let ((d (demo i)))
	(setf (demo-line-x1 d) (mouse-event-x event))
	(setf (demo-line-y1 d) (mouse-event-y event))
	(draw-demo-line d drawing-window)))
 
    (defmethod receive-event (drawing-window (i set-demo-line-x2y2) event)
      (let ((d (demo i)))
	(setf (demo-line-x2 d) (mouse-event-x event))
	(setf (demo-line-y2 d) (mouse-event-y event))
	(draw-demo-line d drawing-window)))))


;;; Eval this after evaling (progn (appendix-a) (draw-a))
;;; (setq *demo2* (make-instance 'better-demo))
