;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.
;;;	

(in-package "USER") 

(defmacro checking-watchee (mw &rest body)
  `(if (slot-boundp (watcher-window ,mw) 'model:watchee)
    (progn ,@body)
    (cerror "Ignore operation" "~&No model being currently watched.~%")))

(defmethod do-rotate ((mw model-watcher))
  (checking-watchee mw
    (let ((watchee (model:watchee (watcher-window mw)))
	  (axes (mapcar #'choose-axis (lv:value (rotation-axes mw))))
	  (angle (* 2 pi .01 (lv:value (rotate-slider mw)))))
      (dotimes (i (lv:value (rotation-count mw)))
	(if axes
	    (model:with-changes-buffered watchee
	      (dolist (axis axes)
		(model:rotate watchee :axis axis :angle angle)))
	    #|
	    (multiple-value-bind (x y z)
	    (arb-rotate watchee ...)
            |#
	    (progn))))))

(defun choose-axis (axis-string)
  (cdr (assoc axis-string
	      `(("X" . ,xgl:xgl-axis-x)
		("Y" . ,xgl:xgl-axis-y)
		("Z" . ,xgl:xgl-axis-z))
	      :test #'string-equal)))


(defmethod do-ph-operation ((mw model-watcher) operation)
  (checking-watchee mw
    (let ((new-ph (funcall operation (model:geometry
				      (model:watchee (watcher-window mw)))))
	  (new-mw (make-instance 'model-watcher)))
      (model:start-watching (watcher-window new-mw)
			    (make-instance 'model:model :geometry new-ph))
      ;; Copy axes and scale
      (setf (lv:value (rotation-axes new-mw)) (lv:value (rotation-axes mw)))
      (setf (lv:value (rotation-count new-mw)) (lv:value (rotation-count mw)))
      new-mw)))

(defmethod do-scale ((mw model-watcher))
  (model:scale (model:watchee (watcher-window mw))
	       :factor (/ (lv:value (scale-slider mw)) 100)
	       :absolutep t))

(defmethod do-truncation ((mw model-watcher))
  (do-ph-operation mw #'ph-opers:truncation))

(defmethod do-dual ((mw model-watcher))
  (do-ph-operation mw #'ph-opers:dual))

(defmethod do-platonic ((mw model-watcher))
  ;; Factor out stuff in common with do-ph-operation.  I could use
  ;; do-ph-operation, except that it does the checking-watchee.
  (let ((ph (choose-platonic (lv:value (platonic-setting mw))))
	(new-mw (make-instance 'model-watcher)))
    (model:start-watching (watcher-window new-mw)
			  (make-instance 'model:model :geometry ph))
    ;; Copy axes and scale
    (setf (lv:value (rotation-axes new-mw)) (lv:value (rotation-axes mw)))
    (setf (lv:value (rotation-count new-mw)) (lv:value (rotation-count mw)))))

(defun choose-platonic (name)
  (cdr (assoc name
	      `(("tetrahedron" . ,ph-lib:tetrahedron)
		("hexahedron" . ,ph-lib:hexahedron)
		("octahedron" . ,ph-lib:octahedron)
		("dodecahedron" . ,ph-lib:dodecahedron)
		("icosahedron" . ,ph-lib:icosahedron))
	      :test #'string-equal)))

;;; Class of sliders initialized to 100 (percent)
(defclass slider-100-init (lv:slider)
  ())

(defmethod initialize-instance
    :after ((sl slider-100-init) &rest args)
    (declare (ignore args))
    (setf (lv:value sl) 100))



;;;; Convenient functions for starting watchers

(defmethod watch ((m model:model))
  "Take a model start a model-watcher watching it.  Returns the model."
  (model:start-watching (watcher-window (make-instance 'model-watcher))
			m)
  m)

(defmethod watch ((ph ph:ph))
  "Make a model of PH and start a model-watcher watching a model of it.
Returns the model for later tweeking."
  (watch (make-instance 'model:model :geometry ph)))
