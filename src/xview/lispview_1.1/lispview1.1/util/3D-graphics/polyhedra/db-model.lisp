;;; -*- Mode: Lisp; Package: MODEL -*-
;;;
;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.
;;;
;;; Created:       Mon Oct 21 12:12:55 1991 by Conal Elliott
;;; Last Modified: Mon Oct 21 13:37:03 1991 by Conal Elliott
;;;
;;;   Experimental double buffering changes to model.lisp
;;;
;;; Sccs Id %W% %G%
;;;

(in-package :MODEL)


(defclass watcher-window (watcher base-window)
  ((ctx :accessor ww-ctx)
   (dbuf-info :accessor dbuf-info)
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

(defmethod (setf status) :after
  ((value (eql :realized)) (ww watcher-window))
  ;; Make a 3d xgl context attached to the window and do update.
  ;; (format t "~&Doing (setf status ) :after.~%")
  (multiple-value-bind (ctx dbuf-info)
      (window-to-xgl-3d-context-and-dbuf-info ww)
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
    (setf (ww-ctx ww) ctx)
    (setf (dbuf-info ww) dbuf-info))
  )

(defmethod update ((ww watcher-window))
  (when (slot-boundp ww 'watchee)
    (xglut-dbuf-switch-buffer (dbuf-info ww))
    (render (ww-ctx ww) (watchee ww)
            ;; (viewing-trans ww)
            )))



#| Testing:


|#
