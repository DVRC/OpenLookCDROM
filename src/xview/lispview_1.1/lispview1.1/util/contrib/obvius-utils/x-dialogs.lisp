;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  File: x-dialogs.lisp
;;;  Authors: Eero Simoncelli
;;;  Description: Automatically generated dialog boxes.
;;;  Creation Date: Fall, 1990
;;;  ----------------------------------------------------------------
;;;    Object-Based Vision and Image Understanding System (OBVIUS),
;;;      Copyright 1988, Vision Science Group,  Media Laboratory,  
;;;              Massachusetts Institute of Technology.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package 'obvius)

(export '(make-global-parameter-dialog make-slot-value-dialog
	  make-slot-default-dialog))

;;; NOTE: this file relies on code in the file clos-extensions.lisp

;;; This file contains code for generating dialog boxes for adjusting
;;; parameter values.  We define three types of dialog box: one for
;;; setting global variable values, one for setting slot values of a
;;; CLOS object, and one for setting default values for the slots of a
;;; CLOS class.  The file also contains code for popping up
;;; documentation strings for the widgets, although this doesn't work
;;; reliably (sometimes LispView ignores mouse clicks in widgets).
;;; You can get it to work by clicking the mouse on a blank area of
;;; the dialog box and then doing a Meta-click on the item of
;;; interest!

;;; We define a set of special-purpose widgets.  Each widget is
;;; associated with either a global parameter, the slot of an existing
;;; CLOS object, or the default value of a slot of a CLOS class.  Each
;;; widget has methods to read and write the value of its associated
;;; object, as well as methods to get the type and documentation for
;;; that object.  Each widget also has methods to read and write its
;;; own value.  The methods are as follows:

;;; get-widget-value - return current value of widget.  Second value is non-nil
;;;                    if an error is encountered.  This is usually just the
;;;                    lispview:value, but note that text items call read-from-string.
;;; set-widget-value - Set the value of the widget.  Again, text-widgets are more
;;;                    complicated.
;;; get-object-value - Return current value of object.
;;; get-object-type  - Get typespec for object value (t if no typespec can be determined).
;;; get-object-documentation 
;;; set-object-value 

;;; In addition, a convert method can be written to convert from the
;;; widget value to a value which is displayable by the widget.

;;; To be fixed:
;;; 1) Object dialogs should allow editing of any initarg (even if it
;;; doesn't correspond to a slot).
;;; 2) Object dialogs should call reinitialize-instance instead of
;;; setting slot-values.
;;; 3) Update-function and exit-function should be methods on dialog.
;;; 3) MANY MAGIC NUMBERS!!  Would be nice to come up with an
;;; aesthetically appropriate layout of widgets (e.g. vertically align
;;; the right side of the labels, and properly auto-size the dialog
;;; box), but this is hard in LispView.

#|
;;; If an error occurs while creating a dialog, destroy it:
(let ((dlg (car (lv:children (lv:root-canvas lv:*default-display*)))))
  (when (and dlg (y-or-n-p "Destroy: ~A " dlg))
    (setf (lv:status dlg) :destroyed)))
|#

(def-simple-class dialog (lispview:base-window)
  (widgets))

;;; Set all widget values from their corresponding objects.
(defmethod revert-widget-values ((dialog dialog))
  (dolist (widget (widgets dialog))
    (set-widget-value widget (get-object-value widget)))
  dialog)

;;; This class is never instantiated.
(def-simple-class widget () ())

;;; Update-value is called when the user hits return or tab.  Having
;;; it do (set-widget-value widget (get-widget-value widget string))
;;; will cause the entered widget value to be type-checked, notifying
;;; the user of errors with a pop-up error notice.
(defmethod initialize-instance :around ((widget widget) &rest initargs)
  (unless (getf initargs :update-value)
    (setf (getf initargs :update-value)
	  #'(lambda (string)
	      (set-widget-value widget (get-widget-value widget string)))))
  (apply #'call-next-method widget initargs)
  widget)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; GLOBAL-VARIABLE DIALOG BOXES

