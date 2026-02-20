;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;%W% %G%


(in-package "LISPVIEW")


(defmethod initialize-instance :after ((c cursor) &rest args)
  (apply #'dd-initialize-cursor (platform c) c args))


(defmethod initialize-instance :around ((c cursor) &key status &allow-other-keys)
  (prog1
      (call-next-method)
    (when (eq status :realized)
      (setf (status c) :realized))))


(defmacro check-cursor-mask (image mask)
  `(unless (and (typep ,mask 'bitmap)
		(let ((mask-br (bounding-region ,mask))
		      (image-br (bounding-region ,image)))
		  (and (= (region-width mask-br) (region-width image-br))
		       (= (region-height mask-br) (region-height image-br)))))
     (error "Cursor mask must be a bitmap of the same size as the cursor image")))


(defmacro check-cursor-image-and-mask (cursor image mask)
  `(progn
     (unless (and (typep ,image 'image)
		  (let ((image-br (bounding-region ,image))
			(x-hot (cursor-x-hot ,cursor))
			(y-hot (cursor-y-hot ,cursor)))
		    (and (or (null x-hot) (< x-hot (region-width image-br)))
			 (or (null y-hot) (< y-hot (region-height image-br))))))
       (error "Cursor hot spot is not within the images bounding-region"))
     (when ,mask
       (check-cursor-mask ,image ,mask))))


(defmethod (setf status) ((value (eql :realized)) (c cursor))
  (when (eq (status c) :initialized)
    (let ((image (cursor-image c))
	  (mask (cursor-mask c))
	  (name (name c)))
      (unless (or image name)
	(error "Either a cursor image or name must be specified"))
      (check-type (foreground c) color-spec)
      (check-type (background c) color-spec)
      (when name
	(check-type name coercible-to-string))
      (when image
	(check-cursor-image-and-mask c image mask)
	(realize image)
	(when mask (realize mask)))
      (dd-realize-cursor (platform c) c)
      (push c (slot-value (display c) 'cursors))))
  (setf (slot-value c 'status) :realized))


(defmethod (setf status) ((value (eql :destroyed)) (c cursor))
  (when (eq (status c) :realized)
    (dd-destroy-cursor (platform c) c))
  (let ((display (display c)))
    (setf (slot-value display 'cursors) (delete c (slot-value display 'cursors))
	  (slot-value c 'status) :destroyed)))


;;; Note: the setf methods for x-hot and y-hot do not check to see
;;; if they fit within the bounds of the cursors image.  The setf method
;;; for image does this check and the setf method for mask ensures that
;;; the mask and the image are the same size.  The setf methods for image
;;; and mask also realize their argument before calling the driver.

(def-solo-accessor NAME cursor :type coercible-to-string 
  :driver dd-cursor-name)

(def-solo-accessor FOREGROUND cursor :type color-spec 
  :driver dd-cursor-foreground)

(def-solo-accessor BACKGROUND cursor :type color-spec 
  :driver dd-cursor-background)

(def-solo-accessor CURSOR-X-HOT cursor :type (or null positive-fixnum)
  :driver dd-cursor-x-hot)

(def-solo-accessor CURSOR-Y-HOT cursor :type (or null positive-fixnum)
  :driver dd-cursor-y-hot)

(def-solo-reader CURSOR-IMAGE cursor :type (or null image)
  :driver dd-cursor-image)

(def-solo-reader CURSOR-MASK cursor :type (or null image)
  :driver dd-cursor-mask)


(defmethod (setf image) (image (c cursor))
  (when (and image (eq (status c) :realized))
    (check-cursor-image-and-mask c image (cursor-mask c))
    (realize image))
  (setf (dd-cursor-image (platform c) c) image))


(defmethod (setf mask) (mask (c cursor))
  (when (and mask (eq (status c) :realized))
    (check-cursor-mask (cursor-image c) mask)
    (realize mask))
  (setf (dd-cursor-mask (platform c) c) mask))


(defmethod (setf cursor) (cursor (c canvas))
  (check-type cursor (or t null cursor))
  (when (eq (status c) :realized)
    (when (typep cursor 'cursor)
      (realize cursor))
    (setf (dd-canvas-cursor (platform c) c) cursor)))

(def-solo-reader CURSOR canvas :type (or (member t nil) cursor)
  :driver dd-canvas-cursor)
