;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)display.lisp	3.10 10/11/91


(in-package "LISPVIEW")


(defmethod platform ((d display-device-status))
  (platform (display d)))


(defmethod initialize-instance :around ((d display) &key status &allow-other-keys)
  (declare (arglist ((d display)
		     &key 
		       status
		       platform
		       host
		       screen
		       server
		       name
		       font-search-path
		       output-buffering
		     &allow-other-keys)))
  (prog1
      (call-next-method)
    (when (eq status :realized)
      (setf (status d) :realized))))


(defmethod initialize-instance :after ((d display) &rest args)
  (apply 'dd-initialize-display (platform d) d args))


(defmethod (setf status) ((value (eql :realized)) (d display))
  (dd-realize-display (platform d) d)
  (prog1
      (setf (slot-value d 'status) :realized)
    (push d *realized-displays*)
    (unless (and (boundp '*default-display*) 
		 (typep *default-display* 'display)
		 (eq (status *default-display*) :realized))
      (setq *default-display* d))))


(defmethod (setf status) ((value (eql :destroyed)) (d display))
  (prog1
      (setf (slot-value d 'status) :destroyed)
    (when (eq (status d) :realized)
      (setq *realized-displays* (delete d *realized-displays*))
      (macrolet ((dolist-destroy (&rest places)
		   `(progn 
		      ,@(mapcar #'(lambda (place)
				    `(dolist (object ,place) 
				       (setf (status object) :destroyed)))
				places))))
	 (dolist-destroy (children (root-canvas d))
			 (display-images d)
			 (display-fonts d)
			 (display-colormaps d)
			 (display-cursors d)))
      (dd-destroy-display (platform d) d))))


(def-solo-reader SCREEN display 
  :driver dd-display-screen
  :type positive-fixnum)

(def-solo-reader HOST display 
  :driver dd-display-host
  :type string)

(def-solo-reader SERVER display 
  :driver dd-display-server
  :type positive-fixnum)

(def-solo-reader NAME display 
  :driver dd-display-name
  :type string)



;;; Backwards compatibility

(defmethod (setf output-buffering) (value (d display))
  (if value
      (pushnew (device d) *output-buffering*)
    (setf *output-buffering* (remove (device d) *output-buffering*))))


(defmethod flush-output-buffer ((d display))
  (dd-flush-output-buffer (platform d) d))


(defmacro with-output-buffering (display &body body)
  (let ((device-var (gensym))
	(display-var (gensym)))
    `(let* ((,display-var ,display)
	    (,device-var (device ,display-var)))
       (let ((*output-buffering* 
	      (if (member ,device-var *output-buffering* :test #'eq)
		  *output-buffering*
		(cons ,device-var *output-buffering*))))
	 ,@body)
       (unless (member ,device-var *output-buffering* :test #'eq)
	 (flush-output-buffer ,display-var)))))



(defmacro without-output-buffering (display &body body)
  `(let ((*output-buffering* (remove (device ,display) *output-buffering*)))
     ,@body))



