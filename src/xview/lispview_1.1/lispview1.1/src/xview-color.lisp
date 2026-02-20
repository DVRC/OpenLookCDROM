;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)xview-color.lisp	3.30 10/11/91


(in-package "LISPVIEW")


;;; Return the next available CMS index or NIL if the colormap is full. This
;;; nonsense is neccessary because XView obscures the X11 XAllocColor, XFreeColor
;;; interface with CMS package.  The CMS package requires one to actually
;;; specify the CMS indices (which are mapped to real X11 pixels internally) you
;;; want to allocate.

(defun alloc-xview-cms-index (xvo)
  (let* ((allocation (xview-colormap-allocation xvo))
	 (last-allocation (xview-colormap-last-allocation xvo))
	 (length (length allocation)))
    (do ((i last-allocation (1+ i)))
	((>= i length))
      (unless (svref allocation i)
	(return-from alloc-xview-cms-index (setf (xview-colormap-last-allocation xvo) i))))

    (dotimes (i last-allocation)
      (unless (svref allocation i)
	(return-from alloc-xview-cms-index (setf (xview-colormap-last-allocation xvo) i))))))


;;; If there's an unallocated cell in this colormaps CMS (see alloc-xview-cms-index) 
;;; then load the colormap using XViews CMS interface.  If a name was 
;;; supplied instead of red,green,blue components then lookup the component
;;; values (with X11:XParseColor) and update the red,green,blue slots.

