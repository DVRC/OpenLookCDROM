;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;%W% %G%


(in-package "LISPVIEW")


(defmethod dd-initialize-cursor ((p XView) cursor &rest initargs)
  (declare (dynamic-extent initargs))

  (setf (device cursor) (apply #'make-xview-cursor :allow-other-keys t initargs)
	(slot-value cursor 'status) :initialized))



(defclass openlook-cursor-font (font) ()
  (:default-initargs
   :family "open look cursor"
   :point-size 12
   :foundry "sun"))

(defun find-openlook-cursor-font (display)
  (let ((fonts (display-fonts display)))
    (or (find-if #'(lambda (f) (typep f 'openlook-cursor-font)) fonts)
	(make-instance 'openlook-cursor-font))))

(defvar *xview-openlook-cursors*
  '(XV:olc-basic-ptr
    XV:olc-move-ptr
    XV:olc-copy-ptr
    XV:olc-busy-ptr
    XV:olc-stop-ptr
    XV:olc-panning-ptr
    XV:olc-navigation-level-ptr))

(defun xview-openlook-cursor-index (name)
  (if (string-equal name "default")
      XV:olc-basic-ptr
    (let ((s (find name *xview-openlook-cursors* :test #'string-equal)))
      (if s (symbol-value s)))))


(defvar *x11-cursors* 
  '(X11:XC-X-cursor
    X11:XC-arrow
    X11:XC-based-arrow-down
    X11:XC-based-arrow-up
    X11:XC-boat
    X11:XC-bogosity
    X11:XC-bottom-left-corner
    X11:XC-bottom-right-corner
    X11:XC-bottom-side
    X11:XC-bottom-tee
    X11:XC-box-spiral
    X11:XC-center-ptr
    X11:XC-circle
    X11:XC-clock
    X11:XC-coffee-mug
    X11:XC-cross
    X11:XC-cross-reverse
    X11:XC-crosshair
    X11:XC-diamond-cross
    X11:XC-dot
    X11:XC-dotbox
    X11:XC-double-arrow
    X11:XC-draft-large
    X11:XC-draft-small
    X11:XC-draped-box
    X11:XC-exchange
    X11:XC-fleur
    X11:XC-gobbler
    X11:XC-gumby
    X11:XC-hand1
    X11:XC-hand2
    X11:XC-heart
    X11:XC-icon
    X11:XC-iron-cross
    X11:XC-left-ptr
    X11:XC-left-side
    X11:XC-left-tee
    X11:XC-leftbutton
    X11:XC-ll-angle
    X11:XC-lr-angle
    X11:XC-man
    X11:XC-middlebutton
    X11:XC-mouse
    X11:XC-pencil
    X11:XC-pirate
    X11:XC-plus
    X11:XC-question-arrow
    X11:XC-right-ptr
    X11:XC-right-side
    X11:XC-right-tee
    X11:XC-rightbutton
    X11:XC-rtl-logo
    X11:XC-sailboat
    X11:XC-sb-down-arrow
    X11:XC-sb-h-double-arrow
    X11:XC-sb-left-arrow
    X11:XC-sb-right-arrow
    X11:XC-sb-up-arrow
    X11:XC-sb-v-double-arrow
    X11:XC-shuttle
    X11:XC-sizing
    X11:XC-spider
    X11:XC-spraycan
    X11:XC-star
    X11:XC-target
    X11:XC-tcross
    X11:XC-top-left-arrow
    X11:XC-top-left-corner
    X11:XC-top-right-corner
    X11:XC-top-side
    X11:XC-top-tee
    X11:XC-trek
    X11:XC-ul-angle
    X11:XC-umbrella
    X11:XC-ur-angle
    X11:XC-watch
    X11:XC-xterm))

;;; Return the value of the X cursor constant XC-<NAME> given a symbol or a string.

(defun x11-cursor-index (name)
  (let ((s (find name *x11-cursors* :test #'string-equal)))
    (if s
	(symbol-value s)
      (error "Can't find an X11 cursor named ~A" name))))


(defmethod cursor-color-to-XColor ((color color) scr substitute)
  (declare (ignore scr substitute))
  (x11-make-XColor (red color) (green color) (blue color)))

(defmethod cursor-color-to-XColor ((color sequence) scr substitute)
  (declare (ignore scr substitute))
  (x11-make-XColor (elt color 0) (elt color 1) (elt color 2)))


(flet 
 ((find-xcolor (name scr substitute)
    (let* ((name-fp (malloc-foreign-string name))
	   (xc (malloc-foreign-pointer :type '(:pointer X11:XColor)))
	   (dsp (X11:screen-display scr))
	   (cmap (X11:screen-cmap scr)))
      (when (= 0 (X11:XParseColor dsp cmap name-fp xc))
	(warn "Couldn't find a color named ~S, substituting ~S" name substitute)
	(let ((name-fp (malloc-foreign-string substitute)))
	  (X11:XParseColor dsp cmap name-fp xc)
	  (free-foreign-pointer name-fp)))
      (free-foreign-pointer name-fp)

      xc)))

 (defmethod cursor-color-to-XColor ((name symbol) scr substitute)
   (find-xcolor (symbol-name name) scr substitute))

 (defmethod cursor-color-to-XColor ((name string) scr substitute)
   (find-xcolor name scr substitute)))


(defun x11-recolor-cursor (xvo dsp)
  (let ((scr (xview-display-scr (xview-object-xvd xvo))))
    (XV:with-xview-lock 
      (X11:XRecolorCursor 
	dsp (xview-object-xid xvo)
	(cursor-color-to-XColor (xview-cursor-foreground xvo) scr "black")
	(cursor-color-to-XColor (xview-cursor-background xvo) scr "white"))
      (xview-maybe-XFlush (xview-object-xvd xvo) dsp))))


;;; Set the cursors device slot to a new X11 cursor.  If the cursor is specified
;;; by name then load the OPEN LOOK or X11 cursor glyph and recolor it.  If a cursor 
;;; name is not specified then create an X11 pixmap cursor.

(defun x11-make-cursor (cursor)
  (XV:with-xview-lock 
    (let* ((display (display cursor))
	   (xvd (device display))
	   (dsp (xview-display-dsp xvd))
	   (scr (xview-display-scr xvd))
	   (xvo (device cursor))
	   (x11-fg (cursor-color-to-XColor (xview-cursor-foreground xvo) scr "black"))
	   (x11-bg (cursor-color-to-XColor (xview-cursor-background xvo) scr "white"))
	   (name (xview-cursor-name xvo))
	   (x11-cursor
	    (flet
	     ((make-openlook-cursor (name)
		(let* ((index (xview-openlook-cursor-index name))
		       (font (find-openlook-cursor-font display))
		       (fid (xview-object-xid (device font))))
		  (X11:XCreateGlyphCursor dsp fid fid index (1+ index) x11-fg x11-bg))))

	     (cond
	      ((and name (xview-openlook-cursor-index name))
	       (make-openlook-cursor name))

	      ((and name (x11-cursor-index name))
	       (let ((xid (X11:XCreateFontCursor dsp (x11-cursor-index name))))
		 (X11:XRecolorCursor dsp xid x11-fg x11-bg)
		 xid))

	      (name 
	       (warn "No cursor named ~S available, using default instead" name)
	       (make-openlook-cursor "default"))	      

	      (:cursor-image-specified
	       (let ((x11-image (xview-object-xid (device (xview-cursor-image xvo))))
		     (mask (xview-cursor-mask xvo)))
		 (X11:XCreatePixmapCursor 
		    dsp x11-image
		    (if mask (xview-object-xid (device mask)) x11-image)
		    x11-fg x11-bg
		    (or (xview-cursor-x-hot xvo) (setf (xview-cursor-x-hot xvo) 0))
		    (or (xview-cursor-y-hot xvo) (setf (xview-cursor-y-hot xvo) 0)))))))))

      (free-foreign-pointer x11-fg)
      (free-foreign-pointer x11-bg)
      (setf (xview-object-xid xvo) x11-cursor
	    (xview-object-xvd xvo) xvd
	    (xview-object-dsp xvo) dsp)
      (xview-maybe-XFlush xvd dsp))))



(defmethod dd-realize-cursor ((p XView) cursor)
  (x11-make-cursor cursor))


(defmethod dd-destroy-cursor ((p XView) cursor)
  (XV:with-xview-lock
    (let* ((xvo (device cursor))
	   (xid (xview-object-xid xvo))
	   (xvd (xview-object-xvd xvo))
	   (dsp (xview-object-dsp xvo)))
      (when (and xid dsp)
       (null-xview-object xvo)
       (X11:XFreeCursor dsp xid)
       (xview-maybe-XFlush xvd dsp)))))



(defmethod dd-cursor-foreground ((p xview) cursor)
  (xview-cursor-foreground (device cursor)))

(defmethod dd-cursor-background ((p xview) cursor)
  (xview-cursor-background (device cursor)))

(defmethod dd-cursor-name ((p XView) cursor)
  (xview-cursor-name (device cursor)))



(defmethod (setf dd-cursor-foreground) (value (p XView) cursor)
  (let* ((xvo (device cursor))
	 (dsp (xview-object-dsp xvo)))
    (setf (xview-cursor-foreground xvo) value)
    (when (eq (status cursor) :realized)
      (x11-recolor-cursor xvo dsp)))
  value)


(defmethod (setf dd-cursor-background) (value (p XView) cursor)
  (let* ((xvo (device cursor))
	 (dsp (xview-object-dsp xvo)))
    (setf (xview-cursor-foreground xvo) value)
    (when (eq (status cursor) :realized)
      (x11-recolor-cursor xvo dsp)))
  value)


;;; Return a Solo image that contains the image of the named X11 cursor.
;;; This is done by loading the cursor font, creating an image big
;;; enough to contain the cursor glyph and drawing the glyph on the image.
;;; This functions sets the image, mask, x-hot, and y-hot slots of the xview-cursor
;;; passed to it.

(defun x11-load-named-cursor-images (xvo cursor)
  (let* ((cursor-font 
	  (if (find (xview-cursor-name xvo) *xview-openlook-cursors* :test #'string-equal)
	      (find-openlook-cursor-font (display cursor))
	    (make-instance 'font :name "cursor" :display (display cursor))))
	 (index (x11-cursor-index (xview-cursor-name xvo)))
	 (cm (char-metrics cursor-font index))
	 (ascent (char-ascent cm))
	 (image (make-instance 'image
		  :display (display cursor)
		  :depth 1
		  :width (char-width cm)
		  :height (+ ascent (char-descent cm)))))
    (draw-string image 0 ascent 
		 (make-string 1 :initial-element (code-char index))
		 ;; :foreground (xview-cursor-foreground xvo)
		 ;; :background (xview-cursor-background xvo)
		 ;; :image-text t
                 :font cursor-font)
    (setf (xview-cursor-x-hot xvo) (char-left-bearing cm)
	  (xview-cursor-y-hot xvo) ascent
	  (xview-cursor-image xvo) image
	  (xview-cursor-mask xvo) image)))



;;; If the cursor has been realized and its image slot is nil then we know that 
;;; the cursor was defined by name.   To find the cursors x or y hot spot we have 
;;; to load the cursors glyph (see x11-load-named-cursor-images).  Each reader 
;;; is defined like this:
;;;
;;; (defmethod dd-cursor-image ((p XView) cursor)
;;;   (let ((xvo (device canvas)))
;;;     (or (xview-cursor-image xvo) 
;;;         (and (eq (status cursor) :realized)
;;;	         (progn 
;;;	           (x11-load-named-cursor-images xvo)
;;;	           (xview-cursor-image xvo))))))

(macrolet 
 ((def-reader (slot-name)
    (let ((gf (intern (format nil "DD-CURSOR-~A" slot-name)))
	  (sa (intern (format nil "XVIEW-CURSOR-~A" slot-name))))
      `(defmethod ,gf ((p XView) cursor)
	 (let ((xvo (device cursor)))
	   (or (,sa xvo)
	       (and (eq (status cursor) :realized)
		    (progn
		      (x11-load-named-cursor-images xvo cursor)
		      (,sa xvo)))))))))
 (progn 
   (def-reader image)
   (def-reader mask)
   (def-reader x-hot)
   (def-reader y-hot)))


;;; X11 Does not support dynamically changing the image, mask, or hot spot of a 
;;; cursor.  To support this we just quietly create a new X11 cursor and then
;;; free the old one.  Changing the name slot of a cursor is handled the same way.
;;; If a cursor slot is set to nil (Solo only allows the image and mask slots 
;;; to be set to nil) then the cursor is not changed.

(macrolet 
 ((def-writer (slot-name)
    (let ((gf (intern (format nil "DD-CURSOR-~A" slot-name)))
	  (sa (intern (format nil "XVIEW-CURSOR-~A" slot-name))))
      `(defmethod (setf ,gf) (value (p XView) cursor)
	 (prog1
	     (setf (,sa (device cursor)) value)
	   (when (and value (eq (status cursor) :realized))
	     (let* ((xvo (device cursor))
		    (old-xid (xview-object-xid xvo))
		    (dsp (xview-object-dsp xvo)))
	       (x11-make-cursor cursor)
	       (XV:with-xview-lock 
		(X11:XFreeCursor dsp old-xid)))))))))
  (progn 
    (def-writer name)
    (def-writer image)
    (def-writer mask)
    (def-writer x-hot)
    (def-writer y-hot)))



(defmethod dd-canvas-cursor ((p XView) canvas)
  (xview-canvas-cursor (device canvas)))

(defmethod (setf dd-canvas-cursor) (cursor (p XView) canvas)
  (let* ((xvo (device canvas))
	 (dsp (xview-object-dsp xvo))
	 (canvas-xid (xview-object-xid xvo))
	 (cursor-xid (if (typep cursor 'cursor) (xview-object-xid (device cursor)))))
    (XV:with-xview-lock 
     (typecase cursor
	(cursor
	 (X11:XDefineCursor dsp canvas-xid cursor-xid))
	(null
	 (X11:XUnDefineCursor dsp canvas-xid)))
     (xview-maybe-XFlush (xview-object-xvd xvo) dsp))
    (setf (xview-canvas-cursor xvo) cursor)))

