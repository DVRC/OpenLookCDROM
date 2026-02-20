;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;; Re: No graphic output will appear on a window until after it has first 
;;; received a damage event, i.e., until it is initially mapped on the
;;; screen.  [LispView Programming Manual, Sec. 1.4]
;;;
;;; Subject: Sometimes it's hard to wait for damage
;;;
;;; Here's an example of how to draw on a window without messing with
;;; damage events.
;;;
;;; Note that if you call (make-instance 'demo-window) from within the local
;;; event dispatching process, e.g. from within a button command, the local
;;; event dispatching process will hang.  

;---------------------------
(in-package "LISPVIEW")

(defclass demo-window (base-window) ())

(defmethod initialize-instance :around ((x demo-window) &rest initargs &key interests &allow-other-keys)
  (let* ((damage-interest (make-instance 'damage-interest))
	 (ready-for-drawing nil)
	 (interests (cons damage-interest interests)))

    (defmethod receive-event (w (i (eql damage-interest)) e)
      (setf (interests x) (remove i (interests x) :test #'eq)
	    ready-for-drawing t))

    (prog1
	(apply #'call-next-method x :interests interests initargs)
      (MP:process-wait (format nil "Waiting for damage-event for ~S" x)
		       #'(lambda () ready-for-drawing)))))

    
(draw-string (make-instance 'demo-window) 50 50 "I've been damaged!")

