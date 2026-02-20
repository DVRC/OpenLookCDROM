;;; -*-Mode: LISP; Package: LISPVIEW; Base: 10; Syntax: Common-lisp -*-
;;;
;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;
;;; Example "presentation style" framework.  "Presentation" is an abstract superclass,
;;; it contains one slot - a presentation-canvas.  Subclasses of presentation must 
;;; support the following protocol:
;;; 
;;;    (defmethod contains-xy-p (presentation x y))
;;;    (defmethod overlaps-region-p (presentation region))
;;;    (defmethod redraw (presentation))
;;;    (defmethod enter (presentation))  
;;;    (defmethod exit (presentation))  
;;; 
;;; The first two methods return non-nil if the presentation "contains" the x,y coordinate
;;; or overlaps the specified region.  The redraw method is required to render the 
;;; presentation on (slot-value presentation 'canvas).  The enter and exit methods are 
;;; called whenever the mouse moves from one presentation to another.  Enter is only
;;; called if the value of the presentation-canvas' predicate returns non nil.  
;;;
;;; New presentations are added to the presentation-canvas with insert, removed with
;;; withdraw.  The interface for these methods is the same as for Solo canvases.
;;;
;;;   (insert presentation relation relative presentation-canvas)
;;;   (withdraw presentation presentation-canvas)

(in-package "LISPVIEW")


(defclass mouse-moved (mouse-interest) ()
  (:default-initargs
   :event-spec '(() :move)))

(defclass select (mouse-interest) ()
  (:default-initargs
   :event-spec '(() (:left :down))))

(defclass redraw (damage-interest) ())

(defclass presentation-canvas (viewport)
  ((presentations :initform nil)
   (current :initform nil)
   (predicate :initform #'(lambda (x) (declare (ignore x)) t))
   (action :initform #'(lambda (x) (declare (ignore x)))))         
  (:default-initargs
   :vertical-scrollbar (make-instance 'vertical-scrollbar)
   :horizontal-scrollbar (make-instance 'horizontal-scrollbar)
   :interests (mapcar #'make-instance '(mouse-moved
					select
					redraw))))

(defclass presentation () 
  ((canvas :initform nil)))


(defmethod insert ((x presentation) relative relation presentation-canvas)
  (with-slots (presentations) presentation-canvas
    (setf presentations (list-insert x relative relation presentations)
	  (slot-value x 'canvas) presentation-canvas)
    (redraw x)))

(defmethod withdraw ((x presentation) presentation-canvas)
  (with-slots (presentations) presentation-canvas
    (setf presentations (delete x presentations :test #'eq)
	  (slot-value x 'canvas) nil)))



(defun update-current-presentation (presentation-canvas event)
  (with-slots (presentations current predicate) presentation-canvas  
    (let* ((x (mouse-event-x event))
	   (y (mouse-event-y event))
	   (new (dolist (p presentations)
		  (when (and (contains-xy-p p x y)
			     (funcall predicate p))
		    (return p)))))
      (unless (eq current new)
	(exit current)
	(setf current new)
	(enter new)))))
  

(defmethod receive-event (presentation-canvas (i mouse-moved) event)
  (update-current-presentation presentation-canvas event))


(defmethod receive-event (presentation-canvas (i redraw) event)
  (let ((r (apply #'region-bounding-region (damage-event-regions event))))
    (with-slots (presentations) presentation-canvas
      (dolist (p (nreverse (copy-list presentations))) ;; draw back to front
	(when (overlaps-region-p p r)
	  (redraw p))))))


(defmethod enter (presentation) (declare (ignore presentation)))
(defmethod exit (presentation) (declare (ignore presentation)))



(defmethod receive-event (presentation-canvas (i select) event)
  (update-current-presentation presentation-canvas event)
  (with-slots (current action) presentation-canvas

    ;; If the mouse went down over the current selection then funcall
    ;; the function stored in the presentation canvas' action slot.

    (when (and current 
	       action 
	       (contains-xy-p current (mouse-event-x event) (mouse-event-y event)))
      (funcall action current))))


(defun accept (presentation-canvas 
	       &key 
	    	 (region (output-region presentation-canvas))
	         (type t)
	         (predicate #'(lambda (x) (declare (ignore x)) t)))
  (let* ((no-selection (gensym))
	 (selection no-selection))
    (flet ((sensitive-p (presentation)
             (and (overlaps-region-p presentation region)
		  (subtypep (type-of presentation) type)
		  (funcall predicate presentation)))
	   (accept-selection (presentation)
	     (setf selection presentation))
	   (wait-for-selection ()
	     (not (eq selection no-selection))))

	  (setf (slot-value presentation-canvas 'predicate) #'sensitive-p
		(slot-value presentation-canvas  'action) #'accept-selection)
	  (MP:process-wait "Waiting" #'wait-for-selection)
	  selection)))



