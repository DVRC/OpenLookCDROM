;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)xview-scroll.lisp	3.24 10/11/91


(in-package "LISPVIEW")


;;; SCROLLBAR


(defmethod dd-initialize-scrollbar ((p XView) scrollbar &rest initargs)
  (unless (slot-boundp scrollbar 'device)
    (setf (device scrollbar) 
	  (apply #'make-xview-scrollbar 
		 :initargs (copy-list initargs)
		 :allow-other-keys t
		 initargs)))
  (setf (slot-value scrollbar 'status) :initialized))


(defvar xview-scrollbar-sizes nil)

(defun xview-scrollbar-size (display)
  (or (getf xview-scrollbar-sizes display)
      (XV:with-xview-lock 
	(let* ((owner (xview-display-nil-parent-frame (device display)))
	       (id (xv_create owner (XV:xview-package-address :scrollbar)
		     SCROLLBAR_DIRECTION SCROLLBAR_VERTICAL 
		     XV_NULL)))
	  (prog1
	      (setf (getf xview-scrollbar-sizes display) (xv_get id XV_WIDTH))
	    (xv-destroy-safe id))))))



(defun init-xview-scrollbar (sb al &key splittable &allow-other-keys)
  (push-xview-attrs al 
    SCROLLBAR_COMPUTE_SCROLL_PROC (lookup-callback-address 'xview-compute-scroll)
    SCROLLBAR_DIRECTION (if (typep sb 'vertical-scrollbar) 
			    SCROLLBAR_VERTICAL
			  SCROLLBAR_HORIZONTAL)
    SCROLLBAR_SPLITTABLE (if splittable TRUE FALSE))
  (let ((client (if sb (scrollbar-client sb))))
    (when client
      (push-xview-attrs al
	SCROLLBAR_VIEW_LENGTH (view-length client sb)
	SCROLLBAR_VIEW_START (view-start client sb)
	SCROLLBAR_OBJECT_LENGTH (view-range sb)))))


(defmethod dd-realize-scrollbar ((p XView) sb)
  (XV:with-xview-lock 
   (let* ((xvd (device (display sb)))
	  (xvo (device sb))
	  (initargs 
	   (prog1
	       (xview-canvas-initargs xvo)
	     (setf (xview-canvas-initargs xvo) nil)))
	  (parent 
	   (or (parent sb) (xview-display-nil-parent-frame xvd)))
	  (container
	   (using-resource (al xview-attr-list-resource parent :window)
             (push-xview-attrs al WIN_MAP FALSE)
	     (apply #'init-xview-window-bounding-region al initargs)
	     (let ((size (xview-scrollbar-size (display sb))))
	       (if (typep sb 'vertical-scrollbar)
		   (push-xview-attrs al XV_WIDTH size)
		 (push-xview-attrs al XV_HEIGHT size)))
	     (flush-xview-attr-list al)
	     (xview-attr-list-id al))))

     (using-resource (al xview-attr-list-resource container :scrollbar)
       (push-xview-attrs al XV_X 0 XV_Y 0 XV_SHOW TRUE)
       (apply #'init-xview-scrollbar sb al initargs)
       (if (typep sb 'vertical-scrollbar)
	   (push-xview-attrs al XV_HEIGHT (xv_get container XV_HEIGHT))
	 (push-xview-attrs al XV_WIDTH (xv_get container XV_WIDTH)))
       (flush-xview-attr-list al)

       (let ((id (xview-attr-list-id al)))
	 (setf (xview-object-id xvo) id
	       (xview-object-xid xvo) (xv_get id XV_XID)
	       (xview-object-xvd xvo) xvd
	       (xview-object-dsp xvo) (xview-display-dsp xvd)))

       (def-xview-object sb xvo)
       
       (xview-maybe-XFlush xvd)))))


(defmethod dd-scrollbar-mapped  ((p XView) sb) 
  (xview-canvas-mapped (device sb)))

(defmethod (setf dd-scrollbar-mapped) (value (p XView) sb)
  (prog1
      (setf (xview-canvas-mapped (device sb)) value)
    (XV:with-xview-lock 
     (let* ((xvo (device sb))
	    (id (xview-container-id xvo)))
       (when id
	 (xv-set-attr value xvo id WIN_MAP 'boolean))))))	 



(defmethod dd-insert-scrollbar ((p XView) scrollbar relation sibling parent)
  (insert-xview-canvas scrollbar relation sibling parent))

(defmethod dd-withdraw-scrollbar ((p XView) scrollbar old-parent)
  (withdraw-xview-canvas scrollbar old-parent))


(defmethod dd-scrollbar-bounding-region ((p XView) sb)
  (XV:with-xview-lock 
    (let* ((xvo (device sb))
	   (id (xview-object-id xvo)))
      (if id
	  (xview-win-bounding-region (xv_get id WIN_PARENT))
	(let* ((initargs (xview-canvas-initargs xvo))
	       (initargs-br (getf initargs :bounding-region))
	       (region
		(or (if initargs-br (copy-region initargs-br))
		    (apply #'make-region :allow-other-keys t initargs)))
	       (size (xview-scrollbar-size (display sb))))
	  (if (typep sb 'vertical-scrollbar)
	      (setf (region-width region) size)
	    (setf (region-height region) size))

	  region)))))

(defmethod (setf dd-scrollbar-bounding-region) (new-br (p XView) sb)
  (XV:with-xview-lock 
    (let* ((xvo (device sb))
	   (id (xview-object-id xvo)))
      (if id
	  (let ((container (xv_get id WIN_PARENT)))
	    (xview-set-win-bounding-region container (xview-object-xvd xvo) new-br)
	    (if (typep sb 'vertical-scrollbar)
		(xv_set id XV_HEIGHT (xv_get container XV_HEIGHT) XV_NULL)
	      (xv_set id XV_WIDTH (xv_get container XV_WIDTH) XV_NULL)))
	(setf (getf (xview-canvas-initargs xvo) :bounding-region) (copy-region new-br)))))
  new-br)


(XV:defcallback xview-compute-scroll (xsb cable-position cable-length motion 
				      (offset (:pointer :unsigned-32bit)) 
				      (object-length (:pointer :unsigned-32bit)))
  (let ((sb (xview-id-to-object xsb)))
    (when (typep sb 'scrollbar)
      (setf xview-scrollbar-motion 
	    (case motion
	      (#.SCROLLBAR_LINE_FORWARD :line-forward)
	      (#.SCROLLBAR_LINE_BACKWARD :line-backward)
	      (#.SCROLLBAR_PAGE_FORWARD :page-forward)
	      (#.SCROLLBAR_PAGE_BACKWARD :page-backward)
	      (#.SCROLLBAR_TO_END :to-end)
	      (#.SCROLLBAR_TO_START :to-start)
	      (#.SCROLLBAR_ABSOLUTE :absolute)
	      (#.SCROLLBAR_POINT_TO_MIN :point-to-view-start)
	      (#.SCROLLBAR_MIN_TO_POINT :view-start-to-point)))
       (let* ((client (scrollbar-client sb))
	      (min (view-min client sb))
	      (max (view-max client sb))
	      (length (- (1+ (abs (- max min))) (view-length client sb)))
	      (view-start 
	       (compute-view-start client sb xview-scrollbar-motion
		  (+ (truncate (* (/ cable-position (coerce cable-length 'float)) length)) min))))
	(cond
	 (view-start
	  (setf (foreign-value object-length) (1+ (- max min))
		(foreign-value offset) (- view-start min)))
	 ((> length 0)
	  (XV:scrollbar-default-compute-scroll-proc 
	   xsb cable-position cable-length motion offset object-length))
	 (t
	  (setf (foreign-value offset) 0)))
	(setf xview-scrollbar-view-start (+ (foreign-value offset) min))))))


(defmethod dd-scrollbar-splittable ((p XView) sb)
  (get-xview-initarg-attr sb SCROLLBAR_SPLITTABLE :splittable 'boolean))

(defmethod (setf dd-scrollbar-splittable) (value (p XView) sb)
  (set-xview-initarg-attr value sb SCROLLBAR_SPLITTABLE :splittable 'boolean))


;;; To prevent XView from delivering a scrollbar_request event after we've 
;;; programatically changed the scrollbar elevator we temporarily set the 
;;; scrollbars notify-client to the root-canvas.  The input handler for 
;;; scrollbar-request events (see handle-xview-internal-event in xview-input.lisp) 
;;; ignores scrollbar-requests events delivered to the root-canvas.

(defmethod dd-update-scrollbar ((p XView) scrollbar)
  (XV:with-xview-lock 
    (let* ((client (scrollbar-client scrollbar))
	   (xvo (if client (device client)))
	   (client-id (if xvo (xview-object-id xvo))))
      (when client-id
	(let ((root-id (xview-display-root (xview-object-xvd xvo)))
	      (scrollbar-id (xview-object-id (device scrollbar))))
	  (when scrollbar-id 
	    (xv_set scrollbar-id
	      SCROLLBAR_NOTIFY_CLIENT root-id
	      SCROLLBAR_VIEW_START (view-start client scrollbar)
	      SCROLLBAR_VIEW_LENGTH (view-length client scrollbar)
	      SCROLLBAR_OBJECT_LENGTH (abs (- (view-max client scrollbar)
					      (view-min client scrollbar)))
	      XV_NULL)
	    (xv_set scrollbar-id SCROLLBAR_NOTIFY_CLIENT client-id XV_NULL)
	    (xview-maybe-XFlush (xview-object-xvd xvo))))))))

(defmethod dd-set-scrollbar-client ((p XView) scrollbar client)
  (declare (ignore client))
  (dd-update-scrollbar p scrollbar))


(defmethod dd-destroy-scrollbar ((p XView) scrollbar)
  (destroy-xview-object scrollbar))



;;; VIEWPORT


(defmethod dd-initialize-canvas ((p XView) (vp viewport) &rest initargs)
  (declare (dynamic-extent initargs))
  (xview-initialize-canvas vp #'make-xview-viewport initargs))



;;; Multiple-value return the dimensions specified for the container-window and 
;;; the extra space needed for the vertical and horizontal scrollbars.

(defun xview-viewport-size-initargs (xvo &rest initargs
					 &key
					   view-region
					   container-region
					 &allow-other-keys)
  (let ((cw-initargs (apply #'bounding-region-spec initargs))
	(bw2 (* (or (xview-window-border-width xvo) 0) 2)))
    (flet
     ((initarg-width-height (x)
	(typecase x
	  (region
	   (values (region-width x) (region-height x)))
	  (list
	   (let ((s (apply #'bounding-region-spec x)))
	     (values (getf s :width) (getf s :height))))))

      (maybe-set-width-height (width height offset)
        (when width  (setf (getf cw-initargs :width) (+ offset width)))
	(when height (setf (getf cw-initargs :height) (+ offset height))))

      (sb-size (sb attr)
	(let ((id (if sb (xview-object-id (device sb)))))
	  (if id (xv_get id attr) 0))))

     (multiple-value-call #'maybe-set-width-height 
       (initarg-width-height view-region) bw2)

     (multiple-value-call #'maybe-set-width-height 
       (initarg-width-height container-region) 0)

     (values cw-initargs 
	     (sb-size (xview-viewport-vertical-scrollbar xvo) XV_WIDTH)
	     (sb-size (xview-viewport-horizontal-scrollbar xvo) XV_HEIGHT)))))


;;; If XView makes the window too small to contain the scrollbars and a small view-window
;;; then default it to 64x64.

(defun make-xview-viewport-container-window (vp xvo initargs)
  (let ((panel (xview-display-nil-parent-panel (xview-object-xvd xvo))))
    (using-resource (al xview-attr-list-resource (xview-canvas-owner vp) :window)
      (push-xview-attrs al 
	WIN_MAP FALSE
	WIN_RETAINED FALSE
	WIN_CMS (xv_get panel WIN_CMS)
	WIN_BACKGROUND_COLOR (xv_get panel WIN_BACKGROUND_COLOR))
      (apply #'init-xview-window-bounding-region al :border-width 0 initargs)
      (flush-xview-attr-list al)
      (xview-attr-list-id al))))


(defun make-xview-viewport-view-window (vp xvo vsb-size hsb-size)
  (declare (ignore vp))
  (let ((owner (xview-viewport-xcw xvo))
	(bw2 (* (or (xview-window-border-width xvo) 0) 2)))
    (using-resource (al xview-attr-list-resource owner :window)
      (push-xview-attrs al 
        WIN_MAP TRUE
        WIN_RETAINED FALSE
	WIN_CMS (xv_get owner WIN_CMS)
	WIN_BACKGROUND_COLOR (xv_get owner WIN_BACKGROUND_COLOR)
	XV_X 0
	XV_Y 0
	XV_WIDTH (- (xv_get owner XV_WIDTH) bw2 vsb-size)
	XV_HEIGHT (- (xv_get owner XV_HEIGHT) bw2 hsb-size)
	WIN_BORDER (if (= bw2 2) TRUE FALSE))
      (flush-xview-attr-list al)
      (xview-attr-list-id al))))


(defun make-xview-viewport-paint-window (vp xvo &rest initargs 
					        &key 
						  output-region 
						  view-region
						&allow-other-keys)
  (let* ((owner (xview-viewport-xvw xvo))
	 (owner-width (xv_get owner XV_WIDTH))
	 (owner-height (xv_get owner XV_HEIGHT))
	 (bw2 (* (or (xview-window-border-width xvo) 0) 2)))
    (multiple-value-bind (width height)
	(typecase output-region
	  (region
	   (values (region-width output-region) (region-height output-region)))
	  (list
	   (let ((s (apply #'bounding-region-spec output-region)))
	     (values (or (getf s :width) owner-width) (or (getf s :height) owner-height))))
	  (t
	   (values (- owner-width bw2) (- owner-height bw2))))

      (multiple-value-bind (left top)
	  (typecase view-region
	     (region
	      (values (- (region-left view-region)) (- (region-top view-region))))
	     (list
	      (let* ((s (apply #'bounding-region-spec view-region)))
		(values (- (or (getf s :width) 0)) (- (or (getf s :height) 0)))))
	     (t
	      (values 0 0)))

	(using-resource (al xview-attr-list-resource owner :window)
	  (push-xview-attrs al
	    XV_X left 
	    XV_Y top
	    XV_WIDTH width
	    XV_HEIGHT height)
	  (apply #'init-xview-canvas vp xvo al initargs)
	  (apply #'init-xview-opaque-canvas vp xvo al initargs)
	  (apply #'realize-xview-canvas vp xvo al initargs)
	  (let ((id (xview-attr-list-id al))) 
	    (xv_set id WIN_MAP TRUE XV_NULL) 
	    id))))))


(defun layout-xview-viewport-scrollbars (xvo)
  (let ((vsb (xview-viewport-vertical-scrollbar xvo))
	(hsb (xview-viewport-horizontal-scrollbar xvo))
	(cw (xview-viewport-xcw xvo))
	(vw (xview-viewport-xvw xvo))
	(bw2 (* (or (xview-window-border-width xvo) 0) 2)))
    (when vsb
      (let ((br (bounding-region vsb)))
	(setf (region-left br) (- (xv_get cw XV_WIDTH) (region-width br))
	      (region-top br) 0
	      (region-height br) (+ bw2 (xv_get vw XV_HEIGHT))
	      (bounding-region vsb) br))
      (update-scrollbar vsb))
    (when hsb
      (let ((br (bounding-region hsb)))
	(setf (region-left br) 0
	      (region-top br) (- (xv_get cw XV_HEIGHT) (region-height br))
	      (region-width br) (+ bw2 (xv_get vw XV_WIDTH))
	      (bounding-region hsb) br))
      (update-scrollbar hsb))))


(defun install-xview-viewport-scrollbar (vp xvo new-sb &optional old-sb)
  (when old-sb
    (let ((id (xview-container-id (device old-sb)))
	  (xvd (xview-object-xvd xvo)))
      (when (and id xvd)
	(xv_set id WIN_PARENT (xview-display-nil-parent-frame xvd) XV_NULL))
      (setf (scrollbar-client old-sb) nil)))

  (when new-sb
    (let ((id (xview-container-id (device new-sb)))
	  (xcw (xview-viewport-xcw xvo)))
      (when (and id xcw)
	(xv_set id WIN_PARENT xcw XV_SHOW TRUE XV_NULL)))
    (setf (scrollbar-client new-sb) vp)))


(defmethod dd-realize-canvas ((p XView) (vp viewport))
  (XV:with-xview-lock 
    (let* ((xvo (device vp))
	   (xvd (setf (xview-object-xvd xvo) (device (display vp))))
	   (initargs 
	    (prog1
		(xview-canvas-initargs xvo)
	      (setf (xview-canvas-initargs xvo) nil))))
      (multiple-value-bind (cw-initargs vsb-size hsb-size)
	  (apply #'xview-viewport-size-initargs xvo initargs)

	(setf (xview-viewport-xcw xvo) 
	      (make-xview-viewport-container-window vp xvo cw-initargs))

	(setf (xview-viewport-xvw xvo) 	      
	      (make-xview-viewport-view-window vp xvo vsb-size hsb-size))
	
	(let ((pw 
	       (setf (xview-viewport-id xvo) 	      
		     (apply #'make-xview-viewport-paint-window vp xvo initargs))))
	  (setf (xview-object-xid xvo) (xv_get pw XV_XID)
		(xview-object-dsp xvo) (xview-display-dsp xvd)))

	(let ((vsb (xview-viewport-vertical-scrollbar xvo))
	      (hsb (xview-viewport-horizontal-scrollbar xvo)))
	  (when vsb (install-xview-viewport-scrollbar vp xvo vsb))
	  (when hsb (install-xview-viewport-scrollbar vp xvo hsb))
	  (when (or vsb hsb) (layout-xview-viewport-scrollbars xvo))))

      (xview-maybe-XFlush xvd))))


(defmethod dd-destroy-canvas ((p XView) (x viewport))
  (let* ((xvo (device x))
	 (xcw (xview-viewport-xcw xvo))
	 (vsb (xview-viewport-vertical-scrollbar xvo))
	 (hsb (xview-viewport-horizontal-scrollbar xvo)))
    (setf (xview-viewport-xcw xvo) nil
	  (xview-viewport-xvw xvo) nil
	  (xview-viewport-vertical-scrollbar xvo) nil
	  (xview-viewport-horizontal-scrollbar xvo) nil)
    (when vsb (undef-xview-object vsb (device vsb)))
    (when hsb (undef-xview-object hsb (device hsb)))
    (destroy-xview-object x xvo)           ;; destroys paint window only
    (when xcw (XV:xv-destroy-safe xcw))    ;; XView destroys scrollbars and view window
    (xview-maybe-XFlush (xview-object-xvd xvo))))


(defmethod dd-viewport-vertical-scrollbar ((p XView) vp)
  (xview-viewport-vertical-scrollbar (device vp)))

(defmethod (setf dd-viewport-vertical-scrollbar) (new-sb (p XView) vp)
  (XV:with-xview-lock 
    (let* ((xvo (device vp))
	   (xvw (xview-viewport-xvw xvo))
	   (old-sb (xview-viewport-vertical-scrollbar xvo))
	   (old-sb-id (if old-sb (xview-container-id (device old-sb))))
	   (new-sb-id (if new-sb (xview-container-id (device new-sb)))))
      (setf (xview-viewport-vertical-scrollbar xvo) new-sb)
      (when (xview-object-id xvo)
	(cond
	 ((and (null old-sb) new-sb)
	  (xv_set xvw 
	    XV_WIDTH (- (xv_get xvw XV_WIDTH) (xv_get new-sb-id XV_WIDTH)) 
	    XV_NULL))
	((and old-sb (null new-sb))
	  (xv_set xvw 
	    XV_WIDTH (+ (xv_get xvw XV_WIDTH) (xv_get old-sb-id XV_WIDTH)) 
	    XV_NULL)))
	(install-xview-viewport-scrollbar vp xvo new-sb old-sb)
	(layout-xview-viewport-scrollbars xvo)
	(xview-maybe-Xflush (xview-object-xvd xvo)))))
  new-sb)


(defmethod dd-viewport-horizontal-scrollbar ((p XView) vp)
  (xview-viewport-horizontal-scrollbar (device vp)))

(defmethod (setf dd-viewport-horizontal-scrollbar) (new-sb (p XView) vp)
  (XV:with-xview-lock 
    (let* ((xvo (device vp))
	   (xvw (xview-viewport-xvw xvo))
	   (old-sb (xview-viewport-horizontal-scrollbar xvo))
	   (old-sb-id (if old-sb (xview-container-id (device old-sb))))
	   (new-sb-id (if new-sb (xview-container-id (device new-sb)))))
      (setf (xview-viewport-horizontal-scrollbar xvo) new-sb)
      (when (xview-object-id xvo)
	(cond
	 ((and (null old-sb) new-sb)
	  (xv_set xvw 
	    XV_HEIGHT (- (xv_get xvw XV_HEIGHT) (xv_get new-sb-id XV_HEIGHT)) 
	    XV_NULL))
	((and old-sb (null new-sb))
	  (xv_set xvw 
	    XV_HEIGHT (+ (xv_get xvw XV_HEIGHT) (xv_get old-sb-id XV_HEIGHT)) 
	    XV_NULL)))
	(install-xview-viewport-scrollbar vp xvo new-sb old-sb)
	(layout-xview-viewport-scrollbars xvo)
	(xview-maybe-Xflush (xview-object-xvd xvo)))))
  new-sb)

    

	
(defmethod dd-canvas-mapped ((p XView) (x viewport))
  (xview-canvas-mapped (device x)))

(defmethod (setf dd-canvas-mapped) (value (p XView) (x viewport))
  (prog1
      (setf (xview-canvas-mapped (device x)) value)
    (XV:with-xview-lock 
      (let* ((xvo (device x))
	     (id (xview-container-id xvo)))
       (when id
	 (xv-set-attr value xvo id WIN_MAP 'boolean))))))


(defun xview-viewport-region (xvo id)
  (if id
      (xview-win-bounding-region id)
    (let* ((initargs (xview-object-initargs xvo))
	   (initargs-br (getf initargs :bounding-region)))
      (or (if initargs-br (copy-region initargs-br))
	  (apply #'make-region :allow-other-keys t initargs)))))

(defmethod dd-viewport-output-region ((p XView) vp)
  (XV:with-xview-lock 
    (let* ((xvo (device vp))
	   (output-region (xview-viewport-region xvo (xview-object-id xvo))))
      (setf (region-left output-region) 0
	    (region-top output-region) 0)
      output-region)))

(defmethod dd-viewport-bounding-region ((p XView) vp)
  (XV:with-xview-lock 
    (let* ((xvo (device vp))
	   (vr (xview-viewport-region xvo (xview-viewport-xvw xvo)))
	   (cr (xview-viewport-region xvo (xview-viewport-xcw xvo))))
      (make-region :left (region-left cr)
		   :top (region-top cr)
		   :width (region-width vr)
		   :height (region-height vr)))))

(defmethod dd-viewport-view-region ((p XView) vp)
  (XV:with-xview-lock 
    (let* ((xvo (device vp))
	   (bw2 (* (or (xview-window-border-width xvo) 0) 2))
	   (vr (xview-viewport-region xvo (xview-viewport-xvw xvo)))
	   (xr (xview-viewport-region xvo (xview-object-id xvo))))
      (make-region :left (- (region-left xr))
		   :top (- (region-top xr))
		   :width (- (region-width vr) bw2)
		   :height  (- (region-height vr) bw2)))))

(defmethod dd-viewport-container-region ((p XView) vp)
  (XV:with-xview-lock 
    (let ((xvo (device vp)))
      (xview-viewport-region xvo (xview-viewport-xcw xvo)))))


(defmethod (setf dd-viewport-output-region) (value (p XView) vp)
  (XV:with-xview-lock 
    (let* ((xvo (device vp))
	   (id (xview-object-id xvo)))
      (when id
	(xview-set-win-bounding-region id (xview-object-xvd xvo) value)
	(let ((vsb (xview-viewport-vertical-scrollbar xvo))
	      (hsb (xview-viewport-horizontal-scrollbar xvo)))
	  (when vsb (update-scrollbar vsb))
	  (when hsb (update-scrollbar hsb))
	  (xview-maybe-Xflush (xview-object-xvd xvo))))))
  value)


(defmethod (setf dd-viewport-bounding-region) (value (p XView) vp)
  (XV:with-xview-lock 
    (let* ((xvo (device vp))
	   (vw (xview-viewport-xvw xvo))
	   (cw (xview-viewport-xcw xvo))
	   (bw2 (* (or (xview-window-border-width xvo) 0) 2))
	   (view-height (- (region-height value) bw2))
	   (view-width (- (region-width value) bw2)))
      (when (and vw cw)
	(xv_set cw 
	  XV_X (region-left value)
	  XV_Y (region-top value)
	  XV_WIDTH (+ (xv_get cw XV_WIDTH) (- view-width (xv_get vw XV_WIDTH)))
	  XV_HEIGHT (+ (xv_get cw XV_HEIGHT) (- view-height (xv_get vw XV_HEIGHT)))
	  XV_NULL)
	(xv_set vw
	  XV_WIDTH view-width
	  XV_HEIGHT view-height
	  XV_NULL)
	(layout-xview-viewport-scrollbars xvo)
	(xview-maybe-Xflush (xview-object-xvd xvo)))))
  value)

(defmethod (setf dd-viewport-view-region) (value (p XView) vp)
  (XV:with-xview-lock 
    (let* ((xvo (device vp))
	   (vw (xview-viewport-xvw xvo))
	   (cw (xview-viewport-xcw xvo))
	   (pw (xview-object-id xvo))
	   (vw-height (region-height value))
	   (vw-width (region-width value)))
      (when (and vw cw pw)
	(xv_set cw
	  XV_WIDTH (+ (xv_get cw XV_WIDTH) (- vw-width (xv_get vw XV_WIDTH)))
	  XV_HEIGHT (+ (xv_get cw XV_HEIGHT) (- vw-height (xv_get vw XV_HEIGHT)))
	  XV_NULL)
	(xv_set vw
	  XV_WIDTH vw-width
	  XV_HEIGHT vw-height
	  XV_NULL)
	(xv_set pw
	  XV_X (- (region-left value))
	  XV_Y (- (region-top value))
	  XV_WIDTH (xv_get pw XV_WIDTH)
	  XV_HEIGHT (xv_get pw XV_HEIGHT)
	  XV_NULL)
	(layout-xview-viewport-scrollbars xvo)
	(xview-maybe-Xflush (xview-object-xvd xvo)))))
  value)

(defmethod (setf dd-viewport-container-region) (value (p XView) vp)
  (XV:with-xview-lock 
    (let* ((xvo (device vp))
	   (vw (xview-viewport-xvw xvo))
	   (cw (xview-viewport-xcw xvo))
	   (cw-height (region-height value))
	   (cw-width (region-width value)))
      (when (and vw cw)
	(xv_set vw
	  XV_WIDTH (+ (xv_get vw XV_WIDTH) (- cw-width (xv_get cw XV_WIDTH)))
	  XV_HEIGHT (+ (xv_get vw XV_HEIGHT) (- cw-height (xv_get cw XV_HEIGHT)))
	  XV_NULL)
	(xv_set cw 
	  XV_X (region-left value)
	  XV_Y (region-top value)
	  XV_WIDTH cw-width 
	  XV_HEIGHT cw-height
	  XV_NULL)
	(layout-xview-viewport-scrollbars xvo)
	(xview-maybe-Xflush (xview-object-xvd xvo)))))
  value)
