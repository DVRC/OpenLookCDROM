;;; -*- Mode: Lisp; Package: XGL -*-
;;;
;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.
;;;
;;; Assorted basic stuff.
;;;
;;; Author: Conal Elliott.  Last Modified Thu Oct 11 15:34:02 1990
;;;
;;; Sccs Id %W% %G%
;;;

(in-package :XGL :use '(:generic :lisp))

;;; ELIMINATE THE 2D STUFF (put in junk.lisp)

(export '(with-fpes-ignored
	  sys-st xgl-get))
(export '(*default-rgb-color-list* indexed-color create-color-list
	  create-xgl-cmap))
(export '(window-to-xgl-xwin window-to-xgl-3d-context
	  xgl-pt xgl-pt-2d xgl-gpt xgl-gpt-2d
	  polyhedron-multi-simple-polygon-args
	  polygon-multi-simple-polygon-args
	  point-to-xgl-pt
	  new-identity-transform
	  with-new-xgl-object with-new-transform with-new-transform-2d
	  with-xgl-context-changes
	  copy-trans multiply-trans))

(defmacro with-fpes-ignored (&rest body)
  "Execute body while ignoring floating-point exceptions.  Necessary because
XGL 2.0 rendering does underflows and divide-by-zeros, which are harmless and
ignored in a standard C environment."
  `(with-fpes-ignored-thunk #'(lambda () ,@body)))

(defun with-fpes-ignored-thunk (thunk)
  (let ((h (sys:get-lisp-interrupt-handler 8)))
    (unwind-protect
	 (progn
	   (sys:setup-interrupt-handler 8 :ignore)
	   (funcall thunk))
      (sys:setup-interrupt-handler 8 h))))


;;; Is this a good way to handle this?
(defvar sys-st (with-xgl-lock (xgl-open 0))
  "The xgl system state object.")

(defun xgl-get (obj attr type &optional fptr)
  "Like xgl-object-get, but takes attribute type instead of pointer, and does
the foreign pointer construction itself.  Optionally takes a foreign pointer
to use instead of a new one.  Do the new ones ever get GC'd?"
  (let ((fptr (or fptr (make-foreign-pointer :type `(:pointer ,type)))))
    (xgl-object-get obj attr fptr)
    (foreign-value fptr)))



;;; Various color-related stuff.

(defconstant *black* (make-xgl-color-rgb))
(defconstant *red* (make-xgl-color-rgb :r 1.0))
(defconstant *green* (make-xgl-color-rgb :g 1.0))
(defconstant *blue* (make-xgl-color-rgb :b 1.0))
(defconstant *yellow* (make-xgl-color-rgb :r 1.0 :g 1.0))
(defconstant *cyan* (make-xgl-color-rgb :g 1.0 :b 1.0))
(defconstant *magenta* (make-xgl-color-rgb :r 1.0 :b 1.0))
(defconstant *white* (make-xgl-color-rgb :r 1.0 :g 1.0 :b 1.0))

(defparameter *default-rgb-color-list*
  (list *black* *red* *green* *blue* *yellow* *cyan* *magenta* *white*)
  "Rgb colors to be used by default in 3d xgl contexts.  The default value of
this default is black, red, green, blue, yellow, cyan, magenta, white.")

(defun create-color-list (color-rgbs)
  "Make an xgl-color-list, given COLOR-RGBS which is a list of xgl-color-rgb
pointers."
  (make-xgl-color-list
   :start-index 0
   :length (length color-rgbs)
   :colors (foreign-array-to-pointer
	    (map-foreign-vector 'xgl-color
	      #'(lambda (rgb)
		  (make-xgl-color :rgb rgb))
	      color-rgbs))))

(defun create-xgl-cmap (color-rgbs)
  "Make a color-map, given COLOR-RGBS which is a list of xgl-color-rgb
pointers."
  (with-xgl-lock
      (xgl-color-map-create
       xgl-cmap-color-table-size (length color-rgbs)
       xgl-cmap-color-table (create-color-list color-rgbs)
       0)))

(defun window-to-xgl-xwin (window)
  (make-xgl-x-window
   :x-display (lv::xview-object-dsp (lv:device window))
   :x-screen (lv:screen (lv:display window))
   :x-window (lv::xview-object-xid (lv:device window))))

(defvar *default-cmap* (create-xgl-cmap *default-rgb-color-list*)
  "The default color map for xgl contexts.")

(defun window-to-xgl-3d-context (window &optional (cmap *default-cmap*))
  "Make a new xgl 3d context, attached to WINDOW.  Optionally takes a color
map, with a reasonable, though small, default."
  (with-xgl-lock
      (let ((ras (xgl-window-raster-device-create
		  xgl-win-x (window-to-xgl-xwin window)
		  xgl-ras-color-map cmap
		  0)))
	(xgl-3d-context-create xgl-ctx-device ras 0))))

