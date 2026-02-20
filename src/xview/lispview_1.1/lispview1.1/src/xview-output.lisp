;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)xview-output.lisp	3.5 10/11/91


(in-package "LISPVIEW")


;;; GRAPHICS CONTEXT 

;;; Generate a macro that maps from CommonLisp "boole" constants to 
;;; an X11 "GX" drawing operation code.  If the boole constants are
;;; in a linear range, e.g. 0 to 15, then we generate a macro that
;;; uses a simple-vector table to do the mapping.  If not we look up
;;; the GX operation in an alist.

(eval-when (compile load eval)
  (let ((boole-to-gx-alist 
	 (sort '((#.boole-clr . #.X11:GXclear)
		 (#.boole-and . #.X11:GXand)
		 (#.boole-andc2 . #.X11:GXandReverse)
		 (#.boole-1 . #.X11:GXcopy)
		 (#.boole-andc1 . #.X11:GXandInverted)
		 (#.boole-2 . #.X11:GXnoop)
		 (#.boole-xor . #.X11:GXxor)
		 (#.boole-ior . #.X11:GXor)
		 (#.boole-nor . #.X11:GXnor)
		 (#.boole-eqv . #.X11:GXequiv)
		 (#.boole-c2 . #.X11:GXinvert)
		 (#.boole-orc2 . #.X11:GXorReverse)
		 (#.boole-c1 . #.X11:GXcopyInverted)
		 (#.boole-orc1 . #.X11:GXorInverted)
		 (#.boole-nand . #.X11:GXnand)
		 (#.boole-set . #.X11:GXset)) #'< :key #'car)))
    (if (do ((l (mapcar #'car boole-to-gx-alist) (cdr l)))
	    ((null (cdr l)) t)
	  (unless (= (cadr l) (1+ (car l)))
	    (return nil)))
	(progn
	  (defconstant boole-to-gx-table 
	    (make-array 16 :initial-contents (mapcar #'cdr boole-to-gx-alist)))
	  (if (= 0 (caar boole-to-gx-alist))
	      (defmacro boole-to-gx (op)
		`(svref boole-to-gx-table ,op))
	    (progn
	      (defconstant min-boole-op (caar boole-to-gx-alist))
	      (defmacro boole-to-gx (op)
		`(svref boole-to-gx-table (- ,op min-boole-op))))))
      (progn
	(defconstant boole-to-gx-alist boole-to-gx-alist)
	(defmacro boole-to-gx (op)
	  `(cdr (assoc ,op boole-to-gx-alist)))))))

		       

;;; The versions of XCreateGC and XChangeGC called x11-create-gc and x11-change-gc 
;;; defined below accept keyword arguments for GC slot values.  This is a little simpler
;;; than using the Xlib XGCValues interface.  The mapping from gc slot keyword
;;; to a bit in the values mask is specified by the table below (see x11-make-gc-values).

(eval-when (load compile eval)
  (let ((gc-mask-bits '((:function  . #.X11:GCFunction)
			(:plane-mask . #.X11:GCPlaneMask)
			(:foreground . #.X11:GCForeground)
			(:background . #.X11:GCBackground)
			(:line-width . #.X11:GCLineWidth)
			(:line-style . #.X11:GCLineStyle)
			(:cap-style . #.X11:GCCapStyle)
			(:join-style . #.X11:GCJoinStyle)
			(:fill-style . #.X11:GCFillStyle)
			(:fill-rule . #.X11:GCFillRule)
			(:tile . #.X11:GCTile)
			(:stipple . #.X11:GCStipple)
			(:ts-x-origin . #.X11:GCTileStipXOrigin)
			(:ts-y-origin . #.X11:GCTileStipYOrigin)
			(:font . #.X11:GCFont)
			(:subwindow-mode . #.X11:GCSubWindowMode)
			(:graphics-exposures .  #.X11:GCGraphicsExposures)
			(:clip-x-origin . #.X11:GCClipXOrigin)
			(:clip-y-origin . #.X11:GCClipYOrigin)
			(:clip-mask . #.X11:GCClipMask)
			(:dash-offset . #.X11:GCDashOffset)
			(:dashes . #.X11:GCDashList)
			(:arc-mode . #.X11:GCArcMode))))
    (dolist (mask-bit gc-mask-bits)
      (setf (get (car mask-bit) 'gc-mask-bit) (cdr mask-bit)))))


;;; The mapping from a Solo gc slot value to the corresponding X11 gc slot
;;; value is determined by the type definitions below.  See x11-make-gc-values.

(deftype x11-gc-function-slot ()
  '(member :function))

(deftype x11-gc-color-slot ()
  '(member :foreground :background))

(deftype x11-gc-image-slot ()
  '(member :tile :stipple))

(deftype x11-gc-font-slot ()
  '(member :font))

(deftype x11-gc-keyword-slot ()
  '(member :line-style 
	   :cap-style 
	   :join-style 
	   :fill-style 
	   :fill-rule 
	   :subwindow-mode 
	   :graphics-exposures 
	   :arc-mode))

;;; The mapping from a Solo keyword gc slot value to the corresponding
;;; X11 integer value is defined by the following table.  Each keyword
;;; gets a property, whose name is the relevant gc slot name, whose value
;;; is the corresponding X11 constant.  For example the X11 gc constant value 
;;; for :dash is (get :dash :line-style).  The property name varies, rather
;;; than being a constant like 'x11-gc-constant, to make it possible to 
;;; distinguish between :cap-style :round (X11:CapRound) and :join-style
;;; :round (X11:JoinRound).

(eval-when (load compile eval)
  (let ((gc-keywords 
	 '((:solid             #.X11:LineSolid          :line-style)
	   (:dash              #.X11:LineOnOffDash      :line-style)
	   (:double-dash       #.X11:LineDoubleDash     :line-style)
	   (:butt              #.X11:CapButt            :cap-style)
	   (:not-last          #.X11:CapNotLast         :cap-style)
	   (:projecting        #.X11:CapProjecting      :cap-style)
	   (:round             #.X11:CapRound           :cap-style)
	   (:bevel             #.X11:JoinBevel          :join-style)
	   (:miter             #.X11:JoinMiter          :join-style)
	   (:round             #.X11:JoinRound          :join-style)
	   (:opaque-stippled   #.X11:FillOpaqueStippled :fill-style)
	   (:solid             #.X11:FillSolid          :fill-style)
	   (:stippled          #.X11:FillStippled       :fill-style)
	   (:tiled             #.X11:FillTiled          :fill-style)
	   (:even-odd          #.X11:EvenOddRule        :fill-rule)
	   (:winding           #.X11:WindingRule        :fill-rule)
	   (:clip-by-children  #.X11:ClipByChildren     :subwindow-mode)
	   (:include-inferiors #.X11:IncludeInferiors   :subwindow-mode)
	   (:chord             #.X11:ArcChord           :arc-mode)
	   (:pie-slice         #.X11:ArcPieSlice        :arc-mode)
	   (:on                #.X11:true               :graphics-exposures)
	   (:off               #.X11:false              :graphics-exposures))))
    (dolist (keyword gc-keywords)
      (setf (get (nth 0 keyword) (nth 2 keyword)) (nth 1 keyword)))))


(deftype x11-gc-slot ()
  '(member :function 
	   :plane-mask 
	   :foreground 
	   :background 
	   :line-width 
	   :line-style 
	   :cap-style 
	   :join-style
	   :fill-style 
	   :fill-rule 
	   :tile 
	   :stipple 
	   :ts-x-origin
	   :ts-y-origin
	   :font 
	   :subwindow-mode 
	   :graphics-exposures 
	   :clip-x-origin
	   :clip-y-origin 
	   :clip-mask 
	   :dash-offset 
	   :dashes 
	   :arc-mode))


(defun x11-set-dashes (dsp gc dash-offset dashes)
  (let* ((n-dashes (max 1 (length dashes)))
	 (Xdashes (malloc-foreign-pointer
		   :type `(:pointer (:array :unsigned-8bit (,n-dashes))))))
    (let ((i 0))
      (dolist (dash (or dashes '(4)))
	(setf (foreign-aref Xdashes i) dash)
	(incf i)))
    (setf (foreign-pointer-type Xdashes) '(:pointer :character))
    (XV:with-xview-lock 
      (X11:XSetDashes dsp gc dash-offset  Xdashes n-dashes))
    (free-foreign-pointer Xdashes)))


(defun x11-set-clip-mask (dsp gc clip-x clip-y clip-mask)
  (when (typep clip-mask 'region)
    (setq clip-mask (list clip-mask)))
  (cond
   ((typep clip-mask 'image)
    (error "image clip masks not supported"))
   ((null clip-mask)
    (XV:with-xview-lock 
      (X11:XSetClipMask dsp gc X11:None)))
   (t
    (let* ((n-rectangles (length clip-mask))
	   (Xrectangles (malloc-foreign-pointer
			 :type `(:pointer (:array X11:XRectangle (,n-rectangles))))))
      (let ((i 0))
	(dolist (rg clip-mask)
	  (let ((rc (foreign-aref Xrectangles i)))
	    (if (typep rg 'region)
		(setf (X11:XRectangle-x rc) (region-min-x rg)
		      (X11:XRectangle-y rc) (region-min-y rg)
		      (X11:XRectangle-width rc) (region-width rg)
		      (X11:XRectangle-height rc) (region-height rg))
	      (error "clip-mask must be a region, image, or list of regions")))
	  (incf i)))
      (setf (foreign-pointer-type Xrectangles) '(:pointer X11:XRectangle))
      (XV:with-xview-lock 
        (X11:XSetClipRectangles dsp gc clip-x clip-y Xrectangles n-rectangles X11:Unsorted))
      (free-foreign-pointer Xrectangles)))))




;;; Manging XGCValues foreign structures
;;;
;;; When an X11 graphics-context (GC) is created or changed all of the C initargs are 
;;; passed in a struct, called XGCValues, which has one slot per initarg.  Additionally 
;;; an integer mask specifies which struct slots actually contain valid values.  Rather 
;;; than repeatedly allocating and freeing XGCValues structs we manage a resource of them.

(defconstant x11-null-xgcvalues
  (make-foreign-pointer :type '(:pointer X11:XGCValues) :address 0))


;;; Define a function called init-XGCValues that takes a XGValues foreign pointer
;;; and one keyword argument per X11 graphics context slot.  Only the specified 
;;; non-nil slots are set.

(macrolet 
 ((defun-init-XGCValues ()
    (let ((slots (substitute 'function 'operation graphics-context-slot-names))
	  (x11-pkg (find-package :x11)))
     `(defun init-XGCValues (fp &key ,@(mapcar #'(lambda (slot) 
						   (list slot 0 (intern (format nil "~A-P" slot))))
					       slots))
	(declare (optimize (speed 3) (safety 0) (compilation-speed 0)))
	,@(mapcar #'(lambda (slot)
		      `(when (and ,slot ,(intern (format nil "~A-P" slot)))
			 (setf (,(intern (format nil "XGCVALUES-~A" slot) x11-pkg) fp) ,slot)))
		  slots)
	fp))))

 (defun-init-XGCValues))

(defvar XGCValues-resource 
  (make-resource "XGCValues Foreign Structures"
	:initial-copies 3
	:initial-args nil
	:initialization-function #'init-XGCValues
        :constructor 
	   #'(lambda (&rest args)
	       (apply #'init-XGCValues (make-foreign-pointer 
					 :type '(:pointer X11:XGCValues)
					 :static t)
		                       args))))

(defmacro alloc-XGCValues (rest-args)
  `(apply #'resource-allocate XGCValues-resource ,rest-args))

(defmacro free-XGCValues (fp)
  `(resource-deallocate XGCValues-resource ,fp))


(defun x11-make-gc-values (args)
  (if (null args)
      (values 0 x11-null-XGCValues)
    (let ((value-mask 0))
      (do ((arg-cdr args (cddr arg-cdr)))
	  ((null (cdr arg-cdr))
	   (values value-mask (alloc-XGCValues args)))
	(let ((keyword (car arg-cdr))
	      (value (cadr arg-cdr)))
	  (when (typep keyword 'x11-gc-slot)
	    (let ((value (typecase keyword
			   (x11-gc-keyword-slot 
			    (get value keyword))
			   (x11-gc-function-slot 
			    (boole-to-gx value))
			   (x11-gc-font-slot
			    (xview-object-xid (device value)))
			   (x11-gc-color-slot
			    (pixel value))
			   ((or x11-gc-image-slot x11-gc-font-slot)
			    (if (typep value 'image)
				(xview-object-xid (device value))))
			   (t value))))
	      (when value
		(setf value-mask (logior value-mask (get keyword 'gc-mask-bit))
		      (cadr arg-cdr) value)))))))))



(defun x11-change-gc (dsp gc &rest args)
  (multiple-value-bind (value-mask values)
      (x11-make-gc-values args)
    (prog1
	(X11:XChangeGC dsp gc value-mask values)
      (free-XGCValues values))))


(defun x11-create-gc (dsp drawable &rest args)
  (multiple-value-bind (value-mask values)
      (x11-make-gc-values args)
    (prog1
	(XV:with-xview-lock 
	  (X11:XCreateGC dsp drawable value-mask values))
      (free-XGCValues values))))


(defmethod dd-initialize-graphics-context ((p XView) gc 
					   &rest initargs 
					   &key 
					     operation 
					     foreground
					     background
					   &allow-other-keys)
  (unless (slot-boundp gc 'device)
    (let ((d (display gc)))
      (setf (device gc)
	    (apply #'make-x11-gc
	      :function (or operation boole-1)
	      :foreground (or foreground (find-color :name :black :display d))
	      :background (or background (find-color :name :white :display d))
	      :allow-other-keys t
	      initargs))))
    (setf (slot-value gc 'status) :initialized))


(defmethod dd-realize-graphics-context ((p XView) gc)
  (let* ((xvo (device gc))
	 (display (display gc))
	 (xvd (setf (xview-object-xvd xvo) (device display)))
	 (dsp (setf (xview-object-dsp xvo) (xview-display-dsp xvd)))
	 (drawable
	  (or (let ((d (x11-gc-drawable xvo)))
		(if d (xview-object-xid (device d))))
	      (XV:with-xview-lock 
	       (XV:xv-get (xview-display-root xvd) :xv-xid))))
	 (clip-x (x11-gc-clip-x-origin xvo))
	 (clip-y (x11-gc-clip-y-origin xvo))
	 (dash-offset (x11-gc-dash-offset xvo))
	 (xgc (setf (xview-object-xid xvo)
		    (x11-create-gc dsp drawable
		     :function (x11-gc-function xvo)
		     :plane-mask (x11-gc-plane-mask xvo)
		     :foreground (x11-gc-foreground xvo)
		     :background (x11-gc-background xvo)
		     :line-width (x11-gc-line-width xvo)
		     :line-style (x11-gc-line-style xvo)
		     :cap-style (x11-gc-cap-style xvo)
		     :join-style (x11-gc-join-style xvo)
		     :fill-style (x11-gc-fill-style xvo)
		     :fill-rule (x11-gc-fill-rule xvo)
		     :tile (x11-gc-tile xvo)
		     :stipple (x11-gc-stipple xvo)
		     :ts-x-origin (x11-gc-ts-x-origin xvo)
		     :ts-y-origin (x11-gc-ts-y-origin xvo)
		     :subwindow-mode (x11-gc-subwindow-mode xvo)
		     :graphics-exposures (x11-gc-graphics-exposures xvo)
		     :clip-x-origin clip-x
		     :clip-y-origin clip-y
		     :dash-offset dash-offset
		     :arc-mode (x11-gc-arc-mode xvo)))))
    (let ((dashes (x11-gc-dashes xvo)))
      (when dashes
	(x11-set-dashes dsp xgc dash-offset dashes)))
    (let ((clip-mask (x11-gc-clip-mask xvo)))
      (when clip-mask
	(x11-set-clip-mask dsp xgc clip-x clip-y clip-mask)))
    (let ((font (x11-gc-font xvo)))
      (if font
	  (XV:with-xview-lock 
	    (X11:XSetFont dsp xgc (xview-font-xid (device font))))
	(setf (x11-gc-font xvo) (make-instance 'font :display display :name "fixed"))))))




;;; For each graphics-context slot except clip-mask, operation, and dashes define a pair of 
;;; methods that look like this:
;;;
;;; (defmethod dd-gc-foreground ((p XView) gc)
;;;   (x11-gc-foreground (device gc)))
;;; 
;;; (defmethod (setf dd-gc-foreground) (value (p XView) gc)
;;;   (XV:with-xview-lock 
;;;     (let* ((xvo (device gc))
;;;            (dsp (xview-object-dsp xvo))
;;; 	       (xid (xview-object-xid xvo)))
;;;       (when xid
;;;          (x11-change-gc dsp xid :foreground value))
;;;       (setf (x11-gc-foreground xvo) value))))

(macrolet 
 ((def-gc-accessor (name)
    (let ((driver (intern (format nil "DD-GC-~A" name)))
	  (initarg (intern (string name) (find-package :keyword)))
	  (accessor (intern (format nil "X11-GC-~A" name))))
      `(progn
	 (defmethod ,driver ((p XView) gc)
	   (,accessor (device gc)))

	 (defmethod (setf ,driver) (value (p XView) gc)
	   (XV:with-xview-lock 
	     (let* ((xvo (device gc))
		    (dsp (xview-object-dsp xvo))
		    (xid (xview-object-xid xvo)))
	       (when xid
		 (x11-change-gc dsp xid ,initarg value))
	       (setf (,accessor xvo) value))))))))

  (def-gc-accessor plane-mask)
  (def-gc-accessor foreground)
  (def-gc-accessor background)
  (def-gc-accessor line-width)
  (def-gc-accessor line-style)
  (def-gc-accessor cap-style)
  (def-gc-accessor join-style)
  (def-gc-accessor fill-style)
  (def-gc-accessor fill-rule)
  (def-gc-accessor tile)
  (def-gc-accessor stipple)
  (def-gc-accessor ts-x-origin)
  (def-gc-accessor ts-y-origin)
  (def-gc-accessor font)
  (def-gc-accessor subwindow-mode)
  (def-gc-accessor graphics-exposures)
  (def-gc-accessor clip-x-origin)
  (def-gc-accessor clip-y-origin)
  (def-gc-accessor dash-offset)
  (def-gc-accessor arc-mode))


(defmethod dd-gc-operation ((p XView) gc)
  (x11-gc-function (device gc)))

(defmethod (setf dd-gc-operation) (value (p XView) gc)
  (XV:with-xview-lock 
    (let* ((xvo (device gc))
	   (dsp (xview-object-dsp xvo))
	   (xid (xview-object-xid xvo)))
      (when xid
	(x11-change-gc dsp xid :function value))
      (setf (x11-gc-function xvo) value))))


(defmethod dd-gc-clip-mask ((p XView) gc)
  (x11-gc-clip-mask (device gc)))

(defmethod (setf dd-gc-clip-mask) (value (p XView) gc)
  (XV:with-xview-lock 
    (let* ((xvo (device gc))
	   (dsp (xview-object-dsp xvo))
	   (xid (xview-object-xid xvo)))
      (when xid
	(x11-set-clip-mask dsp xid (x11-gc-clip-x-origin xvo) (x11-gc-clip-y-origin xvo) value))
      (setf (x11-gc-clip-mask xvo) value))))


(defmethod dd-gc-dashes ((p XView) gc)
  (x11-gc-dashes (device gc)))

(defmethod (setf dd-gc-dashes) (value (p XView) gc)
  (XV:with-xview-lock 
    (let* ((xvo (device gc))
	   (dsp (xview-object-dsp xvo))
	   (xid (xview-object-xid xvo)))
      (when xid
	(x11-set-dashes dsp xid (x11-gc-dash-offset xvo) value))
      (setf (x11-gc-dashes xvo) value))))


(defmethod dd-destroy-graphics-context ((p XView) gc)
  (XV:with-xview-lock 
    (let* ((xvo (device gc))
	   (xid (xview-object-xid xvo)))
      (when xid
	(X11:XFreeGC (xview-object-dsp xvo) xid)
	(null-xview-object xvo)))))
	
  

;;; DRAWING 


(defmethod dd-draw-line ((p XView) gc drawable x1 y1 x2 y2)
  (XV:with-xview-lock 
    (let* ((xvo (device drawable))
	   (dsp (xview-object-dsp xvo))
	   (xid (xview-object-xid xvo))
	   (xgc (xview-object-xid (device gc))))
      (when (and xgc xid)
	 (X11:XDrawLine dsp xid xgc x1 y1 x2 y2)
	 (xview-maybe-XFlush (xview-object-xvd xvo) dsp)))))


(defmethod dd-draw-lines ((p XView) gc drawable lines accessor)
  (XV:with-xview-lock 
    (let* ((xvo (device drawable))
	   (dsp (xview-object-dsp xvo))
	   (xid (xview-object-xid xvo))
	   (xgc (xview-object-xid (device gc)))
	   (n-segments (length lines))
	   (segments (malloc-foreign-pointer 
		       :type `(:pointer (:array X11:XSegment (,n-segments))))))
      (when (and xgc xid)
	(let ((i 0))
	  (dolist (line lines)
	    (multiple-value-bind (x1 y1 x2 y2)
		(funcall accessor line)
	      (let ((s (foreign-aref segments i)))
		(setf (X11:XSegment-x1 s) x1
		      (X11:XSegment-y1 s) y1
		      (X11:XSegment-x2 s) x2
		      (X11:XSegment-y2 s) y2)))
	    (incf i)))
	(setf (foreign-pointer-type segments) '(:pointer X11:XSegment))
	(X11:XDrawSegments dsp xid xgc segments n-segments)
	(xview-maybe-XFlush (xview-object-xvd xvo) dsp))

      (free-foreign-pointer segments))))



(defmethod dd-draw-rectangle ((p XView) gc drawable x y w h filled)
  (XV:with-xview-lock
    (let* ((xvo (device drawable))
	   (dsp (xview-object-dsp xvo))
	   (xid (xview-object-xid xvo))
	   (xgc (xview-object-xid (device gc))))
      (when (and xgc xid)
	(macrolet ((draw (drawfn)
		      `(,drawfn dsp xid xgc x y w h)))
	  (if filled
	      (draw X11:XFillRectangle)
	    (draw X11:XDrawRectangle)))
	(xview-maybe-XFlush (xview-object-xvd xvo) dsp)))))


(defmethod dd-draw-rectangles ((p XView) gc drawable rectangles accessor filled)
  (XV:with-xview-lock 
    (let* ((xvo (device drawable))
	   (dsp (xview-object-dsp xvo))
	   (xid (xview-object-xid xvo))
	   (xgc (xview-object-xid (device gc)))
	   (n-rectangles (length rectangles))
	   (Xrectangles (malloc-foreign-pointer 
			  :type `(:pointer (:array X11:XRectangle (,n-rectangles))))))
      (when (and xgc xid)
	(let ((i 0))
	  (dolist (rectangle rectangles)
	    (multiple-value-bind (x y w h)
		(funcall accessor rectangle)
	      (let ((r (foreign-aref Xrectangles i)))
		(setf (X11:XRectangle-x r) x
		      (X11:XRectangle-y r) y
		      (X11:XRectangle-width r) w
		      (X11:XRectangle-height r) h)))
	    (incf i)))
	(setf (foreign-pointer-type Xrectangles) '(:pointer X11:XRectangle))
	(macrolet ((draw (drawfn)
		      `(,drawfn dsp xid xgc Xrectangles n-rectangles)))
	 (if filled
	     (draw X11:XFillRectangles)
	   (draw X11:XDrawRectangles)))
	(xview-maybe-XFlush (xview-object-xvd xvo) dsp))

      (free-foreign-pointer Xrectangles))))



;;; Ideally the application will pass us a simple-string which we can pass
;;; directly to lisp-XDrawString.  We defer interrupts during this call
;;; to prevent the GC from relocating the string while C has its address.
;;; If we're given a something else we copy it into *XDrawString-buffer*, if
;;; the buffer isn't big enough we create a new one that is.

(defvar *XDrawString-buffer* 
  (make-string  2048 :initial-element #\null))

(proclaim '(simple-string *XDrawString-buffer*))

(defmethod dd-draw-string ((p XView) gc drawable x y string start end)
  (declare (inline X11:lisp-XDrawString)
	   (type-reduce number fixnum))
  (XV:with-xview-lock 
    (let* ((xvo (device drawable))
	   (dsp (xview-object-dsp xvo))
	   (xid (xview-object-xid xvo))
	   (xgc (xview-object-xid (device gc)))
	   (start (or start 0))
	   (end (or end (length string))))
      (when (and xgc xid)
	 (if (simple-string-p string)
	     (with-interrupts-deferred
	       (X11:lisp-XDrawString dsp xid xgc x y string start end))
	   (let ((length (- end start)))
	     (unless (<= length (length *XDrawString-buffer*))
	       (setq *XDrawString-buffer* (make-string  length :initial-element #\null)))
	     (dotimes (i length)
	       (setf (schar *XDrawString-buffer* i) (aref string (+ i start))))
	     (with-interrupts-deferred
	       (X11:lisp-XDrawString dsp xid xgc x y *XDrawString-buffer* 0 length))))
	 (xview-maybe-XFlush (xview-object-xvd xvo) dsp)))))


(defmethod dd-draw-char ((p XView) gc drawable x y char)
  (XV:with-xview-lock 
    (let* ((xvo (device drawable))
	   (dsp (xview-object-dsp xvo))
	   (xid (xview-object-xid xvo))
	   (xgc (xview-object-xid (device gc))))
      (when (and xgc xid)
	 (setf (schar *XDrawString-buffer* 0) char)
	 (with-interrupts-deferred
	   (X11:lisp-XDrawString dsp xid xgc x y *XDrawString-buffer* 0 1))
	 (xview-maybe-XFlush (xview-object-xvd xvo) dsp)))))



(defmethod dd-copy-area ((p XView) gc from to from-x from-y width height to-x to-y)
  (XV:with-xview-lock
    (let* ((src-xvo (device from))
	   (dst-xvo (device to))
	   (src-xid (xview-object-xid src-xvo))
	   (dst-xid (xview-object-xid dst-xvo))
	   (xgc (xview-object-xid (device gc)))
	   (dsp (xview-object-dsp src-xvo))
	   (from-depth (xview-drawable-depth src-xvo))
	   (to-depth (xview-drawable-depth dst-xvo)))
      (when (and src-xid dst-xid xgc)
	(cond
	 ((= from-depth to-depth)
	  (X11:XCopyArea dsp src-xid dst-xid xgc from-x from-y width height to-x to-y))
	 ((= from-depth 1)
	  (X11:XCopyPlane dsp src-xid dst-xid xgc from-x from-y width height to-x to-y 1))
	 (t
	  (error "copying from a drawable of depth ~D not supported" from-depth)))
	(xview-maybe-XFlush (xview-object-xvd src-xvo) dsp)))))



(defmethod dd-draw-arc ((p XView) gc drawable x y w h a1 a2 filled)
  (XV:with-xview-lock
    (let* ((xvo (device drawable))
	   (dsp (xview-object-dsp xvo))
	   (xid (xview-object-xid xvo))
	   (xgc (xview-object-xid (device gc))))
      (when (and xgc xid)
	(macrolet ((draw (drawfn)
		      `(,drawfn dsp xid xgc x y w h (truncate (* a1 64)) (truncate (* a2 64)))))
	  (if filled
	      (draw X11:XFillArc)
	    (draw X11:XDrawArc)))
	(xview-maybe-XFlush (xview-object-xvd xvo) dsp)))))


(defmethod dd-draw-arcs ((p XView) gc drawable arcs accessor filled)
  (XV:with-xview-lock 
    (let* ((xvo (device drawable))
	   (dsp (xview-object-dsp xvo))
	   (xid (xview-object-xid xvo))
	   (xgc (xview-object-xid (device gc)))
	   (n-arcs (length arcs))
	   (Xarcs (malloc-foreign-pointer 
		     :type `(:pointer (:array X11:XArc (,n-arcs))))))
      (when (and xgc (integerp xid))
	(let ((i 0))
	  (dolist (arc arcs)
	    (multiple-value-bind (x y w h a1 a2)
		(funcall accessor arc)
	      (let ((a (foreign-aref Xarcs i)))
		(setf (X11:XArc-x a) x
		      (X11:XArc-y a) y
		      (X11:XArc-width a) w
		      (X11:XArc-height a) h
		      (X11:XArc-angle1 a) (truncate (* a1 64))
		      (X11:XArc-angle2 a) (truncate (* a2 64)))))
	    (incf i)))
	(setf (foreign-pointer-type Xarcs) '(:pointer X11:XArc))
	(macrolet ((draw (drawfn)
		      `(,drawfn dsp xid xgc XArcs n-arcs)))
	  (if filled
	      (draw X11:XFillArcs)
	    (draw X11:XDrawArcs)))
	(xview-maybe-XFlush (xview-object-xvd xvo) dsp))
      (free-foreign-pointer XArcs))))

