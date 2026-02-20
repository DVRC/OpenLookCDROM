;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;%W% %G%

(in-package "LISPVIEW")


(defmethod initialize-instance :after ((x image) 
				       &rest args 
				       &key 
				         data 
					 depth
					 width
					 height
					 filename
					 pixel-map
				       &allow-other-keys)
  (check-arglist (data (or null (array * (* *))))
		 (depth (or null positive-fixnum))
		 (width (or null positive-fixnum))
		 (height (or null positive-fixnum))
		 (filename (or null string pathname))
		 (pixel-map (satisfies pixel-map-p)))
  (when depth
    (let ((display (display x)))
      (unless (assoc depth (supported-depths display) :test #'=)
	(error "Images of depth ~S aren't supported on display ~S~%" depth display))))

  (apply #'dd-initialize-image (platform x) x args)

  (when data 
    (setf (bounding-region x) (make-region :width (array-dimension data 1)
					   :height (array-dimension data 0)))))



(defmethod initialize-instance :around ((i image) 
					&key 
					  status 
					&allow-other-keys)
  (prog1
      (call-next-method)
    (when (eq status :realized)
      (setf (status i) :realized))))


(defmethod (setf status) ((value (eql :realized)) (i image))
  (when (eq (status i) :initialized)
    (dd-realize-image (platform i) i)
    (push i (slot-value (display i) 'images)))
  (setf (slot-value i 'status) :realized))


(defmethod (setf status) ((value (eql :destroyed)) (i image))
  (when (eq (status i) :realized)
    (dd-destroy-image (platform i) i))
  (let ((d (display i)))
    (setf  (slot-value d 'images) (delete i (slot-value d 'images))
	   (slot-value i 'status) :destroyed)))


(defun image-bounding-region-p (r)
  (and (> (region-width r) 0)
       (> (region-height r) 0)))

(def-solo-accessor BOUNDING-REGION image 
  :type (satisfies image-bounding-region-p)
  :driver dd-image-bounding-region)


(def-solo-accessor DEPTH image 
  :type (or null positive-fixnum)
  :driver dd-image-depth)


(def-solo-reader VISUAL image 
  :type visual
  :driver dd-image-visual)


(def-solo-reader COLORMAP-COLORS image 
  :type sequence
  :driver dd-image-colormap-colors)


(defmethod (setf image-array) (array (x image) &key region)
  (check-arglist (array (array * (* *)))
		 (region (or null region)))
  (setf (dd-image-array (platform x) x region) array))


(defmethod image-array ((x image) &key region element-type)
  (check-type region (or null region))
  (dd-image-array (platform x) x region element-type))


(defmethod read-image (filename &key (format :sun-icon))
  (warn "READ-IMAGE is no longer supported by LispView, use~% (make-instance 'image :filename filename :format format) instead.")
  (make-instance 'image :filename filename :format format))

