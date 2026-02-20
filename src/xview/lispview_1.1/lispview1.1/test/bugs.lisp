;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)bugs.lisp	1.6 10/17/91


(in-package "LISPVIEW-TEST")

(defmethod x11-get-geometry ((x drawable))
  (let ((foreign-pointers nil))
    (flet 
     ((make-return-fp (type) 
	(car (push (malloc-foreign-pointer :type (list :pointer type)) 
		   foreign-pointers))))

     (let* ((xvo (device x))
	    (xid (xview-object-xid xvo))
	    (dsp (xview-object-dsp xvo))
	    (root (make-return-fp 'X11:Window))
	    (x (make-return-fp 'X11:int))
	    (y (make-return-fp 'X11:int))
	    (width (make-return-fp 'X11:unsigned-int))
	    (height (make-return-fp 'X11:unsigned-int))
	    (border-width (make-return-fp 'X11:unsigned-int))
	    (depth (make-return-fp 'X11:unsigned-int))
	    (status (XV:with-xview-lock 
		      (X11:XGetGeometry dsp xid root x y width height border-width depth))))
       (multiple-value-prog1
	   (if status
	       (let ((bw2 (* 2 (foreign-value border-width))))
		 (list 
		  :bounding-region 
		     (make-region 
		       :left (foreign-value x)
		       :top (foreign-value y)
		       :width (+ (foreign-value width) bw2)
		       :height (+ (foreign-value height) bw2))
		  :depth (foreign-value depth) 
		  :border-width (foreign-value border-width)
		  :root (foreign-value root)))
	     (warn "XGetGeometry failed"))
	 (map nil #'free-foreign-pointer foreign-pointers))))))



;;; Non interactive tests for LispView/XView bugs that have been fixed or will be.



(def-bug-test read-image-pixmap-depth-bug ()
  (
   :synopsis "Pixmaps created by reading X bitmap file aren't always depth 1"
   :fixed  "SCCS version 1.2 of xview/xloadimage/lv-send.c"
  )

  (let* ((bitmap-filename "test-bitmap.xbm")
	 (image (make-instance 'image :filename bitmap-filename))
	 (pl (x11-get-geometry image)))
    (unwind-protect
	(unless (and (= (depth image) 1) (= (getf pl :depth) 1))
	  (error "(make-instance 'image :filename ~S) failed, bitmap depth ~S, pixmap depth ~S~%"
		 bitmap-filename
		 (depth image)
		 (getf pl :depth)))
      (destroy image))))
    
			      

(def-bug-test char-metrics-invalid-type-bug ()
  (
   :synopsis "Char-metrics returns invalid type (nil) for undefined glyphs."
   :fixed "SCCS version 2.3 of src/xview-font.lisp"
  )

  (let ((f (make-instance 'font)))
    (flet 
     ((check-char-metrics (x type existing/non-existing code)
	(unless (typep x type)
	  (error "with font ~S, char-metrics returns ~S, which isn't typep ~S, for ~S glyph ~S"
		 f x type existing/non-existing (code-char code)))))

      (unwind-protect 
	  (dotimes (i char-code-limit)
	    (multiple-value-bind (cm exists)
		(char-metrics f i)
	      (if exists 
		  (check-char-metrics cm 'char-metrics "an existing" i)
		(check-char-metrics cm 'zero-char-metrics "a non-existing" i))))
	(destroy f)))))



(def-bug-test panel-has-nil-depth-bug ()
  (
   :synopsis "panel has depth = nil"
   :fixed "SCCS version 2.15 of src/xview-canvas.lisp"
  )

  (with-paneled-base-window (p :label "Test: panel-has-nil-depth-bug")
     (unless (integerp (depth p))
       (error "panel depth, ~S, should be an integer" (depth p)))))



(def-bug-test viewport-background-default-initarg-ignored-bug ()
  (
   :synopsis "Viewport background (color) default initarg ignored."
   :fixed "in LispView version 1.1"
  )

  (defclass test-vp-bg-color-default-initarg (viewport) () 
    (:default-initargs 
     :background (find-color :name "green")))

  (let* ((w (make-instance 'base-window :label "Test viewport-background-color-ignored-bug"))
	 (v (make-instance 'test-vp-bg-color-default-initarg :parent w)))
    (unwind-protect
	(unless (string-equal (name (background v)) "green")
	  (error "~S default initarg :background failed, background is ~S, should be ~S"
		 (type-of v)
		 (background v)
		 (find-color :name "green")))
      (destroy w))))



(def-bug-test available-font-creation-bug ()
  (
   :synopsis "Applying make-instance to an element of the list returned by available-fonts fails"
   :fixed "SCCS version 1.16 of src/font.lisp"
  )

  (let ((initargs (car (available-fonts :point-size 12 :max-matches 1))))
    (if initargs
	(let ((font (apply 'make-instance 'font initargs)))
	  (unless (typep font 'font)
	    (error "Applying make-instance to an element of the list returned by available-fonts, ~S, failed"
		   initargs))
	  (destroy font))
      (warn "available-font-creation-bug test aborted: couldn't find a 12 point font"))))




(def-bug-test non-existant-glyph-char-metrics-bug ()
  (
   :synopsis "The char metrics for non-existent glyphs don't return 0."
   :fixed "SCCS version 2.3 of src/xview-font.lisp"
  )

  (let* ((initargs '(:name "cursor"))
	 (f (apply #'make-instance 'font initargs)))
    (unwind-protect
	(if (and (< (max-char-code f) char-code-limit)       ;; There aren't glyphs for every char

		 (multiple-value-bind (cm exists)            ;; This glyph DOES exist
		     (char-metrics f (1- (max-char-code f)))
		   (declare (ignore cm))
		   exists)

		 (multiple-value-bind (cm exists)            ;; This glyph doesn't
		     (char-metrics f (1+ (max-char-code f)))
		   (declare (ignore cm))
		   (null exists)))

	    (let ((cm (char-metrics f (1+ (max-char-code f)))))
	      (unless (and (= 0 (char-left-bearing cm))
			   (= 0 (char-right-bearing cm))
			   (= 0 (char-width cm))
			   (= 0 (char-ascent cm))
			   (= 0 (char-descent cm)))
		(error "with font ~S, all char-metrics, ~S,  for non existant glyph, ~S, should be 0"
		       f cm (code-char (1+ (max-char-code f))))))
	  (warn "non-existant-glyph-char-metrics-bug test aborted, ~S doesn't specify a font with undefined glyphs"
		initargs))
      (destroy f))))



(def-bug-test damage-interests-dropped-bug ()
  (
   :synopsis "initial damage interests dropped"
   :fixed "in LispView version 1.1"
  )	     

  (let ((w (make-instance 'base-window :label "Test damage-interests-dropped-bug"))
	(i (make-instance 'damage-interest))
	(e (make-damage-event)))
    (push i (interests w))
    (defmethod receive-event (w (i (eql i)) event) (declare (ignore event)) (destroy w))
    (send-event w e)
    (sleep 1) (unless (eq (status w) :destroyed) (sleep 4))
    (unless (eq (status w) :destroyed)
      (unwind-protect
	  (error "interest ~S for ~S failed to match ~S" i w e)
	(destroy w)))))
      

(def-bug-test monochrome-black-white-bug ()
  (
   :synopsis "on monochrome displays, window default foreground and background are white"
   :fixed "Lispview version 1.1 in src/xview-canvas.lisp"
  )	    

  (let ((w (make-instance 'base-window)))
    (unwind-protect
	(unless (and (string-equal (name (background w)) "white")
		     (string-equal (name (foreground w)) "black"))
	  (error "~S foreground and background aren't black and white" w))
      (destroy w))))



(def-bug-test exclusive-scrolling-list-value-bug ()
  (
   :synopsis "Setting the value of an exclusive-scrolling-list with selection required fails."
   :fixed "Lispview version 1.1 in src/xview-item.lisp"
  )

  (with-paneled-base-window (p :label "Test exclusive-scrolling-list-value-bug")
    (let ((sl (make-instance 'exclusive-scrolling-list 
		:parent p 
		:choices '(alpha beta gamma) 
		:selection-required t)))
      (check-accessor value sl 'alpha)
      (check-accessor value sl 'beta)
      (check-accessor value sl 'gamma))))



(def-bug-test popup-bounding-region-unmapped-bug  ()
  (
   :synopsis "(setf bounding-region) of a popup before it is mapped causes its left top to be off by the size of the popups frame"
   :lispview-bugid 1043700
   :Fixed "Lispview version 1.1"
  )

  (let* ((base-window 
	  (make-instance 'base-window 
	    :left 100 
	    :top 100
	    :label "Test popup-bounding-region-unmapped-bug"))
	 (popup 
	  (make-instance 'popup-window 
	    :owner base-window 
	    :mapped nil 
	    :width 100 
	    :height 100))
	 (br (bounding-region popup)))

    (setf (region-left br) 100 
	  (region-top br) 100 
	  (bounding-region popup) br
	  (mapped popup) t
	  br (bounding-region popup))

    (unwind-protect
	(unless (and (= 100 (region-left br))
		     (= 100 (region-top br)))
	  (error "popup bounding-region, ~S, is wrong, left,top should be 100,100"))
      (destroy base-window))))



(def-bug-test closed-windows-bug ()
  (
   :synopsis "top level windows break on (setf closed) T"
   :fixed "LispView version 1.1"
  )

  (let* ((w (make-instance 'base-window :label "Test: closed-windows-bug"))
	 (p (make-instance 'popup-window :owner w :mapped t)))
    (unwind-protect
	(progn
	  (check-accessor closed w t)
	  (sleep 3)	;; give windows time to close.
	  
	  (unless (and (closed w) (closed p))
	    (error "The value of closed for ~S and ~S should be T" w p))
	  (check-accessor closed w nil)
	  (when (or (closed w) (closed p))
	    (error "The value of closed for ~S and ~S should be NIL" w p)))
      (destroy w))))


(def-bug-test window-children-initarg-bug ()
  (
   :synopsis "window :children initarg fails"
   :fixed "LispView version 1.1"
  )

  (let ((base-window (make-instance 'base-window :label "Test window-children-initarg-bug"))
	(root-window (root-canvas *default-display*)))
    (unwind-protect
	(dolist (window-class *window-classes*)
	  (when (or (eq window-class 'viewport) (subtypep window-class 'opaque-canvas))
	    (let* ((children (list (make-instance 'window)))
		   (parent 
		    (make-instance window-class
		      :label (format nil "Test window-children-initarg-bug ~S" window-class)
		      :children children
		      :parent (if (subtypep window-class 'top-level-window) 
				  root-window
				base-window))))
	      (independent-test
	       (unwind-protect 
		   (unless (equal (children parent) children)
		     (error "children of ~S are ~S, supposed to be ~S"
			    parent (children parent) children))
		 (destroy parent))))))

      (destroy base-window))))



(def-bug-test panel-with-nil-parent-fails-bug ()
  (
   :synopsis "Creating a panel whose parent is NIL fails"
   :fixed  "SCCS version 3.22 of src/xview-canvas.lisp"
  )

  (let ((p (make-instance 'panel :parent nil))
	(w (make-instance 'base-window :label "panel-with-nil-parent-fails-bug")))

    (unwind-protect 
	(progn
	  (unless (null (parent p))
	    (error "Parent of ~S, ~S, should be NIL" p (parent p)))
	  (setf (parent p) w)
	  (unless (eq (parent p) w)
	    (error "Parent of ~S, ~S, should be ~S" p (parent p) w)))
      (progn
	(destroy w)
	(destroy p)))))


(def-bug-test panel-item-foreground-ignored-bug ()
  (
   :synopsis "foreground of a panel item ignored if set before the the item was realized"
   :fixed "SCCS version 3.6 of src/xview-item.lisp"
   :interactive t
  )

  (defclass plum-button (command-button) ())
  
  (defmethod initialize-instance :after ((x plum-button) &rest initargs) 
    (declare (ignore initargs))
    (setf (foreground x) (find-color :name "plum" :display (display x))))

  (let* ((w (make-instance 'base-window :mapped nil :label "Plum Colored Button Label" ))
	 (p (make-instance 'panel :parent w))
	 (b (make-instance 'plum-button :parent p :label "I should be kind of purplish")))

    (defmethod (setf status) ((value (eql :destroyed)) (window (eql w)))
      (destroy (foreground b))
      (call-next-method))

    (setf (mapped w) t)
    (unwind-protect
	(unless (yes-or-no-p "Is the button label plum colored?")
	  (error "panel-item-foreground-ignored-bug failed"))
      (destroy w))))



(def-bug-test mouse-interest-up-events-only-bug ()
  (
   :synopsis "Expressing interest in mouse up events ONLY fails"
   :fixed  "SCCS version 3.8 of src/xview-input.lisp"
   :bugtraq 1043702
   :interactive t
  )

  (let* ((i (make-instance 'mouse-interest :event-spec '(() (:left :up))))
	 (l "mouse-interest-up-events-only-bug")
	 (w (make-instance 'base-window :label l :interests (list i)))
	 (x nil))

    (defmethod receive-event (w (i (eql i)) e)
      (declare (ignore w))
      (multiple-value-bind (modifiers action)
	  (mouse-event-gesture e)
	(declare (ignore modifiers))
	(setf x (eq (cadr action) :up))))

    (format t "Mouse left in the window labeled ~S and then type return here " l)
    (force-output)
    (read-line)
    (unwind-protect 
	(unless x 
	  (error "~S failed to select/match a mouse up transition" i))
      (destroy w))))



(def-bug-test keyboard-interest-matches-too-much-bug ()
  (
   :synopsis "Many keys, e.g. shift, are unexpectedly reported as #\null"
   :fixed  "SCCS version 3.27 of src/xview-input.lisp"
   :interactive t
  )

  (let* ((i (make-instance 'keyboard-interest))
	 (w (make-instance 'base-window 
	      :label "keyboard-interest-matches-too-much-bug"
	      :interests (list i)
	      :keyboard-focus-mode :passive)))
    (flet 
     ((find-keysym (event keysyms)
	(find  (keyboard-event-keysym event) keysyms
			 :test #'=
			 :key #'symbol-value)))

     (defmethod receive-event (w (i (eql i)) e)
       (declare (ignore w))
       (let ((keysym (or (find-keysym e X11:latin-1-keysyms)
			 (find-keysym e X11:keyboard-keysyms))))
	 (format t "char: ~S, Keysym: ~A, ~S, modifiers: ~S,  ~D,~D~%"
		 (keyboard-event-char e)
		 (if keysym 
		     (format nil "~S [~D]" keysym (symbol-value keysym))
		   "")
		 (keyboard-event-action e)
		 (keyboard-event-modifiers e)
		 (keyboard-event-x e)
		 (keyboard-event-y e))))

     (format t "Verify that the correct char, keysym, and modifiers are being reported~%")
     (format t "Be sure to check shift, control, and meta modified keys~%")

     (unwind-protect
	 (unless (yes-or-no-p "Are keyboard events being reported properly?")
	   (error "keyboard-interest-matches-too-much-bug failed"))
       (destroy w)))))

	 

(def-bug-test change-parent-canvas-insert-bug ()
  (
   :synopsis "Changing a canvas' parent with insert fails to change XView parent"
   :fixed  "SCCS version 3.14 of src/canvas.lisp"
  )

  (let* ((w1 (make-instance 'base-window :label "change-parent-canavs-insert [1/2]"))
	 (w2 (make-instance 'base-window :label "change-parent-canvas-insert [2/2]"))
	 (p (make-instance 'panel :parent w1)))
    (insert p :after nil w2)
    (unwind-protect
	(unless (= (xview-object-id (device w2))
		   (xv-get (xview-object-id (device p)) :win-parent))
	  (error "change-parent-canvas-insert failed"))
      (map nil #'destroy (list w1 w2 p)))))
    


	 

