;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)color.lisp	3.20 10/11/91


(in-package "LISPVIEW")


(defun check-colormap-colors (colors)
  (flet 
   ((check-color (c)
      (and (slot-boundp c 'pixel)
	   (or (slot-boundp c 'name)
	       (and (slot-boundp c 'red) (slot-boundp c 'green) (slot-boundp c 'blue))
	       (and (slot-boundp c 'hue) (slot-boundp c 'saturation) (slot-boundp c 'intensity))))))

   (unless (every #'check-color colors)
     (error "Each colormap color must specify a pixel and either a name, rgb, or hsi components"))))


;;; Given  RGB color components, where each component is 0.0 <= component <= 1.0,
;;; multiple-value return equivalent HSI values.  This code comes from SPAR from
;;; compatibility/generic-colors.lisp which was based on 
;;; "Smith, SIGGraph 1978 page 14".

(defun rgb-to-hsi (r g b)
  (if (and (zerop r) (zerop g) (zerop b))	; avoid most==0 below
      (values r g b)
    (let* ((most (max r g b))
	   (least (min r g b))
	   (range (- most least))
	   (saturation (/ range most)))
	(if (zerop saturation)		; most=least, avoid range=0 below
	    (values 0.0 0.0 most)
	  (let* ((redpart (/ (- most r) range))
		 (bluepart (/ (- most b) range))
		 (greenpart (/ (- most g) range))
		 (quadrant (cond 
			     ((= r most)
			      (if (= g least) (+ 5 bluepart) (- 1 greenpart)))
			     ((= g most)
			      (if (= b least) (+ 1 redpart) (- 3 bluepart)))
			     (T ;; (= b most)
			      (if (= r least) (+ 3 greenpart) (- 5 redpart))))))
	    (values (/ quadrant 6.0) saturation most))))))


;;; Given HSI color components, where each component is 0.0 <= component <= 1.0,
;;; multiple-value return equivalent RGB components.  This code comes from SPAR from
;;; compatibility/generic-colors.lisp which was based on 
;;; "Smith, SIGGraph 1978 page 14".

(defun hsi-to-rgb (h s i)
  (multiple-value-bind (quadrant f)
      (floor (* 6 h))
    (let* ((scaledsat s)
	   (scaledint i)
	   (m (* scaledint (- 1.0 scaledsat)))
	   (n (* scaledint (- 1.0 (* scaledsat (if (oddp quadrant) f (- 1.0 f)))))))
      (case quadrant
	(0 (values scaledint n m))
	(1 (values scaledint m m))
	(2 (values m scaledint n))
	(3 (values m n scaledint))
	(4 (values n m scaledint))
	(5 (values scaledint n m))
	(T (error "Quadrant isn't in range for hsi-to-rgb"))))))


(defmethod initialize-instance :around ((x color) &key status &allow-other-keys)
  (prog1
      (call-next-method)
    (when (eq status :realized)
      (setf (status x) :realized))))


(defmethod initialize-instance :after ((x color) 
				       &key 
				         name pixel
				         r g b (red r) (green g) (blue b)
					 h s i (hue h) (saturation s) (intensity i)
				       &allow-other-keys)
  (if (slot-boundp x 'colormap)
      (check-type (slot-value x 'colormap) colormap)
    (setf (slot-value x 'colormap) (default-colormap (display x))))

  (check-arglist (name (or null coercible-to-string))
		 (pixel (or null integer)))

  (when (and red green blue)
    (check-color-components red green blue))

  (when (and hue saturation intensity)
    (check-color-components hue saturation intensity)
    (multiple-value-bind (r g b)
	(hsi-to-rgb hue saturation intensity)
      (setf (slot-value x 'red) r
	    (slot-value x 'green) g
	    (slot-value x 'blue) b)))

  (dd-initialize-color (platform x) x))


(defmethod (setf status) ((value (eql :realized)) (c color))
  (when (eq (status c) :initialized)
    (dd-realize-color (platform c) c))
  (setf (slot-value c 'status) :realized))


(defmethod (setf status) ((value (eql :destroyed)) (c color))
  (when (eq (status c) :realized)
    (dd-destroy-color (platform c) c))
  (setf (slot-value c 'status) :destroyed))


(defun find-color (&rest initargs
		   &key 
		     (display (default-display))
		     (colormap (default-colormap display))
		     (allocated-colors (allocated-colors colormap))
		     name pixel
		     r g b (red r) (green g) (blue b)
		     h s i (hue h) (saturation s) (intensity i)
		     (if-not-found :realize)
		     (color-class 'color)
		   &allow-other-keys)
  (check-arglist (allocated-colors sequence)
		 (name (or null coercible-to-string))
		 (pixel (or null integer))
		 (color-class symbol))

  (macrolet 
   ((cvt-to-int (float)
      `(truncate (* ,float 65535.0))))

   (let* ((color 
	   (cond 
	    (name 
	     (find (string name) allocated-colors 
		   :key #'(lambda (c) (if (slot-boundp c 'name) (name c)))
		   :test #'string-equal))
	    (pixel 
	     (find pixel allocated-colors :key #'pixel :test #'=))
	    ((and red green blue)
	     (check-color-components red green blue)
	     (let ((r (cvt-to-int red))
		   (g (cvt-to-int green))
		   (b (cvt-to-int blue)))
	       (dotimes (n (length allocated-colors) NIL)
		 (let ((c (svref allocated-colors n)))
		   (when (and (= (cvt-to-int (red c)) r) 
			      (= (cvt-to-int (green c)) g)  
			      (= (cvt-to-int (blue c)) b))
		     (return c))))))
	    ((and hue saturation intensity)
	     (check-color-components hue saturation intensity)
	     (let ((h (cvt-to-int hue))
		   (s (cvt-to-int saturation))
		   (i (cvt-to-int intensity)))
	       (dotimes (n (length allocated-colors) NIL)
		 (let ((c (svref allocated-colors n)))
		   (when (and (= (cvt-to-int (hue c)) h) 
			      (= (cvt-to-int (saturation c)) s)  
			      (= (cvt-to-int (intensity c)) i))
		     (return c)))))))))
     (if color
	 (values color :already-created)
       (values
	(case if-not-found 
	  (:initialize
	   (apply #'make-instance color-class :status :initialized initargs))
	  (:realize
	   (apply #'make-instance color-class :status :realized initargs))
	  (:find-closest
	   (apply #'dd-find-closest-allocated-color (platform display) initargs))
	  ((:warn :error)
	   (apply (if (eq if-not-found :warn) #'warn #'error)
		  "Can't find or create a color that matches ~S" initargs))
	  (t if-not-found))
	if-not-found)))))
	  


(flet
 ((maybe-initialize-rgb (c component)
    (unless (slot-boundp c component)
      (if (and (slot-boundp c 'hue) (slot-boundp c 'saturation) (slot-boundp c 'intensity))
	  (multiple-value-bind (r g b)
	      (hsi-to-rgb (hue c) (saturation c) (intensity c))
	    (setf (slot-value c 'red) r
		  (slot-value c 'green) g
		  (slot-value c 'blue) b))
	(error "Neither RGB or HSI values are available for ~S" c)))))

 (defmethod red ((c color))
   (maybe-initialize-rgb c 'red)
   (slot-value c 'red))

 (defmethod green ((c color))
   (maybe-initialize-rgb c 'green)
   (slot-value c 'green))

 (defmethod blue ((c color))
   (maybe-initialize-rgb c 'blue)
   (slot-value c 'blue)))



(flet
 ((maybe-initialize-hsi (c component)
    (unless (slot-boundp c component)
      (if (and (slot-boundp c 'red) (slot-boundp c 'green) (slot-boundp c 'blue))
	  (multiple-value-bind (h s i)
	      (rgb-to-hsi (red c) (green c) (blue c))
	    (setf (slot-value c 'hue) h
		  (slot-value c 'saturation) s
		  (slot-value c 'intensity) i))
	(error "Neither RGB or HSI values are available for ~S" c)))))

 (defmethod hue ((c color))
   (maybe-initialize-hsi c 'hue)
   (slot-value c 'hue))

 (defmethod saturation ((c color))
   (maybe-initialize-hsi c 'saturation)
   (slot-value c 'saturation))

 (defmethod intensity ((c color))
   (maybe-initialize-hsi c 'intensity)
   (slot-value c 'intensity)))



;;; Backwards Compatibility definitions of mumble-component readers for colors.

(proclaim 
 '(special red-component-warning green-component-warning blue-component-warning
	   hue-component-warning saturation-component-warning intensity-component-warning))

(macrolet 
 ((def-reader (new-name)
    (let* ((old-name (intern (format nil "~A-COMPONENT" new-name)))
	   (warning (intern (format nil "~A-WARNING" old-name))))
      `(progn
	 (defvar ,warning nil)
	 (defmethod ,old-name ((c color)) 
	   (unless ,warning
	     (setq ,warning t)
	     (warn "~S is obsolete, use ~S instead" ',old-name ',new-name))
	   (,new-name c))))))

 (def-reader red)
 (def-reader green)
 (def-reader blue)
 (def-reader hue)
 (def-reader saturation)
 (def-reader intensity))


;;; Backwards compatibility with version 1.0

(defmethod display-colors ((d display)) (allocated-colors (default-colormap d)))



;;; COLORMAPS 


(defun default-colormap (&optional (display (default-display)))
  (colormap (root-canvas display)))




(defun visual-to-colormap-class (visual)
  (typecase visual
    (pseudo-color-visual 'pseudo-colormap)
    (gray-scale-visual 'gray-scale-colormap)
    (direct-color-visual 'direct-color-colormap)
    (true-color-visual 'true-colormap)
    (static-color-visual 'static-colormap)
    (static-gray-visual 'static-gray-colormap)
    (monochrome-visual 'monochrome-colormap)))

(defun colormap-to-visual-class (colormap)
  (typecase colormap
    (pseudo-colormap  'pseudo-color-visual)
    (gray-scale-colormap 'gray-scale-visual)
    (direct-colormap 'direct-color-visual)
    (true-colormap 'true-color-visual)
    (static-colormap 'static-color-visual)
    (static-gray-colormap 'static-gray-visual)
    (monochrome-colormap 'monochrome-visual)))


(defun supported-colormap-classes (&key class 
					depth
					(display (default-display)))
  (check-arglist (class (or symbol class))
		 (depth (or null (integer 0 *)))
		 (display display))

  (let ((supported-depths (supported-depths display))
	(visual-class (or (colormap-to-visual-class 
			    (cond
			     ((typep class 'class) class)
			     (class (class-prototype (find-class class)))))
			  t)))
    (mapcan #'(lambda (visual)
		(if (typep visual visual-class)
		    (list (visual-to-colormap-class visual))))
	    (if depth
		(cdr (assoc depth supported-depths :test #'=))
	      (mapcan #'cdr (copy-alist supported-depths))))))


(defmethod initialize-instance :after ((x colormap) 
				       &rest initargs 
				       &key 
				         display
					 colors
					 (depth (depth (root-canvas display)))
					 skip
					 load
				       &allow-other-keys)
  (declare (dynamic-extent initargs))

  (check-arglist (display display)
		 (colors sequence)
		 (depth (integer 0 *))
		 (skip colormap-skip-sequence)
		 (load (vector * 3)))
  (unless (supported-colormap-classes :class (class-of x) :display display :depth depth)
    (error "Display ~S doesn't support ~S colormaps at depth ~S" display (class-of x) depth))
  (when (and colors (typep x 'read-only-colormap))
    (error "Can't specify colors for a read-only colormap"))
  (check-colormap-colors colors)

  (setf (slot-value x 'undefined-color) 
	(make-instance 'undefined-color :display display :colormap x))

  (apply #'dd-initialize-colormap (platform x) x initargs))


(defmethod initialize-instance :around ((x colormap) &key status &allow-other-keys)
  (prog1
      (call-next-method)
    (when (eq status :realized)
      (setf (status x) :realized))))


(defmethod (setf status) ((value (eql :realized)) (x colormap))
  (when (eq (status x) :initialized)
    (dd-realize-colormap (platform x) x)
    (push x (slot-value (display x) 'colormaps)))
  (setf (slot-value x 'status) :realized))


(defmethod (setf status) ((value (eql :destroyed)) (x colormap))
  (when (eq (status x) :realized)
    (dd-destroy-colormap (platform x) x))
  (let ((d (display x)))
    (setf  (slot-value d 'colormaps) (delete x (slot-value d 'colormaps))
	   (slot-value x 'status) :destroyed)))



(defmethod colormap-length ((x colormap))
  (dd-colormap-length (platform x) x))

(defmethod colormap-length ((x visual))
  (dd-visual-colormap-length (platform x) x))


(defmethod colormap-colors ((x colormap))
  (dd-colormap-colors (platform x) x))

(defmethod (setf colormap-colors) (colors (x read-write-colormap) 
					  &key (skip t)
					       (load colormap-load-rgb))
  (check-arglist (colors sequence)
		 (skip colormap-skip-sequence))
  (check-colormap-colors colors)
  
  (setf (dd-colormap-colors (platform x) x skip load) colors))


(defun allocated-colors (colormap)
  (remove-if #'(lambda (x) (typep x 'undefined-color)) (colormap-colors colormap)))


(def-solo-reader RESERVED-COLORMAP-COLORS display
  :type sequence
  :driver dd-display-reserved-colormap-colors)


(def-solo-reader VISUAL colormap
  :type (or null visual)
  :driver dd-colormap-visual)


(def-solo-accessor COLORMAP opaque-canvas 
  :type (or null colormap)
  :driver dd-opaque-canvas-colormap)


(def-solo-reader PROXY-COLOR color
  :type color
  :driver dd-proxy-color)
