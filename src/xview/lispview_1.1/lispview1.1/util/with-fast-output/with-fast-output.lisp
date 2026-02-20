;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

(in-package 'lispview)

(proclaim '(optimize (compilation-speed 0) (speed 3) (safety 1)))

(export '(with-fast-output) 'lispview)

;;; This macro was designed to aid in achieving performance speedup
;;; for graphics-intensive portions of code.
;;; [Note: At the end of this file, commented out, is a function
;;; test-fast-drawing which can be used to check the logical integrity
;;; of the macro; see the comments with that function.]

;;; Using with-fast-output:
;;; To use this macro, merely wrap it around a drawing-intensive loop in
;;; your code.  You need to declare three things to
;;; this macro when you use it:  the names of the drawables you will be drawing to inside the loop,
;;; the names of the gcs that will be referenced, and the names of the drawing-functions that the loop uses.
;;; If the loop is already wrapped in the with-output-buffering macro, you should get rid of it, since with-fast-output
;;; does an implicit with-output-buffering of its own; however, things will still work properly if you leave it in.
;;;   Here is an example.

;;;  Before using the with-fast-output macro:
;(DEFUN FOO (W WIDTH HEIGHT GC)
;  (WITH-OUTPUT-BUFFERING *DEFAULT-DISPLAY*
;    (LOOP FOR I FROM 0 TO WIDTH BY 10 DO
;	  (LOOP FOR J FROM 0 TO WIDTH BY 10 DO NIL
;		(DRAW-LINE W I 0 J HEIGHT :GC GC)
;		))))


;;; After using with-fast-output.  Since the loop writes to a the drawable w, w is declared
;;; in the list of :drawables to with-fast-output.  Similarly, since the loop references the drawing-function
;;; draw-line and the graphics-context gc, these are also declared in the lists of :drawing-functions and :graphics-contexts
;;; to with-fast-output.  Note that the with-output-buffering form is gone from the function now.  It is not longer needed,
;;; since with-fast-output performs its own implicit with-output-buffering.
;(DEFUN FOO (W WIDTH HEIGHT GC)
;  (WITH-FAST-OUTPUT (:DRAWABLES (W)
;		     :DRAWING-FUNCTIONS (DRAW-LINE)
;		     :GRAPHICS-CONTEXTS (GC))
;    (LOOP FOR I FROM 0 TO WIDTH BY 10 DO
;	  (LOOP FOR J FROM 0 TO WIDTH BY 10 DO NIL
;		(DRAW-LINE W I 0 J HEIGHT :GC GC)
;		))))


;;; Your drawing-intensive loop should satisfy these constraints in order for with-fast-output to work
;;; properly: it should write to only one display (though to as many windows and graphics-contexts as it wants to);
;;; it should NOT pass any gc-keyword-args to any of its declared drawing-functions.  For example, the form
;;; (draw-line w 0 0 100 100 :foreground green) is allowable if and only if draw-line is not declared in the :drawing-functions list
;;; of with-fast-output, in which case the call to draw-line is treated normally and not optimized.  I should point
;;; out that if draw-line were declared in the :drawing-functions list, but the drawable w were not declared in
;;; the drawables list, resulting again in a non-optimized function call (as explained in the next paragraph), the
;;; graphics-context keyword arg :foreground in the preceding example would still not be allowable.  The way it is written,
;;; with-graphics-output ignores all graphics-context keyword args to all of the drawing-functions declared in its
;;; :drawing-functions list.
;;;        with-fast-output only optimizes calls in which the drawing-function is declared in its :drawing-functions list, AND all
;;; of the drawable and graphics-context arguments to the drawing-function are also declared in their respective :drawables
;;; and :graphics-contexts lists.  For example, the following would be left as a standard, non-optimized call by with-fast-output:

;(with-fast-output (:drawables (w1 w2)
;		   :graphics-contexts (gc1 gc2)
;		   :drawing-functions (draw-line draw-rectangle)
;		   )
;    (loop for i from 1 to 100 by 10
;	  (draw-rectangle w3 i 0 5 5 :gc gc)))

;;; because w3 was not declared in the :drawables list of with-fast-output.  This is assuming that w3 is not eq to
;;; either w1 or w2.  If it were eq to either w1 or w2, then the call would be optimized.
		   


;;; The main trick of fast drawing is to bind the xid pointers once for each
;;; window and gc, so that they don't need to be retrieved inside the drawing loop on
;;; each iteration.  For this to work, we need to know at compiletime exactly which windows
;;; and gcs will be used.  We perform some fast runtime checks to verify this, and, if we
;;; find that we do not have a window or gc that has a precompiled xid, then we escape to
;;; the standard, slower draw-<thing>.
;;;    Drawing-functions inside of a fast-drawing environment will have all gc-component keyword args ignored.
;;; They could have been made to not ignore the args in some cases, using &rest args, but since dynamic-extent declarations
;;; don't work inside of fletted functions, we would end up consing, so I decided it was too costly to implement this feature.
;;;    Note--Copy area fast version does not do a copyplane in case of mismatched depths from 1 to something else.
;;; The depths must be equal.
;;;    Note--You do not need to wrap your code in with-output-buffering if you are using this macro.
;;;    Note--This macro does not handle multiple displays.
;;;    Note--This macro does nothing for you if your code achieves its drawing-operation intensity through recursion.
;;;   Implementor's note:  Although in many places this macro and its subfunctions appear to be
;;; handling the general case of multiple displays, there are a few places where this is not carried through.
;;; In particular, you'll note that output-buffering is only on for the default display. This macro will only
;;; handle the single-display case properly.  Some modifications will
;;; need to be made to handle multiple displays.

(defmacro with-fast-output ((&key drawing-functions drawables graphics-contexts) &body body)
  (let ((ws (mapcar #'(lambda (x) (declare (ignore x)) (gensym "DRAWABLE")) drawables))
	(xvos (mapcar #'(lambda (x) (declare (ignore x)) (gensym "XVO")) drawables))
	(dsps (mapcar #'(lambda (x) (declare (ignore x)) (gensym "DSP")) drawables))
	(xids (mapcar #'(lambda (x) (declare (ignore x)) (gensym "XID")) drawables))
	(depths (mapcar #'(lambda (x) (declare (ignore x)) (gensym "DEPTH")) drawables))
	(gcs  (mapcar #'(lambda (x) (declare (ignore x)) (gensym "GC")) graphics-contexts))
	(xgcs (mapcar #'(lambda (x) (declare (ignore x)) (gensym "XGC")) graphics-contexts))
	(default-display (gensym "DEFAULT-DISPLAY"))
	(default-gc (gensym "DEFAULT-GC"))
	(default-xgc (gensym "DEFAULT-XGC"))	
	)
    `(let* (;; This clause creates xid bindings for all of the specified drawables
	    ,@(loop for drawable in drawables
		    for w in ws
		    for xvo in xvos
		    for dsp in dsps
		    for xid in xids
		    for depth in depths
		    append `((,w ,drawable)
			     (,xvo (device ,w))
			     (,dsp (xview-object-dsp ,xvo))
			     (,xid (xview-object-xid ,xvo))
			     ;;special case for copy-area, needs depths of all drawables.
			     ,@(when (member 'copy-area drawing-functions :test #'eq)
				   `((,depth (xview-drawable-depth ,xvo))))))
	      
	      ;; We assume drawing occurs to only a single display.  We grab it from the first window.
	      (,default-display (display ,(first ws)))
	      ;; In case no :GC arg is passed to the draw method, we bind the display's current gc as a default.
	      (,default-gc (graphics-context ,default-display))
	      (,default-xgc (xview-object-xid (device ,default-gc)))
	      ;; This clause creates bindings for all of the specified gcs.
	      ,@(loop for gc in gcs
		      for xgc in xgcs		    
		      for graphics-context in graphics-contexts
		      append `((,gc ,graphics-context)
			       (,xgc (xview-object-xid (device ,gc))))))
      (flet
	(,@(loop for drawing-function in drawing-functions
		 for macroexpansion = (fast-drawing-function-macroexpansion drawing-function
									    ws
									    xvos
									    dsps
									    xids
									    depths
									    gcs
									    xgcs
									    default-xgc
									    )
		 when macroexpansion collect macroexpansion)
	 )

      (xv:with-xview-lock
       (with-interrupts-deferred
          (with-output-buffering ,default-display
	   ,@body)))))))
      



(defmethod fast-drawing-function-macroexpansion ((draw-fun (eql 'draw-line)) ws xvos dsps xids depths gcs xgcs default-xgc)
  (declare (ignore xvos depths))
  `(draw-line  (drawable x1 y1 x2 y2  &key (gc nil))
       ;; This cond clause checks at runtime to make sure we have a window and gc with precompiled xids.
       (cond ,@(loop for w in ws
		     for dsp in dsps
		     for xid in xids
		     collect `((eq drawable ,w)
			       (X11:XDrawLine ,dsp
					      ,xid
					      (cond ,@(loop for lgc in gcs
							    for xgc in xgcs
							    collect `((eq gc ,lgc)
								      ,xgc))
						    ((null gc) ,default-xgc)
						    ;; This clause is evaluated in case the window had a precompiled
						    ;; xid, but the gc did not.  We do the slow gc xid access at runtime.
						    (t (xview-object-xid (device gc))))
					      x1
					      y1
					      x2
					      y2)))
	     ;; We didn't have a window with a precompiled xid, so do the slow draw.
	     (t (draw-line drawable x1 y1 x2 y2 :gc gc)))))




;;; Catch-all method for draw-functions that don't have fast-version-macroexpansions written yet.
(defmethod fast-drawing-function-macroexpansion ((draw-fun symbol) ws xvos dsps xids depths gcs xgcs default-xgc)
  (declare (ignore ws xvos dsps xids depths gcs xgcs default-xgc))
  nil)


(defmethod fast-drawing-function-macroexpansion ((draw-fun (eql 'draw-rectangle)) ws xvos dsps xids depths gcs xgcs default-xgc)
  (declare (ignore xvos depths))
  `(draw-rectangle (drawable x y width height  &key gc fill-p)
      ;; This cond clause checks at runtime to make sure we have a window and gc with precompiled xids.
      (cond (fill-p
	     (cond ,@(loop for w in ws
			   for dsp in dsps
			   for xid in xids
			   collect `((eq drawable ,w)
				     (X11:XFillRectangle ,dsp
							 ,xid
							 (cond ,@(loop for lgc in gcs
								       for xgc in xgcs
								       collect `((eq gc ,lgc)
										 ,xgc))
							       ((null gc) ,default-xgc)
							       ;; This clause is evaluated in case the window had a precompiled
							       ;; xid, but the gc did not.  We do the slow gc xid access at runtime.
							       (t (xview-object-xid (device gc))))
							 x
							 y
							 width
							 height)))
		   ;; We didn't have a window with a precompiled xid, so do the slow access.
		   (t (draw-rectangle drawable x y width height :gc gc :fill-p fill-p))))
	    (t (cond ,@(loop for w in ws
			     for dsp in dsps
			     for xid in xids
			     collect `((eq drawable ,w)
				       (X11:XDrawRectangle ,dsp
							   ,xid
							   (cond ,@(loop for lgc in gcs
									 for xgc in xgcs
									 collect `((eq gc ,lgc)
										   ,xgc))
								 ((null gc) ,default-xgc)
								 ;; This clause is evaluated in case the window had a precompiled
								 ;; xid, but the gc did not.  We do the slow gc xid access at runtime.
								 (t (xview-object-xid (device gc))))
							   x
							   y
							   width
							   height)))
		     ;; We didn't have a window with a precompiled xid, so do the slow access.
		     (t (draw-rectangle drawable x y width height :gc gc :fill-p fill-p)))))))



(defmethod fast-drawing-function-macroexpansion ((draw-fun (eql 'draw-string)) ws xvos dsps xids depths gcs xgcs default-xgc)
  (declare (ignore xvos depths))
  `(draw-string (drawable x y string  &key (start 0) (end (length string)) gc)
      (flet
       ((xdrawstring (drawable x y string gc start end)
	  (cond ,@(loop for w in ws
			for dsp in dsps
			for xid in xids
			collect `((eq drawable ,w)
				  (X11:lisp-XDrawString ,dsp
							,xid
							(cond ,@(loop for lgc in gcs
								      for xgc in xgcs
								      collect `((eq gc ,lgc)
										,xgc))
							      ((null gc) ,default-xgc)
							      ;; This clause is evaluated in case the window had a precompiled
							      ;; xid, but the gc did not.  We do the slow gc xid access at runtime.
							      (t (xview-object-xid (device gc))))
							x
							y
							string
							start
							end)))
		;; We didn't have a window with a precompiled xid, so do the slow access.
		(t (draw-string drawable x y string :start start :end end :gc gc)))))
       (if (simple-string-p string)
	   (with-interrupts-deferred
	    (xdrawstring drawable x y string gc start end))
	 (let ((length (- end start)))
	   (unless (<= length (length *XDrawString-buffer*))
	     (setq *XDrawString-buffer* (make-string  length :initial-element #\null)))
	   (dotimes (i length)
	     (setf (schar *XDrawString-buffer* i) (aref string (+ i start))))
	   (with-interrupts-deferred
	    (xdrawstring drawable x y *XDrawString-buffer* gc 0 length)))))))



;;;  Note--This does not do a copyplane in case of different depths from 1 to something else.  The depths must be equal.
(defmethod fast-drawing-function-macroexpansion ((draw-fun (eql 'copy-area)) ws xvos dsps xids depths gcs xgcs default-xgc)
  (declare (ignore xvos))
  `(copy-area (from to from-x from-y width height to-x to-y &key gc)
       (cond ,@(loop for from in ws
		     for from-dsp in dsps
		     for from-xid in xids 
		     for from-depth in depths collect
		     `((eq from ,from)
		       (cond ,@(loop for to in ws
				     for to-xid in xids 
				     for to-depth in depths collect
				     `((eq to ,to)
				       (cond ((= ,from-depth ,to-depth)
					      (X11:XCopyArea ,from-dsp
							     ,from-xid
							     ,to-xid
							     (cond ,@(loop for lgc in gcs
									   for xgc in xgcs
									   collect `((eq gc ,lgc)
										     ,xgc))
								   ((null gc) ,default-xgc)
								   ;; This clause is evaluated in case the window had a precompiled
								   ;; xid, but the gc did not.  We do the slow gc xid access at runtime.
								   (t (xview-object-xid (device gc))))
							     from-x
							     from-y
							     width
							     height
							     to-x
							     to-y))
					     ((= ,from-depth 1)
					      (X11:XCopyPlane ,from-dsp
							     ,from-xid
							     ,to-xid
							     (cond ,@(loop for lgc in gcs
									   for xgc in xgcs
									   collect `((eq gc ,lgc)
										     ,xgc))
								   ((null gc) ,default-xgc)
								   ;; This clause is evaluated in case the window had a precompiled
								   ;; xid, but the gc did not.  We do the slow gc xid access at runtime.
								   (t (xview-object-xid (device gc))))
							     from-x
							     from-y
							     width
							     height
							     to-x
							     to-y
							     1))
					     (t
					      (error "copying from a drawable of depth ~D not supported" ,from-depth))
					     )))
				     ;; We didn't have a window with a precompiled xid, so do the slow draw.				     
				     (t (copy-area from to from-x from-y width height to-x to-y :gc gc)))))
		     ;; We didn't have a window with a precompiled xid, so do the slow draw.
		     (t (copy-area from to from-x from-y width height to-x to-y :gc gc)))))



(defmethod fast-drawing-function-macroexpansion ((draw-fun (eql 'draw-arc)) ws xvos dsps xids depths gcs xgcs default-xgc)
  (declare (ignore xvos depths))
  `(draw-arc (drawable x y width height start-angle stop-angle &key gc fill-p)
       (if fill-p
	   (cond ,@(loop for w in ws
			 for dsp in dsps
			 for xid in xids
			 collect `((eq drawable ,w)
				   (X11:XFillArc ,dsp
						 ,xid
						 (cond ,@(loop for lgc in gcs
							       for xgc in xgcs
							       collect `((eq gc ,lgc)
									 ,xgc))
						       ((null gc) ,default-xgc)
						       ;; This clause is evaluated in case the window had a precompiled
						       ;; xid, but the gc did not.  We do the slow gc xid access at runtime.
						       (t (xview-object-xid (device gc))))
						 x
						 y
						 width
						 height
						 (truncate (* start-angle 64))
						 (truncate (* stop-angle 64)))))
		 ;; We didn't have a window with a precompiled xid, so do the slow access.
		 (t (draw-arc drawable x y width height start-angle stop-angle :gc gc :fill-p fill-p)))
	 (cond ,@(loop for w in ws
		       for dsp in dsps
		       for xid in xids
		       collect `((eq drawable ,w)
				 ( X11:XDrawArc ,dsp
						,xid
						(cond ,@(loop for lgc in gcs
							      for xgc in xgcs
							      collect `((eq gc ,lgc)
									,xgc))
						      ((null gc) ,default-xgc)
						      ;; This clause is evaluated in case the window had a precompiled
						      ;; xid, but the gc did not.  We do the slow gc xid access at runtime.
						      (t (xview-object-xid (device gc))))
						x
						y
						width
						height
						(truncate (* start-angle 64))
						(truncate (* stop-angle 64)))))
	       ;; We didn't have a window with a precompiled xid, so do the slow access.
	       (t (draw-arc drawable x y width height start-angle stop-angle :gc gc :fill-p fill-p))))))  






#| ##############


;;; Use this function to verify the logical integrity of the with-fast-output macro.  It
;;; creates two windows, one with fast drawing, the other with standard drawing.  The two windows should
;;; look exactly alike.  If they don't, something is wrong.  This macro does not test the speed improvement
;;; gained by using the macro.
(defun test-fast-drawing ()
  (let* ((b (make-instance 'base-window
			   :width 300
			   :height 300
			   :mapped nil
			   :label "Standard Drawing"))
	 (w1 (make-instance 'window
			    :parent b
			    :width 100
			    :height 100
			    :border-width 1
			    :background (find-color :name "violet")))
	 (w2 (make-instance 'window
			    :parent b
			    :width 100
			    :height 100
			    :left 0
			    :top 200
			    :border-width 1
			    :background (find-color :name "lightgrey")))
	 (w3 (make-instance 'window
			    :parent b
			    :width 100
			    :height 100
			    :left 200
			    :top 0
			    :border-width 1
			    :background (find-color :name "gray")))
	 (w4 (make-instance 'window
			    :parent b
			    :width 100
			    :height 100
			    :left 200
			    :top 200
			    :border-width 1
			    :background (find-color :name "pink")))
	 (gc1 (make-instance 'graphics-context
			     :foreground (find-color :name "red")))
	 (gc2 (make-instance 'graphics-context
			     :foreground (find-color :name "blue")))
	 (gc3 (make-instance 'graphics-context
			     :foreground (find-color :name "orange")))
	 (d (make-instance 'damage-interest))
	 )
    (push d (interests b))
    (push d (interests w1))
    (push d (interests w2))
    (push d (interests w3))
    (push d (interests w4))    
    (defmethod receive-event (w (i (eql d)) e)
      (declare (ignore  e))
      (when (eq w w1)
	(draw-line w1 0 0 100 100 :gc gc1)
	(draw-line w1 0 100 100 0 :gc gc2)
	(draw-line w1 50 0 50 100 :gc gc3)
	(draw-line w1 0 50 100 50))
      (when (eq w w2)
	(draw-line w2 0 0 100 100 :gc gc1)
	(draw-line w2 0 100 100 0 :gc gc2)
	(draw-line w2 50 0 50 100 :gc gc3)
	(draw-line w2 0 50 100 50))
      (when (eq w w3)
	(draw-line w3 0 0 100 100 :gc gc1)
	(draw-line w3 0 100 100 0 :gc gc2)
	(draw-line w3 50 0 50 100 :gc gc3)
	(draw-line w3 0 50 100 50))
      (let ((w1 w4)
	    (gc1 gc2)
	    (gc2 gc3)
	    (gc3 gc1))
	(when (eq w w1)
	  (draw-line w1 20 0 20 100 :gc gc1)
	  (draw-line w1 80 0 80 100 :gc gc2)
	  (draw-line w1 0 20 100 20 :gc gc3)
	  (draw-line w1 0 80 100 80))
	(when (eq w w2)
	  (draw-line w2 20 0 20 100 :gc gc1)
	  (draw-line w2 80 0 80 100 :gc gc2)
	  (draw-line w2 0 20 100 20 :gc gc3)
	  (draw-line w2 0 80 100 80))
	)
      (with-graphics-context (gc1 :foreground (find-color :name "green"))
	(when (eq w w1)
	  (draw-line w1 0 0 200 100 :gc gc1)
	  (draw-line w1 0 0 100 200 :gc gc2)))
      )
    (setf (mapped b) t))
  (let* ((b (make-instance 'base-window
			   :width 300
			   :height 300
			   :mapped nil
			   :label "Fast Drawing"))
	 (w1 (make-instance 'window
			    :parent b
			    :width 100
			    :height 100
			    :border-width 1
			    :background (find-color :name "violet")))
	 (w2 (make-instance 'window
			    :parent b
			    :width 100
			    :height 100
			    :left 0
			    :top 200
			    :border-width 1
			    :background (find-color :name "lightgrey")))
	 (w3 (make-instance 'window
			    :parent b
			    :width 100
			    :height 100
			    :left 200
			    :top 0
			    :border-width 1
			    :background (find-color :name "gray")))
	 (w4 (make-instance 'window
			    :parent b
			    :width 100
			    :height 100
			    :left 200
			    :top 200
			    :border-width 1
			    :background (find-color :name "pink")))
	 (gc1 (make-instance 'graphics-context
			     :foreground (find-color :name "red")))
	 (gc2 (make-instance 'graphics-context
			     :foreground (find-color :name "blue")))
	 (gc3 (make-instance 'graphics-context
			     :foreground (find-color :name "orange")))
	 (d (make-instance 'damage-interest))
	 )
    (push d (interests b))
    (push d (interests w1))
    (push d (interests w2))
    (push d (interests w3))
    (push d (interests w4))    
    (defmethod receive-event (w (i (eql d)) e)
      (declare (ignore  e))
      (with-fast-output (:drawables (w1 w2)
				      :graphics-contexts (gc1 gc2)
				      :drawing-functions (draw-line))
	 (when (eq w w1)
	   (draw-line w1 0 0 100 100 :gc gc1)
	   (draw-line w1 0 100 100 0 :gc gc2)
	   (draw-line w1 50 0 50 100 :gc gc3)
	   (draw-line w1 0 50 100 50))
	   (when (eq w w2)
	     (draw-line w2 0 0 100 100 :gc gc1)
	     (draw-line w2 0 100 100 0 :gc gc2)
	     (draw-line w2 50 0 50 100 :gc gc3)
	     (draw-line w2 0 50 100 50))
	   (when (eq w w3)
	     (draw-line w3 0 0 100 100 :gc gc1)
	     (draw-line w3 0 100 100 0 :gc gc2)
	     (draw-line w3 50 0 50 100 :gc gc3)
	     (draw-line w3 0 50 100 50))
	   (let ((w1 w4)
		 (gc1 gc2)
		 (gc2 gc3)
		 (gc3 gc1))
	     (when (eq w w1)
	       (draw-line w1 20 0 20 100 :gc gc1)
	       (draw-line w1 80 0 80 100 :gc gc2)
	       (draw-line w1 0 20 100 20 :gc gc3)
	       (draw-line w1 0 80 100 80))
	     (when (eq w w2)
	       (draw-line w2 20 0 20 100 :gc gc1)
	       (draw-line w2 80 0 80 100 :gc gc2)
	       (draw-line w2 0 20 100 20 :gc gc3)
	       (draw-line w2 0 80 100 80))
	     )
	   (with-graphics-context (gc1 :foreground (find-color :name "green"))
				  (when (eq w w1)
				    (draw-line w1 0 0 200 100 :gc gc1)
				    (draw-line w1 0 0 100 200 :gc gc2)))
	   ))
    (setf (mapped b) t))
  )

############## |#

