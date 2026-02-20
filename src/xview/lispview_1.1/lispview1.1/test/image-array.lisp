;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)image-array.lisp	1.4 10/17/91

(in-package "LISPVIEW-TEST")


#+lucid
(defun fill-array (array value)
  (multiple-value-bind (array-sv offset total-size)
      (SYS:underlying-simple-vector array)
    (declare (type (vector (unsigned-byte 8) *) array-sv))
    (do ((i offset (1+ i)))
	((>= i total-size) array)
      (setf (aref array-sv i) value))))
  
#-lucid
(defun fill-array (array value)
  (dotimes (row (array-dimension array 0) array)
    (dotimes (col (array-dimension array 1) array)
      (setf (aref array row col) value))))


(defun filled-array-p (array depth nrows ncols pixel)
  (let ((type (if (= depth 8)
		  `(array (unsigned-byte 8) (,nrows ,ncols))
		`(array bit (,nrows ,ncols)))))
    (unless (typep array type)
      (return-from filled-array-p 
        (warn "Expected image array ~S to be type ~S" array type))))
  (dotimes (r nrows array)
    (dotimes (c ncols)
      (unless (= (aref array r c) pixel)
	(return-from filled-array-p 
	 (warn "Location ~D,~D is ~D, supposed to be ~D" r c (aref array r c) pixel))))))


(defun test-image-array-color (&optional (width 503) (height 493))
  (let* ((repaint (make-instance 'damage-interest))
	 (array (make-array (list height width) :element-type '(unsigned-byte 8)))
	 (margin 10)
	 (plum-pixel (pixel (find-color :name "plum")))
	 (green-pixel (pixel (find-color :name "SeaGreen")))
	 (image 
	  (make-instance 'image 
	    :depth 8
	    :data (fill-array array plum-pixel)))
	 (window 
	  (make-instance 'base-window 
	    :label "Color Image Array Test"
	    :width (+ margin margin width)
	    :height (+ margin margin height)
	    :interests (list repaint)
	    :mapped nil
	    :show-resize-corners nil)))

    (defmethod receive-event (w (i (eql repaint)) e)
      (declare (ignore e))
      (copy-area image w 0 0 width height margin margin))

    (defmethod (setf status) ((value (eql :destroyed)) (w (eql window)))
      (call-next-method)
      (destroy image))

    (setf (mapped window) t)

    (prog1
	(and 
	 (yes-or-no-p "Does ~S have a large plum square in the center?" window)
	 (filled-array-p (image-array image) 8 height width plum-pixel)

	 (progn
	   (setf (image-array image) (fill-array array green-pixel))
	   (copy-area image window 0 0 width height margin margin)
	   (and 
	    (yes-or-no-p "Does ~S have a large green square in the center?" window)
	    (filled-array-p (image-array image) 8 height width green-pixel)))

	 (let* ((width2 (truncate width 3))
		(height2 (truncate height 4))
		(array 
		 (make-array (list height2 width2)
		   :initial-element plum-pixel
		   :element-type '(unsigned-byte 8)))
		(region 
		 (make-region 
		   :left (truncate (- width width2) 2)
		   :top (truncate (- height height2) 2)
		   :width width2
		   :height height2)))
	   (setf (image-array image :region region) array)
	   (copy-area image window 0 0 width height margin margin)
	   (and (yes-or-no-p "Does ~S have a small plum rectangle in the center?" window)
		(filled-array-p (image-array image :region region) 8 height2 width2 plum-pixel))))

      (destroy window))))



(defun test-image-array-mono (&optional (width 49) (height 51))
  (let* ((repaint (make-instance 'damage-interest))
	 (array (make-array (list height width) :element-type '(unsigned-byte 8)))
	 (margin 10)
	 (black-pixel (pixel (find-color :name "black")))
	 (white-pixel (pixel (find-color :name "white")))
	 (image 
	  (make-instance 'image 
	    :depth 1
	    :data (fill-array array black-pixel)))
	 (window 
	  (make-instance 'base-window 
	    :label "B&W"
	    :width (+ margin margin width)
	    :height (+ margin margin height)
	    :interests (list repaint)
	    :mapped nil
	    :show-resize-corners nil)))

    (defmethod receive-event (w (i (eql repaint)) e)
      (declare (ignore e))
      (copy-area image w 0 0 width height margin margin))

    (defmethod (setf status) ((value (eql :destroyed)) (w (eql window)))
      (call-next-method)
      (destroy image))

    (setf (mapped window) t)

    (prog1
	(and 
	 (yes-or-no-p "Does ~S have a black square in the center?" window)
	 (filled-array-p (image-array image) 1 height width black-pixel)

	 (progn
	   (setf (image-array image) (fill-array array white-pixel))
	   (copy-area image window 0 0 width height margin margin)
	   (and 
	    (yes-or-no-p "Is ~S now completely white?" window)
	    (filled-array-p (image-array image) 1 height width white-pixel)))


	 (let* ((width2 (- width 2))
		(height2 (- height 2))
		(array2 (make-array (list height2 width2) :initial-element white-pixel))
		(region (make-region :left 1 :top 1 :width width2 :height height2)))
	   (setf (image-array image) (fill-array array black-pixel)
		 (image-array image :region region) (fill-array array2 white-pixel))
	   (copy-area image window 0 0 width height margin margin)
	   (yes-or-no-p "Does ~S contain a rectangular outline?" window)))

      (destroy window)
      (destroy image))))
     

(def-test test-image-array ()
  (
   :type :test
   :interactive t
  )
  
  (unless (if (equal (supported-colormap-classes) '(monochrome-colormap))
	      (test-image-array-mono)
	    (test-image-array-color))
    (error "test-image-array failed")))


