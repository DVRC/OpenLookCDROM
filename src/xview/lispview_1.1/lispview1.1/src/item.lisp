;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)item.lisp	3.7 10/11/91

;;; Solo User Interface Components: 
;;;    Basics 
;;;      item, label, command, numeric-range
;;;    Real Components
;;;      message, slider, exclusive-setting, non-exclusive-setting, 
;;;      abbreviated-exclusive-setting, text-field, numeric-field,
;;;      command-button, menu-button, non-exclusive-scrolling-list, 
;;;      exclusive-scrolling-list


(in-package "LISPVIEW")


;;; Items

(defmethod initialize-instance :after ((x item) 
				       &rest initargs
				       &key 
				         parent
					 foreground
					 background
					 state
					 layout
				       &allow-other-keys)
  (declare (dynamic-extent initargs))

  (apply #'dd-initialize-item (platform x) x initargs)

  (check-arglist (parent panel)
		 (foreground (or null color))
		 (background (or null color))
		 (state item-state)
		 (layout item-layout))
  (when parent
    (insert x :at 0 parent)))


(defmethod initialize-instance :around ((i item) &key status &allow-other-keys)
  (prog1
      (call-next-method)
    (when (eq status :realized)
      (setf (status i) :realized))))


(defmethod (setf status) ((value (eql :realized)) (x item))
  (when (eq (status x) :initialized)
    (dd-realize-item (platform x) x))
  (setf (slot-value x 'status) :realized))


(defmethod (setf status) ((value (eql :destroyed)) (i item))
  (when (eq (status i) :realized)
    (withdraw i (parent i))
    (dd-destroy-item (platform i) i))
  (setf (slot-value i 'status) :destroyed))


(defmethod event-dispatch-queue ((i item))
  (let ((parent (parent i)))
    (if parent 
	(event-dispatch-queue parent)
      (event-dispatch-queue (root-canvas (display i))))))


(defmethod children ((i item)) nil)

(defmethod insert (node where sibling (parent item))
  (declare (ignore node where sibling))
  (error "Objects of type ~S can't have children" (type-of parent)))


(defmethod insert ((x item) where sibling new-parent)
  (check-arglist (sibling (or null positive-fixnum item))
		 (new-parent panel))
  (dd-insert-item (platform x) x where sibling new-parent)
  (call-next-method))


(defmethod withdraw ((i item) parent)
  (declare (ignore parent))
  (let ((parent (parent i)))
    (when parent
      (prog1
	  (call-next-method)
	(dd-withdraw-item (platform i) i parent)))))


(def-solo-accessor BOUNDING-REGION item
  :type region
  :driver dd-item-bounding-region)

(def-solo-accessor FOREGROUND item
  :driver dd-item-foreground)

(def-solo-accessor BACKGROUND item
  :driver dd-item-background)

(def-solo-accessor MAPPED item
  :driver dd-item-mapped)

(def-solo-accessor STATE item :type item-state
  :driver dd-item-state)

(def-solo-accessor LAYOUT item :type item-layout
  :driver dd-item-layout)

(defmethod (SETF LABEL) (value (x item))
  (check-type value item-label)
  (setf (dd-item-label (platform x) x) value
	(slot-value x 'label) value))
  
(defmethod label (x) (princ-to-string x))

(defmethod label ((x image)) x)

(defmethod label ((x string)) x)


(def-solo-accessor LABEL-WIDTH item
  :type fixnum
  :driver dd-item-label-width)


(def-solo-accessor KEYBOARD-FOCUS panel
  :type (or null item)
  :driver dd-panel-keyboard-focus)


;;; Numeric-Range


(def-solo-reader value numeric-range :type integer
  :driver dd-numeric-range-value)


(defmethod (setf value) (value (n numeric-range))
  (assert (and (integerp value)
 	       (<= value (max-value n))
	       (>= value (min-value n)))
	  (value)
	  "~A value must within range: ~D - ~D" 
	  (type-of n)
	  (min-value n)
	  (max-value n))
  (setf (dd-numeric-range-value (platform n) n) value))


(def-solo-accessor min-value numeric-range :type integer
  :driver dd-numeric-range-min-value)

(def-solo-accessor max-value numeric-range :type integer
  :driver dd-numeric-range-max-value)


;;; Update-Value

(defmethod (setf update-value) (value (i item))
  (setf (dd-update-value (platform i) i) value
	(slot-value i 'update-value) value))


(defmethod receive-event (item interest (event update-value-event))
  (declare (ignore interest))
  (let ((fn (update-value item)))
    (when (functionp fn)
      (funcall fn (update-value-event-value event)))))


;;; Gauge


(def-solo-accessor SHOW-RANGE gauge
  :driver dd-show-range)

(def-solo-accessor SHOW-VALUE gauge
  :driver dd-show-value)

(def-solo-accessor NTICKS gauge :type (integer 0 *)
  :driver dd-nticks)

(def-solo-accessor GAUGE-LENGTH gauge :type (integer 0 *)
  :driver dd-gauge-length)


;;; Slider

(def-solo-accessor SHOW-END-BOXES slider
  :driver dd-show-end-boxes)


;;; Setting

(def-solo-accessor VALUE setting 
  :driver dd-setting-value)

(def-solo-accessor CHOICES setting :type list
  :driver dd-setting-choices)

(def-solo-accessor CHOICES-NROWS setting :type fixnum
  :driver dd-setting-choices-nrows)

(def-solo-accessor CHOICES-NCOLS setting :type fixnum
  :driver dd-setting-choices-ncols)

(def-solo-accessor SELECTION-REQUIRED setting
  :driver dd-setting-selection-required)

(def-solo-accessor DEFAULT setting
  :driver dd-setting-default)


;;; Text-Field, Numeric-Field

(def-solo-accessor VALUE text-field
  :driver dd-text-field-value)

(def-solo-accessor VALUE numeric-field
  :driver dd-numeric-field-value)

(def-solo-accessor STORED-VALUE-LENGTH text-field
  :driver dd-text-field-stored-value-length)

(def-solo-accessor DISPLAYED-VALUE-LENGTH text-field
  :driver dd-text-field-displayed-value-length)

(def-solo-accessor VALUE-UNDERLINED text-field
  :driver dd-text-field-value-underlined)

(def-solo-accessor READ-ONLY text-field
  :driver dd-text-field-read-only)

(def-solo-accessor MASK-CHAR text-field
  :driver dd-text-field-mask-char)



;;; Buttons

(def-solo-accessor STATE button :type button-state
  :driver dd-button-state)

(def-solo-accessor MENU menu-button :type (or null menu)
  :driver dd-menu-button-menu)


(defmethod receive-event (button interest (event button-pressed-event))
  (declare (ignore interest))
  (let ((command (if (slot-boundp button 'command) (slot-value button 'command))))
    (when (and command (functionp command))
      (unwind-protect
	  (progn
	    (setf (state button) :busy)
	    (funcall command))
	(setf (state button) :active)))))



;;; Scrolling Lists


(def-solo-accessor CHOICES scrolling-list :type list
  :driver dd-scrolling-list-choices)

(def-solo-accessor CHOICE-WIDTH scrolling-list :type fixnum
  :driver dd-scrolling-list-choice-width)

(def-solo-accessor CHOICE-HEIGHT scrolling-list :type fixnum
  :driver dd-scrolling-list-choice-height)

(def-solo-accessor NCHOICES scrolling-list :type fixnum
  :driver dd-scrolling-list-nchoices)

(def-solo-accessor NCHOICES-VISIBLE scrolling-list :type fixnum
  :driver dd-scrolling-list-nchoices-visible)

(def-solo-accessor SELECTION-REQUIRED exclusive-scrolling-list 
  :driver dd-exclusive-scrolling-list-selection-required)

(def-solo-accessor VALUE exclusive-scrolling-list 
  :driver dd-exclusive-scrolling-list-value)

(def-solo-accessor VALUE non-exclusive-scrolling-list :type list
  :driver dd-non-exclusive-scrolling-list-value)

(def-solo-accessor READ-ONLY scrolling-list
  :driver dd-scrolling-list-read-only)

(defmethod receive-event ((item scrolling-list) interest  (event update-value-event))
  (declare (ignore interest))
  (let ((fn (update-value item)))
    (when (functionp fn)
      (funcall fn (update-value-event-value event) (update-value-event-op event)))))




