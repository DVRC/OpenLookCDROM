;;; -*- Mode: Lisp; Package: xgl -*-
;;;
;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.
;;;
;;; Created:       Fri Oct 18 15:32:46 1991 by Conal Elliott
;;; Last Modified: Mon Oct 21 14:02:45 1991 by Conal Elliott
;;;
;;;   Experimental double-buffering support, via xglut.
;;;
;;; Sccs Id %W% %G%
;;;

(in-package :xgl)

(export '(window-to-xgl-3d-context-and-dbuf-info))



;;; Changed from basics.lisp

(defun window-to-xgl-3d-context-and-dbuf-info
    (window &optional (color-list *default-rgb-color-list*))
  "Make a new xgl 3d context, attached to WINDOW.  Optionally takes a color
list, with a reasonable, though small, default.  Sets up double buffering.
Returns two values: the context and new a double-buffering info structure."
  (with-xgl-lock
      (let* ((ras (xgl-window-raster-device-create
		   xgl-win-x (window-to-xgl-xwin window)
		   0))
	     (ctx (xgl-3d-context-create xgl-ctx-device ras 0))
	     (dbuf-info
	      (make-xglut-dbuf-info
	       :ctx ctx
	       :number-of-colors-per-buffer (length color-list)
	       :color-table (foreign-array-to-pointer
			     (map-foreign-vector 'xgl-color
			       #'(lambda (rgb)
				   (make-xgl-color :rgb rgb))
			       color-list)))))
	(xglut-dbuf-init dbuf-info)
	(xglut-dbuf-on dbuf-info)
	(values ctx dbuf-info))))



#| Testing:


|#
