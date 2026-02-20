;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)text-demo.lisp	1.5 7/3/90 10:09:45

;;; LispView Text Demo
;;;
;;; USAGE: 
;;; Load this file and then type (make-instance 'demo:text-demo).  Mouse 
;;; left to start typing, typing a return redraws the display with whatever 
;;; you've typed.  The delete key works  but not much else.


(in-package :demo :use '("LISP" "CLOS" "LISPVIEW"))

(export '(text-demo))


(defclass start-typing (mouse-interest) ()
  (:default-initargs 
   :event-spec '(() (:left :down))))

(defclass echo-keyboard (keyboard-interest) ())

(defclass repaint-text (damage-interest) ())

(defclass text-viewport (viewport) 
  ((text-demo :initarg :text-demo))
  (:default-initargs
   :interests (mapcar #'make-instance '(start-typing repaint-text))))

(defclass text-demo-base-window (base-window)
  ((text-demo :initarg :text-demo))
  (:default-initargs
   :interests (list (make-instance 'echo-keyboard))))

(defparameter initial-text
  "The quick brown fox jumped over the old lazy dog.")
  
(defclass text-demo ()
  (window
   viewport
   font
   ascent
   linefeed-height
   draw 
   erase
   (x :initform 0)
   (y :initform 0)
   char-widths
   (buffer :initform (make-array (length initial-text) 
		       :element-type 'string-char
		       :adjustable t 
		       :fill-pointer t
		       :initial-contents initial-text))))



(defmethod initialize-instance :after ((vp text-viewport) &rest args)
  (declare (ignore args))
  (let ((td (slot-value vp 'text-demo)))
    (with-slots (font char-widths) td
      (setf char-widths 
	      (map 'vector 
		   #'(lambda (code)
		       (let ((char-metrics (if code (char-metrics font code))))
			 (if char-metrics
			     (char-width char-metrics)
			   0)))
		   (let ((codes nil))
		     (dotimes (code char-code-limit (nreverse codes))
		       (push (if (graphic-char-p (code-char code))
				 code)
			     codes))))
	    (slot-value vp 'text-demo) td))))


(defmethod receive-event (vp (i start-typing) event)
  (with-slots (ascent linefeed-height erase x y char-widths buffer) (slot-value vp 'text-demo)
    (let ((line-top (* linefeed-height (truncate (mouse-event-y event) linefeed-height))))
      (draw-rectangle vp 0 line-top 
		      (region-width (output-region vp)) linefeed-height 
		      :fill-p t :gc erase)
      (setf (fill-pointer buffer) 0
	    y (+ line-top ascent)
	    x 0))))

  
(defmethod receive-event (vp (i echo-keyboard) event)
  (let ((char (keyboard-event-char event))
	(td (slot-value vp 'text-demo)))
    (with-slots (ascent linefeed-height draw erase x y char-widths buffer) td
      (case char 
	((#\newline #\return)
	 (setf x 0)
	 (incf y linefeed-height)
	 (let ((r (output-region vp)))
	   (draw-rectangle vp 0 0 (region-width r) (region-height r) :fill-p t :gc erase))
	 (repaint-text-demo td (list (view-region vp))))
	(#\rubout 
	 (let ((i (1- (fill-pointer buffer))))
	   (when (>= i 0)
	     (setf (fill-pointer buffer) i
		   char (aref buffer i))
	     (decf x (svref char-widths (char-code char)))
	     (draw-char vp x y char :gc erase))))
	(t
	 (when (string-char-p char)
	   (vector-push-extend char buffer)
	   (draw-char vp x y char :gc draw)
	   (incf x (svref char-widths (char-code char)))))))))


(defun repaint-text-demo (td damaged-regions)
  (declare (LCL:type-reduce number fixnum))
  (with-slots (viewport font ascent linefeed-height draw buffer) td
    (let* ((br (apply #'region-bounding-region damaged-regions))
	   (x 0)
	   (y (+ (* linefeed-height (truncate (region-top br) linefeed-height)) ascent))
	   (nlines (ceiling (region-height br) linefeed-height)))
      (with-output-buffering (display viewport)
	(dotimes (i nlines)
	  (draw-string viewport x y buffer :gc draw)
	  (incf y linefeed-height))))))


(defmethod receive-event (vp (i repaint-text) event)
  (repaint-text-demo (slot-value vp 'text-demo) (damage-event-regions event)))


(defmethod initialize-instance :after ((td text-demo) &rest initargs)
  (declare (ignore initargs))
  
  (with-slots (window 
	       viewport
	       font
	       ascent
	       linefeed-height
	       draw
	       erase) td
    (setf window 
	    (make-instance 'text-demo-base-window 
	      :text-demo td
   	      :keyboard-focus-mode :locally-active
	      :mapped nil
	      :label "Text"
	      :icon (make-instance 'icon 
		      :background (lv:find-color :name "lightsteelblue")
		      :label (if (probe-file "lispview-app.icon")
				 (list "Text"
				       (make-instance 'image 
					       :filename "lispview-app.icon"))
				 "Text"))
	      :left-footer 
	      "Click SELECT on a line, type some text & press RETURN")

	  font 
	    (make-instance 'font
	      :family "Lucida"
	      :slant :roman
	      :point-size 12)

	  ascent (font-ascent font)

	  linefeed-height (+ 3 ascent (font-descent font))

	  draw (make-instance 'graphics-context :font font)

	  erase 
            (make-instance 'graphics-context 
	      :font font 
              :foreground (background window))
	  
	  viewport
            (make-instance 'text-viewport
	      :parent window
	      :container-region (copy-region (bounding-region window) :left 0 :top 0)
	      :output-region (make-region :width 750 :height 2000)
	      :horizontal-scrollbar (make-instance 'horizontal-scrollbar)
	      :vertical-scrollbar (make-instance 'vertical-scrollbar)
	      :text-demo td))
	    
    (setf (keyboard-focus window) viewport
	  (mapped window) t)))


(format t "~%To run this demo: (make-instance 'demo:text-demo)~%")


