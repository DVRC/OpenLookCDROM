;;;; x-bucky.lisp 

(in-package 'lispview)
(export '(match-event-spec))

;;; This is similar to lispview:match-event.  It finds an interest on
;;; a canvas which will match the given event spec (hopefully, the
;;; same way the corresponding event would do it!).  Note that the
;;; event spec should correspond to a single unique low-level X11
;;; event.
(let ((internal-mouse-doc-interest	;lexical closure for dummy mouse interest
       (make-instance 'mouse-interest :event-spec '(() (:left :down)))))
  (defun match-event-spec (canvas event-spec)
    (setq event-spec (parse-mouse-event-spec event-spec))
    (setf (slot-value internal-mouse-doc-interest 'parsed-event-spec) event-spec)
    (let* ((xvo (device canvas))
	   (type (car (x11-event-types internal-mouse-doc-interest)))
	   (button
	    (car (if (or (= type #.X11:ButtonPress) (= type #.X11:ButtonRelease))
		     (mapcar #'(lambda (buttons)
				 (case (cadr buttons);; no support for button chords
				   (:button0 #.X11:Button1)
				   (:button1 #.X11:Button2)
				   (:button2 #.X11:Button3)
				   (:button3 #.X11:Button4)
				   (:button4 #.X11:Button5)))
			     (cdaadr event-spec))))))
      (multiple-value-bind (state-mask state-match)
	  (x11-event-state-target (cdadar event-spec))
	(loop for xvi in (svref (xview-canvas-interest-table xvo) type) do
	      (when (and (= button (x11-mouse-interest-button xvi))
			 (= (x11-mouse-interest-state-match xvi) state-match))
		(return (x11-interest-object xvi)))
	      finally (return nil))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; These two functions from Hmullers bug fix message: Thu, 7 Mar 91
;;;; 14:30:16 PST.

(defun xview-install-initial-interests (canvas xvo id)
  (let ((input-mask 0))
    (dolist (interest (interests canvas))
      (setf input-mask 
	    (logior input-mask (xview-insert-interest xvo interest :at 0 canvas))))
    (XV:xv-set id :win-consume-x-event-mask input-mask
	          :win-ignore-x-event-mask
		  (if (/= 0 (logand input-mask X11:KeyReleaseMask))
		      0
		    X11:KeyReleaseMask))))

(defmethod dd-insert-interest ((p XView) interest relation relative canvas)
  (when (eq (status canvas) :realized)
    (XV:with-xview-lock 
     (let* ((xvo (device canvas))
	    (dsp (xview-object-dsp xvo))
	    (id (xview-object-id xvo)))
       (when id
	 (XV:xv-set id 
	   :win-consume-x-event-mask 
	     (xview-insert-interest xvo interest relation relative canvas)
	   :win-ignore-x-event-mask 
	     (if (svref (xview-canvas-interest-table xvo) X11:KeyRelease)
		 0
	       X11:KeyReleaseMask))
	 (defeat-xview-passive-grab dsp (xview-object-xid xvo))
	 (xview-maybe-XFlush (xview-object-xvd xvo) dsp))))))