(defun alloc-xview-color (colormap-xvo color)
  (let ((index (alloc-xview-cms-index colormap-xvo))
	(cms (xview-object-id colormap-xvo))
	(xc (malloc-foreign-pointer :type '(:pointer X11:XColor))))
    (if (not (and index cms))
	(progn (free-foreign-pointer xc) nil)
      (flet 
       ((load-color ()
	  (XV:xv-set cms :cms-index index
		         :cms-color-count 1
			 :cms-x-colors (foreign-pointer-address xc))

	  (let ((pixel (XV:xv-get cms :cms-pixel index)))
	    (setf (svref (xview-colormap-allocation colormap-xvo) index) color
		  (slot-value color 'pixel) pixel
		  (X11:xcolor-pixel xc) pixel)
	    (make-xview-color
	      :index index
	      :xcolor xc))))

       (setf (X11:xcolor-flags xc) x11-do-rgb)
       (cond
	((and (slot-boundp color 'red) (slot-boundp color 'green) (slot-boundp color 'blue))
	 (setf (X11:xcolor-red xc)   (truncate (* 65535.0 (red color)))
	       (X11:xcolor-green xc) (truncate (* 65535.0 (green color)))
	       (X11:xcolor-blue xc)  (truncate (* 65535.0 (blue color))))
	 (load-color))

	((slot-boundp color 'name)
	 (let* ((name (name color))
		(name-fp (malloc-foreign-string (string name))))
	   (prog1
	       (if (/= 0 (X11:XParseColor (xview-object-dsp colormap-xvo) 
					  (xview-object-xid colormap-xvo) name-fp xc))
		   (prog1
		       (load-color)
		     (with-slots (red green blue) color
		       (setf red   (/ (X11:xcolor-red xc)   65535.0)
			     green (/ (X11:xcolor-green xc) 65535.0)
			     blue  (/ (X11:xcolor-blue xc)  65535.0))))
		 (warn "Couldn't find a color named ~S" name))
	     (free-foreign-pointer name-fp)))))))))


(defun free-xview-color (colormap-xvo color)
  (let ((xvc (device color)))
    (unless (typep xvc 'xview-toolkit-color)
      (let ((allocated (xview-colormap-allocation colormap-xvo))
	    (index (xview-color-index xvc)))
	(when (eq (svref allocated index) color)
	  (free-foreign-pointer (xview-color-xcolor xvc))
	  (setf (svref allocated index) nil
		(device color) no-such-xview-color))))))



(defun xcolor-to-color (display colormap xc name pixel index)
  (make-instance 'color 
    :display display
    :colormap colormap
    :name name
    :red   (/ (X11:XColor-red xc)   65535.0)
    :green (/ (X11:XColor-green xc) 65535.0)
    :blue  (/ (X11:XColor-blue xc)  65535.0)
    :pixel pixel
    :device (make-xview-toolkit-color
	      :index index
	      :xcolor (copy-foreign-pointer xc :static t))))


;;; Each entry represents an OPEN LOOK color name and the XView CMS index
;;; it's supposed to be loaded into.  The indices were taken from the XView 2.0 
;;; sources: libxvin/color/cms_pblc.c.

(defvar xview-control-color-table
  '((:bg1 . 0)
    (:bg2 . 1) 
    (:bg3 . 2) 
    (:highlight . 3)))

(defun make-xview-control-colors (display colormap)
  (let* ((xvo (device colormap))
	 (allocation (xview-colormap-allocation xvo))
	 (cms (xview-object-id xvo))
	 (cms-xid (xview-object-xid xvo))
	 (ncolors (length xview-control-color-table))
	 (xcolors (malloc-foreign-pointer 
		    :type `(:pointer (:array X11:XColor (,ncolors))))))
    (let ((i 0))
      (dolist (c xview-control-color-table)
	(setf (X11:XColor-pixel (foreign-aref xcolors i)) (XV:xv-get cms :cms-pixel (cdr c)))
	(incf i)))

    (X11:XQueryColors (xview-object-dsp xvo) cms-xid (foreign-array-to-pointer xcolors) ncolors)
    
    (let ((i 0))
      (dolist (c xview-control-color-table)
	(let* ((xc (foreign-aref xcolors i))
	       (pixel (X11:xcolor-pixel xc)))
	(setf (svref allocation (cdr c))
	      (xcolor-to-color display colormap xc (car c) pixel (cdr c)))
	(incf i))))

    (free-foreign-pointer xcolors)))



(defun read-x11-colormap-colors (colormap &optional (n (colormap-length colormap)))
  (let* ((xvo (device colormap))
	 (xid (xview-object-xid xvo))
	 (pixel-to-index (xview-colormap-pixel-to-index xvo))
	 (dsp (xview-object-dsp xvo))
	 (xcolors (malloc-foreign-pointer :type `(:pointer (:array X11:XColor (,n)))))
	 (colors (make-array n))
	 (display (display colormap)))

     (dotimes (i n)
       (setf (X11:XColor-pixel (foreign-aref xcolors i)) i))
     (X11:XQueryColors dsp xid (foreign-array-to-pointer xcolors) n)

     (dotimes (i n)
       (let ((xc (foreign-aref xcolors i)))
	 (setf (svref colors i)
	       (xcolor-to-color display colormap xc "" i (svref pixel-to-index i)))))

     (free-foreign-pointer xcolors)
     colors))



;;; In addition to reserving the colors that are allocated by XView (black, white,
;;; BG1,BG2, HIGHLIGHT), we make a crude attempt to reserve the colors that the
;;; window manager is using by reserving the first 8 colors in the colormap.  This
;;; works if the window manager is using 8 or fewer colors, if the server allocates
;;; colormap cells sequentially beginning with 0, and if the window manager was
;;; the first application to allocate colors.  

(defmethod reserve-xview-colors (display (colormap pseudo-colormap))
  (XV:with-xview-lock
    (make-xview-control-colors display colormap)
    (setf (xview-colormap-reserved-colors (device colormap))
	  (remove-duplicates 
	   (concatenate 'simple-vector 
			(read-x11-colormap-colors colormap 8)
			(allocated-colors colormap))
	   :test #'=
	   :key #'pixel))))


(defmethod reserve-xview-colors (display (colormap monochrome-colormap))
  (declare (ignore display))
  (setf (xview-colormap-reserved-colors (device colormap))
	(allocated-colors colormap)))



(defun make-inverted-cms-index-table (cms size)
  (let ((cms-index-table (make-foreign-pointer 
			    :type `(:pointer (:array X11:unsigned-long (,size)))
			    :address (XV:xv-get cms :cms-index-table)))
	(pixel-to-index (make-array size :initial-element 0)))
    (dotimes (index size pixel-to-index)
      (let ((pixel (foreign-aref cms-index-table index)))
	(if (and (>= pixel 0) (< pixel size))
            (setf (svref pixel-to-index pixel) index))))))


;;; If the default-colormap for this display is monochrome then just allocate black 
;;; and white, the default CMS will just be the root windows CMS.  If the default-colormap 
;;; supports color, and it's read/write then create a new CMS that's takes over 50%
;;; of the possible colormap cells, if it's read-only then create a CMS for all
;;; the colormap cells.  Initialize the new XView "control" CMS with the background 
;;; color at CMS offset 0 (not counting the control colors) and the foreground color in
;;; the last CMS entry.

(defvar *default-colormap-allocation* 0.4
  "Percentage of the available cells in the default colormap that are allocated for LispView")

(defun make-xview-default-colormap (root-canvas)
  (let* ((display (display root-canvas))
	 (root-xvo (device root-canvas))
	 (xvd (xview-object-xvd root-xvo))
	 (root-visual (visual root-canvas))
	 (root-depth (depth root-canvas))
	 (x11-root-visual (device root-visual))
	 (size (if (typep root-visual 'static-visual)
		   (expt 2 root-depth)
		 (truncate  (* *default-colormap-allocation* (expt 2 root-depth)))))
	 (allocation (make-array size))
	 (xvo 
	  (make-xview-toolkit-colormap
	    :xvd xvd
	    :dsp (xview-display-dsp xvd)
	    :id 0  ;; short circuit dd-realize-colormap
	    :visual root-visual
	    :allocation allocation))
	 (colormap 
	  (make-instance (visual-to-colormap-class root-visual)
	    :display display
	    :device xvo
	    :depth (X11:visual-bits-per-rgb x11-root-visual))))

    (labels
     ((make-mono-color (cms name index rgb)
	(let ((pixel (XV:xv-get cms :cms-pixel index))
	      (xc (X11:make-xcolor :red rgb :green rgb :blue rgb :flags x11-do-rgb)))
	  (setf (svref allocation index)
		(xcolor-to-color display colormap xc name pixel index))))

      (make-black-and-white (cms black white)
	(make-mono-color cms :black black 0)
	(make-mono-color cms :white white 65535)))

     (typecase root-visual
       (monochrome-visual
	(XV:with-xview-lock 
	  (let ((cms (XV:xv-get (xview-object-id (device root-canvas)) :win-cms)))
	    (setf (xview-object-xid xvo) (XV:xv-get cms :cms-cmap-id)
		  (xview-object-id xvo) cms)

	    (make-black-and-white cms 1 0))))
       (t
	(XV:with-xview-lock 
	 (let* ((bg-index XV:cms-control-colors)
		(fg-index (1- size))
		(cms (XV:xv-create (xview-display-screen (xview-object-xvd xvo)) :cms
		       :cms-type :xv-dynamic-cms
		       :cms-size size  
		       :cms-control-cms t)))
	   (XV:xv-set cms 
	     :cms-color-count 1 
	     :cms-index bg-index
	     :cms-named-colors '("white"))
	   (XV:xv-set cms :cms-color-count 1 
	     :cms-color-count 1 
	     :cms-index fg-index
	     :cms-named-colors '("black"))

	   (setf (xview-object-xid xvo) (XV:xv-get cms :cms-cmap-id)
		 (xview-object-id xvo) cms)

	   (make-black-and-white cms fg-index bg-index))))))

    (let ((cms (xview-object-id xvo)))
      (setf (xview-colormap-pixel-to-index xvo) 
	    (make-inverted-cms-index-table cms (XV:xv-get cms :cms-size))))
	    
    (reserve-xview-colors display colormap)

    colormap))



(defmethod dd-initialize-color ((p XView) color &rest initargs)
  (declare (ignore initargs))
  (setf (slot-value color 'status) :initialized))


(defmethod dd-proxy-color ((p XView) color)
  (let ((xvo (device color)))
    (if (typep xvo 'xview-proxy-color)
	(xview-proxy-color-proxy xvo)
      color)))


(defun alloc-monochrome-xview-color (colormap color)
  (let ((proxy
	 (if (if (slot-boundp color 'name)
		 (string-equal (name color) "white")
	       (and (>= (red color) 0.9999) 
		    (>= (green color) 0.9999) 
		    (>= (blue color) 0.9999)))
	     (find-color :colormap color :name "white")
	   (find-color :colormap colormap :name "black"))))
    (setf (slot-value color 'pixel) (pixel proxy))
    (make-xview-proxy-color proxy)))
    

;;; If the requested color can't be allocated then we shadow an already
;;; allocated color instead.  The existing color is called the "proxy-color";
;;; it can be retreived by applying proxy-color to the new color.
;;; The new color will not appear in the sequence returned by allocated-colors, 
;;; destroying it will not free any server resources.  

(defmethod dd-realize-color ((p XView) color)
  (unless (or (slot-boundp color 'pixel) (slot-boundp color 'device))
    (unless (slot-boundp color 'colormap)
      (error "Colormap for ~S wasn't specified" color))
    (let ((colormap (colormap color)))
      (if (typep colormap 'monochrome-colormap)
	  (setf (device color)
		(alloc-monochrome-xview-color colormap color))
	(setf (device color)
	      (or (XV:with-xview-lock (alloc-xview-color (device colormap) color))
		  (let* ((name (if (slot-boundp color 'name) (name color)))
			 (proxy (find-color 
				   :colormap colormap 
				   :if-not-found :find-closest
				   :name name 
				   :red (if (null name) (red color))
				   :green (if (null name) (green color))
				   :blue (if (null name) (blue color)))))
		    (setf (slot-value color 'pixel) (pixel proxy))
		    (make-xview-proxy-color proxy))))))))



(defmethod dd-destroy-color ((ws XView) color)
  (free-xview-color (device (colormap color)) color))



(defmethod dd-find-closest-allocated-color ((p XView) &rest args
					              &key 
					                name colormap
					                red green blue 
							hue saturation intensity
						      &allow-other-keys)
  (declare (dynamic-extent args))

  (when (and (not (or red green blue)) hue saturation intensity)
    (multiple-value-setq (red green blue)
	(hsi-to-rgb hue saturation intensity)))
  (cond
   ((and red green blue)
    (let ((min nil)
	  (best nil)
	  (allocated-colors (allocated-colors colormap)))
      (dotimes (n (length allocated-colors) best)
	(let* ((c (svref allocated-colors n))
	       (d (+ (abs (- red   (red c)))
		     (abs (- green (green c)))
		     (abs (- blue  (blue c))))))
	  (when (or (null best) (< d min))
	    (setf min d
		  best c))))))
   (name
    (let ((xvo (device colormap))
	  (name-fp (malloc-foreign-string (string name)))
	  (exact (malloc-foreign-pointer :type '(:pointer X11:XColor)))
	  (best (malloc-foreign-pointer :type '(:pointer X11:XColor))))
      (prog1
	  (XV:with-xview-lock 
	    (if (/= 0 (X11:XLookupColor (xview-object-dsp xvo)
					(xview-object-xid xvo)
					name-fp 
					exact
					best))
		(apply #'find-color :red   (truncate (/ (X11:xcolor-red best)   65535.0))
				    :green (truncate (/ (X11:xcolor-green best) 65535.0))
				    :blue  (truncate (/ (X11:xcolor-blue best)  65535.0))
				    args)
	      (progn
		(warn "Couldn't find a color named ~S, substituting black" name)
		(apply #'find-color :name :black args))))
	(free-foreign-pointer name-fp)
	(free-foreign-pointer exact)
	(free-foreign-pointer best))))))



(defun x11-make-XColor (r g b)
  (macrolet ((x11-16bit-color (n)
	      `(min (floor (* ,n 65535)) 65535)))
    (let ((fp (malloc-foreign-pointer :type '(:pointer X11:XColor))))
      (declare (optimize (speed 3) (space 0) (compilation-speed 0)))
      (setf (X11:XColor-red fp) (x11-16bit-color r)
	    (X11:XColor-green fp) (x11-16bit-color g)
	    (X11:XColor-blue fp) (x11-16bit-color b))
      fp)))
	  
	     

;;; COLORMAPS


(defun find-x11-colormap-visual (display colormap depth)
  (let ((visual-class (colormap-to-visual-class colormap)))
    (or (find-if #'(lambda (v)
		     (typep v visual-class))
		 (cdr (assoc depth (supported-depths display))))
	(error "~S colormaps are't supported at depth ~S, on display ~S"
	       colormap depth display))))



;;; BUG: If a color is specified by Name only - need to lookup components.

(defun load-x11-colormap (xvo dsp xid colors skip load)
  (let* ((ncolors (length colors))
	 (xcolors (when (> ncolors 0)
		    (malloc-foreign-pointer :type `(:pointer (:array X11:XColor (,ncolors))))))
	 (flags (logior (if (aref load 0) X11:DoRed 0)
			(if (aref load 1) X11:DoGreen 0)
			(if (aref load 2) X11:DoBlue 0)))
	 (allocation (xview-colormap-allocation xvo))
	 (pixel-to-index (xview-colormap-pixel-to-index xvo))
	 (i 0))
    (flet 
     ((load-color (c)
	(let* ((xc (foreign-aref xcolors i))
	       (pixel (pixel c))
	       (sub (dotimes (i (length skip) NIL)
		      (when (= pixel (pixel (svref skip i)))
			(return (svref skip i)))))
	       (index nil))
	  (if sub
	      (setf (svref allocation (svref pixel-to-index pixel)) sub
		    (foreign-aref xcolors i) (setf index (xview-color-xcolor (device sub))))
	    (setf (X11:XColor-pixel xc) pixel
		  (X11:XColor-red xc) (truncate (* (red c) 65535.0))
		  (X11:XColor-green xc) (truncate (* (green c) 65535.0))
		  (X11:XColor-blue xc) (truncate (* (blue c) 65535.0))
		  (X11:XColor-flags xc) flags
		  (svref allocation (setf index (svref pixel-to-index pixel))) c))
	  (unless (slot-boundp c 'device)
	    (setf (device c) (make-xview-color
			       :index index
			       :xcolor (copy-foreign-pointer xc))))
	  (incf i))))

     (map nil #'load-color colors))

    (when (and xcolors (> i 0))
      (X11:XStoreColors dsp xid (foreign-array-to-pointer xcolors) i))
    (when xcolors
      (free-foreign-pointer xcolors))))
      

(defmethod dd-initialize-colormap ((p XView) colormap &rest initargs)
  (declare (dynamic-extent initargs))

  (unless (slot-boundp colormap 'device)
    (setf (device colormap) 
	  (apply #'make-xview-colormap 
		 :allow-other-keys t
		 :initargs (copy-list initargs)
		 initargs)))
  (setf (slot-value colormap 'status) :initialized))


(defmethod dd-realize-colormap ((p XView) colormap)
  (let ((xvo (device colormap)))
    (unless (xview-object-id xvo)
      (XV:with-xview-lock 
	(let* ((initargs (prog1
			     (xview-colormap-initargs xvo)
			   (setf (xview-colormap-initargs xvo) nil)))
	       (display (display colormap))
	       (reserved-colors (reserved-colormap-colors display))
	       (xvd (setf (xview-object-xvd xvo) (device display)))
	       (dsp (setf (xview-object-dsp xvo) (xview-display-dsp xvd)))
	       (root (root-canvas display))
	       (depth (getf initargs :depth (depth root)))
	       (visual (setf (xview-colormap-visual xvo) 
			     (find-x11-colormap-visual display colormap depth)))
	       (x11-visual (device visual))
	       (read-only (typep colormap 'read-only-colormap))
	       (cms-size (X11:visual-map-entries x11-visual))
	       (id (setf (xview-object-id xvo)
			 (XV:xv-create (xview-display-screen xvd) :cms
			   :xv-visual-class (X11:visual-class x11-visual)
			   :cms-type :xv-dynamic-cms
			   :cms-size cms-size)))
	       (xid (setf (xview-object-xid xvo) (XV:xv-get id :cms-cmap-id))))

	  (setf (xview-colormap-allocation xvo) 
		   (make-array cms-size)
		(xview-colormap-pixel-to-index xvo) 
		   (make-inverted-cms-index-table id cms-size))

	  (unless read-only
	    (load-x11-colormap xvo dsp xid reserved-colors nil colormap-load-rgb)
	    (flet 
	     ((init-colormap-cells (&key colors load skip &allow-other-keys)
		 (when colors
		   (let ((skip 
			  (if (typep skip 'sequence)
			      skip
			    reserved-colors)))
		     (load-x11-colormap xvo dsp xid colors skip load)))))
	     (apply #'init-colormap-cells initargs))))))))


(defmethod dd-destroy-colormap ((p XView) colormap)
  (destroy-xview-object colormap))


(defmethod dd-colormap-length ((p XView) colormap)
  (let* ((xvo (device colormap))
	 (cms (xview-object-id xvo))
	 (visual (xview-colormap-visual xvo)))
    (cond
     (cms (XV:xv-get cms :cms-size))
     (visual (X11:visual-map-entries (device visual)))
     (t 0))))

(defmethod dd-visual-colormap-length ((p XView) visual)
  (if visual
      (X11:visual-map-entries (device visual))
    0))


(defmethod dd-colormap-colors ((p XView) colormap)
  (substitute (slot-value colormap 'undefined-color) nil (xview-colormap-allocation (device colormap))))


(defmethod (setf dd-colormap-colors) (colors (p XView) colormap skip load)
  (XV:with-xview-lock 
    (let* ((xvo (device colormap))
	   (xid (xview-object-xid xvo))
	   (dsp (xview-object-dsp xvo))
	   (skip
	    (if (typep skip 'sequence)
		skip
	      (xview-colormap-reserved-colors 
	       (device (colormap (root-canvas (display colormap))))))))
      (when xid
	(load-x11-colormap xvo dsp xid colors skip load))))
  colors)


(defmethod dd-colormap-visual ((p XView) colormap)
  (xview-colormap-visual (device colormap)))

(defmethod dd-opaque-canvas-colormap ((p XView) canvas)
  (XV:with-xview-lock 
    (let* ((xvo (device canvas))
	   (id (xview-object-id xvo)))
      (or (xview-opaque-canvas-colormap xvo)
	  (when id
	    (setf (xview-opaque-canvas-colormap xvo)
		  (make-instance 'colormap
		    :display (display canvas)
		    :status :realized
		    :device (make-xview-toolkit-colormap 
			      :xid (XV:xv-get (XV:xv-get id :win-cms) :cms-cmap-id)
			      :dsp (xview-object-dsp xvo)
			      :xvd (xview-object-xvd xvo)
			      :visual (visual canvas)))))))))


(defmethod (setf dd-opaque-canvas-colormap) (colormap (p XView) canvas)
  (XV:with-xview-lock 
    (let* ((canvas-xvo (device canvas))
	   (canvas-id (xview-object-id canvas-xvo))
	   (colormap-id (xview-object-id (device colormap))))
      (when (and canvas-id colormap-id)
	(unless (= (X11:visual-class (device (visual canvas)))
		   (X11:visual-class (device (visual colormap))))
	  (error "The visual for ~S must match the visual for ~S" canvas colormap))
	(setf (xview-opaque-canvas-colormap canvas-xvo) colormap)
	(XV:xv-set canvas-id :win-cms colormap-id)
	(xview-maybe-XFlush (xview-object-xvd canvas-xvo)))))
  colormap)
	
	

(defmethod dd-display-reserved-colormap-colors ((p XView) display)
  (copy-seq (xview-colormap-reserved-colors (device (colormap (root-canvas display))))))







