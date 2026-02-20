;;; -*- Mode: Lisp; Package: MODEL -*-
;;;
;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.
;;;	
;;; Models and model windows.  Some organizing mixins.
;;;
;;; Author: Conal Elliott.  Last Modified Mon Nov 26 16:18:34 1990
;;;
;;; Sccs Id %W% %G%
;;;

(in-package :MODEL :use '(lispview xgl generic ffi clos lisp))

(export '(changed
          watched add-watcher delete-watcher with-changes-buffered
          renderable render render-geometry
          transformable scale rotate translate
          model geometry
          watcher watchee start-watching stop-watching die update
          watcher-window))


;;;; A simple protocol for an object to declare that it has changed.

(defgeneric changed (obj)
  (:documentation
   "Declare that OBJECT has changed.  Any object may do this, but the default
method does nothing."))

(defmethod changed ((obj T))
  )


;;;; Mixin for objects that can have other objects watching them.
(deftype buffering-status ()
  "The possible update-watchers buffering states of a watched.  Either not
buffering, buffering but nothing yet pending, or buffering and at least one
update pending."
  '(member :not-buffering :buffering-no-pending :buffering-pending))

(defclass watched ()
  ((watchers :accessor watchers :initform ())
   (buffering-stat :accessor buffering-stat :initform :not-buffering)))

(defmethod add-watcher ((ob watched) new-watcher)
  "Add a watcher for an object."
  (pushnew new-watcher (watchers ob)))

(defmethod delete-watcher ((ob watched) old-watcher)
  "Delete a watcher for an object."
  (setf (watchers ob) (delete old-watcher (watchers ob) :test #'eq)))

(defmethod changed ((ob watched))
  "Note that a watched has changed.  Either does update-watchers or not,
depending on whether the watched is buffering.  See with-changes-buffererd."
  (if (eq (buffering-stat ob) :not-buffering)
      (update-watchers ob)
      (setf (buffering-stat ob) :buffering-pending)))

(defmacro with-changes-buffered (watched &rest body)
  "Hold off updating watchers about changes to WATCHED until after the forms in
BODY are done.  This way there can be several changes requested but at most one
update message will be sent to each watcher."
  ;; If we're already buffering, then just do the body.  Otherwise, set the
  ;; status to no-pending, do the body, and if the status turned to pending,
  ;; then really do the update.  In any case, reset the status.
  (let ((watched-var (gensym)))
    `(let ((,watched-var ,watched))
      (if (eq (buffering-stat ,watched-var) :not-buffering)
          (progn
            (setf (buffering-stat ,watched-var) :buffering-no-pending)
            (unwind-protect (progn ,@body)
              (when (eq (buffering-stat ,watched-var) :buffering-pending)
                (update-watchers ,watched-var))
              (setf (buffering-stat ,watched-var) :not-buffering)))
          (progn ,@body)))))

(defmethod update-watchers ((ob watched))
  "Tell all an object's watchers to update."
  (mapc 'update (watchers ob))
  (values))


;;;; Objects that can render themselves in a context.  We should probably make
;;;; the distinction between 2d and 3d.

(defclass renderable () ())

(defgeneric render (ctx renderable #|&optional view-trans|#)
  (:documentation 
   "Render the model in the context."))

(defgeneric render-geometry (ctx geometry)
  (:documentation "Render the geometry into the context.  Assume xgl already
locked and the context's transforms are set up properly."))


;;;; Transformable mixin.  Could be used for models, cameras, lights, etc.

;;; Maintains separate scaling, rotation, and translation transforms.
;;; Responds to "render", plus various transformation requests: "scale",
;;; "translate", "rotate", each of which can be either relative or absolute.
(defclass transformable ()
  ((scale-lmt :accessor scale-lmt
              :initform (new-identity-transform))
   (rotate-lmt :accessor rotate-lmt
               :initform (new-identity-transform))
   (translate-lmt :accessor translate-lmt
                  :initform (new-identity-transform))))

(defun update-arg (absolutep)
  "Generate an xgl-trans-update value from absolutep."
  (if absolutep xgl-trans-replace xgl-trans-postconcat))

(defmethod scale ((obj transformable) &key (factor 1.0) x y z xyz absolutep)
  "Translate a transformable according to :factor (default 1.0), and/or
:x, :y, :z (which individually override :factor), or the xgl point :xyz (which
has highest priority).  Scale is relative to current transformation, unless
absolutep keyword argument is given and non-nil."
  (floatifyf factor x y z xyz)
  (xgl-transform-scale (scale-lmt obj)
                       (or xyz
                           (xgl-gpt (or x factor) (or y factor) (or z factor)))
                       (update-arg absolutep))
  (changed obj))

(defmethod rotate ((obj transformable)
                   &key (angle 0.2) (axis xgl-axis-y) absolutep)
  "Rotate a transformable according to keyword args angle (in radians, default
0.2) and axis (defaulting to xgl-axis-y).  Relative to current rotation, unless
:absolutep argument is given and non-nil."
  (floatifyf angle)
  (xgl-transform-rotate (rotate-lmt obj) angle axis (update-arg absolutep))
  (changed obj))

#|

(defmethod arb-rotate ((obj transformable) xcomp ycomp zcomp
		       &key (angle 0.2) absolutep)
  "Like rotate, but takes three arguments specifying the x, y, and z components
of the axis of rotation."
  (floatifyf angle)
  (let ((matrix
	 (let ((size (sqrt (+ (* xcomp xcomp) (* ycomp ycomp)
			      (* zcomp zcomp)))))
	   (assert (not (= size 0.0)) () "zero length rotation axis vector")
	   (let* ((x (/ xcomp size))
		  (y (/ ycomp size))
		  (z (/ zcomp size))
		  (s (sin angle))
		  (c (cos angle))
		  (tt (- 1 c)))
	     (foreign-array-to-pointer
	      (map-foreign-vector
	       'float
	       #'identity
	       (list (+ (* tt x x) c)	; row 1
		     (+ (* tt x y) (* s z))
		     (- (* tt x z) (* s y))
		     0.0
		     (- (* tt x y) (* s z)) ; row 2
		     (+ (* tt y y) c)
		     (+ (* tt y z) (* s x))
		     0.0
		     (+ (* tt x z) (* s y)) ; row 3
		     (- (* tt y z) (* s x))
		     (+ (* tt z z) c) 0.0
		     0.0 0.0 0.0 1.0	; row 4
		     )))))))
    (if absolutep
	(xgl-transform-write (rotate-lmt obj) matrix)
	(with-new-transform tr
	  (xgl-transform-write tr matrix)
	  (xgl-transform-multiply (rotate-lmt obj) (rotate-lmt obj) tr))))
  (changed obj))
|#

(defmethod translate ((obj transformable)
                      &key gpt-xyz (x 0.0) (y 0.0) (z 0.0) absolutep)
  "Translate a transformable according to :x,:y,:z, each defaulting to 0.0 or
the overriding :xyz, which is an xgl 3d floating point point.  Relative to
current translation, unless :absolutep argument is given and non-nil."
  (floatifyf gpt-xyz x y z)
  (xgl-transform-translate (translate-lmt obj)
                           (or gpt-xyz (xgl-gpt x y z))
                           (update-arg absolutep))
  (changed obj))


;;;; Models to be watched and tweeked.

;;; Maintains separate scaling, rotation, and translation transforms.
;;; Later add "bbox", which is now assumed to be [-1,1]x[-1,1]x[-1,1]).
;;; Maybe watched should not be mixed in at this level.
(defclass model (watched transformable renderable)
  ((geometry :initarg :geometry :accessor geometry)))

(defmethod (setf geometry) :after
  (geom (m model))
  (declare (ignore geom))
  (changed m))

(defmethod render (ctx (m model) #|&optional view-trans|#)
  ;;; (declare (ignore view-trans))
  (with-xgl-lock
      (let ((ctx-lmt (xgl-get ctx
                              xgl-ctx-local-model-trans
                              ;;xgl-ctx-view-trans
                              'xgl-trans)))
        ;; Do scaling and rotation, and then translation.
        (xgl-transform-multiply ctx-lmt (scale-lmt m) (rotate-lmt m))
        (xgl-transform-multiply ctx-lmt ctx-lmt (translate-lmt m))
        ;;(when view-trans (xgl-transform-multiply ctx-lmt ctx-lmt view-trans))
	)
      ;;(switch-buffer ctx)
      (xgl-context-new-frame ctx)
      (with-fpes-ignored
	  (render-geometry ctx (geometry m)))
      (xgl-context-post ctx 1)
      ))


;;;; Watcher mixin.   Provides stop-watching, start-watching, and die.
;;;; Specializations should provide update.  The watched object can be of any
;;;; type, but watcheds get their watcher sets updated.  Would it be better to
;;;; allow only watcheds?

(defclass watcher ()
  ;; Fix so the start-watching stuff happens when init arg.  Use :after for
  ;; initialize-instance.
  ((watchee :accessor watchee :initarg :watchee)))

#| This gets called too soon for watcher-window.

(defmethod initialize-instance :after
  ((w watcher) &rest args)
  (declare (ignore args))
  (when (slot-boundp w 'watchee)
    (start-watching w (watchee w))))
|#


(defmethod stop-watching ((w watcher))
  "Stop watching the object we're currently watching, if any."
  (when (slot-boundp w 'watchee)
    (when (typep (watchee w) 'watched)
      (delete-watcher (watchee w) w))
    (slot-makunbound w 'watchee))
  (values))

(defmethod start-watching ((w watcher) ob)
  "Start watching an object.  If the object is a watched, then get added to the
object's set of watchers.  But first, do stop-watching."
  (stop-watching w)
  (setf (watchee w) ob)
  (when (typep ob 'watched)
    (add-watcher ob w))
  (update w)
  (values))

(defmethod die ((w watcher))
  "To be called when a watcher dies.  Returns t.  Is there a standard protocol
for this already?"
  (stop-watching w)
  t)

(defgeneric update (watcher)
  (:documentation "Let the watcher know that its watchee has changed."))

;;; Just for testing.  This should be overriden for real subclasses of watcher.
(defmethod update ((w watcher))
  (format t "~&Ok, now ~s knows that ~s has changed.~%" w (watchee w)))


;;;; Base window that watches renderables.

(defclass watcher-window (watcher base-window)
  ((ctx :accessor ww-ctx)
   #| Add in viewing stuff
   (viewing-trans :accessor viewing-trans)
   (viewpoint :type xgl-pt-f3d :accessor viewpoint
              :initarg :viewpoint :initform (xgl-pt 0 0 -10))
   |#
   )
  (:default-initargs
      :interests (list (make-instance 'damage-interest))
    :width 250 :height 250
    :label "Watcher window"
    :icon (make-instance 'icon :label "Watcher")
    :confirm-quit #'die))

(defmethod update ((ww watcher-window))
  (when (slot-boundp ww 'watchee)
    (render (ww-ctx ww) (watchee ww)
            ;; (viewing-trans ww)
            )))

(defmethod receive-event ((ww watcher-window) (i damage-interest) e)
  (declare (ignore e))
  (update ww))

#|
;;; z-buffering version.  Seems to work
(defmethod (setf status) :after
  ((value (eql :realized)) (ww watcher-window))
  ;; Make a 3d xgl context attached to the window and do update.
  ;; (format t "~&Doing (setf status ) :after.~%")
  (let ((ctx (window-to-xgl-3d-context ww)))
    (with-xgl-lock
        (xgl-object-set
         ctx
         xgl-3d-ctx-surf-face-cull xgl-cull-back
         ;;   Doing hlhsr would cause division by zero error if we weren't
	 ;;   catching these.
         xgl-3d-ctx-hlhsr-mode xgl-hlhsr-zbuffer
         xgl-ctx-new-frame-action
         (logior xgl-ctx-new-frame-clear xgl-ctx-new-frame-hlhsr-action)
         ;;  The vretrace doesn't reduce the flashing any
         ;;xgl-ctx-new-frame-action
         ;;(logior xgl-ctx-new-frame-clear xgl-ctx-new-frame-vretrace)
         0)
        (xgl-object-set
         ctx
         xgl-ctx-vdc-window
         (make-xgl-bounds-f3d :xmin -1.5 :xmax 1.5
                              :ymin -1.5 :ymax 1.5
                              :zmin -100.0 :zmax 200.0)
         0)
        (xgl-object-set
         ctx
         xgl-ctx-vdc-map xgl-vdc-map-aspect
         0)
        (xgl-object-set
         ctx
         xgl-ctx-background-color (make-xgl-color :index 0)
         xgl-ctx-surf-front-color (make-xgl-color :index 2)
         xgl-ctx-edge-color (make-xgl-color :index 0)
         0)
        (xgl-object-set
         ctx
         xgl-ctx-surf-edge-flag 1
         0))
    (setf (ww-ctx ww) ctx))
  ;; The damage interest takes care of updating here.
  )
|#

(defmethod (setf status) :after
  ((value (eql :realized)) (ww watcher-window))
  ;; Make a 3d xgl context attached to the window and do update.
  ;; (format t "~&Doing (setf status ) :after.~%")
  (let ((ctx (window-to-xgl-3d-context ww)))
    (with-xgl-lock
        (xgl-object-set
         ctx
         xgl-ctx-background-color (make-xgl-color :index 0)
         xgl-ctx-surf-front-color (make-xgl-color :index 2)
         xgl-ctx-edge-color (make-xgl-color :index 0)
         0)
        (xgl-object-set
         ctx
         xgl-ctx-surf-edge-flag 1
         xgl-ctx-vdc-map xgl-vdc-map-aspect
         xgl-ctx-vdc-window
         ;; My current geometries do not fall into -1,1.  Remove
         ;; this dependency sometime.
         (make-xgl-bounds-f3d :xmin -1.2 :xmax 1.4
                              :ymin -1.2 :ymax 1.4)
         0)
        (xgl-object-set
         ctx
         xgl-3d-ctx-surf-face-cull xgl-cull-back
         ;;  The vretrace doesn't reduce the flashing any
         xgl-ctx-new-frame-action
         (logior xgl-ctx-new-frame-clear xgl-ctx-new-frame-vretrace)
         0))
    (setf (ww-ctx ww) ctx))
  ;; The damage interest takes care of updating here.
  )

;;; Destroy xgl objects upon dying.
(defmethod die :after
  ((ww watcher-window))
  ;; If there is an error during creation, the ctx doesn't get set
  (when (slot-boundp ww 'ctx)
    (with-xgl-lock
        (let* ((ctx (ww-ctx ww))
               (ras (xgl-get ctx xgl-ctx-device 'xgl-ras)))
          (xgl-object-destroy ras)
          (xgl-object-destroy ctx)
          ))))

(defmethod (setf bounding-region) (new-br (ww watcher-window))
  ;; (format t "~&Doing (setf bounding-region).~%")
  (call-next-method)
  ;; If there is an error during creation, the ctx doesn't get set
  (when (slot-boundp ww 'ctx)
    (with-xgl-lock
        (xgl-window-raster-resize
         (xgl-get (ww-ctx ww) xgl-ctx-device 'xgl-ras))))
  ;; We don't need to update here, because the damage interest does.
  )
