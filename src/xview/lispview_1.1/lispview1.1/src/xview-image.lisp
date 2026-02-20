;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)xview-image.lisp	3.15 10/11/91


(in-package "LISPVIEW")


(defun xl-image-colors (xl-image xl-pixel-map)
  (if (= (X11:image-type xl-image) X11:ibitmap)
      (flet 
       ((make-mono-color (pixel value)
	  (make-instance 'color :pixel pixel :red value :green value :blue value)))

       (list (make-mono-color 0 1.0) (make-mono-color 1 0.0)))

    (let* ((rgbmap (X11:image-rgb xl-image))
	   (ncolors (X11:rgbmap-used rgbmap))
	   (xl-pixel-map-array (foreign-pointer-to-array xl-pixel-map ncolors))
	   (red (foreign-pointer-to-array (X11:rgbmap-red rgbmap) ncolors))
	   (green (foreign-pointer-to-array (X11:rgbmap-green rgbmap) ncolors))
	   (blue (foreign-pointer-to-array (X11:rgbmap-blue rgbmap) ncolors))
	   (colors nil))
      (dotimes (i ncolors (nreverse colors))
	(push (make-instance 'color
		:pixel (foreign-aref xl-pixel-map-array i)
		:red (/ (foreign-aref red i) 65535.0)
		:green (/ (foreign-aref green i) 65535.0)
		:blue (/ (foreign-aref blue i) 65535.0))
	      colors)))))
			 

(let* ((static-map-array
	(make-foreign-pointer :type '(:pointer (:array X11:Pixel (4096))) :static t))
       (static-map 
	(foreign-array-to-pointer static-map-array)))

  (defun static-xl-pixel-map (map depth)  
    (let ((max (expt 2 depth)))
      (if (typep map 'vector) 
	  (dotimes (i max static-map)
	    (setf (foreign-aref static-map-array i) (aref map i)))
	(dotimes (i max static-map) 
	  (setf (foreign-aref static-map-array i) i))))))


(defconstant x11-null-visual 
  (make-foreign-pointer :type '(:pointer X11:visual) :address 0 :static t))

(defun xview-read-image (image filename pixel-map verbose)
  (XV:with-xview-lock 
    (let* ((xvo (device image))
	   (xvd (setf (xview-object-xvd xvo) (device (display image))))
	   (dsp (setf (xview-object-dsp xvo) (xview-display-dsp xvd)))
	   (file (malloc-foreign-string (namestring (truename filename))))
	   (display (display image))
	   (xl-image (X11:loadImage file (if verbose 1 0))))
      (when (= 0 (foreign-pointer-address xl-image))
	(error "Couldn't load an image from file ~S" filename))

      (let* ((depth (X11:image-depth xl-image))
	     (visual (setf (xview-image-visual xvo) 
			   (cadr (assoc depth (supported-depths display))))))
	(unless (or visual (= depth 1))
	  (error "This display, ~S, doesn't support images of depth ~S~%" display depth))

	(let* ((x11-visual (if visual (device visual) x11-null-visual))
	       (xl-pixel-map (static-xl-pixel-map pixel-map depth))
	       (pixmap (X11:sendImagetoX dsp (screen display) x11-visual xl-image xl-pixel-map)))
	  (when (= 0 pixmap)
	    (error "Couldn't create an X11 pixmap for ~S" filename))
		       
	  (setf (xview-image-colors xvo) (xl-image-colors xl-image xl-pixel-map)
		(xview-image-depth xvo) depth
		(xview-object-xid xvo) pixmap
		(xview-object-id xvo)
		    (XV:xv-create (xview-display-screen xvd) :server-image
		      :server-image-pixmap pixmap
		      :server-image-save-pixmap t)))

      (free-foreign-pointer file)))))



(defconstant x11-null-data 
  (make-foreign-pointer :type '(:pointer X11:char) :address 0 :static t))

(def-foreign-function (offset-bcopy-sv (:return-type :null)
				       (:name "_offset_bcopy"))
  (from :simple-vector-type)
  (to (:pointer char))
  (length :fixnum)
  (from-offset :fixnum)
  (to-offset :fixnum))

(defun make-x11-image (dsp array width height depth visual)
  (multiple-value-bind (array-sv offset total-size)
      (SYS:underlying-simple-vector array)
    (let* ((byte-array (typep array-sv '(or (vector (unsigned-byte 8))
					    (vector (signed-byte 8)))))
	   (bytes-per-line (if byte-array width 0))  ;; 0 - XCreateImage calculates
	   (image 
	    (XV:with-xview-lock
	      (X11:XCreateImage dsp 
				(or visual x11-null-visual)
				depth 
				X11:ZPixmap 
				0                ;; offset
				x11-null-data
				width
				height
				16                ;; bitmap_pad
				bytes-per-line)))
	   (image-size (* (X11:ximage-bytes-per-line image) height))
	   (image-data 
	    (setf (X11:ximage-data image) 
		  (foreign-array-to-pointer 
		   (malloc-foreign-pointer :type `(:pointer (:array char (,image-size))))))))
      (cond
       ((and byte-array (= depth 8) (= image-size (- total-size offset)))
	(with-interrupts-deferred
	  (offset-bcopy-sv array-sv image-data image-size offset 0)))

       (t (dotimes (y height)
	    (dotimes (x width)
	      (X11:XPutPixel image x y (aref array y x))))))

      image)))



(defun xview-make-image (image width height)
  (let* ((display (display image))
	 (xvo (device image))
	 (xvd (setf (xview-object-xvd xvo) (device display)))
	 (dsp (setf (xview-object-dsp xvo) (xview-display-dsp xvd)))
	 (root (XV:xv-get (xview-display-root xvd) :xv-xid))
	 (depth (xview-image-depth xvo))
	 (support (assoc depth (supported-depths display) :test #'=)))
    (unless support
      (error "No support for images of depth ~D on display ~S" depth display))

    (XV:with-xview-lock 
      (let ((pixmap 
	     (setf (xview-object-xid xvo)
		   (X11:XCreatePixmap dsp root width height depth)))
	    (data (xview-image-data xvo)))
	(setf (xview-object-id xvo)
	      (XV:xv-create (xview-display-screen xvd) :server-image
		:server-image-save-pixmap t
		:server-image-pixmap pixmap))

	;; The following hack patches XView bug #1048180 which should
	;; be fixed in XView 3.0

	(when (= depth 1)
	  (let ((id (xview-object-id xvo)))
	    (XV:xv-set id :server-image-save-pixmap nil
		          :server-image-depth 1)
	    (setf pixmap (setf (xview-object-xid xvo) (XV:xv-get id :xv-xid)))))

	(when data
	  (let* ((visual (or (xview-image-visual xvo) (cadr support)))
		 (x11-visual (if visual (device visual)))
		 (ximage (make-x11-image dsp data width height depth x11-visual))
		 (xgc (x11-create-gc dsp pixmap)))
	    (X11:XPutImage dsp pixmap xgc ximage 0 0 0 0 width height)
	    (X11:XFreeGC dsp xgc)
	    (X11:XDestroyImage ximage)))))))


(defmethod dd-initialize-image ((p XView) image &rest initargs)
  (unless (slot-boundp image 'device)
    (setf (device image) (apply #'make-xview-image 
				:initargs (copy-list initargs)
				:allow-other-keys t 
				initargs)))
  (setf (slot-value image 'status) :initialized))
	 

(defmethod dd-realize-image ((p XView) image)
  (let* ((xvo (device image))
	 (initargs (prog1
		       (xview-image-initargs xvo)
		     (setf (xview-image-initargs xvo) nil)))
	 (file (getf initargs :filename))
	 (pixel-map (getf initargs :pixel-map)))
    (unless (xview-object-id  xvo)
      (if file
	  (xview-read-image image file pixel-map (getf initargs :verbose))
	(let ((br (or (getf initargs :bounding-region)
		      (apply #'make-region :allow-other-keys t initargs))))
	  (xview-make-image image (region-width br) (region-height br)))))))


(defmethod dd-image-bounding-region ((p XView) image)
  (XV:with-xview-lock 
    (let* ((xvo (device image))
	   (id (xview-object-id xvo)))
      (if id
	  (make-region :width (XV:xv-get id :xv-width)
		       :height (XV:xv-get id :xv-height))
	(let ((initargs (xview-image-initargs xvo)))
	  (or (getf initargs :bounding-region)
	      (apply #'make-region :allow-other-keys t initargs)))))))

(defmethod (setf dd-image-bounding-region) (new-br (p XView) image)
  (XV:with-xview-lock 
    (let* ((xvo (device image))
	   (id (xview-object-id xvo)))
      (if id
	  (error "No support for changing the dimensions of a realized image")
	(setf (getf (xview-image-initargs xvo) :bounding-region) (copy-region new-br)))))
  new-br)


(defmethod dd-destroy-image ((p XView) image)
  (destroy-xview-object image))


(defmethod dd-image-visual ((p XView) image)
  (xview-image-visual (device image)))

(defmethod dd-image-colormap-colors ((p XView) image)
  (copy-seq (xview-image-colors (device image))))


(defmethod dd-image-depth ((p XView) image)
  (xview-image-depth (device image)))

(defmethod (setf dd-image-depth) (value (p XView) image)
  (let* ((xvo (device image))
	 (id (xview-object-id xvo)))
    (if (and (integerp id) (eq (status image) :realized))
	(error "no XView support for changing the depth of a realized image")
      (setf (xview-image-depth xvo) value))))



(defmethod (setf dd-image-array) (array (p XView) image region)
  (let* ((xvo (device image))
	 (pixmap (xview-object-xid xvo))
	 (dsp (xview-object-dsp xvo)))
    (when pixmap
      (let* ((visual (xview-image-visual xvo))
	     (x11-visual (if visual (device visual)))
	     (width (array-dimension array 1))
	     (height (array-dimension array 0))
	     (x (if region (region-left region) 0))
	     (y (if region (region-top region) 0))
	     (w (if region (region-width region) width))
	     (h (if region (region-height region) height))
	     (depth (depth image))
	     (ximage (make-x11-image dsp array width height depth x11-visual))
	     (xgc (x11-create-gc dsp pixmap)))
	(X11:XPutImage dsp pixmap xgc ximage 0 0 x y w h)
	(X11:XFreeGC dsp xgc)
	(X11:XDestroyImage ximage))))
  array)


(def-foreign-function (offset-bcopy-fp (:return-type :null)
				       (:name "_offset_bcopy"))
  (from (:pointer char))
  (to :simple-vector-type)
  (length :fixnum)
  (from-offset :fixnum)
  (to-offset :fixnum))


(defmethod dd-image-array ((p XView) image region element-type)
  (XV:with-xview-lock 
    (let* ((xvo (device image))
	   (id (xview-object-id xvo)))
      (if (null id)
	  (xview-image-data xvo)
	(let* ((dsp (xview-object-dsp xvo))
	       (xid (xview-object-xid xvo))
	       (br (bounding-region image))
	       (r (if region (region-intersection br region) br))
	       (width (if r (region-width r) 0))
	       (height (if r (region-height r) 0)))
	  (if (and (> width 0) (> height 0))
	      (let* ((ximg (X11:XGetImage dsp xid 
					  (region-left r) (region-top r) width height
					  #xFFFFFFFF
					  X11:ZPixmap))
		     (depth (depth image))
		     (element-type (or element-type (case (depth image)
						      (1 'bit)
						      (8 '(unsigned-byte 8)))))
		     (byte-array (member element-type '((unsigned-byte 8) (signed-byte 8)) :test #'equal))
		     (array (make-array (list height width) :element-type element-type))
		     (bytes-per-row (X11:ximage-bytes-per-line ximg)))
		(cond
		 ((and byte-array (= depth 8))
		  (multiple-value-bind (array-sv offset total-size) 
		      (SYS:underlying-simple-vector array)
		    (if (= width bytes-per-row)
			(with-interrupts-deferred
			  (offset-bcopy-fp (X11:ximage-data ximg) array-sv total-size 0 offset))
		      (let ((from-offset 0)
			    (to-offset offset))
			(dotimes (row height)
			  (offset-bcopy-fp (X11:ximage-data ximg) array-sv width from-offset to-offset)
			  (incf from-offset bytes-per-row)
			  (incf to-offset width))))))
		 (t 
		  (dotimes (row height)
		    (dotimes (col width)
		      (setf (aref array row col) (X11:XGetPixel ximg col row))))))

		(X11:XDestroyImage ximg)
		array)

	    (make-array '(0 0) :element-type element-type)))))))