(defun xgl-pt (x y z)
  "Make a f3d xgl point from floats X Y Z."
  (make-xgl-pt-f3d :x (coerce x 'float)
		   :y (coerce y 'float)
		   :z (coerce z 'float)))

(defun xgl-pt-2d (x y)
  "Make a f2d xgl point from floats X Y."
  (make-xgl-pt-f2d :x (coerce x 'float)
		   :y (coerce y 'float)))

(defun xgl-gpt (x y z)
  "Make a general xgl point."
  (make-xgl-pt :pt-type xgl-pt-f3d
	       :pt (make-xgl-pt-position :f3d (xgl-pt x y z))))

(defun xgl-gpt-2d (x y)
  "Make a general xgl 2d point."
  (make-xgl-pt :pt-type xgl-pt-f2d
	       :pt (make-xgl-pt-position :f2d (xgl-pt-2d x y))))


(defun polyhedron-multi-simple-polygon-args (points indexed-faces face-colors)
  "Come up with the arguments (except for the first) to
xgl-multi-simple-polygon to render a polyhedron.  Factored this way so that
static polyhedra may be converted to the optimal form just once."
  (list
   0				; optimization flags
   (make-xgl-facet-list
    :facet-type xgl-facet-color
    :num-facets (length face-colors)
    :facets (make-xgl-facet-list-struct-1
             :color-facets
             (foreign-array-to-pointer
              (map-foreign-vector 'xgl-color-facet
                #'(lambda (color)
                    (make-xgl-color-facet :color color))
                face-colors))))
   (make-null-foreign-pointer 'xgl-bbox)
   (length indexed-faces)
   (foreign-array-to-pointer
    (map-foreign-vector 'xgl-pt-list
      #'(lambda (f)
          (make-xgl-pt-list :pt-type xgl-pt-f3d
                            :bbox (make-null-foreign-pointer 'xgl-bbox)
                            :num-pts (length f)
                            :pts (make-xgl-pt-pcnf
                                  :f3d
                                  (foreign-array-to-pointer
                                   (map-foreign-vector 'xgl-pt-f3d
                                     #'(lambda (i)
                                         (point-to-xgl-pt
                                          (elt points i)))
                                     f)))))
      indexed-faces))))

(defun polygon-multi-simple-polygon-args (points)
  "Come up with the arguments (except for the first) to
xgl-multi-simple-polygon to render a simple polygon.  Factored this way so that
static polygons may be converted to the optimal form just once."
  (list
   0				; optimization flags
   (make-null-foreign-pointer 'xgl-facet-list) ; get color from context
   (make-null-foreign-pointer 'xgl-bbox)
   1				; only one simple polygon
   (foreign-array-to-pointer
    (map-foreign-vector 'xgl-pt-list
      #'(lambda (f)
          (make-xgl-pt-list :pt-type xgl-pt-f3d
                            :bbox (make-null-foreign-pointer 'xgl-bbox)
                            :num-pts (length f)
                            :pts (make-xgl-pt-pcnf
                                  :f3d
                                  (foreign-array-to-pointer
                                   (map-foreign-vector 'xgl-pt-f3d
				     #'point-to-xgl-pt
                                     f)))))
      (list points)))))

(defun point-to-xgl-pt (p)
  "Convert a point into an xgl f3d point."
  (xgl-pt (point:point-x p) (point:point-y p) (point:point-z p) ))

(defun new-identity-transform (&optional (xgl-trans-dimen xgl-trans-3d))
  "Make a new identity 3D floating point transform."
  (with-xgl-lock
      (xgl-transform-create
       xgl-trans-data-type xgl-data-flt
       xgl-trans-dimension xgl-trans-dimen
       0)))

(defmacro with-new-xgl-object ((obj-variable construction-form)
			       &rest body)
  "Create a new xgl object to be called OBJ-VARIABLE, constructed by
CONSTRUCTION-FORM to be used in the BODY.  The object is destoyed upon exit
 (normal or otherwise) from BODY."
  `(let ((,obj-variable ,construction-form))
    (unwind-protect
	 (progn ,@body)
      (with-xgl-lock (xgl-object-destroy ,obj-variable)))))

(defmacro with-new-transform (trans-variable &rest body)
  "Create a new (3D float) transform to be called TRANS-VARIABLE during the
execution of BODY.  Initialized to the identity.  The transform is destoyed
upon exit (normal or otherwise) from BODY."
  `(with-new-xgl-object (,trans-variable (new-identity-transform))
    ,@body))

(defmacro with-new-transform-2d (trans-variable &rest body)
  "Create a new 2D float transform to be called TRANS-VARIABLE during the
execution of BODY.  Initialized to the identity.  The transform is destoyed
upon exit (normal or otherwise) from BODY."
  `(with-new-xgl-object (,trans-variable
			 (new-identity-transform xgl-trans-2d))
    ,@body))



;;; I don't use this, and am not sure it works.
(defmacro with-xgl-context-changes ((ctx &rest att-value-pairs) &rest body)
  "Temporarily modify CTX via ATT-VALUE-PAIRS while executing BODY."
  (assert (= (mod (length att-value-pairs) 2) 0)
	  ()
	  "attribute-value list ~s has an odd number of members"
	  att-value-pairs)
  (labels ((every-eventh-member-and-zero (l)
	     (if (null l)
		 '(0)
		 (cons (first l) (every-eventh-member-and-zero
				  (rest (rest l)))))))
    (let ((ctx-var (gensym "CTX-")))
      `(let ((,ctx-var ,ctx))
	(with-xgl-lock
	    (xgl-context-push ,ctx-var
	     (vector ,@(every-eventh-member-and-zero att-value-pairs))))
	(unwind-protect
	     (progn
	       (with-xgl-lock
		   (xgl-object-set ,ctx-var ,@att-value-pairs 0))
	       ,@body)
	  (with-xgl-lock
	      (xgl-context-pop ,ctx-var)))))))



;;; Convenience transform functions.

(defun copy-trans (trans)
  "Make a copy of TRANS."
  (let ((new-trans (new-identity-transform)))
    (xgl-transform-copy new-trans trans)
    new-trans))

(defun multiply-trans (trans-left trans-right)
  "Make a new transform by multiplying TRANS-LEFT by TRANS-RIGHT."
  (let ((product (new-identity-transform)))
    (xgl-transform-multiply product trans-left trans-right)
    product))
