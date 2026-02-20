;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)menu.lisp	3.8 10/11/91


(in-package "LISPVIEW")


;;; Create a command-menu-item or a submenu-item (and its menu) given one
;;; choice from a menu-spec.  If the syntax of the choice is incorrect
;;; we signal an error here.

(defun parse-menu-spec-choice (display choice)
  (check-type choice menu-spec-choice)
  (let ((label (nth 0 choice))
	(action (nth 1 choice)))
    (if (eq action :menu)
	(make-instance 'submenu-item
	  :display display
	  :status :initialized
	  :label label
	  :menu (make-instance 'menu
		  :display display
		  :menu-spec (nth 2 choice)))
      (apply #'make-instance 'command-menu-item
	     :display display
	     :status :initialized
	     :label label
	     :command action
	     (cddr choice)))))


;;; MENU-SPEC := ({MENU-CHOICE}* &rest menu-initargs)
;;; MENU-CHOICE := (label function &rest command-button-initargs) | (label :menu MENU-SPEC)

(defmethod initialize-instance :after ((m menu) &rest args
				                &key 
						  menu-spec 
						  choices
						  choices-nrows
						  choices-ncols
						  default
						  owner
						&allow-other-keys)
  (declare (dynamic-extent initargs))

  (check-arglist (choices (satisfies menu-choices-p))
		 (choices-nrows (or null positive-fixnum))
		 (choices-ncols (or null positive-fixnum))
		 (default (or null positive-fixnum menu-item))
		 (owner (or null base-window)))

  (if menu-spec
      (let* ((display (if (slot-boundp m 'display) (display m)))
	     (choices nil)
	     (initargs 
	      (dolist (x menu-spec)
		(when (keywordp x) 
		  (return (member x menu-spec)))
		(push (parse-menu-spec-choice display x) choices)))
	     (label (getf initargs :label)))
	(when label (setf (slot-value m 'label) label))
	(apply #'dd-initialize-menu (platform m) m (append initargs args))
	(setf (choices m) (nreverse choices)))
    (apply #'dd-initialize-menu (platform m) m args)))


(defmethod initialize-instance :around ((m menu) &key status &allow-other-keys)
  (prog1
      (call-next-method)
    (when (eq status :realized)
      (setf (status m) :realized))))


(defmethod (setf status) ((value (eql :realized)) (m menu))
  (when (eq (status m) :initialized)
    (unless (and (slot-boundp m 'event-dispatch-process)
		 (typep (event-dispatch-process m) 'event-dispatch-process))
      (setf (event-dispatch-process m)
	    (event-dispatch-process (root-canvas (display m)))))
    (let ((choices (choices m)))
      (when (and (consp choices) (typep (car choices) 'menu-item))
	(dolist (choice choices) (realize choice))))
    (dd-realize-menu (platform m) m)
    (push m (slot-value (display m) 'menus)))
  (setf (slot-value m 'status) :realized))


(def-solo-accessor CHOICES menu 
  :type (satisfies menu-choices-p)
  :driver dd-menu-choices)

(def-solo-accessor CHOICES-NROWS menu 
  :type (or null positive-fixnum)
  :driver dd-menu-choices-nrows)

(def-solo-accessor CHOICES-NCOLS menu 
  :type (or null positive-fixnum)
  :driver dd-menu-choices-ncols)

(def-solo-accessor LAYOUT menu 
  :type menu-layout
  :driver dd-menu-layout)

(defmethod (SETF LABEL) (value (x menu))
  (check-type value menu-label)
  (when (eq (status x) :realized)
    (setf (dd-menu-label (platform x) x) value))
  (setf (slot-value x 'label) value))

(def-solo-accessor DEFAULT menu 
  :type (or null positive-fixnum menu-item)
  :driver dd-menu-default)

(def-solo-accessor PUSHPIN menu 
  :driver dd-menu-pushpin)

(def-solo-accessor OWNER menu
  :type (or null base-window)
  :driver dd-menu-owner)

(def-solo-accessor DISMISSED menu
  :driver dd-menu-dismissed)


(defmethod menu-show (menu canvas &key x y)
  (check-arglist (menu menu) (canvas canvas) (x (or null fixnum)) (y (or null fixnum)))
  (dd-menu-show (platform menu) menu canvas :x x :y y))


(defmethod (setf status) ((value (eql :destroyed)) (m menu))
  (when (eq (status m) :realized)
    (dd-destroy-menu (platform m) m))
  (let ((d (display m)))
    (setf (slot-value d 'menus) (delete m (slot-value d 'menus))
	  (slot-value m 'status) :destroyed)))



;;; Menu Items

(defmethod initialize-instance :after ((m menu-item) &rest initargs)
  (declare (dynamic-extent initargs))

  (apply #'dd-initialize-menu-item (platform m) m initargs))
  

(defmethod initialize-instance :around ((m menu-item) &key status &allow-other-keys)
  (prog1
      (call-next-method)
    (when (eq status :realized)
      (setf (status m) :realized))))


(defmethod (setf status) ((value (eql :realized)) (m menu-item))
  (unless (eq (status m) :realized)
    (dd-realize-menu-item (platform m) m))
  (setf (slot-value m 'status) :realized))


(defmethod (SETF LABEL) (value (x menu-item))
  (check-type value menu-label)
  (setf (dd-menu-item-label (platform x) x) value
	(slot-value x 'label) value))

(def-solo-accessor STATE menu-item :type menu-item-state
  :driver dd-menu-item-state)

(def-solo-accessor MAPPED menu-item 
  :driver dd-menu-item-mapped)


(defmethod (setf status) ((value (eql :destroyed)) (m menu-item))
  (when (eq (status m) :realized)
    (dd-destroy-menu (platform m) m))
  (setf (slot-value m 'status) :destroyed))




;;; Notices

(defun notice-prompt (&key 
			(display (default-display))
			(owner (root-canvas display))
			(message "")
			(x 0)
			(y 0)
			(beep t)
			choices)
  (check-type owner canvas)
  (dd-notice-prompt (platform owner) 
		    :display display
		    :owner owner
		    :message message
		    :x x
		    :y y
		    :beep beep
		    :choices choices))


;;; Utility

;;; Popup a menu based on items, at x,y relative to the origin of canvas.
;;; Items is a list of elements that match one of the following: (label value), 
;;; (value), or value.  If only a value is specified then whatever (label value)
;;; returns is used as the label of the item.  If the user selects an item
;;; return its value, otherwise return default.

(defmethod menu-choose (items canvas &key (x 0) (y 0) default)
  (let ((flag nil)
	(choice default))
    (labels
     ((make-menu-choice (item)
	(multiple-value-bind (label value)
	    (if (consp item)
		(values (car item) (if (cdr item) (cadr item) (car item)))
	      (values item item))
	  (make-instance 'command-menu-item 
	    :label (label label)
	    :command #'(lambda () (setf choice value))))))

     (let ((menu (make-instance 'menu
		   :owner canvas
		   :dismissed #'(lambda () (setf flag t))
		   :choices (mapcar #'make-menu-choice items))))
       (unwind-protect
	   (progn
	     (menu-show menu canvas :x x :y y)
	     (process-allow-schedule)
	     (process-wait "Menu Selection" #'(lambda () flag)))
	 (setf (status menu) :destroyed))))

    choice))

