;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)click.lisp	1.2 10/17/91


(in-package "LISPVIEW-TEST")


(defclass test-click-flag () ((matched :initform nil)))


(defclass test-click1 (test-click-flag mouse-interest) 
  ((prompt :initform "click left once"))
  (:default-initargs
   :event-spec '(() (:left :click1))))

(defclass test-click2 (test-click-flag mouse-interest) 
  ((prompt :initform "click left twice"))
  (:default-initargs
   :event-spec '(() (:left :click2))))

(defclass test-click3 (test-click-flag mouse-interest) 
  ((prompt :initform "click left three times"))
  (:default-initargs
   :event-spec '(() (:left :click3))))

(defclass test-click4 (test-click-flag mouse-interest) 
  ((prompt :initform "click left four times"))
  (:default-initargs
   :event-spec '(() (:left :click4))))

(defclass test-control-click2 (test-click-flag mouse-interest)
  ((prompt :initform "holding the control key down click middle twice"))
  (:default-initargs
   :event-spec '((:control) ((or :left :middle :right) :click2))))

(defclass test-shift-click2 (test-click-flag mouse-interest)
  ((prompt :initform "holding the shift key down click right twice"))
  (:default-initargs
   :event-spec '((:shift) ((or :left :middle :right) :click2))))

(defparameter test-click-interest-classes 
  '(test-click1 test-click2 test-click3 test-click4 test-control-click2 test-shift-click2))


(defmethod receive-event (w (i test-click-flag) e)
  (declare (ignore w e))
  (setf (slot-value i 'matched) t))


(def-test test-button-click-interests ()
  (
   :type :test
   :interactive t
  )

  (let ((w (make-instance 'base-window :label "test-clicks")))
    (unwind-protect 
	(dolist (c test-click-interest-classes)
	  (independent-test 
	   (let ((i (make-instance c)))
	     (setf (interests w) (list i))
	     (format t "~A (hit return if nothing happens) " (slot-value i 'prompt))
	     (force-output)
	     (MP:process-wait "Waiting for Click" 
			      #'(lambda ()
				  (or (slot-value i 'matched) (listen))))
	     (if (slot-value i 'matched)
		 (format t "OK~%")
	       (progn 
		 (read-line)
		 (error "Failed to match click interest: ~S" i))))))
      (destroy w))))





(defclass create-square (mouse-interest)  ()
  (:default-initargs
   :event-spec '(() (:left :click2))))

(defclass pick-square (mouse-interest) ()
  (:default-initargs
   :event-spec '(() (:left :down))))

(defclass drag-square (mouse-interest) ()
  (:default-initargs
   :event-spec '((:left) :move)))

(defclass drop-square (mouse-interest) ()
  (:default-initargs
   :event-spec '(() (:left :up))))

(defclass repaint-squares (damage-interest) ())


(defun double-click-demo ()
  (let* ((squares nil)
	 (dragging-square nil)
	 (gc (make-instance 'graphics-context :line-width 3))
	 (window
	  (make-instance 'base-window 
	    :label "Double Click to Create a Square"
	    :interests (mapcar #'make-instance '(create-square
						 pick-square
						 drag-square
						 drop-square
						 repaint-squares)))))
    (flet 
     ((event-to-square (e)
	(make-region 
	 :left (- (mouse-event-x e) 10) :top (- (mouse-event-y e) 10) :width 20 :height 20))

      (draw-square (s operation)
	(setf (operation gc) operation)
	(draw-rectangle window
	  (region-left s) (region-top s) (region-width s) (region-height s) :gc gc)))

     (defmethod receive-event (w (i create-square) e)
       (declare (ignore w))
       (let ((square (event-to-square e)))
	 (push square squares)
	 (draw-square square boole-1)))

     (defmethod receive-event (w (i pick-square) e)
       (declare (ignore w))
       (let* ((x (mouse-event-x e)) 
	      (y (mouse-event-y e))
	      (square (find-if #'(lambda (s) (region-contains-xy-p s x y)) squares)))
	 (when square
	   (setf squares (delete (setf dragging-square square) squares)))))

     (defmethod receive-event (w (i drag-square) e)
       (declare (ignore w))
       (when dragging-square
	 (draw-square dragging-square boole-xor)
	 (draw-square (setf dragging-square (event-to-square e)) boole-xor)))

     (defmethod receive-event (w (i drop-square) e)
       (declare (ignore w))
       (when dragging-square
	 (draw-square dragging-square boole-xor)
	 (draw-square (setf dragging-square (event-to-square e)) boole-1)
	 (push dragging-square squares)
	 (setf dragging-square nil)))

     (defmethod receive-event (w (i repaint-squares) e)
       (declare (ignore w e))
       (dolist (s squares) (draw-square s boole-1)))

     (defmethod (setf status) ((value (eql nil)) (x (eql window)))
       (call-next-method)
       (destroy gc)))

    window))


(def-test test-button-click-usage ()
  (
   :type :test
   :interactive t
  )

  (let ((w (double-click-demo)))
    (format t "~%Create a few squares and then drag them around with the left button~%")
    (unwind-protect
	(unless (yes-or-no-p "Can you create and drag squares OK")
	  (error "test-button-click-usage failed"))
      (destroy w))))
  
