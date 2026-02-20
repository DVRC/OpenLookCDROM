;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)colors.lisp	1.4 11/5/91


(in-package "LISPVIEW-TEST")

;;; Verify that black and white and, for non mono displays, the OPEN LOOK colors
;;; bg1 bg2 bg3 highlight are already allocated in the default colormap.

(defun check-default-colormap ()
  (let* ((colormap (default-colormap))
	 (pre-allocated-colors
	  (if (typep colormap 'monochrome-colormap)
	      '(black white)
	    '(black white bg1 bg2 bg3 highlight))))

    (flet
      ((already-created-p (name)
	 (multiple-value-bind (ignore status)
	     (find-color :name name :colormap colormap :if-not-found nil)
	   (declare (ignore ignore))
	   (eq status :already-created))))

      (unless (every #'already-created-p pre-allocated-colors)
	(error "Couldn't find the standard OPEN LOOK colors, ~S, in the default colormap"
	       pre-allocated-colors)))))

	 
(defvar test-colors
  '(("PapayaWhip" 255 239 213) 
    ("blanched almond" 255 235 205)
    ("LemonChiffon" 255 250 205)
    ("MistyRose" 255 228 225)
    ("PaleTurquoise" 175 238 238)
    ("LightSeaGreen" 32 178 170)
    ("chartreuse" 127 255 0)
    ("peru" 205 133 63)
    ("salmon" 250 128 114)
    ("hot pink" 255 105 180)
    ("maroon" 176 48 96)
    ("lavender" 230 230 250)
    ("dim grey" 105 105 105)
    ("slate grey" 112 128 144)
    ("DodgerBlue" 30 144 255)))


;;; Try allocating a moderate number of colors, verify that they're about right
;;; by eyeball, and then deallocate them.

(defun check-color-output ()
  (let* ((colormap (default-colormap))
	 (colors (mapcar #'(lambda (x)
			     (make-instance 'color :colormap colormap :name (car x)))
			 test-colors))
	 (font (font (graphics-context (display colormap))))
	 (font-ascent (font-ascent font))
	 (font-height (+ font-ascent (font-descent font)))
	 (ncolors (length colors))
	 (repaint (make-instance 'damage-interest))
	 (window
	  (make-instance 'base-window
	    :label (format nil "~D A Sordid Colors" ncolors)
	    :colormap colormap
	    :mapped nil
	    :interests (list repaint)))
	 (bw (max 56 (apply #'max (mapcar #'(lambda (x)
					      (+ 8 (string-width font (car x))))
					  test-colors))))
	 (bh (- 56 font-height)))

    ;; verify that the color components are similar to what they're
    ;; supposed to be, warn if they aren't

    (defmethod receive-event ((w (eql window)) (interest (eql repaint)) event)
      (declare (ignore event))
      (let ((x 0) 
	    (y 0)
	    (width (region-width (bounding-region w))))
	(dolist (c colors)
	  (draw-rectangle w (+ x 4) (+ y 4) bw bh :foreground c :fill-p t)
	  (draw-string w (+ 4 x) (+ y 4 bh font-ascent) (name c))
	  (incf x (+ bw 8))
	  (when (>= (+ bw 8 x) width)
	    (setf x 0) 
	    (incf y 64)))))
	  
    
    (defmethod (setf status) ((value (eql :destroyed)) (w (eql window)))
      (call-next-method)
      (dolist (c colors)
	(destroy c))
      (let ((zombie-colors (intersection colors (coerce (allocated-colors colormap) 'list))))
	(when zombie-colors
	  (error "(destroy color) failed - ~S still exist" zombie-colors))))

    (setf (mapped window) t)
    (unwind-protect
	(unless (yes-or-no-p "15 moderately different colors")
	  (error "check-color-output failed"))
      (destroy window))))
    


;;; Stress test color allocation and deallocation.  Allocate and then deallocate
;;; a large number of shades of red, green, and blue and stop in between to verify 
;;; things by eyeball.

(defvar nshades-allocated 50)

(defun check-color-allocation ()
  (let* ((colormap (default-colormap))
	 (intensities (let ((l nil))
			(dotimes (i nshades-allocated (nreverse l))
			  (push i l))))
	 (repaint (make-instance 'damage-interest))
	 (window
	   (make-instance 'base-window 
	     :colormap colormap
	     :width (* nshades-allocated 4)
	     :mapped nil
	     :interests (list repaint)))
	 (colors nil))
	 
    (defmethod receive-event (w (i (eql repaint)) event)
      (declare (ignore event))
      (let ((x 0)
	    (h (region-height (bounding-region w))))
	(dolist (c colors)
	  (draw-rectangle w x 0 4 h :foreground c :fill-p t)
	  (incf x 4))))

    (labels
     ((make-colors (component)
        (mapcar #'(lambda (args) (apply #'find-color args))
		(mapcar #'(lambda (value)
			    (let ((args (list :colormap colormap
					      :name (format nil "~A~D" component value)
					      :red 0.0 :green 0.0 :blue 0.0)))
			      (setf (getf args component) (/ value (float nshades-allocated)))
			      args))
			intensities)))
      (test-colors (component)
       (setf colors (make-colors component))
       (setf (mapped window) t)
       (prog1
	   (yes-or-no-p (format nil "About ~D shades of ~A" 
				nshades-allocated
				(string-capitalize component)))
	 (setf (mapped window) nil)
	 (map nil #'destroy colors))))

     (unless (every #'test-colors '(:red :green :blue))
       (error "Color allocation/deallocation failed")))))


     
(defun check-pseudo-colormaps ()
  (let* ((root (root-canvas *default-display*))
	 (depth (depth root))
	 (length (expt 2 depth))
	 (label "Colormap Test"))
    (labels 
     ((make-colors (component)
	(let ((colors nil))
	  (dotimes (value length colors)
	    (let ((rgb (list :red 0.0 :green 0.0 :blue 0.0)))
	      (setf (getf rgb component) (/ value (float length)))
	      (push (apply #'make-instance 'color 
			   :name (format nil "~A~D" component value)
			   :pixel value
			   rgb)
		    colors)))))
      (make-colormap (component)
	(make-instance 'pseudo-colormap :depth depth :colors (make-colors component))))

     (if (null (supported-colormap-classes :class 'pseudo-colormap :depth depth))
	 (warn "No support for pseudo-colormap on this display")
       (let* ((r-cmap (make-colormap :red))
	      (g-cmap (make-colormap :green))
	      (b-cmap (make-colormap :blue))
	      (repaint (make-instance 'damage-interest))
	      (w (make-instance 'base-window 
		   :depth depth 
		   :mapped nil
		   :width (* length 3)
		   :interests (list repaint)
		   :colormap r-cmap
		   :label label)))

	 (defmethod receive-event (w (i (eql repaint)) event)
	   (declare (ignore event))
	   (let* ((br (bounding-region w))
		  (height (region-height br))
		  (colors (colormap-colors (colormap w))))
	     (with-output-buffering (display w)
	       (dotimes (i length)
		 (draw-rectangle w (* i 3) 0 3 height :fill-p t :foreground (svref colors i))))))
	 
	 (setf (mapped w) t)
	 (flet 
	  ((check (component colormap)
	     (when colormap
	       (setf (colormap w) colormap))
	     (yes-or-no-p 
	      (format nil "With the mouse over the window labeled ~S, mostly shades of ~A are displayed" 
		      label
		      (string-capitalize component)))))

	  (unwind-protect
	      (unless (every #'check '(:red :green :blue) (list nil g-cmap b-cmap))
		(error "PseudoColor colormaps aren't working correctly"))
	    (map nil #'destroy (list w r-cmap g-cmap b-cmap)))))))))



(defun test-color-pixel-map (&key (display (default-display)) (depth 8))
  (let* ((npixels (expt 2 depth))
	 (pixel-map (make-array npixels))
	 (remapped-pixel npixels))
    (dotimes (i npixels) 
      (setf (svref pixel-map i) i))
    (dolist (pixel (map 'list  #'pixel  (reserved-colormap-colors display)) pixel-map)
      (setf (svref pixel-map pixel) (decf remapped-pixel)))))

	    
(defun check-color-image (&key 
			  (filename "mead.im8") 
			  (skip t)
			  (label filename)
			  (remap-pixels t))
  (let* ((image (make-instance 'image 
		  :pixel-map (if remap-pixels (test-color-pixel-map))
		  :filename filename))
	 (depth (depth image))
	 (colormap (if (/= depth 1)
		       (make-instance 'pseudo-colormap 
			 :depth depth
			 :colors (colormap-colors image)
			 :skip skip)))
	 (repaint (make-instance 'damage-interest))
	 (image-br (bounding-region image))
	 (width (region-width image-br))
	 (height (region-height image-br))
	 (win (make-instance 'base-window 
		:label label
		:width width
		:height height
		:colormap colormap
		:interests (list repaint))))

    (defmethod receive-event (w (i (eql repaint)) event)
      (declare (ignore event))
      (let* ((win-br (bounding-region w))
	     (x (truncate (- (region-width win-br) width) 2))
	     (y (truncate (- (region-height win-br) height) 2)))
	(copy-area image w 0 0 width height x y)))

    (defmethod (setf status) ((value (eql :destroyed)) (w (eql win)))
      (call-next-method)
      (map nil #'destroy (remove nil (list image colormap ))))

    win))


(def-test test-default-colormap () 
  (
   :type :test
   :interactive nil
  )

  (check-default-colormap))

(def-test test-color-output () 
  (
   :type :test
   :interactive t
  )

  (check-color-output))

(def-test test-color-allocation () 
  (
   :type :test
   :interactive t
  )

  (check-color-allocation))

(def-test test-pseudo-colormaps ()  
  (
   :type :test
   :interactive t
  )

  (check-pseudo-colormaps))
  

;;; Need to generate a test that exercises xbitmap, xpixmap, sun rasterfile,
;;; rle encoded sun rasterfile, PGM and PBM files, sun icon/pixrect files. 
;;; All of the 8 bit files should be tested with uncompressed and compressed
;;; image files.  Only test the icon/pixrect and xbitmap files for mono displays.

(def-test test-color-images ()
  (
   :type :test
   :interactive t
  )

  (let ((windows
	 (list (check-color-image :filename "mead.im8")
	       (check-color-image :filename "mgtd.im8")
	       (check-color-image :filename "mead.im1" :remap-pixels nil)
	       (check-color-image :filename "help.icon" :remap-pixels nil))))
  
    (unwind-protect
	(unless (yes-or-no-p "Colors look reasonable, window frames don't flash too much")
	  (error "test-color-images failed"))
      (map nil #'destroy windows))))