;;; Make a dialog box for editing values of global variables.  The
;;; parameters argument should be a list of symbols with global
;;; bindings.  Variable types are used to automatically create
;;; specific types of widget (e.t. numeric, exclusive-settings, etc).
;;; Types can be specified for these variables by putting a :type
;;; field on the symbol-plist of the global symbol, although nothing
;;; will break if this is missing.  Variable documentation is provided
;;; to the user via Meta-left mouse clicks (see above).
;;; Update-function is called when the user clicks the "Apply" button.
;;; It will be called with two args: the list of parameter widgets and
;;; the update-arguments.  It should set the global variable values,
;;; returning nil if there are no problems or t if an error is
;;; encountered.  This dialog uses the global-variable widgets defined
;;; below.
(defun make-global-parameter-dialog
    (parameters &key (label "Global Parameters")
		(update-function 'standard-update-function)
		(update-arguments nil)
		(exit-function 'destroying-exit-function))
  (let* ((width 400) (all-button-width 176) ;*** MAGIC NUMBERS!
	 (widget-height 31) (pad 6)
	 (height (+ (* (1+ (list-length parameters)) widget-height) pad pad))
	 parameter-fields panel dialog)
    (setq dialog (make-instance 'dialog
				:mapped nil
				:label label
				:height height :width width :top 0 :left 0))
    (setq panel (make-instance 'helpful-panel :parent dialog))
    (setq parameter-fields
	  (loop for top from pad by widget-height
		for param in parameters
		collect
		(make-global-variable-widget param :parent panel :top top :left pad)))
    (make-instance 'lispview:command-button :parent panel
		   :left (round (- width all-button-width) 2)
		   :label "Apply" :top (- height widget-height)
		   :command
		   #'(lambda ()
		       (apply update-function parameter-fields update-arguments)))
    (make-instance 'lispview:command-button :parent panel
		   :label "Revert" :top (- height widget-height)
		   :command #'(lambda () (revert-widget-values dialog)))
    (make-instance 'lispview:command-button :parent panel
		   :label "Exit" :top (- height widget-height)
		   :command #'(lambda () (funcall exit-function dialog)))
    (setf (slot-value dialog 'widgets) parameter-fields)
    (revert-widget-values dialog)	;initialize values
    (setf (lispview::mapped dialog) t)
    dialog))

;;; This class not meant for instantiation.  It should be mixed in
;;; with the various lispview item classes: text-field, numeric-field,
;;; exlusive-setting, check-box, etc.
(def-simple-class global-variable-widget (widget)
  ((global-variable :type symbol :documentation "Symbol name of the global variable")))

(defmethod initialize-instance :around ((widget global-variable-widget) &rest initargs)
  (let ((the-variable (getf initargs :global-variable)))
    (unless (and the-variable (symbolp the-variable) (boundp the-variable))
      (error "Must provide a :global-variable argument which is a globally bound symbol."))
    (unless (getf initargs :label)
      (setf (getf initargs :label) (string-downcase (string the-variable))))
    (apply #'call-next-method widget initargs)))

;;; Initargs are passed on to the initialize-instance for the lispview
;;; item.  This should probably be made more flexible: it should check
;;; the symbol-plist for a :widget-type entry to override the
;;; automatic one chosen by compute-item-type-and-initargs.
(defun make-global-variable-widget (param &rest initargs)
  (unless (and param (symbolp param) (boundp param))
    (error "Argument must be a symbol with a value binding: ~A" param))
  (multiple-value-bind (widget-subtype specialized-initargs)
	(compute-item-type-and-initargs (get param :type t))
    (let* ((class (intern (concatenate 'string "GLOBAL-VARIABLE-"
				       (symbol-name widget-subtype)) 'obvius)))
      (unless (find-class class nil)	;no error
	(warn "There is no class named: ~A" class)
	(setq class 'global-variable-text-field))
      (apply 'make-instance class :global-variable param
	     (append initargs specialized-initargs)))))

(defmethod get-object-type ((widget global-variable-widget))
  (get (global-variable widget) :type t))

(defmethod get-object-documentation ((widget global-variable-widget))
  (documentation (global-variable widget) 'variable))

;;; Retrieve the current value of the object associated with the
;;; widget.  This will be called to get an initial value.
(defmethod get-object-value ((widget global-variable-widget))
  (symbol-value (global-variable widget)))

;;; Set the value of the object.  This is used when the user clicks
;;; "apply".
(defmethod set-object-value ((widget global-variable-widget) value)
  (setf (symbol-value (global-variable widget)) value))

;;; Get the value of the widget.  Convert the internal widget value
;;; (lispview:value widget) into a value suitable for storing in the
;;; object, checking the type for consistency.  Optional arg allows us
;;; to compute this transformation on an arbitrary lispview:value (this
;;; is used by the update-value function).  If there is an error
;;; getting the value, pop up an error message to tell the user, and
;;; return current value of object. 
(defmethod get-widget-value 
    ((widget global-variable-widget) &optional (lispview-value (lispview:value widget)))
  (multiple-value-bind (val errorp)
      (call-next-method)
    (handler-case
	(values (convert val (get-object-type widget)) errorp)
      (condition (error-condition)	;if coerce error, give error message.
	(widget-notice
	 widget
	 (format nil "~A is a bad value for ~A:~%~%~A"
		 lispview-value (global-variable widget) error-condition))
	(values (get-object-value widget) :coerce-error)))))

;;; Subclasses:
(defclass global-variable-text-field
    (global-variable-widget lispview:text-field) ())
(defclass global-variable-numeric-field
    (global-variable-widget lispview:numeric-field) ())
(defclass global-variable-exclusive-setting
    (global-variable-widget lispview:exclusive-setting) ())
;(defclass global-variable-exclusive-scrolling-list
;    (global-variable-widget lispview:exclusive-scrolling-list) ())
(defclass global-variable-check-box
    (global-variable-widget lispview:check-box) ())
(defclass global-variable-horizontal-slider
    (global-variable-widget lispview:horizontal-slider) ())

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; CLOS OBJECT SLOT VALUE DIALOGS

(def-simple-class slot-value-dialog (dialog)
  (object))

;;; Make a dialog box to edit some slots of a CLOS object.  Slot-names
;;; defaults to the list of all slots of the object.  Slot types are
;;; used to automatically create specific types of widget (e.t.
;;; numeric, exclusive-settings, etc).  Slot documentation is provided
;;; to the user via Meta-left mouse clicks (see above).
;;; Update-function is called when the user clicks the "Apply" button.
;;; It will be called with two args: the list of slot widgets and the
;;; update-arguments.  It should set the slot values, returning nil if
;;; there are no problems or t if an error is encountered.  This
;;; dialog uses the slot widgets defined below.
(defmethod make-slot-value-dialog ((object t) &key
				   (slot-names (visible-slot-names (class-of object)))
				   (label (format nil "slot value dialog"))
				   (update-function 'standard-update-function)
				   (update-arguments nil)
				   (exit-function 'destroying-exit-function))
  (unless (null slot-names)
    (let* ((width 300) (all-button-width 246) ;MAGIC NUMBERS
	   (widget-height 31) (pad 6)
	   (height (+ (* (+ 2 (length slot-names)) widget-height) pad pad pad))
	   panel slot-fields dialog)
      (setq dialog (make-instance 'slot-value-dialog
				  :object object :label label :mapped nil
				  :height height :width width :top 0 :left 0))
      (setq panel (make-instance 'helpful-panel :parent dialog))
      (make-instance 'lispview:message :parent panel :top pad :left pad
		     :label (format nil "Slots of ~S: " object))
      (setq slot-fields
	    (loop for top from (+ widget-height pad pad) by widget-height
		  for the-name in slot-names
		  collect
		  (make-slot-value-widget object the-name :parent panel
					  :top top :left pad)))
      (make-instance 'lispview:command-button :parent panel
		     :left (round (- width all-button-width) 2)
		     :label "Apply" :top (- height widget-height)
		     :command
		     #'(lambda ()
			 (funcall update-function slot-fields update-arguments)))
      (make-instance 'lispview:command-button :parent panel
		     :label "Revert" :top (- height widget-height)
		     :command #'(lambda () (revert-widget-values dialog)))
      (make-instance 'lispview:command-button :parent panel
		     :label "Defaults"  :top (- height widget-height)
		     :command
		     #'(lambda ()
			 (mapcar #'(lambda (widget)
				     (set-widget-value
				      widget
				      (eval (get-default (class-of (object widget))
							 (slot-name widget)))))
				 slot-fields)))
      (make-instance 'lispview:command-button :parent panel
		     :label "Exit"  :top (- height widget-height)
		     :command #'(lambda () (funcall exit-function dialog)))
      (setf (slot-value dialog 'widgets) slot-fields)
      (revert-widget-values dialog)	;initialize values
      (setf (lispview::mapped dialog) t)
      dialog)))

(def-simple-class slot-value-widget (widget)
  (object
   (slot-name :type symbol)))

(defmethod initialize-instance :around ((widget slot-value-widget) &rest initargs)
  (let ((slot-name (getf initargs :slot-name))
	(the-instance (getf initargs :object)))
    (unless (and slot-name the-instance
		 (symbolp slot-name)  
		 (find-slot (class-of the-instance) slot-name))
      (error "Bad instance (~S) or slot-name (~S)." the-instance slot-name))
    (unless (getf initargs :label)
      (setf (getf initargs :label) (string-downcase (string slot-name))))
    (apply #'call-next-method widget initargs)))

(defun make-slot-value-widget (object slot-name &rest initargs)
  (let* ((slot (find-slot (class-of object) slot-name t))
	 (type (if slot (CLOS::slot-definition-type slot) t)))
    (unless slot
      (error "~A is not a valid slot-name for ~A" slot-name object))
    (multiple-value-bind (widget-subtype specialized-initargs)
	(compute-item-type-and-initargs type)
      (let* ((widget-class (intern (concatenate 'string "SLOT-"
						(symbol-name widget-subtype)) 'obvius)))
	(unless (find-class widget-class nil)	;no error
	  (warn "There is no class named: ~A" widget-class)
	  (setq widget-class 'slot-text-field))
	(apply 'make-instance widget-class
	       :object object :slot-name slot-name
	       (append initargs specialized-initargs))))))

(defmethod get-object-type ((widget slot-value-widget))
  (let ((slot (find-slot (class-of (object widget)) (slot-name widget) t)))
    (if slot (CLOS::slot-definition-type slot) t)))

(defmethod get-object-documentation ((widget slot-value-widget))
  (let ((slot (find-slot (class-of (object widget)) (slot-name widget) t)))
    (when slot (documentation slot))))

;;; *** SHould use slot reader here.
(defmethod get-object-value ((widget slot-value-widget))
  (CLOS:slot-value (object widget) (slot-name widget)))

;;; Set the value of the object. *** SHould use slot writer.
(defmethod set-object-value ((widget slot-value-widget) value)
  (setf (slot-value (object widget) (slot-name widget)) value))

(defmethod get-widget-value
     ((widget slot-value-widget) &optional (lispview-value (lispview:value widget)))
  (multiple-value-bind (val errorp) (call-next-method)
    (handler-case
	(values (convert val (get-object-type widget)) errorp)
      (condition (error-condition)	;if error, give error message.
		 (widget-notice
		  widget
		  (format nil "~A is a bad value for slot ~A:~%~%~A"
			  lispview-value (slot-name widget) error-condition))
		 (values (get-object-value widget) :coerce-error)))))

;;; Sub-classes that are instantiated:
(defclass slot-text-field (slot-value-widget lispview:text-field) ())
(defclass slot-numeric-field (slot-value-widget lispview:numeric-field) ())
(defclass slot-exclusive-setting (slot-value-widget lispview:exclusive-setting) ())
;(defclass slot-exclusive-scrolling-list
;    (slot-value-widget lispview:exclusive-scrolling-list) ())
(defclass slot-horizontal-slider (slot-value-widget lispview:horizontal-slider) ())

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; CLOS CLASS SLOT DEFAULT DIALOGS  (initforms/default-initargs)

;;; Make a dialog box to edit the DEFAULT slot values for an object
;;; class.  This relies on the CLOS extension code in
;;; clos-extensions.lisp.
(defun make-slot-default-dialog
    (class-name &key
		(slot-names (visible-slot-names (find-class class-name)))
		(label "slot default dialog")
		(update-function 'standard-update-function)
		(update-arguments nil)
		(exit-function 'destroying-exit-function))
  (unless (null slot-names)
    (let* ((slot-plist (get-defaults class-name :print nil
				     :slot-names-or-initargs slot-names))
	   (width 300) (widget-height 31)
	   (all-button-width 176) (pad 6)
	   (height (+ (* (+ 2 (/ (length slot-plist) 2)) widget-height) pad pad pad))
	   panel slot-fields dialog)
      (setq dialog (make-instance 'dialog :label label :mapped nil
				  :height height :width width))
      (setq panel (make-instance 'helpful-panel :parent dialog))
      (make-instance 'lispview:message :parent panel :top pad :left pad
		     :label (format nil "Defaults for slots of class ~S: " class-name))
      (setq slot-fields
	    (loop for top from (+ widget-height pad pad) by widget-height
		  for item in slot-plist by #'cddr
		  collect
		  (make-slot-default-widget class-name item :parent panel
					    :top top :left pad)))
      (make-instance 'lispview:command-button :parent panel
		     :left (round (- width all-button-width) 2)
		     :label "Apply" :top (- height widget-height)
		     :command
		     #'(lambda () (funcall update-function slot-fields update-arguments)))
      (make-instance 'lispview:command-button :parent panel
		     :label "Revert" :top (- height widget-height)
		     :command #'(lambda () (revert-widget-values dialog)))
      (make-instance 'lispview:command-button :parent panel
		     :label "Exit" :top (- height widget-height)
		     :command #'(lambda () (funcall exit-function dialog)))
      (setf (slot-value dialog 'widgets) slot-fields)
      (revert-widget-values dialog)	;initialize values
      (setf (lispview::mapped dialog) t)
      dialog)))

(def-simple-class slot-default-widget (widget)
  ((class-name :type symbol)
   (slot-name :type symbol)))

(defmethod initialize-instance :around ((widget slot-default-widget) &rest initargs)
  (let ((slot-name (getf initargs :slot-name))
	(class-name (getf initargs :class-name)))
    (unless (and slot-name class-name (symbolp slot-name))
      (error "Bad class-name (~S) or slot-name (~S)." class-name slot-name))
    (get-default (find-class class-name) slot-name) ;check for legal slot
    (unless (getf initargs :label)
      (setf (getf initargs :label) (string-downcase (string slot-name))))
    (apply #'call-next-method widget initargs)))

(defun make-slot-default-widget (class-name slot-name-or-initarg &rest initargs)
  (let* ((class (find-class class-name))
	 (slot (find-slot class slot-name-or-initarg t))
	 (default-initarg (find-default-initarg slot-name-or-initarg
						(CLOS::class-default-initargs class)
						slot))
	 (type (if slot (CLOS::slot-definition-type slot) t)))
    (unless (or slot default-initarg)
      (error "~A is not a valid slot-name or initarg for class ~A"
	     slot-name-or-initarg class-name))
    (multiple-value-bind (widget-subtype specialized-initargs)
	(compute-item-type-and-initargs type)
      (let* ((widget-class (intern (concatenate 'string "SLOT-DEFAULT-"
						(symbol-name widget-subtype)) 'obvius)))
	(unless (find-class widget-class nil)	;no error
	  (warn "There is no class named: ~A" widget-class)
	  (setq widget-class 'slot-default-text-field))
	(apply 'make-instance widget-class
	       :class-name class-name :slot-name slot-name-or-initarg
	       (append initargs specialized-initargs))))))

(defmethod get-object-type ((widget slot-default-widget))
  (let ((slot (find-slot (find-class (class-name widget)) (slot-name widget) t)))
    (if slot (CLOS::slot-definition-type slot) t)))

(defmethod get-object-documentation ((widget slot-default-widget))
  (let ((slot (find-slot (find-class (class-name widget)) (slot-name widget) t)))
    (when slot (documentation slot))))

(defmethod get-object-value ((widget slot-default-widget))
  (get-default (find-class (class-name widget)) (slot-name widget)))

(defmethod set-object-value ((widget slot-default-widget) value)
  (set-default-internal (class-name widget) (slot-name widget) value t))

(defmethod get-widget-value
    ((widget slot-default-widget) &optional (lispview-value (lispview:value widget)))
  (multiple-value-bind (val errorp) (call-next-method)
    (handler-case
	(progn (convert (eval val) (get-object-type widget))
	       (values val errorp))
      (condition (error-condition)	;if error, give error message.
		 (widget-notice
		  widget
		  (format nil "~A is a bad value for ~A:~%~%~A"
			  lispview-value (slot-name widget) error-condition))
		 (values (get-object-value widget) :coerce-error)))))

;;; Sub-classes that are instantiated:
(defclass slot-default-text-field (slot-default-widget lispview:text-field) ())
(defclass slot-default-numeric-field (slot-default-widget lispview:numeric-field) ())
(defclass slot-default-exclusive-setting (slot-default-widget lispview:exclusive-setting) ())
;(defclass slot-default-exclusive-scrolling-list
;    (slot-default-widget lispview:exclusive-scrolling-list) ())
(defclass slot-default-horizontal-slider (slot-default-widget lispview:horizontal-slider) ())

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; GET-WIDGET-VALUE and SET-WIDGET-VALUE methods on standard lispview items.

;;; If the user leaves the field blank, don't generate an error, but
;;; return the current value of the object
(defmethod get-widget-value
    ((widget lispview:text-field) &optional (lispview-value (lispview:value widget)))
  (let (val errorp)
    (handler-case
	(setq val (read-from-string lispview-value nil :empty-string))
      (condition (error-condition)	;if read error, give error message.
		 (widget-notice
		  widget
		  (format nil "~A" error-condition))
		 (setq errorp :read-error)
		 (setq val (get-object-value widget))))
    (when (eq val :empty-string)
      (setq val (get-object-value widget))
      (setq errorp :empty-string))
    (values val errorp)))

;;; Necessary because numeric-field inherits from text-field
(defmethod get-widget-value
    ((widget lispview:numeric-field) &optional (lispview-value (lispview:value widget)))
  (values lispview-value nil))

(defmethod get-widget-value
    ((widget lispview:item) &optional (lispview-value (lispview:value widget)))
  (values lispview-value nil))

;;; This captures the conversion function between the value of the
;;; object and the widget internal representation (in this case, a
;;; string).
(defmethod set-widget-value ((widget lispview:text-field) val)
  (let ((*print-pretty* t))
    (setf (lispview:value widget) (write-to-string val))
    val))

(defmethod set-widget-value ((widget lispview:numeric-field) val)
  (setf (lispview:value widget) val))

(defmethod set-widget-value ((widget lispview:item) val)
  (setf (lispview:value widget) val))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Conversion functions:  Value <--> widget-parameter.

;;; Default method just calls coerce.
(defmethod convert (value type)
  (coerce value type))

(defmethod convert ((sym symbol) (type (eql 'lispview:color)))
  (find-true-color :name sym :if-not-found :error))

(defmethod convert ((ls list) (type (eql 'lispview:color)))
  (find-true-color :red (car ls) :green (cadr ls) :blue (caddr ls)
		   :if-not-found :error))

(defmethod set-widget-value :around (widget (val lispview:color))
  (setq val (or (and (slot-boundp val 'lispview:name) (lispview:name val))
		(list (lispview:red val) (lispview:green val) (lispview:blue val))))
  (call-next-method widget val))
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Panels with pop-up documentation for their items.  Useful since
;;;; the OpenWindows help facility cannot be accessed dynamically from
;;;; LispView.

(defclass helpful-panel (lispview:panel)
  ())

(defclass widget-help-interest (lispview:mouse-interest)
  ()
  (:default-initargs :event-spec '((:meta) ((or :left :right :middle) :down))))

(defvar *the-widget-help-interest*
  (make-instance 'widget-help-interest))

(defmethod initialize-instance :around ((p helpful-panel) &rest initargs)
  (setf (getf initargs :interests)
	(cons *the-widget-help-interest*
	      (getf initargs :interests (get-default (class-of p) :interests))))
  (apply #'call-next-method p initargs))

(defmethod lispview:receive-event
    ((panel helpful-panel) (interest widget-help-interest) event)
  (loop with widget = nil
	with mouse-x = (lispview:mouse-event-x event)
	with mouse-y = (lispview:mouse-event-y event)
	with doc = nil
	for child in (lispview:children panel)
	until (and (lispview:region-contains-xy-p
		    (lispview:bounding-region child) mouse-x mouse-y)
		   (setq doc (get-object-documentation child))
		   (setq widget child))
	finally
	(when widget
	  (lispview:notice-prompt
	   :message (or doc "Sorry, no documentation provided for this item.")
	   :x mouse-x :y mouse-y :owner panel
	   :beep nil :choices '((:yes "OK" t))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Miscellaneous stuff:

;;; This function captures the default widget subtype behavior.  For
;;; entering data of type, it hands back the default type of
;;; lispview:item to use, along with a set of initargs appropriate for
;;; that item.
(defun compute-item-type-and-initargs (type)
  (let (range)
    (cond ((and (listp type) (eq (car type) 'member)
		(<= (length type) 5))
	   (values 'lispview:exclusive-setting `(:choices ,(cdr type))))
;	  ((and (listp type) (eq (car type) 'member))
;	   (values 'lispview:exclusive-scrolling-list
;		   `(:selection-required t)))
	  ((and (listp type) (eq (car type) 'integer)
		(<= (setq range (abs (apply '- (cdr type)))) 16)) ;*** MAGIC NUMBER
	   (values 'lispview:numeric-field
		   `(:min-value ,(second type) :max-value ,(third type)
		     :show-range t :show-value t)))
	  ((and (listp type) (eq (car type) 'integer)
		(<= range 50))
	   (values 'lispview:horizontal-slider
		   `(:min-value ,(second type) :max-value ,(third type)
		     :show-range t :show-value t)))
	  (t (values 'lispview:text-field nil)))))

(defmethod get-object-documentation (thing)
  (declare (ignore thing))
  nil)

(defmethod get-object-type (thing)
  (declare (ignore thing))
  t)

;;; Put up a lispview:notice-prompt, centered on the widget.
(defun widget-notice (widget message &key (beep t))
  (let* ((widget-rgn (lispview:bounding-region widget))
	 (x (+ (lispview:region-left widget-rgn) 100)) ;*** MAGIC NUMBER.
	 (y (round (+ (lispview:region-top widget-rgn)
		      (lispview:region-bottom widget-rgn)) 2)))
    (lispview:notice-prompt :x x :y y
			    :owner (lispview:parent widget)
			    :beep beep
			    :message message
			    :choices '((:yes "OK" t)))))

;;; Returns non-nil if there are errors in the widget values.  This is
;;; used by the global-variable dialogs, as well as the slot-value and
;;; slot-default dialogs.
(defun standard-update-function (widgets)
  (loop with val
	with errorp
	with any-errors
	for widget in widgets
	do
	(multiple-value-setq (val errorp) (get-widget-value widget))
	(when errorp (set-widget-value widget val))
	(unless (equal val (get-object-value widget))
	  (set-object-value widget val))
	(setq any-errors (or errorp any-errors))
	finally (return any-errors)))

(defun destroying-exit-function (dialog)
  (setf (lispview:status dialog) :destroyed))

(defun unmapping-exit-function (dialog)
  (setf (lispview:mapped dialog) nil))

(defun visible-slot-names (class)
  (mapcar 'CLOS::slot-definition-name
	  (CLOS-SYS:visible-slots-using-class class nil 'inspect)))

#|
;;; Function from x-window.lisp:

;;; Calls lispview:find-color with :if-not-found :realize.  If color
;;; returned is an approximation, we destroy it, giving a warning or
;;; error according to :if-not-found, and we return nil.
(defun find-true-color (&rest keys &key if-not-found)
  (let ((color (apply 'lispview:find-color :if-not-found :realize keys)))
    (when (not (eq color (lispview::proxy-color color)))
      (setf (lispview:status color) :destroyed)
      (setq color nil)
      (case if-not-found
	(:warn (warn "Color specified by ~A could not be allocated." keys))
	(:error (error "Color specified by ~A could not be allocated." keys))))
    color))
|#

#| Example usage:

(defvar global1 10
  "Global var with integer values between 0 and 12.")
(eval-when (load eval) (setf (get 'global1 :type) '(integer 0 10)))

(defvar global2 :a
  "Global var that takes on values :a, :b, or :c.")
(eval-when (load eval) (setf (get 'global2 :type) '(member :a :b :c)))

(defvar global3 0
  "Global var that takes on integer values between -25 and 25.")
(eval-when (load eval) (setf (get 'global3 :type) '(integer -25 25)))

(defvar global4 0.0
  "Global var that takes on float values.")
(eval-when (load eval) (setf (get 'global4 :type) 'float))

(make-global-parameter-dialog '(global1 global2 global3 global4))


(def-simple-class foo ()
  ((small-int :type (integer 0 10) :initform 5
	      :documentation "A slot holding a small integer.")
   (med-int :type (integer -5 30)
	    :documentation "A slot holding a medium size integer.")
   (big-int :type (integer 10 5000) :initform 300
	    :documentation "A slot holding a big integer.")
   (t-or-nil :type (member t nil) :initform t
	     :documentation "A slot which holds t or nil.")
   (a-b-c-d  :type (member :a :b :c :d) :initform :a
	     :documentation "A slot which holds one of :a, :b, :c, or :d.")
   (a-float :type float
	    :documentation "A slot which holds a float.  Try entring a non-float."))
  (:default-initargs :med-int 0 :big-list :bozzle :a-float 0.1))

(setq the-instance (make-instance 'foo))

(make-slot-value-dialog the-instance)
(make-slot-default-dialog 'foo)

|#


