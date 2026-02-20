;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)xview-menu.lisp	3.9 10/11/91


(in-package "LISPVIEW")


(defmethod dd-initialize-menu ((p XView) menu &rest initargs)
  (unless (slot-boundp menu 'device)
    (setf (device menu)
	  (apply #'make-xview-menu
	   :allow-other-keys t
	   :initargs (copy-list initargs)
	   initargs)))
  (setf (slot-value menu 'status) :initialized))


(defun xview-menu-choice-initargs (choices layout nrows ncols)
  (let ((nchoices (length choices)))
    (nconc
     (mapcan #'(lambda (choice)
		 (list :menu-append-item (xview-object-id (device choice))))
	     choices)
     (case layout
       (:vertical
	(list :menu-ncols 1
	      :menu-nrows (or nrows nchoices)))
       (:horizontal
	(list :menu-nrows 1
	      :menu-ncols (or ncols nchoices)))
       (:row-major 
	(list :menu-nrows (or nrows nchoices)
	      :menu-ncols (or ncols 1)))
       (:col-major 
	(list :menu-nrows (or nrows 1)
	      :menu-ncols (or ncols nchoices)))))))

  
(defun xview-menu-xvinitargs (menu choices
			      &key 
				choices-nrows
				choices-ncols
				layout
				pushpin
				default
				owner
				dismissed
			       &allow-other-keys)
  (let* ((label (if (slot-boundp menu 'label) (label menu)))
	 (owner-id (if owner (xview-object-id (device owner))))
	 (pushpin (and owner-id pushpin)))
    (nconc
      (typecase label
	(string (list :menu-title-item label))
	(image (list :menu-title-image (xview-object-id (device label)))))
      (if (menu-item-list-p choices)
	  (xview-menu-choice-initargs choices layout choices-nrows choices-ncols)
	(list :menu-gen-proc 'xview-menu-gen-proc))
      (typecase default
	(integer 
	 (list :menu-default (+ default 1 (if (or label pushpin) 1 0))))
	(menu-item 
	 (list :menu-default-item (xview-object-id (device default)))))
      (if owner
	  (list :menu-parent owner-id))
      (if pushpin
	  (list :menu-gen-pin-window (list owner-id (if (stringp label) label ""))))
      (if dismissed
	  (list :menu-done-proc 'xview-menu-done-proc)))))


(defmethod dd-realize-menu ((p XView) menu)
  (let* ((xvo (device menu))
	 (xvd (device (display menu)))
	 (initargs (prog1
		       (xview-item-initargs xvo)
		     (setf (xview-item-initargs xvo) nil)))
	 (id (apply #'XV:xv-create (xview-display-id xvd) :menu
		    (apply #'xview-menu-xvinitargs menu (xview-menu-choices xvo) 
			   initargs))))
    (setf (xview-object-id xvo) id
	  (xview-object-xvd xvo) xvd
	  (xview-object-dsp xvo) (xview-display-dsp xvd))

    (def-xview-object menu xvo)

    (XV:with-xview-lock 
      (xview-maybe-XFlush xvd))))


(defmethod dd-menu-choices ((p XView) x)
  (xview-menu-choices (device x)))


;;; Delete all of the items in an XView menu being careful to leave the 
;;; menus title alone.

(defun xview-delete-menu-items (menu-id)
  (let ((nitems (XV:xv-get menu-id :menu-nitems)))     
    (when (> nitems 0)
      (dotimes (i (1- nitems))
	(XV:xv-set menu-id :menu-remove (- nitems i)))
      (let ((item1 (XV:xv-get menu-id :menu-nth-item 1)))
	(unless (/= 0 (XV:xv-get item1 :menu-title))
	  (XV:xv-set menu-id :menu-remove-item item1))))))

  
(defmethod (setf dd-menu-choices) (value (p XView) x)
  (XV:with-xview-lock 
    (let* ((xvo (device x))
	   (id (xview-object-id xvo)))
      (when id
        (xview-delete-menu-items id)
	(if (menu-item-list-p value)
	    (progn
	      (dolist (choice value)
		(XV:xv-set id :menu-append-item (xview-object-id (device choice))))
	      (XV:xv-set id :menu-gen-proc nil))
	  (XV:xv-set id :menu-gen-proc 'xview-menu-gen-proc))
	(xview-maybe-XFlush (xview-object-xvd xvo)))
      (setf (xview-menu-choices xvo) value))))



(def-xview-initarg-accessor dd-menu-choices-nrows 
  :menu-nrows
  :choices-nrows)

(def-xview-initarg-accessor dd-menu-choices-ncols 
  :menu-ncols
  :choices-ncols)


(defmethod dd-menu-layout ((p XView) x)
  (XV:with-xview-lock 
    (let* ((xvo (device x))
	   (id (xview-object-id xvo)))
    (if id
	(cond
	 ((= 1 (XV:xv-get id :menu-ncols)) :vertical)
	 ((= 1 (XV:xv-get id :menu-nrows)) :horizontal)
	 (t (if (/= 0 (XV:xv-get id :menu-col-major))
		:col-major 
	      :row-major)))
      (getf (xview-item-initargs xvo) :layout)))))


(defmethod (setf dd-menu-layout) (value (p XView) x)
  (XV:with-xview-lock 
    (let* ((xvo (device x))
	   (id (xview-object-id xvo)))
      (if id
	  (let ((nitems (XV:xv-get id :menu-nitems)))
	    (case value
	      (:vertical   (XV:xv-set id :menu-ncols 1 :menu-nrows nitems))
	      (:horizontal (XV:xv-set id :menu-ncols 1 :menu-nrows nitems))
	      (:row-major  (XV:xv-set id :menu-col-major nil))
	      (:col-major  (XV:xv-set id :menu-col-major t)))
	    (xview-maybe-XFlush (xview-object-xvd xvo))
	    value)
	(setf (getf (xview-item-initargs xvo) :layout) value)))))



;;; If the menu already has a title item then just change its :menu-string or 
;;; :menu-image attribute - otherwise create a new title item with 
;;; :menu-title-image or :menu-title-item.  If the menu has a pushpin then update
;;; the pin-windows :xv-label as well.
;;;
;;; If the new label is null then remove the title item if there's no pushpin.  If
;;; there is a pushpin then set the title items string to "".
;;;
;;; Note: If the first item in a menu is actually the menu title then the value of
;;; (XV:xv-get first-item :menu-title) will be non-zero.  Note also that the title
;;; item is shared by the pushpin image.

(defmethod (setf dd-menu-label) (value (p XView) x)
  (XV:with-xview-lock 
    (let* ((xvo (device x))
	   (menu-id (xview-object-id xvo)))
      (if menu-id
	  (progn
	    (let ((item-id (XV:xv-get menu-id :menu-nth-item 1)))
	      (if (and (/= item-id 0) (/= 0 (XV:xv-get item-id :menu-title)))
		  (typecase value
		     (string 
		      (XV:xv-set item-id :menu-string value))
		     (image 
		      (XV:xv-set item-id :menu-image (xview-object-id (device value))))
		     (null 
		      (if (/= 0 (XV:xv-get menu-id :menu-pin))
			  (XV:xv-set menu-id :menu-title-item "")
			(XV:xv-set menu-id :menu-remove-item item-id))))
		(typecase value
		   (string 
		    (XV:xv-set menu-id :menu-title-item value))
		   (image 
		    (XV:xv-set menu-id :menu-title-image (xview-object-id (device value)))))))
	  (let ((pinwin (XV:xv-get menu-id :menu-pin-window)))
	    (when (and (/= 0 (XV:xv-get menu-id :menu-pin)) (/= 0 pinwin))
	      (if (stringp value)
		  (XV:xv-set pinwin :xv-label value)
		(XV:xv-set pinwin :xv-label ""))))
	  (xview-maybe-XFlush (xview-object-xvd xvo))
	  value)
      (setf (getf (xview-item-initargs xvo) :label) value)))))



;;; Menu items are numbered from 1 (0 represents "no selection") unless
;;; a title or a pushpin is present - then items are numbered from 2.

(defun xview-menu-item-offset (menu-id)
  (if (or (/= 0 (XV:xv-get menu-id :menu-pin))
	  (/= 0 (XV:xv-get (XV:xv-get menu-id :menu-nth-item 1) :menu-title)))
      2
    1))



(defmethod dd-menu-default ((p XView) x)
  (xview-menu-default (device x)))

(defmethod (setf dd-menu-default) (value (p XView) menu)
  (XV:with-xview-lock 
    (let* ((xvo (device menu))
	   (choices (xview-menu-choices xvo))
	   (id (xview-object-id xvo))
	   (offset (if id (xview-menu-item-offset id))))
      (when id
	(XV:xv-set id :menu-default (+ offset (if (integerp value)
						  value
						(or (position value choices) 0))))
	(xview-maybe-XFlush (xview-object-xvd xvo)))
      (setf (xview-menu-default xvo) value))))



(defmethod dd-menu-pushpin ((p XView) x)
 (xview-menu-pushpin (device x)))


(defmethod (setf dd-menu-pushpin) (value (p XView) x)
  (XV:with-xview-lock 
    (let* ((xvo (device x))
	   (menu-id (xview-object-id xvo)))
      (when menu-id
	(if value
	    (let* ((owner (xview-menu-owner xvo))
		   (owner-id (if owner (xview-object-id (device owner))))
		   (label (if (slot-boundp x 'label) (label x))))
	      (unless (stringp label)
		(setf label ""))
	      (when owner-id
		(XV:xv-set menu-id :menu-gen-pin-window (list owner-id label))
		(xview-maybe-XFlush (xview-object-xvd xvo))))
	  (progn
	    (XV:xv-set menu-id :menu-pin nil)
	    (xview-maybe-XFlush (xview-object-xvd xvo)))))
      (setf (xview-menu-pushpin xvo) value))))



;;; The owner of a menu (assuming that the menu has a pushpin) is the :owner
;;; of the menus :menu-pin-window and the :menu-parent of the menu itself.

(defmethod dd-menu-owner ((p XView) x)
  (xview-menu-owner (device x)))

(defmethod (setf dd-menu-owner) (value (p XView) x)
  (XV:with-xview-lock 
    (let* ((xvo (device x))
	   (id (xview-object-id xvo))
	   (owner-id (xview-object-id (device value))))
      (when (and id owner-id)
        (let ((pinwin (XV:xv-get id :menu-pin-window)))
	  (XV:xv-set id :menu-parent owner-id)
	  (when (/= 0 pinwin)
	    (XV:xv-set pinwin :xv-owner owner-id))
	  (xview-maybe-XFlush (xview-object-xvd xvo))))
      (setf (xview-menu-owner xvo) value))))



(defvar xview-menu-event (make-foreign-pointer :type '(:pointer XV:event) :static t))

(defmethod dd-menu-show ((p XView) menu window &key (x 0) (y 0))
  (XV:with-xview-lock 
    (let* ((menu-id (xview-object-id (device menu)))
	   (window-xvo (device window))
	   (window-id (xview-object-id window-xvo)))
      (when (and menu-id window-id)
        (setf (XV:event-ie-code xview-menu-event) #.XV:ms-right
	      (XV:event-ie-locx xview-menu-event) x
	      (XV:event-ie-locy xview-menu-event) y
	      (XV:event-action xview-menu-event) #.XV:action-menu
	      (XV:event-ie-win xview-menu-event) window-id)
	(XV:xv-menu-show menu-id window-id xview-menu-event)
	(X11:XFlush (xview-object-dsp window-xvo))))))
	     
  

(defmethod dd-destroy-menu ((p XView) x)
  (destroy-xview-object x))


(defun eval-xview-menu-items-generator (gen)
  (let ((items (typecase gen
		 (symbol
		  (cond 
		   ((fboundp gen) 
		    (funcall gen))
		   ((boundp gen) 
		    (symbol-value gen))))
		 (function 
		  (funcall gen))
		 (t
		  (eval gen)))))
    (if (menu-item-list-p items)
	items
      (error "value returned by ~S -> ~S, is not a list of menu-items" gen items))))
	     

(defun xview-gen-menu-items (menu)
  (let* ((xvo (device menu))
	 (id (xview-object-id xvo))
	 (items-gen (xview-menu-choices xvo)))
    (when id
      (multiple-value-bind (ignore condition)
	  (ignore-errors
	   (let ((items (eval-xview-menu-items-generator items-gen)))
	     (xview-delete-menu-items id)
	     (dolist (item items)
	       (let ((item-id (xview-object-id (device item))))
		 (if (integerp id)
		     (XV:xv-set id :menu-append-item item-id)
		   (warn "bad menu-item ~S returned by ~S for menu ~S" item items-gen menu))))))
	(declare (ignore ignore))
	(when condition
	  (warn "An error was signaled generating choices for menu ~S using ~S:~%~A"
		menu items-gen condition))))))


(defvar *current-xview-menu-op* NOTIFY_DONE)

(XV:defcallback (xview-menu-gen-proc (:abort-value xv-menu)) ((xv-menu XV:menu) op)
  (let ((menu (xview-id-to-object xv-menu)))
    (when (typep menu 'menu)
      (setf *current-xview-menu-op* op)
      (case op
	(#.MENU_DISPLAY (xview-gen-menu-items menu))
	(#.MENU_DISPLAY_DONE)
	(#.MENU_NOTIFY
	 (when (/= *current-xview-menu-op* MENU_DISPLAY_DONE)
	   (xview-gen-menu-items menu)))
	(#.MENU_NOTIFY_DONE))))
  xv-menu)


(defmethod dd-menu-dismissed ((p XView) menu)
  (xview-menu-dismissed (device menu)))

(defmethod (setf dd-menu-dismissed) (value (p XView) menu)
  (XV:with-xview-lock 
    (let* ((xvo (device menu))
	   (id (xview-object-id xvo)))
      (when id
	(setf (xview-menu-dismissed (device menu)) value)
	(if value
	    (XV:xv-set id :menu-done-proc 'xview-menu-done-proc)
	  (XV:xv-set id :menu-done-proc nil))))))


(XV:defcallback xview-menu-done-proc ((xv-menu XV:menu) result)
  (declare (ignore result))
  (let ((menu (xview-id-to-object xv-menu)))
    (when (typep menu 'menu)
      (deliver-event menu
		     :menu-dismissed
		     (make-menu-dismissed-event)))))
      

(defmethod receive-event (menu interest (event menu-dismissed-event))
  (declare (ignore menu interest))
  (let ((dismissed (dismissed menu)))
    (when dismissed
      (funcall dismissed))))



;;; Menu Items


(defmethod dd-initialize-menu-item ((p XView) item &rest initargs)
  (unless (slot-boundp item 'device)
    (setf (device item)
	  (apply #'make-xview-menu-item
	   :allow-other-keys t
	   :initargs (copy-list initargs)
	   initargs)))
  (setf (slot-value item 'status) :initialized))


(defun xview-menu-item-xvinitargs (item &key 
				          state
					  mapped
				        &allow-other-keys)
  (let ((label (if (slot-boundp item 'label) (label item))))
    (nconc
     (case state
       (:inactive
	(list :menu-inactive t))
       (:busy 
	(list :menu-invert t)))
     (if (null mapped)
	 (list :menu-feedback nil))
     (typecase label
       (string
	(list :menu-string label))
       (image
	(list :menu-image (xview-object-id (device label))))
       (t 
	(list :menu-string ""))))))


(defun realize-xview-menu-item (item &rest xview-initargs)
  (let* ((xvo (device item))
	 (xvd (device (display item)))
	 (initargs (prog1
		       (xview-item-initargs xvo)
		     (setf (xview-item-initargs xvo) nil)))
	 (id (apply #'XV:xv-create (xview-display-screen xvd) :menuitem
		    (nconc
		     (apply #'xview-menu-item-xvinitargs item initargs)
		     xview-initargs))))
    (setf (xview-object-id xvo) id
	  (xview-object-xvd xvo) xvd
	  (xview-object-dsp xvo) (xview-display-dsp xvd))

    (def-xview-object item xvo)

    (XV:with-xview-lock 
      (xview-maybe-XFlush xvd))))


(defmethod dd-realize-menu-item ((p XView) (i command-menu-item))
  (realize-xview-menu-item i :menu-action-proc 'xview-command-item-action))


(defmethod dd-realize-menu-item ((p XView) (i submenu-item))
  (let* ((xvd (device (display i)))
	 (menu (if (slot-boundp i 'menu) (menu i)))
	 (xvm (if (typep menu 'menu)
		  (xview-object-id (device menu))
		(XV:with-xview-lock	       
		 (XV:xv-create (xview-display-screen xvd) :menu)))))
    (realize-xview-menu-item i :menu-pullright xvm)))


(defmethod dd-realize-menu-item ((p XView) (i spacer-menu-item))
  (realize-xview-menu-item i :menu-feedback nil))



(defmethod (setf dd-menu-item-label) (value (p XView) x)
  (XV:with-xview-lock 
    (let* ((xvo (device x))
	   (id (xview-object-id xvo)))
      (if id
	(progn
	  (typecase value
	    (string
	     (set-xview-string-attribute id :menu-string value))
	    (image
	     (XV:xv-set id :menu-image (xview-object-id (device value))))
	    (t
	     (set-xview-string-attribute id :menu-string "")))
	  (xview-maybe-XFlush (xview-object-xvd xvo))
	  value)
	(setf (getf (xview-item-initargs xvo) :label) value)))))


(defmethod dd-menu-item-state ((p XView) x)
  (XV:with-xview-lock 
    (let* ((xvo (device x))
	   (id (xview-object-id xvo)))
      (if id
	  (cond
	   ((/= 0 (XV:xv-get id :menu-inactive))
	    :inactive)
	   ((/= 0 (XV:xv-get id :menu-invert))
	    :busy)
	   (t 
	    :active)))
      (getf (xview-item-initargs xvo) :state))))


(defmethod (setf dd-menu-item-state) (value (p XView) x)
  (XV:with-xview-lock 
    (let* ((xvo (device x))
	   (id (xview-object-id xvo)))
      (if id
	  (progn
	    (case value
	      (:inactive
	       (XV:xv-set id :menu-invert nil :menu-inactive t))
	      (:busy
	       (XV:xv-set id :menu-inactive nil :menu-invert t))
	      (t 
	       (XV:xv-set id :menu-invert nil :menu-inactive nil)))
	    (xview-maybe-XFlush (xview-object-xvd xvo))
	    value)
	(setf (getf (xview-item-initargs xvo) :state) value)))))



(def-xview-object-accessor dd-menu-item-mapped
  :menu-feedback
  xview-menu-item-mapped
  :type boolean)


(defmethod dd-menu-bounding-region ((p XView) x)
  (declare (ignore x))
  (error "No menu item bounding-region support in XView"))


(defmethod (setf dd-bounding-region) (value (p XView) x)
  (declare (ignore value x))
  (error "No menu item bounding-region support in XView"))


(defmethod dd-destroy-menu-item ((p XView) x)
  (destroy-xview-object x))


(XV:defcallback xview-command-item-action ((xv-menu XV:menu) (xv-item XV:menu-item))
  (declare (ignore xv-menu)) 
  (let ((menu  (xview-id-to-object xv-menu))
	(item (xview-id-to-object xv-item)))
    (when (and (typep item 'command-menu-item)
	       (typep menu 'menu))
      (deliver-event menu
		     :menu-item-selected
		     (make-menu-item-selected-event :item item)))))
		      

(defmethod receive-event (menu interest (event menu-item-selected-event))
  (declare (ignore menu interest))
  (let* ((item (menu-item-selected-event-item event))
	 (command (if (slot-boundp item 'command) (slot-value item 'command))))
    (when (and command (functionp command))
      (when (functionp command)
	(funcall command)))))



;;; Notices

(defun xview-notice-message-to-strings (message)
  (let* ((start 0)
	 (end (position #\newline message))
	 (length (length message))
	 (strings nil))
    (loop
       (when (>= start length)
	 (return))
       (push (malloc-foreign-string (subseq message start (or end length)))
	     strings)
       (if end
	   (setf start (1+ end)
		 end (position #\newline message :start start))
	 (return)))
    (nreverse strings)))


;;; Convert a list of "choices" with this format: label  |  ( [:yes | :no] label [value] )
;;; to an attribute-value list for xv-notice-prompt.  If only the label is supplied then
;;; the label serves as the value.

(defun xview-notice-choices-to-buttons (choices)
  (let* ((n 2)
	 (table (make-array (+ n (length choices)))))
    (flet
     ((choice-to-button (choice)
        (multiple-value-bind (yes/no label value)
	    (cond 
	     ((and (consp choice) (member (car choice) '(:yes :no) :test #'eq))
	      (values (car choice) (cadr choice) (if (cddr choice) 
						     (caddr choice) 
						   (cadr choice))))
	     ((consp choice)
	      (values nil (car choice) (if (cdr choice) 
					   (cadr choice) 
					 (car choice))))
	     (t
	      (values nil choice choice)))
	  (let ((string (malloc-foreign-string (label label))))
	    (if yes/no
		(prog1
		    (list (if (eq yes/no :yes) 
			      :notice-button-yes 
			    :notice-button-no) 
			  string)
		  (setf (svref table (if (eq yes/no :yes) 1 0)) value))
	      (prog1
		  (list :notice-button (list string n))
		(setf (svref table n) value)
		(incf n)))))))

    (values (mapcan #'choice-to-button choices) table))))


(defmethod dd-notice-prompt ((p XView)
			     &key 
			       owner 
			       message
			       x y
			       beep
			       choices
			     &allow-other-keys)
  (let ((owner-id (xview-object-id (device owner))))
    (when owner-id
      (multiple-value-bind (buttons table)
	  (if choices
	      (xview-notice-choices-to-buttons choices)
	    (values (list :notice-button-yes (malloc-foreign-string "Yes")
			  :notice-button-no (malloc-foreign-string "No"))
		    (make-array '(2) :initial-contents '(nil t))))
	(let* ((strings (xview-notice-message-to-strings message))
	       (value 
		(XV:with-xview-lock 
		  (prog1
		      (apply #'xv-notice-prompt owner-id xview-null-event
			:notice-message-strings strings
			:notice-focus-xy (list x y)
			:notice-no-beeping (not beep)
			buttons)
		    (X11:XFlush (xview-display-dsp (device (display owner))))))))
	  (prog1
	      (cond
	       ((and (>= value 0) (< value (length table)))
		(svref table value))
	       (t 
		(warn "dd-notice-prompt failed ~S" value)))

	    (dolist (x strings)
	      (free-foreign-pointer x))

	    (dolist (x buttons)
	      (typecase x
		(foreign-pointer 
		 (free-foreign-pointer x))
		(cons 
		 (when (typep (car x) 'foreign-pointer)
		   (free-foreign-pointer (car x))))))))))))


