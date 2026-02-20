;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)xview-item.lisp	3.43 10/29/91


(in-package "LISPVIEW")


;;; Items

(defmethod dd-initialize-item ((p XView) 
			       item 
			       &rest initargs 
			       &key 
			         mapped 
				 (make-xview-item #'make-xview-item)
			       &allow-other-keys)
  (declare (dynamic-extent initargs))

  (unless (slot-boundp item 'device)
    (setf (device item)
	  (apply make-xview-item
	   :allow-other-keys t
	   :mapped mapped
	   :initargs (copy-list initargs)
	   initargs)))
  (setf (slot-value item 'status) :initialized))


(defmethod dd-destroy-item ((p XView) item)
  (destroy-xview-object item))


(defmethod dd-item-mapped ((p XView) x)
  (xview-item-mapped (device x)))

(defmethod (setf dd-item-mapped) (value (p XView) x)
  (setf (xview-item-mapped (device x))
	(set-xview-attr value x XV_SHOW 'boolean)))


(defmethod dd-item-state ((p XView) x)
  (get-xview-initarg-attr x PANEL_INACTIVE :state 'boolean
    #'(lambda (v) (if v :inactive :active))))

(defmethod (setf dd-item-state) (value (p XView) x)
  (set-xview-initarg-attr value x PANEL_INACTIVE :state 'boolean
    #'(lambda (v) (not (eq v :active)))))
       

(defmethod dd-item-layout ((p Xview) x)
  (get-xview-initarg-attr x PANEL_LAYOUT :layout 'integer
    #'(lambda (v) (if (= v PANEL_VERTICAL) :vertical :horizontal))))

(defmethod (setf dd-item-layout) (value (p Xview) x)
  (set-xview-initarg-attr value x PANEL_LAYOUT :layout 'integer
    #'(lambda (v) (if (eq v :vertical) PANEL_VERTICAL PANEL_HORIZONTAL))))


(defun init-xview-panel-item-bounding-region (al &key 
						   bounding-region
						   left bottom right top width height
						 &allow-other-keys)
  (with-default-region-dimensions (width height left top right bottom bounding-region)
    (when left   (push-xview-attrs al XV_X left))
    (when top    (push-xview-attrs al XV_Y top))
    (when width  (push-xview-attrs al XV_WIDTH width))
    (when height (push-xview-attrs al XV_HEIGHT height))))


(defun init-xview-panel-item (al &key 
				   state 
				   layout 
				   font 
				   value-x 
				   value-y 
				   spot-help 
				 &allow-other-keys)
  (when (stringp spot-help)
    (let ((fp (malloc-foreign-string spot-help)))
      (push-xview-attrs al XV_KEY_DATA XV_HELP fp)))

  (when value-x (push-xview-attrs al PANEL_VALUE_X value-x))
  (when value-y (push-xview-attrs al PANEL_VALUE_Y value-y))
  (when (eq state :inactive) (push-xview-attrs al PANEL_INACTIVE TRUE))
  (case layout
    (:vertical (push-xview-attrs al PANEL_LAYOUT PANEL_VERTICAL))
    (:horizontal (push-xview-attrs al PANEL_LAYOUT PANEL_HORIZONTAL)))
  (when font
    (let ((id (xview-object-id (device font))))
      (when id
	(push-xview-attrs al XV_FONT id)))))


(defun realize-xview-item (al object)
  (let ((xvo (device object))
	(xvd (device (display object))))
    (flush-xview-attr-list al)
    (setf (xview-object-id xvo) (xview-attr-list-id al)
	  (xview-object-xvd xvo) xvd
	  (xview-object-dsp xvo) (xview-display-dsp xvd))

    (def-xview-object object xvo)

    (let ((fg (xview-item-foreground xvo)))
      (when fg
	(push-xview-attrs al PANEL_ITEM_COLOR (xview-color-index (device fg)))))
    (if (xview-item-mapped xvo)
	(push-xview-attrs al XV_SHOW TRUE)
	(push-xview-attrs al XV_SHOW FALSE)) ;; no consistent default in XView
    (flush-xview-attr-list al)

    (xview-maybe-XFlush xvd)))



(defmethod dd-item-bounding-region ((p XView) x)
  (XV:with-xview-lock 
    (let* ((xvo (device x))
	   (id (xview-object-id xvo)))
      (if id
	  (make-region :left (xv_get id XV_X)
		       :top  (xv_get id XV_Y)
		       :width (xv_get id XV_WIDTH)
		       :height (xv_get id XV_HEIGHT))
	(let* ((initargs (xview-item-initargs xvo))
	       (initargs-br (getf initargs :bounding-region)))
	  (or (if initargs-br (copy-region initargs-br))
	      (apply #'make-region :allow-other-keys t initargs)))))))


(defmethod (setf dd-item-bounding-region) (new-br (p XView) x)
  (XV:with-xview-lock 
    (let* ((xvo (device x))
	   (id (xview-object-id xvo)))
      (if id
	  (progn
	    (xv_set id XV_X (region-left new-br)
		       XV_Y (region-top new-br)
		       XV_WIDTH (region-width new-br)
		       XV_HEIGHT (region-height new-br)
		       XV_NULL)
	    (xview-maybe-XFlush (xview-object-xvd xvo)))
	(setf (getf (xview-item-initargs xvo) :bounding-region) (copy-region new-br)))))

  new-br)


(defmethod dd-insert-item ((p XView) item relation sibling parent)
  (declare (ignore item relation sibling parent)))

(defmethod dd-withdraw-item ((p XView) item parent)
  (declare (ignore item parent)))


(defmethod dd-panel-keyboard-focus ((p XView) panel)
  (when (find-if #'(lambda (x) (typep x 'text-field)) (children panel))
    (XV:with-xview-lock 
      (let* ((xvo (device panel))
	     (id (xview-object-id xvo)))
	(when id 
	  (let ((item (xv_get id PANEL_CARET_ITEM)))
	    (when item
	      (xview-id-to-object item))))))))

(defmethod (setf dd-panel-keyboard-focus) (value (p XView) panel)
  (unless (eq (parent value) Panel)
    (error "Keyboard focus item, ~S, isn't a child of ~S" value panel))
  (XV:with-xview-lock 
    (let* ((xvo (device panel))
	   (panel-id (xview-object-id xvo))
	   (item-id (if value (xview-object-id (device value)))))
      (when (and panel-id item-id)
	(xv_set panel-id PANEL_CARET_ITEM item-id XV_NULL)
	(xview-maybe-XFlush (xview-object-xvd xvo)))))
  value)


;;; Item Labels

(defun init-xview-panel-item-label (al object &key label-width &allow-other-keys)
  (let ((label (and (slot-boundp object 'label) (label object))))
    (typecase label
       (string
	 (push-xview-attrs al PANEL_LABEL_STRING (malloc-foreign-string label)))
       (image
	 (let ((id (xview-object-id (device label))))
	   (when id
	     (push-xview-attrs al PANEL_LABEL_IMAGE id)))))
     (when label-width
       (push-xview-attrs al PANEL_LABEL_WIDTH label-width))))




(flet
 ((set-xview-label (x form)
    (let ((label 
	   (cond 
	    ((typep form '(or string image)) form)
	    ((symbolp form)
	     (cond
	      ((boundp form) (symbol-value form))
	      ((fboundp form) (funcall form))
	      (t (symbol-value form))))
	    ((functionp form) (funcall form))
	    (t (eval form)))))
      (etypecase label
	 (string (set-xview-attr label x PANEL_LABEL_STRING))
	 (image (set-xview-attr label x PANEL_LABEL_IMAGE))))))


 (defmethod (setf dd-item-mapped) (value (p XView) (x label))
   (when (and value (slot-boundp x 'label))
     (set-xview-label x (label x)))
   (call-next-method))

 (defmethod (setf dd-item-label) (value (platform XView) (x item))
   (set-xview-label x value)
   value))


(defmethod dd-item-label-width ((p XView) x)
  (get-xview-initarg-attr x PANEL_LABEL_WIDTH :label-width))

(defmethod (setf dd-item-label-width) (value (p XView) x)
  (set-xview-initarg-attr value x PANEL_LABEL_WIDTH :label-width))


;;; Message Item

(defmethod dd-realize-item ((p XView) (m message))
  (let* ((xvo (device m))
	 (initargs (prog1
		       (xview-item-initargs xvo)
		     (setf (xview-item-initargs xvo) nil))))
    (using-resource (al xview-attr-list-resource (parent m) :panel-message)
      (push-xview-attrs al PANEL_LABEL_BOLD (if (getf initargs :label-bold t) TRUE FALSE))
      (apply #'init-xview-panel-item-bounding-region al initargs)
      (apply #'init-xview-panel-item al initargs)
      (apply #'init-xview-panel-item-label al m initargs)

      (realize-xview-item al m))))


(defmethod dd-item-foreground ((p XView) x)
  (xview-item-foreground (device x)))

(defmethod (setf dd-item-foreground) (value (p XView) x)
  (setf (xview-item-foreground (device x))
	(set-xview-attr value x PANEL_ITEM_COLOR)))


(defmethod dd-item-background ((p XView) x)
  (xview-item-background (device x)))

(defmethod (setf dd-item-background) (value (p XView) x)
  (setf (xview-item-background (device x))
	(set-xview-attr value x WIN_BACKGROUND_COLOR)))


;;; Numeric Range

(defmethod dd-numeric-range-value ((p XView) x)
  (get-xview-initarg-attr x PANEL_VALUE :value))

(defmethod (setf dd-numeric-range-value) (value (p XView) x)
  (set-xview-initarg-attr value x PANEL_VALUE :value))


(defmethod dd-numeric-range-min-value ((p XView) x)
  (get-xview-initarg-attr x PANEL_MIN_VALUE :min-value))

(defmethod (setf dd-numeric-range-min-value) (value (p XView) x)
  (set-xview-initarg-attr value x PANEL_MIN_VALUE :min-value))


(defmethod dd-numeric-range-max-value ((p XView) x)
  (get-xview-initarg-attr x PANEL_MAX_VALUE :max-value))

(defmethod (setf dd-numeric-range-max-value) (value (p XView) x)
  (set-xview-initarg-attr value x PANEL_MAX_VALUE :max-value))



;;; Update-Value

(defun xview-set-panel-notify-proc (item value callback)
  (XV:with-xview-lock 
    (let* ((xvo (device item))
	   (id (xview-object-id xvo)))
      (when id
	(XV:with-xview-lock 
	 (if value
	     (xv_set id PANEL_NOTIFY_PROC (lookup-callback-address callback) XV_NULL)
	   (xv_set id PANEL_NOTIFY_PROC 0 XV_NULL)))))))



;;; Gauge

(defmethod dd-initialize-item ((p XView) (g gauge) &rest initargs)
  (apply #'call-next-method p g
	 :make-xview-item (if (typep g 'slider) #'make-xview-slider #'make-xview-gauge)
	 initargs))



(defun init-xview-panel-gauge (al g &key
				      value
				      min-value 
				      max-value
				      show-range
				      show-value
				      nticks
				      gauge-length
				      show-end-boxes
				      update-value
				    &allow-other-keys)
  (push-xview-attrs al PANEL_DIRECTION 
    (if (typep g '(or vertical-gauge vertical-slider))
	PANEL_VERTICAL 
      PANEL_HORIZONTAL))
  (when value 
    (push-xview-attrs al PANEL_VALUE value))
  (when min-value 
    (push-xview-attrs al PANEL_MIN_VALUE min-value))
  (when max-value 
    (push-xview-attrs al PANEL_MAX_VALUE max-value))
  (when (null show-range)
    (push-xview-attrs al PANEL_SHOW_RANGE FALSE))
  (when (null show-value)
    (push-xview-attrs al PANEL_SHOW_VALUE FALSE))
  (when nticks
    (push-xview-attrs al PANEL_TICKS nticks))
  (when gauge-length
    (if (typep g 'slider)
	(push-xview-attrs al PANEL_SLIDER_WIDTH gauge-length)
	(push-xview-attrs al PANEL_GAUGE_WIDTH gauge-length)
      ))
  (when (and show-end-boxes (typep g 'slider))
    (push-xview-attrs al PANEL_SLIDER_END_BOXES TRUE))
  (when (and update-value (typep g 'slider))
    (push-xview-attrs al PANEL_NOTIFY_PROC (lookup-callback-address 'slider-notify-proc))))


(defmethod dd-realize-item ((p XView) (g gauge))
  (let* ((xvo (device g))
	 (initargs (prog1
		       (xview-item-initargs xvo)
		     (setf (xview-item-initargs xvo) nil))))
      (using-resource (al xview-attr-list-resource (parent g) :panel-gauge)
	(apply #'init-xview-panel-item-bounding-region al initargs)
	(apply #'init-xview-panel-item al initargs)
	(apply #'init-xview-panel-item-label al g initargs)
	(apply #'init-xview-panel-gauge al g initargs)

	(realize-xview-item al g))))


(defmethod dd-show-range ((p XView) x)
  (xview-gauge-show-range (device x)))

(defmethod (setf dd-show-range) (value (p XView) x)
  (setf (xview-gauge-show-range (device x))
	(set-xview-attr value x PANEL_SHOW_RANGE 'boolean)))


(defmethod dd-show-value ((p XView) x)
  (xview-gauge-show-value (device x)))

(defmethod (setf dd-show-value) (value (p XView) x)
  (setf (xview-gauge-show-value (device x))
	(set-xview-attr value x PANEL_SHOW_VALUE 'boolean)))


(defmethod dd-nticks ((p XView) x)
  (get-xview-initarg-attr x PANEL_TICKS :nticks))

(defmethod (setf dd-nticks) (value (p XView) x)
  (set-xview-initarg-attr value x PANEL_TICKS :nticks))


(defmethod dd-gauge-length ((p XView) x)
  (get-xview-initarg-attr x PANEL_GAUGE_WIDTH :gauge-length))

(defmethod (setf dd-gauge-length) (value (p XView) x)
  (set-xview-initarg-attr value x PANEL_GAUGE_WIDTH :gauge-length))


;;; Slider

(defmethod dd-realize-item ((p XView) (s slider))
  (let* ((xvo (device s))
	 (initargs (prog1
		       (xview-item-initargs xvo)
		     (setf (xview-item-initargs xvo) nil))))
      (using-resource (al xview-attr-list-resource (parent s) :panel-slider)
	(apply #'init-xview-panel-item-bounding-region al initargs)
	(apply #'init-xview-panel-item al initargs)
	(apply #'init-xview-panel-item-label al s initargs)
	(apply #'init-xview-panel-gauge al s initargs)

	(realize-xview-item al s))))


(defmethod (setf dd-update-value) (value (p XView) (item slider))
  (xview-set-panel-notify-proc item value 'slider-notify-proc))


(XV:defcallback slider-notify-proc (xv-item xv-value xv-event)
  (declare (ignore xv-event))
  (let ((item (xview-id-to-object xv-item)))
    (when (typep item 'slider)
      (deliver-event item :update-value
	 (make-update-value-event :value xv-value)))))


(defmethod dd-gauge-length ((p XView) (x slider))
  (get-xview-initarg-attr x PANEL_SLIDER_WIDTH :gauge-length))

(defmethod (setf dd-gauge-length) (value (p XView) (x slider))
  (set-xview-initarg-attr value x PANEL_SLIDER_WIDTH :gauge-length))

(defmethod dd-show-end-boxes ((p XView) x)
  (xview-slider-show-end-boxes (device x)))

(defmethod (setf dd-show-end-boxes) (value (p XView) x)
  (setf (xview-slider-show-end-boxes (device x))
	(set-xview-attr value x PANEL_SLIDER_END_BOXES 'boolean)))

;;; Setting

(defmethod dd-initialize-item ((p XView) (s setting) &rest initargs)
  (apply #'call-next-method p s 
	 :make-xview-item #'make-xview-setting 
	 initargs))


(defmacro choice-position (choice choices)
  (let ((choice-var (gensym)))
    `(let ((,choice-var ,choice))
       (position ,choice-var ,choices 
		 :test (if (stringp ,choice-var) #'equal #'eql)))))


;;; The last sentence at end of section 7.4 in the "Revised and Updated for Version 2" 
;;; version of the O'Reilly Xview Manual: "For choice items whose PANEL_CHOOSE_NONE is 
;;; TRUE, a PANEL_VALUE of -1 may be set or returned indicating that no choices are 
;;; set for that item".

(defun solo-to-xview-setting-value (setting choices value)
  (if (typep setting 'exclusive-setting)
      (or (choice-position value choices) 
	  (if (selection-required setting) 0 -1)) 
    (let ((mask 0))                                
      (dolist (choice value mask)
	(let ((n (choice-position choice choices)))
	  (when n
	    (setf mask (logior mask (expt 2 n)))))))))


(defun xview-to-solo-setting-value (setting choices value)
  (flet ((choice-elt (n)
	   (cond
	    ((and (typep setting 'exclusive-setting) (= n -1)) 
	     nil)
	    ((< -1 n (length choices))
	     (elt choices n))
	    (t
	     (warn "XView reported unknown choice position ~D for ~S" n setting)))))
    (if (typep setting 'exclusive-setting)
	(choice-elt value)
      (let ((selected-choices nil))
	(dotimes (n (integer-length value) (nreverse selected-choices))
	  (when (logbitp n value)
	    (push (choice-elt n) selected-choices)))))))

    
(defun init-xview-panel-choice-choice (al row choice-label-callback choice)
  (flet 
   ((init-choice (label)
      (etypecase label
        (string
	 (push-xview-attrs al PANEL_CHOICE_STRING row (malloc-foreign-string label)))
	(image
	 (let ((id (xview-object-id (device label))))
	   (when id
	     (push-xview-attrs al PANEL_CHOICE_IMAGE row id)))))))

   (multiple-value-bind (string image)
       (funcall choice-label-callback choice)
     (when string (init-choice string))
     (when image (init-choice image)))))


(defun init-xview-panel-choice (al s &key 
				       value
				       choices-nrows
				       choices-ncols
				       update-value
				     &allow-other-keys)
  (let* ((xvo (device s))
	 (choices (xview-setting-choices xvo)))
    (push-xview-attrs al PANEL_CHOOSE_NONE 
      (if (xview-setting-selection-required xvo) FALSE TRUE))
    (push-xview-attrs al PANEL_DEFAULT_VALUE
      (solo-to-xview-setting-value s choices (xview-setting-default xvo)))
    (when value
      (push-xview-attrs al PANEL_VALUE 
	(solo-to-xview-setting-value s choices value)))
    (when choices-nrows
      (push-xview-attrs al PANEL_CHOICE_NROWS choices-nrows))
    (when choices-ncols
      (push-xview-attrs al PANEL_CHOICE_NCOLS choices-ncols))
    (let ((callback (choice-label-callback s))
	  (row -1))
      (dolist (choice choices)
	(init-xview-panel-choice-choice al (incf row) callback choice)))

    (when update-value
      (push-xview-attrs al PANEL_NOTIFY_PROC 
	(lookup-callback-address 'xview-setting-notify-proc)))))


(defun realize-xview-panel-choice (s &rest xview-attrs)
  (XV:with-xview-lock 
    (let* ((xvo (device s))
	   (initargs 
	    (prog1
		(xview-item-initargs xvo)
	      (setf (xview-item-initargs xvo) nil))))

      (using-resource (al xview-attr-list-resource (parent s) :panel-choice)
	(apply #'push-xview-attrs al xview-attrs)
	(apply #'init-xview-panel-item-bounding-region al initargs)
	(apply #'init-xview-panel-item al initargs)
	(apply #'init-xview-panel-item-label al s initargs)
	(apply #'init-xview-panel-choice al s initargs)

	(realize-xview-item al s)))))


;;; For non-abbreviated exclusive settings do not set PANEL_CHOOSE_ONE
;;; to TRUE explicitly [let XView make it TRUE by default].  This avoids
;;; an OW2 XView bug [fixed in OW3].        /25-jul-91, alk

(defmethod dd-realize-item ((p XView) (s exclusive-setting))
  (realize-xview-panel-choice s))

(defmethod dd-realize-item ((p XView) (s abbreviated-exclusive-setting))
  (realize-xview-panel-choice s PANEL_CHOOSE_ONE TRUE PANEL_DISPLAY_LEVEL PANEL_CURRENT))

(defmethod dd-realize-item ((p XView) (s non-exclusive-setting))
  (realize-xview-panel-choice s PANEL_CHOOSE_ONE FALSE))

(defmethod dd-realize-item ((p XView) (s check-box))
  (realize-xview-panel-choice s PANEL_CHOOSE_ONE FALSE PANEL_FEEDBACK PANEL_MARKED))



(defmethod dd-setting-choices ((p XView) s)
  (xview-setting-choices (device s)))

(defmethod (setf dd-setting-choices) (new-choices (p XView) s)
  (XV:with-xview-lock 
    (let* ((xvo (device s))
	   (id (xview-object-id xvo))
	   (old-choices (xview-setting-choices xvo)))
      (prog1
	  (setf (xview-setting-choices xvo) new-choices)
	(when id
	  (using-resource (al xview-attr-list-resource (parent s) :panel-choice id)
	    (when (> (length old-choices) (length new-choices))
	      (push-xview-attrs al PANEL_CHOICE_STRINGS (malloc-foreign-string "") XV_NULL)
	      (flush-xview-attr-list al))

	    (push-xview-attrs al PANEL_DEFAULT_VALUE 
	      (solo-to-xview-setting-value s new-choices (xview-setting-default xvo)))

	    (let ((callback (choice-label-callback s))
		  (row -1))
	      (dolist (choice (xview-setting-choices xvo))
		(init-xview-panel-choice-choice al (incf row) callback choice)))

	    (xview-maybe-XFlush (xview-object-xvd xvo))))))))

    
(defmethod dd-setting-choices-nrows ((p XView) x)
  (get-xview-initarg-attr x PANEL_CHOICE_NROWS :choices-nrows))

(defmethod (setf dd-setting-choices-nrows) (value (p XView) x)
  (set-xview-initarg-attr value x PANEL_CHOICE_NROWS :choices-nrows))


(defmethod dd-setting-choices-ncols ((p XView) x)
  (get-xview-initarg-attr x PANEL_CHOICE_NCOLS :choices-ncols))

(defmethod (setf dd-setting-choices-ncols) (value (p XView) x)
  (set-xview-initarg-attr value x PANEL_CHOICE_NCOLS :choices-ncols))


(defmethod dd-setting-value ((p XView) x)
  (get-xview-initarg-attr x PANEL_VALUE :value 'integer
    #'(lambda (v) (xview-to-solo-setting-value x (xview-setting-choices (device x)) v))))

(defmethod (setf dd-setting-value) (value (p XView) x)
  (set-xview-initarg-attr value x PANEL_VALUE :value 'integer
    #'(lambda (v) (solo-to-xview-setting-value x (xview-setting-choices (device x)) v))))


(defmethod dd-setting-default ((p XView) x)
  (get-xview-initarg-attr x PANEL_DEFAULT_VALUE :default 'integer
    #'(lambda (v) (xview-to-solo-setting-value x (xview-setting-choices (device x)) v))))

(defmethod (setf dd-setting-default) (value (p XView) x)
  (set-xview-initarg-attr value x PANEL_DEFAULT_VALUE :default 'integer
    #'(lambda (v) (solo-to-xview-setting-value x (xview-setting-choices (device x)) v))))


(defmethod dd-setting-selection-required ((p XView) x)
  (xview-setting-selection-required (device x)))

(defmethod (setf dd-setting-selection-required) (value (p XView) x)
  (setf (xview-setting-selection-required (device x))
	(set-xview-attr value x PANEL_CHOOSE_NONE 'boolean #'not)))
    

(defmethod (setf dd-update-value) (value (p XView) (item setting))
  (xview-set-panel-notify-proc item value 'xview-setting-notify-proc))


(XV:defcallback xview-setting-notify-proc (xv-item xv-value xv-event)
  (declare (ignore xv-event))
  (let ((item (xview-id-to-object xv-item)))
    (when (typep item 'setting)
      (deliver-event item :update-value
        (make-update-value-event
	  :value (xview-to-solo-setting-value 
		  item (xview-setting-choices (device item)) xv-value))))))


;;; Text Field


(defmethod dd-initialize-item ((p XView) (x text-field) &rest initargs)
  (apply #'call-next-method p x
	 :make-xview-item #'make-xview-text-field
	 initargs))

(defun init-xview-panel-text (al x &key 
				     stored-value-length
				     displayed-value-length
				     value-underlined 
				     read-only
				     mask-char
				     value
				     min-value 
				     max-value
				     update-value
				   &allow-other-keys)
  (when stored-value-length 
    (push-xview-attrs al PANEL_VALUE_STORED_LENGTH stored-value-length))
  (when displayed-value-length 
    (push-xview-attrs al PANEL_VALUE_DISPLAY_LENGTH displayed-value-length))
  (unless value-underlined
    (push-xview-attrs al PANEL_VALUE_UNDERLINED FALSE))
  (when read-only 
    (push-xview-attrs al PANEL_READ_ONLY TRUE))
  (when mask-char 
    (push-xview-attrs al PANEL_MASK_CHAR (char-code mask-char)))
  (when value
    (if (typep x 'numeric-field)
	(push-xview-attrs al PANEL_VALUE (truncate value))
      (push-xview-attrs al PANEL_VALUE (malloc-foreign-string (string value)))))
  (when (typep x 'numeric-field)
    (when min-value 
      (push-xview-attrs al PANEL_MIN_VALUE min-value))
    (when max-value 
      (push-xview-attrs al PANEL_MAX_VALUE max-value)))
  (when update-value
    (push-xview-attrs al PANEL_NOTIFY_PROC (lookup-callback-address 'xview-text-notify-proc))))


(defmethod dd-realize-item ((p XView) (x text-field))
  (let* ((xvo (device x))
	 (initargs (prog1
		       (xview-item-initargs xvo)
		     (setf (xview-item-initargs xvo) nil)))
	 (package (if (typep x 'numeric-field) :panel-numeric-text :panel-text)))
      (using-resource (al xview-attr-list-resource (parent x) package)
	(apply #'init-xview-panel-item-bounding-region al initargs)
	(apply #'init-xview-panel-item al initargs)
	(apply #'init-xview-panel-item-label al x initargs)
	(apply #'init-xview-panel-text al x initargs)

	(realize-xview-item al x))))


(defmethod dd-text-field-value ((p XView) x)
  (get-xview-initarg-attr x PANEL_VALUE :value 'string))

(defmethod (setf dd-text-field-value) (value (p XView) x)
  (set-xview-initarg-attr value x PANEL_VALUE :value 'string))


(defmethod dd-numeric-field-value ((p XView) x)
  (get-xview-initarg-attr x PANEL_VALUE :value))

(defmethod (setf dd-numeric-field-value) (value (p XView) x)
  (set-xview-initarg-attr value x PANEL_VALUE :value))


(defmethod dd-text-field-stored-value-length ((p XView) x)
  (get-xview-initarg-attr x PANEL_VALUE_STORED_LENGTH :stored-value-length))

(defmethod (setf dd-text-field-stored-value-length) (value (p XView) x)
  (set-xview-initarg-attr value x PANEL_VALUE_STORED_LENGTH :stored-value-length))


(defmethod dd-text-field-displayed-value-length ((p XView) x)
  (get-xview-initarg-attr x PANEL_VALUE_DISPLAY_LENGTH :displayed-value-length))

(defmethod (setf dd-text-field-displayed-value-length) (value (p XView) x)
  (set-xview-initarg-attr value x PANEL_VALUE_DISPLAY_LENGTH :displayed-value-length))


(defmethod dd-text-field-value-underlined ((p XView) x)
  (xview-text-field-value-underlined (device x)))

(defmethod (setf dd-text-field-value-underlined) (value (p XView) x)
  (setf (xview-text-field-value-underlined (device x))
	(set-xview-attr value x PANEL_VALUE_UNDERLINED 'boolean)))


(defmethod dd-text-field-read-only ((p XView) x)
  (xview-text-field-read-only (device x)))

(defmethod (setf dd-text-field-read-only) (value (p XView) x)
  (setf (xview-text-field-read-only (device x))
	(set-xview-attr value x PANEL_READ_ONLY 'boolean)))


(defmethod dd-text-field-mask-char ((p XView) x)
  (xview-text-field-mask-char (device x)))

(defmethod (setf dd-text-field-mask-char) (value (p XView) x)
  (setf (xview-text-field-mask-char (device x))
	(set-xview-attr value x PANEL_MASK_CHAR 'integer
	  #'(lambda (v) (if (characterp v) (char-code v) 0)))))


(defmethod (setf dd-update-value) (value (p XView) (item text-field))
  (xview-set-panel-notify-proc item value 'xview-text-notify-proc))


(XV:defcallback (xview-text-notify-proc (:abort-value PANEL_NEXT))
		(xv-item xv-event)
  (declare (ignore xv-event))
  (let ((item (xview-id-to-object xv-item)))
    (when (typep item 'text-field)
      (deliver-event item :update-value
        (make-update-value-event 
	 :value (if (typep item 'numeric-field)
		    (xv_get xv-item PANEL_VALUE)
		  (foreign-string-value 
		   (make-foreign-pointer :type '(:pointer :character) 
					 :address (xv_get xv-item PANEL_VALUE))))))))
  PANEL_NEXT)


;;; Buttons

(defmethod dd-realize-item ((p XView) (b button))
  (let* ((xvo (device b))
	 (initargs (prog1
		       (xview-item-initargs xvo)
		     (setf (xview-item-initargs xvo) nil))))
    (using-resource (al xview-attr-list-resource (parent b) :panel-button)
      (apply #'init-xview-panel-item-bounding-region al initargs)
      (apply #'init-xview-panel-item al initargs)
      (apply #'init-xview-panel-item-label al b initargs)
      (if (typep b 'menu-button)
	  (let ((menu (getf initargs :menu)))
	    (push-xview-attrs al PANEL_ITEM_MENU 
	      (or (and menu (xview-object-id (device menu))) (XV:xv-create nil :menu))))
	(push-xview-attrs al PANEL_NOTIFY_PROC (lookup-callback-address 'xview-command-button-notify)))

      (realize-xview-item al b))))


(defmethod dd-button-state ((p XView) x)
  (get-xview-initarg-attr x PANEL_INACTIVE :state 'boolean
    #'(lambda (v) (if v :inactive :active))))

(defmethod (setf dd-button-state) (value (p XView) x)
  (set-xview-initarg-attr value x PANEL_INACTIVE :state 'boolean
    #'(lambda (v) (or (eq v :busy) (eq v :inactive)))))


(defmethod dd-menu-button-menu ((p XView) x)
  (get-xview-initarg-attr x PANEL_ITEM_MENU :menu 'integer
    #'(lambda (v) (xview-id-to-object v))))

(defmethod (setf dd-menu-button-menu) (value (p XView) x)
  (set-xview-initarg-attr value x PANEL_ITEM_MENU :menu))


(XV:defcallback xview-command-button-notify (xv-button (xv-event (:pointer XV:event)))
  (let ((button (xview-id-to-object xv-button)))
    (when (typep button 'command-button)
      (deliver-event button 
		     :button-pressed
		     (make-button-pressed-event
		       :x (XV:event-ie-locx xv-event)
		       :y (XV:event-ie-locy xv-event)
		       :%gesture (XV:event-ie-shiftmask xv-event)))
      ;; Check to see if the pushpin is in, if the pushpin is in, only then
      ;; make the call to xv_set. This preserves the default behaviour
      ;; where the popup is dismissed when a button is pressed in an 
      ;; unpinned popup window. The loop is required for nested panels.
      (let ((w (parent button)))
	(loop
	 (when (null w) (return nil))
	 (when (typep w 'popup-window)
	   (when (eq (xv_get (xview-object-id (device w)) FRAME_CMD_PUSHPIN_IN)
		     1)
	     (xv_set xv-button PANEL_NOTIFY_STATUS xv-error XV_NULL))
	   (return nil))
	 (setq w (parent w)))))))


;;; Scrolling List


(defmethod dd-initialize-item ((p XView) (sl scrolling-list) &rest initargs)
  (apply #'call-next-method p sl
	 :make-xview-item #'make-xview-scrolling-list
	 initargs))


(defun init-xview-panel-list-choice (al row choice-label-callback choice)
  (flet 
   ((init-choice (label)
      (etypecase label
        (string
	 (push-xview-attrs al PANEL_LIST_STRING row (malloc-foreign-string label)))
	(image
	 (let ((id (xview-object-id (device label))))
	   (when id
	     (push-xview-attrs al PANEL_LIST_GLYPH row id)))))))

   (multiple-value-bind (string image)
       (funcall choice-label-callback choice)
     (when string (init-choice string))
     (when image (init-choice image)))

   (push-xview-attrs al PANEL_LIST_CLIENT_DATA row row)))



(defun init-xview-panel-list (al sl &key 
				      font
				      value
				      choices
				      choice-width
				      choice-height
				      nchoices
				      nchoices-visible
				      read-only
				      selection-required
				    &allow-other-keys)

  (let ((font-id (if font (xview-object-id (device font)))))
    (when font-id
      (push-xview-attrs al PANEL_LIST_ROW_HEIGHT (xv_get font-id FONT_DEFAULT_CHAR_HEIGHT)))
    (when choice-width 
      (push-xview-attrs al PANEL_LIST_WIDTH choice-width))
    (when choice-height 
      (push-xview-attrs al PANEL_LIST_ROW_HEIGHT choice-height))
    (when nchoices
      (push-xview-attrs al PANEL_LIST_NROWS nchoices))
    (when nchoices-visible
      (push-xview-attrs al PANEL_LIST_DISPLAY_ROWS nchoices-visible))
    (when read-only
      (push-xview-attrs al PANEL_READ_ONLY TRUE))

    (push-xview-attrs al PANEL_NOTIFY_PROC (lookup-callback-address 'panel-list-notify-proc))

    (let ((row 0)
	  (callback (choice-label-callback sl)))
      (dolist (choice choices)
	(when font-id 
	  (push-xview-attrs al PANEL_LIST_FONT row font-id))
	(init-xview-panel-list-choice al row callback choice)
	(incf row)))

    (if (typep sl 'exclusive-scrolling-list)
	(progn
	  (push-xview-attrs al
	    PANEL_CHOOSE_ONE TRUE
	    PANEL_CHOOSE_NONE (if selection-required FALSE TRUE))
	  (when value
	    (push-xview-attrs al PANEL_LIST_SELECT (choice-position value choices) TRUE)))
      (progn
	(push-xview-attrs al PANEL_CHOOSE_ONE FALSE)
	(dolist (choice value)
	  (push-xview-attrs al PANEL_LIST_SELECT (choice-position choice choices) TRUE))))))



(defmethod dd-realize-item ((p XView) (sl scrolling-list))
  (XV:with-xview-lock 
    (let* ((xvo (device sl))
	   (initargs 
	    (prog1
		(xview-item-initargs xvo)
	      (setf (xview-item-initargs xvo) nil))))

      (using-resource (al xview-attr-list-resource (parent sl) :panel-list)
	(push-xview-attrs al XV_SHOW FALSE)
	(apply #'init-xview-panel-item-bounding-region al initargs)
	(apply #'init-xview-panel-item al initargs)
	(apply #'init-xview-panel-item-label al sl initargs)
	(apply #'init-xview-panel-list al sl initargs)

	(realize-xview-item al sl)))))


(defmethod dd-non-exclusive-scrolling-list-value ((p XView) sl)
  (XV:with-xview-lock
    (let* ((xvo (device sl))
	   (id (xview-object-id xvo))
	   (values nil)
	   (row 0))
      (if id
	  (dolist (choice (xview-scrolling-list-choices xvo) (nreverse values))
	    (when (/= FALSE (xv_get id PANEL_LIST_SELECTED row))
	      (push choice values))
	    (incf row))
	(getf (xview-item-initargs xvo) :value)))))



;;; This is extra complicated to make XView always leave the scrolling-list showing
;;; the first new choice.  To do this we update all of the choices and then toggle
;;; the first one to force XView to scroll if neccessary.

(defmethod (setf dd-non-exclusive-scrolling-list-value) (choices (p XView) sl)
  (XV:with-xview-lock
    (let* ((xvo (device sl))
	   (id (xview-object-id xvo))
	   (row 0)
	   (first-selected-row nil))
      (if id
	  (using-resource (al xview-attr-list-resource (parent sl) :panel-list id)
	    (dolist (choice (xview-scrolling-list-choices xvo))
	      (let ((new-value (find choice choices :test (if (stringp choice) #'equal #'eql)))
		    (old-value (/= FALSE (xv_get id PANEL_LIST_SELECTED row))))
		(when (and choices (eq choice (car choices)))
		  (setf first-selected-row row))
		(when (xor new-value old-value)
		  (push-xview-attrs al PANEL_LIST_SELECT row (if new-value TRUE FALSE)))
		(incf row)))
	    (when first-selected-row
	      (push-xview-attrs al 
		PANEL_LIST_SELECT first-selected-row FALSE
		PANEL_LIST_SELECT first-selected-row TRUE))
	    (flush-xview-attr-list al)
	    (xview-maybe-XFlush (xview-object-xvd xvo)))
	(setf (getf (xview-item-initargs xvo) :value) choices))))
  choices)



(defmethod dd-exclusive-scrolling-list-value ((p XView) sl)
  (XV:with-xview-lock
    (let* ((xvo (device sl))
	   (id (xview-object-id xvo))
	   (choices (xview-scrolling-list-choices xvo))
	   (row 0))
      (if id
	  (dolist (choice choices)
	    (when (/= FALSE (xv_get id PANEL_LIST_SELECTED row))
	      (return choice))
	    (incf row))
	(getf (xview-item-initargs xvo) :value)))))


(defmethod (setf dd-exclusive-scrolling-list-value) (value (p XView) sl)
  (XV:with-xview-lock
    (let* ((xvo (device sl))
	   (id (xview-object-id xvo)))
      (if id
	  (progn
	    (if (or value (xview-setting-selection-required xvo))
		(let ((row (choice-position value (xview-scrolling-list-choices xvo))))
		  (xv_set id PANEL_LIST_SELECT row TRUE XV_NULL))
	      (dotimes (row (xv_get id PANEL_LIST_NROWS))
		(when (/= 0 (xv_get id PANEL_LIST_SELECTED row))
		  (xv_set id PANEL_LIST_SELECT row FALSE XV_NULL)
		  (return))))
	    (xview-maybe-XFlush (xview-object-xvd xvo)))
	(setf (getf (xview-item-initargs xvo) :value) value))))
  value)



(defmethod dd-scrolling-list-choices ((p XView) sl)
  (xview-scrolling-list-choices (device sl)))


(defmethod (setf dd-scrolling-list-choices) (new-choices (p XView) sl)
  (XV:with-xview-lock 
    (let* ((xvo (device sl))
	   (id (xview-object-id xvo))
	   (old-choices (xview-scrolling-list-choices xvo))
	   (n-old-choices (length old-choices))
	   (n-new-choices (length new-choices)))
      (when id
	(using-resource (al xview-attr-list-resource (parent sl) :panel-list id)
	  (cond 
	   ((> n-new-choices n-old-choices)
	    (dotimes (i (- n-new-choices n-old-choices))
	      (push-xview-attrs al PANEL_LIST_INSERT (+ n-old-choices i))))
	   ((> n-old-choices n-new-choices)
	    (dotimes (i (- n-old-choices n-new-choices))
	      (push-xview-attrs al PANEL_LIST_DELETE (- n-old-choices i 1)))))

	  (let ((row 0)
		(callback (choice-label-callback sl)))
	    (dolist (choice new-choices)
	      (init-xview-panel-list-choice al row callback choice)
	      (incf row)))

	  (flush-xview-attr-list al)
	  (xview-maybe-XFlush (xview-object-xvd xvo))))

      (setf (xview-scrolling-list-choices xvo) new-choices))))


  
(defmethod dd-scrolling-list-choice-width ((p XView) x)
  (get-xview-initarg-attr x PANEL_LIST_WIDTH :choice-width))

(defmethod (setf dd-scrolling-list-choice-width) (value (p XView) x)
  (set-xview-initarg-attr value x PANEL_LIST_WIDTH :choice-width))


(defmethod dd-scrolling-list-choice-height ((p XView) x)
  (get-xview-initarg-attr x PANEL_LIST_ROW_HEIGHT :choice-height))

(defmethod (setf dd-scrolling-list-choice-height) (value (p XView) x)
  (set-xview-initarg-attr value x PANEL_LIST_ROW_HEIGHT :choice-height))


(defmethod dd-scrolling-list-nchoices ((p XView) x)
  (get-xview-initarg-attr x PANEL_LIST_NROWS :nchoices))

(defmethod (setf dd-scrolling-list-nchoices) (value (p XView) x)
  (set-xview-initarg-attr value x PANEL_LIST_NROWS :nchoices))


(defmethod dd-scrolling-list-nchoices-visible ((p XView) x)
  (get-xview-initarg-attr x PANEL_LIST_DISPLAY_ROWS :nchoices-visible))

(defmethod (setf dd-scrolling-list-nchoices-visible) (value (p XView) x)
  (set-xview-initarg-attr value x PANEL_LIST_DISPLAY_ROWS :nchoices-visible))


(defmethod dd-exclusive-scrolling-list-selection-required ((p XView) x)
  (xview-scrolling-list-selection-required (device x)))

(defmethod (setf dd-exclusive-scrolling-list-selection-required) (value (p XView) x)
  (setf (xview-scrolling-list-selection-required (device x))
	(set-xview-attr value x PANEL_CHOOSE_NONE 'boolean #'not)))


(defmethod dd-scrolling-list-read-only ((p XView) x)
  (xview-scrolling-list-read-only (device x)))

(defmethod (setf dd-scrolling-list-read-only) (value (p XView) x)
  (setf (xview-scrolling-list-read-only (device x))
	(set-xview-attr value x PANEL_READ_ONLY 'boolean)))


(defmethod (setf dd-update-value) (value (p XView) (item scrolling-list)) value)


(defun delete-xview-panel-list-choice (sl row)
  (let* ((xvo (device sl))
	 (id (xview-object-id (device sl))))
    (XV:with-xview-lock 
      (let ((choices (xview-scrolling-list-choices xvo)))
	(setf (xview-scrolling-list-choices xvo)
	      (if (= 0 row)
		  (cdr choices)
		(let ((x (nthcdr (1- row) choices)))
		  (when (cdr x) (setf (cdr x) (cddr x)))
		  choices)))

	(using-resource (al xview-attr-list-resource (parent sl) :panel-list id)
	  (dotimes (i (- (length choices) row 1))
	    (push-xview-attrs al PANEL_LIST_CLIENT_DATA (+ row i 1) (+ row i)))
	  (flush-xview-attr-list al))))))


(defun insert-xview-panel-list-choice (sl row xv-string-addr)
  (let* ((xvo (device sl))
	 (id (xview-object-id (device sl))))
    (XV:with-xview-lock 
      (let ((choices (copy-list (xview-scrolling-list-choices xvo)))
	    (choice 
	     (funcall (validate-choice-callback sl) 
		      sl
		      row
		      (foreign-string-value
		       (make-foreign-pointer :type '(:pointer :character)
					     :address xv-string-addr)))))

	(if (null choice)
	    (return-from insert-xview-panel-list-choice choice)
	  (progn
	   (setf (xview-scrolling-list-choices xvo)
		 (if (= row 0)
		     (cons choice choices)
		   (let ((ip (nthcdr (1- row) choices)))
		     (if ip
			 (progn (push choice (cdr ip)) choices)))))

	   (using-resource (al xview-attr-list-resource (parent sl) :panel-list id)
	     (dotimes (i (- (1+ (length choices)) row))
	       (push-xview-attrs al PANEL_LIST_CLIENT_DATA (+ row i) (+ row i)))
	     (flush-xview-attr-list al))

	   choice))))))

;;;; Original code
#+ignore
(XV:defcallback (panel-list-notify-proc (:abort-value XV:xv-ok))
		(xv-item xv-string-addr xv-client-data xv-op xv-event-addr)
  (declare (ignore xv-string-addr xv-event-addr))
  (let ((op (XV:enum-case xv-op
	      (:panel-list-op-deselect :deselect)
	      (:panel-list-op-select :select)
	      (:panel-list-op-validate :insert)
	      (:panel-list-op-delete :delete)))
	(sl (xview-id-to-object xv-item)))
    (let* ((choices (xview-scrolling-list-choices (device sl)))
	   (choice (nth xv-client-data choices)))
      (when (typep sl 'scrolling-list)
	(case op
	  (:delete
	   (delete-xview-panel-list-choice sl xv-client-data))
	  (:insert
	   (setf choice
		 (insert-xview-panel-list-choice sl xv-client-data xv-string-addr))))
	(when (and choice (update-value sl))
	  (deliver-event sl
			 :update-scrolling-list-value
			 (make-update-value-event :value choice :op op)))
	(if choice XV:xv-ok XV:xv-error)))))

(XV:defcallback (panel-list-notify-proc (:abort-value XV:xv-ok))
		(xv-item xv-string-addr xv-client-data xv-op xv-event-addr)
  (declare (ignore xv-string-addr xv-event-addr))
  (let ((op (XV:enum-case xv-op
	      (:panel-list-op-deselect :deselect)
	      (:panel-list-op-select :select)
	      (:panel-list-op-validate :insert)
	      (:panel-list-op-delete :delete)))
	(sl (xview-id-to-object xv-item)))
    (let ((choices (xview-scrolling-list-choices (device sl))))
      (if (< -1 xv-client-data (length choices))
	  (let ((choice (nth xv-client-data choices)))
	    (when (typep sl 'scrolling-list)
	      (case op
		(:delete
		 (delete-xview-panel-list-choice sl xv-client-data))
		(:insert
		 (setf choice
		       (insert-xview-panel-list-choice sl xv-client-data xv-string-addr))))
	      (when (and choice (update-value sl))
		(deliver-event sl
			       :update-scrolling-list-value
			       (make-update-value-event :value choice :op op)))
	      (if choice XV:xv-ok XV:xv-error)))
	  XV:xv-ok))))


(defmethod dd-item-spot-help ((p XView) x)
  (XV:with-xview-lock
    (let* ((xvo (device x))
	   (id (xview-object-id xvo)))
      (if id
	  (let ((addr (xv_get id XV_KEY_DATA XV_HELP)))
	    (foreign-string-value
	      (make-foreign-pointer :type '(:pointer :character) :address addr)))
	(getf (xview-item-initargs xvo) :spot-help)))))


(defmethod (setf dd-item-spot-help) (value (p XView) x)
  (XV:with-xview-lock
    (let* ((xvo (device x))
	   (id (xview-object-id xvo)))
      (if id
	  (let ((fp (malloc-foreign-string value)))
	    (xv_set id XV_KEY_DATA XV_HELP (foreign-pointer-address fp) XV_NULL)
	    (xview-maybe-XFlush (xview-object-xvd xvo)))
	(setf (getf (xview-item-initargs xvo) :spot-help) value))))
  value)


