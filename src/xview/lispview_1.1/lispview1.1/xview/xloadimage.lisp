;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)xloadimage.lisp	1.2 10/11/91

;;; Foreign interface to a library version of xloadimage.  See xloadimage/Makefile.lispview


(in-package "X11" :use '("LISP" "FOREIGN-FUNCTION-INTERFACE"))

(def-exported-foreign-synonym-type Intensity unsigned-short)
(def-exported-foreign-synonym-type Pixel unsigned-long)

(def-exported-foreign-struct RGBmap
  (size :type unsigned-int)
  (used :type unsigned-int)
  (red :type (:pointer Intensity))
  (green :type (:pointer Intensity))
  (blue :type (:pointer Intensity)))

(def-exported-foreign-struct Image
  (title :type (:pointer char))
  (type :type unsigned-int)
  (rgb :type RGBMap)
  (width :type unsigned-int)
  (height :type unsigned-int)
  (depth :type unsigned-int)
  (pixlen :type unsigned-int)
  (data :type (:pointer unsigned-char)))

(def-exported-constant ibitmap 0)
(def-exported-constant irgb 1)

(def-exported-foreign-function (loadImage (:return-type (:pointer image))
					  (:name "_loadImage"))
  (name (:pointer char))
  (verbose unsigned-long))

(def-exported-foreign-function (freeImage (:return-type :null)
					  (:name "_freeImage"))
  (image (:pointer Image)))


(def-exported-foreign-function (sendImageToX (:return-type unsigned-int)
					     (:name "_sendImageToX"))
  (disp (:pointer Display))
  (scrn int)
  (visual (:pointer Visual))
  (image (:pointer Image))
  (index (:pointer Pixel)))


