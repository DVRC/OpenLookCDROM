;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)xview-canvas.lisp	3.40 10/11/91


(in-package "LISPVIEW")


;;; Canvas, Window - Initialialization and Realization

;;; All of the dd-initialize-canvas methods just store a copy of the initargs in the 
;;; xview-canvas' initargs slot, and store an appropriate xview structure in the 
;;; canvas' device slot.  Note that all of the XView slots that don't correspond
;;; directly to Solo slots are set by the dd-realize functions so there is no danger
;;; of an application inadvertantly setting a slot that the driver depends on.

(defun xview-initialize-canvas (canvas constructor initargs)
  (unless (slot-boundp canvas 'device)
    (setf (device canvas)
	  (apply constructor
		 :from-focus canvas
		 :to-focus canvas
		 :initargs (copy-list initargs) 
		 :allow-other-keys t 
		 initargs))
    (setf (slot-value canvas 'status) :initialized)))

(defmethod dd-initialize-canvas ((p XView) (c opaque-canvas) &rest initargs)
  (declare (dynamic-extent initargs))
  (xview-initialize-canvas c #'make-xview-opaque-canvas initargs))

(defmethod dd-initialize-canvas ((p XView) (c transparent-canvas) &rest initargs)
  (declare (dynamic-extent initargs))
  (xview-initialize-canvas c #'make-xview-transparent-canvas initargs))

(defmethod dd-initialize-canvas ((p XView) (w window) &rest initargs)
  (declare (dynamic-extent initargs))
  (xview-initialize-canvas w #'make-xview-window initargs))

(defmethod dd-initialize-canvas ((p XView) (w top-level-window) &rest initargs)
  (declare (dynamic-extent initargs))
  (xview-initialize-canvas w #'make-xview-top-level-window initargs))



;;; Each bit-gravity keyword gets a property, 'x-bit-gravity, that is equal
;;; to the value of the corresponding X11 constant.

(macrolet 
 ((def-bit-gravity-keywords ()
    `(let ((x11-bit-gravity-keywords 
	    '(X11:ForgetGravity 
	      X11:NorthWestGravity 
	      X11:NorthGravity	       
	      X11:NorthEastGravity
	      X11:WestGravity
	      X11:CenterGravity
	      X11:EastGravity 
	      X11:SouthWestGravity
	      X11:SouthGravity
	      X11:SouthEastGravity
	      X11:StaticGravity)))
       (dolist (keyword bit-gravity-keywords)
	 (setf (get keyword 'x-bit-gravity) 
	       (symbol-value (find (format nil "~AGRAVITY" keyword) x11-bit-gravity-keywords
				   :test #'string-equal)))))))
 (def-bit-gravity-keywords))
	     

(defun x11-bit-gravity-keyword (value)
  (find value bit-gravity-keywords 
	:key #'(lambda (keyword) (get keyword 'x-bit-gravity))))


(defun xview-install-initial-interests (canvas xvo id)
  (let ((input-mask 0))
    (dolist (interest (interests canvas))
      (setf input-mask 
	    (logior input-mask (xview-insert-interest xvo interest :at 0 canvas))))
    (XV:xv-set id :win-consume-x-event-mask input-mask
	          :win-ignore-x-event-mask
		  (if (/= 0 (logand input-mask X11:KeyReleaseMask))
		      0
		    X11:KeyReleaseMask))))


(defun xview-set-window-foreground-background (x xvo id)
  (when (or (not (typep x 'panel)) (xview-opaque-canvas-background xvo))
    (let* ((colormap (colormap x))
	   (fg (or (xview-opaque-canvas-foreground xvo)
		   (setf (xview-opaque-canvas-foreground xvo)
			 (find-color :name :black :colormap colormap))))
	   (bg (or (xview-opaque-canvas-background xvo)
		   (setf (xview-opaque-canvas-background xvo)
			 (find-color :name :white :colormap colormap)))))
      (xv_set id
	WIN_FOREGROUND_COLOR (xview-color-index (device fg))
	WIN_BACKGROUND_COLOR (xview-color-index (device bg))
	XV_NULL))))


(defun xview-setup-top-level-window (x xvo id)
  (XV:notify-interpose-destroy-func 
    (xview-object-id xvo)
    (lookup-callback-address 'xview-handle-destroy-event))

  (let ((mode (xview-top-level-window-keyboard-focus-mode xvo)))
    (when (typep mode '(member :locally-active :passive))
      (xv_set id WIN_CONSUME_X_EVENT_MASK X11:FocusChangeMask XV_NULL)
      (when mode
	(setf (keyboard-focus-mode x) mode)))))


(defun realize-xview-canvas (x xvo al &key 
			                override-redirect 
				      &allow-other-keys)
  (when (and override-redirect (typep (parent x) 'root-canvas))
    (push-xview-attrs al WIN_TOP_LEVEL_NO_DECOR TRUE))

  (flush-xview-attr-list al)

  (let* ((id  (setf (xview-object-id xvo) (xview-attr-list-id al)))
	 (xid (setf (xview-object-xid xvo) (xv_get id XV_XID)))
	 (xvd (setf (xview-object-xvd xvo) (device (display x))))
	 (dsp (setf (xview-object-dsp xvo) (xview-display-dsp xvd))))

    (def-xview-object x xvo)

    (let ((cursor (xview-canvas-cursor xvo)))
      (when (typep cursor 'cursor)
	(let ((cursor-xid (xview-object-xid (device cursor))))
	  (when cursor-xid
	    (X11:XDefineCursor dsp xid cursor-xid)))))

    (xview-install-initial-interests x xvo id)
    (defeat-xview-click-to-type id)
    (defeat-xview-passive-grab dsp (xview-object-xid xvo))
    (when (typep x 'opaque-canvas)
      (xview-set-window-foreground-background x xvo id))
    (when (typep x 'top-level-window)
      (xview-setup-top-level-window x xvo id))))


(defun init-xview-window-bounding-region (al &key 
					       bounding-region
					       left bottom right top width height
					       (border-width 0)
					     &allow-other-keys)
  (with-default-region-dimensions (width height left top right bottom bounding-region)
    (let ((bw2 (* 2 border-width)))
      (when left   (push-xview-attrs al XV_X left))
      (when top    (push-xview-attrs al XV_Y top))
      (when width  (push-xview-attrs al XV_WIDTH (- width bw2)))
      (when height (push-xview-attrs al XV_HEIGHT (- height bw2))))))


(defun init-xview-canvas (x xvo al &rest initargs)
  (declare (ignore xvo initargs))
  (push-xview-attrs al WIN_MAP FALSE)
  (if (typep x 'panel)
      (push-xview-attrs al PANEL_BACKGROUND_PROC (lookup-callback-address 'handle-xview-event))
    (push-xview-attrs al WIN_NOTIFY_EVENT_PROC (lookup-callback-address 'handle-xview-event))))


(defun init-xview-opaque-canvas (x xvo al &rest initargs)
  (declare (ignore initargs))
  (let* ((display (display x))
	 (colormap 
	  (or (colormap x)
	      (setf (xview-opaque-canvas-colormap xvo) (default-colormap display))))
	 (x11-visual (device (xview-colormap-visual (device colormap))))
	 (depth 
	  (or (depth x)
	      (setf (xview-opaque-canvas-depth xvo) (X11:visual-bits-per-rgb x11-visual)))))
    (declare (ignore depth))  ;; :win-depth depth  - See XView Bugtraq ID 1036909

    (push-xview-attrs al XV_VISUAL_CLASS 
      (X11:visual-class x11-visual))
    (push-xview-attrs al WIN_CMS 
      (xview-object-id (device colormap)))
    (push-xview-attrs al WIN_BIT_GRAVITY 
      (or (get (xview-opaque-canvas-bit-gravity xvo) 'x-bit-gravity) X11:NorthWestGravity))
    (push-xview-attrs al WIN_RETAINED 
      (if (xview-opaque-canvas-backing-store xvo) TRUE FALSE))))


(defun init-xview-window (x xvo al &rest initargs)
  (declare (ignore x initargs))
  (let ((bw (xview-window-border-width xvo)))
    (unless (or (= bw 0) (= bw 1))
      (error "XView only supports windows with :border-width = 0 or 1"))
    (when (= bw 1)
      (push-xview-attrs al WIN_BORDER 1))))


(defun init-xview-top-level-window (x xvo al &key 
				               label 
					       left-footer 
					       right-footer 
					       busy 
					       closed 
					       show-resize-corners
					     &allow-other-keys)
  (declare (ignore x xvo))
  (when label 
    (push-xview-attrs al 
      FRAME_SHOW_LABEL TRUE
      XV_LABEL (malloc-foreign-string label)))
  (when busy    
    (push-xview-attrs al  FRAME_BUSY TRUE))
  (when closed  
    (push-xview-attrs al FRAME_CLOSED TRUE))
  (when (or left-footer right-footer)
    (push-xview-attrs al FRAME_SHOW_FOOTER TRUE))
  (when left-footer
    (push-xview-attrs al FRAME_LEFT_FOOTER (malloc-foreign-string left-footer)))
  (when right-footer 
    (push-xview-attrs al FRAME_RIGHT_FOOTER (malloc-foreign-string right-footer)))
  (push-xview-attrs al FRAME_SHOW_RESIZE_CORNER
		    (if show-resize-corners TRUE FALSE)))



(defun init-xview-frame-base (x xvo al &key 
					 confirm-quit
				       &allow-other-keys)
  (declare (ignore x xvo))
  (push-xview-attrs al FRAME_NO_CONFIRM (if confirm-quit FALSE TRUE)))


(XV:defcallback xview-frame-cmd-done-proc (frame-id)
  (let ((canvas (xview-id-to-object frame-id)))
    (when (typep canvas 'popup-window)
      (setf (mapped canvas) nil))))

(defun init-xview-frame-cmd (x xvo al &key 
					 pushpin
				       &allow-other-keys)
  (declare (ignore x xvo))
  (push-xview-attrs al 
    FRAME_CMD_PUSHPIN_IN (if (eq pushpin :in) TRUE FALSE)
    FRAME_DONE_PROC (lookup-callback-address 'xview-frame-cmd-done-proc)))



(defun xview-canvas-owner (x)
  (let ((xvd (device (display x))))
    (if (typep x 'top-level-window)
	(let ((specd-owner (xview-top-level-window-owner (device x))))
	  (if specd-owner
	      (or (xview-object-id (device specd-owner))
		  (xview-display-nil-parent-frame xvd))
	    (if (typep x 'base-window)
		(xview-display-root xvd)
	      (xview-display-nil-parent-frame xvd))))
      (or (parent x)
	  (xview-display-nil-parent-frame xvd)))))


;;; The root-canvas is created by xview-make-root-window when the roots
;;; display is realized.

(defun apply-xview-opaque-canvas-inits (x xvo al initargs)
  (apply #'init-xview-window-bounding-region al initargs)
  (apply #'init-xview-canvas x xvo al initargs)
  (apply #'init-xview-opaque-canvas x xvo al initargs))


(defmethod dd-realize-canvas ((p XView) (w root-canvas)))


(defmethod dd-realize-canvas ((p xview) (w opaque-canvas))
  (XV:with-xview-lock 
    (let* ((xvo (device w))
	   (initargs 
	    (prog1
		(xview-object-initargs xvo)
	      (setf (xview-object-initargs xvo) nil))))

      (using-resource (al xview-attr-list-resource (xview-canvas-owner w) :window)
	(apply-xview-opaque-canvas-inits w xvo al initargs)
	(apply #'realize-xview-canvas w xvo al initargs)))))


(defmethod dd-realize-canvas ((p XView) (w transparent-canvas))
  (XV:with-xview-lock 
    (let* ((xvo (device w))
	   (initargs 
	    (prog1
		(xview-object-initargs xvo)
	      (setf (xview-object-initargs xvo) nil))))

      (using-resource (al xview-attr-list-resource (xview-canvas-owner w) :window)
        (push-xview-attrs al WIN_INPUT_ONLY)
        (apply #'init-xview-window-bounding-region al initargs)
	(apply #'init-xview-canvas w xvo al initargs)
	(apply #'realize-xview-canvas w xvo al initargs)))))


(defmethod dd-realize-canvas ((p xview) (w window))
  (XV:with-xview-lock 
    (let* ((xvo (device w))
	   (initargs 
	    (prog1
		(xview-object-initargs xvo)
	      (setf (xview-object-initargs xvo) nil))))

      (using-resource (al xview-attr-list-resource (xview-canvas-owner w) :window)
	(apply-xview-opaque-canvas-inits w xvo al initargs)
	(apply #'init-xview-window w xvo al initargs)
	(apply #'realize-xview-canvas w xvo al initargs)))))


(defmethod dd-realize-canvas ((p xview) (w panel))
  (XV:with-xview-lock 
    (let* ((xvo (device w))
	   (initargs 
	    (prog1
		(xview-object-initargs xvo)
	      (setf (xview-object-initargs xvo) nil))))

      (using-resource (al xview-attr-list-resource (xview-canvas-owner w) :panel)
	(apply-xview-opaque-canvas-inits w xvo al initargs)
	(apply #'init-xview-window w xvo al initargs)
	(apply #'realize-xview-canvas w xvo al initargs)))))



;;; We create an icon for the window here, if one wasn't specified, because XView
;;; doesn't support setting a windows icon after the window has been created.  Fortunately 
;;; one can change the icons label and image dynamically.

(defmethod dd-realize-canvas ((p XView) (w base-window))
  (XV:with-xview-lock 
    (let* ((xvd (device (display w)))
	   (root (xview-display-root xvd))
	   (xvo (device w))
	   (initargs 
	    (prog1
		(xview-object-initargs xvo)
	      (setf (xview-object-initargs xvo) nil)))
	   (icon (xview-top-level-window-icon xvo))
	   (xview-icon
	    (if icon
		(xview-object-id (device icon))
	      (xv_create root (XV:xview-package-address :icon) XV_NULL))))

      (using-resource (al xview-attr-list-resource (xview-canvas-owner w) :frame-base)
	(apply-xview-opaque-canvas-inits w xvo al initargs)
	(apply #'init-xview-window w xvo al initargs)
	(apply #'init-xview-top-level-window w xvo al initargs)
	(apply #'init-xview-frame-base w xvo al initargs)
	(push-xview-attrs al FRAME_ICON xview-icon)
	(apply #'realize-xview-canvas w xvo al initargs)))))


;;; XView currently creates a panel for the FRAME_CMD which we ignore 
;;; (by unmapping it) here.  The panel is moved out of view, above and to 
;;; the right of the popups origin so that any new children will start out
;;; in the usual XView default location.
;;;
;;; It would be better to destroy the panel rather than unmapping it so that the 
;;; server resources used by the window could freed - unfortunately XView blindly 
;;; tries to destroy the panel itself when the popup is destroyed, even if 
;;; it the panel was ALREADY destroyed.  XView bugid 1036913.

(defmethod dd-realize-canvas ((p XView) (w popup-window))
  (XV:with-xview-lock 
    (let* ((xvo (device w))
	   (initargs 
	    (prog1
		(xview-object-initargs xvo)
	      (setf (xview-object-initargs xvo) nil))))

      (using-resource (al xview-attr-list-resource (xview-canvas-owner w) :frame-cmd)
	(apply-xview-opaque-canvas-inits w xvo al initargs)
	(apply #'init-xview-window w xvo al initargs)
	(apply #'init-xview-top-level-window w xvo al initargs)
	(apply #'init-xview-frame-cmd w xvo al initargs)
	(apply #'realize-xview-canvas w xvo al initargs))

      (let ((panel (xv_get (xview-object-id xvo) FRAME_CMD_PANEL)))
	(xv_set panel XV_X (- (xv_get panel XV_WIDTH))
		      XV_Y (- (xv_get panel XV_HEIGHT))
		      WIN_MAP FALSE
		      XV_NULL)))))
	    


;;; DESTROY, DEPTH, MAPPED

;;; If the application doesn't veto the destroy then we apply null-xview-object
;;; (sets all of the xview-object slots, like id, xid, to nil) to the canvas
;;; and all of its descendants.  This ensures that none of the driver routines will 
;;; inadvertantly be applied to an xview object after it has been destroyed.
;;; 
;;; If the canvas that's going to be destroyed is a base-window then find all of
;;; the popup-windows that it owns and apply null-xview-object to the popups
;;; and all of their descendants too.
;;;
;;; Errors signalled while running the applications confirm-quit function and while
;;; traversing the tree are ignored with a warning.  This is done in the interest
;;; of keeping the notifier running.

(defun xview-handle-destroy-checking (client canvas)
  (let ((base-window (typep canvas 'base-window)))
    (macrolet ((funcallable-p (f) `(if (symbolp ,f) (fboundp ,f) (functionp ,f))))
      (let ((confirm-quit (if base-window (confirm-quit canvas))))
	(if (and (funcallable-p confirm-quit)
		 (null (multiple-value-bind (value condition)
			   (ignore-errors (funcall confirm-quit canvas))
			 (when condition
			   (warn "An error was signaled by the confirm-quit function for ~S:~%~A"
				 canvas condition))
			 (or condition value))))
	    (XV:notify-veto-destroy client)
	  (handler-case
	    (labels 
	     ((null-family (canvas)
		(setf (slot-value canvas 'status) :destroyed)
		(let ((xvo (device canvas)))
		  (null-xview-object xvo)
		  (when (typep xvo 'xview-viewport)
		    (let ((vsb (xview-viewport-vertical-scrollbar xvo))
			  (hsb (xview-viewport-horizontal-scrollbar xvo)))
		      (when vsb (null-xview-object vsb))
		      (when hsb (null-xview-object hsb)))))
		(map nil #'null-family (children canvas))))

	     (null-family canvas)

	     (when base-window
	       (dolist (child (children (root-canvas (display canvas))))
		 (when (and (typep child 'top-level-window) (eq (owner child) canvas))
		   (null-family child)))))

	    (error (condition)
	      (warn "An error was signaled while destroying ~S and its children:~%~A" 
		    canvas condition))))))))


(XV:defcallback (xview-handle-destroy-event 
		 (:abort-value (XV:notify-next-destroy-func client status)))
		(client status)
  (let ((canvas (xview-id-to-object client)))
    (XV:enum-case status
      (:destroy-checking 
       (let ((xvo (device canvas)))
	 (setf (xview-top-level-window-destroyed-xvo xvo) (copy-xview-object xvo)
	       (xview-top-level-window-destroyed-p xvo) nil)
	 (if (eq (status canvas) :destroyed)
	     (null-xview-object xvo)
	   (xview-handle-destroy-checking client canvas))))

      (:destroy-cleanup  
       (XV:notify-next-destroy-func client status)
       (setf (xview-top-level-window-destroyed-p (device canvas)) t)
       (deliver-event canvas
		      :status-notification
		      (make-status-notification-event
		        :object canvas
			:status :destroyed)))))
  (XV:keyword-enum :notify-done))


(defmethod dd-destroy-canvas ((p XView) canvas)
  (XV:with-xview-lock 
    (destroy-xview-object canvas)))


(defmethod dd-opaque-canvas-depth ((p XView) canvas)
  (XV:with-xview-lock 
    (let* ((xvo (device canvas))
	   (id (xview-object-id xvo)))
      (cond   
       ((xview-opaque-canvas-depth (device canvas)))
       (id (setf (xview-opaque-canvas-depth xvo) (xv_get id WIN_DEPTH)))
       (t nil)))))

(defmethod (setf dd-opaque-canvas-depth) (value (p XView) canvas)
  (let* ((xvo (device canvas))
	 (id (xview-object-id xvo)))
    (if (and (integerp id) (eq (status canvas) :realized))
	(error "no XView support for changing the depth of a realized canvas")
      (setf (xview-opaque-canvas-depth xvo) value))))

  
(defmethod dd-canvas-mapped ((p XView) x)
  (xview-canvas-mapped (device x)))

(defmethod (setf dd-canvas-mapped) (value (p XView) x)
  (setf (xview-canvas-mapped (device x))
	(set-xview-attr value x WIN_MAP 'boolean)))



;;; BOUNDING-REGION

(defun xview-get-xv-rect (id)
  (make-foreign-pointer :address (xv_get id XV_RECT) :type '(:pointer XV:rect)))

(defun xview-win-bounding-region (id)
  (let ((rect (xview-get-xv-rect id))
	(bw2 (if (/= 0 (xv_get id WIN_BORDER)) 2 0)))
    (make-region :left (XV:rect-r-left rect)
		 :top  (XV:rect-r-top rect)
		 :width (+ (XV:rect-r-width rect) bw2)
		 :height (+ (XV:rect-r-height rect) bw2))))

(defun xview-set-win-bounding-region (id xvd br)
  (let ((bw2 (if (/= 0 (xv_get id WIN_BORDER)) 2 0)))
    (xv_set id XV_X (region-left br)
	       XV_Y (region-top br)
	       XV_WIDTH (- (region-width br) bw2)
	       XV_HEIGHT (- (region-height br) bw2)
	       XV_NULL))
  (xview-maybe-XFlush xvd))


(defmethod dd-canvas-bounding-region ((p XView) w)
  (XV:with-xview-lock 
    (let* ((xvo (device w))
	   (id (xview-object-id xvo)))
      (if id
	  (xview-win-bounding-region id)
	(let* ((initargs (xview-canvas-initargs xvo))
	       (initargs-br (getf initargs :bounding-region)))
	  (or (if initargs-br (copy-region initargs-br))
	      (apply #'make-region :allow-other-keys t initargs)))))))

(defmethod dd-canvas-bounding-region ((p XView) (w top-level-window))
  (let ((config (xview-top-level-window-configuration (device w))))
    (if config
	(let ((bw2 (* 2 (X11:XConfigureEvent-border-width config))))
	  (make-region :left (X11:XConfigureEvent-x config)
		       :top (X11:XConfigureEvent-y config)
		       :width (+ bw2 (X11:XConfigureEvent-width config))
		       :height (+ bw2 (X11:XConfigureEvent-height config))))
      (call-next-method))))


(defmethod (setf dd-canvas-bounding-region) (new-br (p XView) w)
  (unless (typep new-br 'notification-region)
    (XV:with-xview-lock 
      (let* ((xvo (device w))
	     (id (xview-object-id xvo)))
	(if id
	    (xview-set-win-bounding-region id (xview-object-xvd xvo) new-br)
	  (setf (getf (xview-canvas-initargs xvo) :bounding-region) (copy-region new-br))))))
  new-br)


(defmethod (setf dd-canvas-bounding-region) (new-br (p XView) (w top-level-window))
  (unless (typep new-br 'notification-region)
    (setf (xview-top-level-window-configuration (device w)) nil))
  (call-next-method))



;;; STACKING ORDER

;;; This method assumes that XView caches a windows parent but does not
;;; cache a windows stacking order.  This is why we only xv_set the canvases 
;;; WIN_PARENT slot if the value is going to change but we always update
;;; the canvas' stacking order.
;;; 
;;; If relation is :at we convert to :before by making sibling the canvas
;;; that follows canvas (the argument) in the now updated list of children.

(let* ((windows-array 
	(make-foreign-pointer :type '(:pointer (:array X11:Window (2)))
			      :static t))
       (windows-fp
	(make-foreign-pointer :address (foreign-pointer-address windows-array)
			      :type '(:pointer X11:Window)
			      :static t)))

  (flet 
   ((init-windows-array (A B)
      (setf (typed-foreign-aref '(:pointer (:array X11:Window (2))) windows-array 0) A
	    (typed-foreign-aref '(:pointer (:array X11:Window (2))) windows-array 1) B)))

   (defun INSERT-XVIEW-CANVAS (canvas relation sibling parent)
     (when (eq (status canvas) :realized)
       (XV:with-xview-lock 
	 (let* ((xvo (device canvas))
		(dsp (xview-canvas-dsp xvo))
		(child-id (xview-container-id xvo))
		(child-xid (xv_get child-id XV_XID))
		(parent-id (xview-object-id (device parent))))
	   (when (and child-id parent-id)
	     (multiple-value-bind (relation sibling)
		 (if (eq relation :at)
		     (if (= sibling 0) 
			 (values :after nil)
		       (let ((siblings (children parent)))
			 (if (= sibling (1- (length siblings)))   ;; sibling is integer position
			     (values :before nil)
			   (let ((siblings (delete canvas siblings)))
			     (values :after (car (nthcdr (1- sibling) siblings)))))))
		   (values relation sibling))

	       (unless (= (xv_get child-id WIN_PARENT) parent-id)
		 (xv_set child-id WIN_PARENT parent-id XV_NULL))

	       (if (null sibling)
		   (if (eq relation :after)
		       (X11:XRaiseWindow dsp child-xid)
		     (X11:XLowerWindow dsp child-xid))
		 (let* ((sibling-xid (xview-object-xid (device sibling))))
		   (if (eq relation :after)
		       (init-windows-array sibling-xid child-xid)
		     (init-windows-array child-xid sibling-xid))
		   (X11:XRestackWindows dsp windows-fp 2)))

	       (xview-maybe-XFlush (xview-object-xvd xvo) dsp)))))))))


(defmethod dd-insert-canvas ((p XView) canvas relation sibling parent)
  (insert-xview-canvas canvas relation sibling parent))


(defun withdraw-xview-canvas (canvas old-parent)
  (when (and old-parent (not (typep old-parent 'root-canvas)))
    (XV:with-xview-lock
      (let* ((xvo (device canvas))
	     (xvd (xview-object-xvd xvo)))
	(when (xview-object-id xvo)
	  (xv_set (xview-container-id xvo) WIN_PARENT (xview-display-nil-parent-frame xvd) XV_NULL)
	  (xview-maybe-XFlush (xview-object-xvd xvo)))))))


(defmethod dd-withdraw-canvas ((p XView) canvas old-parent)
  (withdraw-xview-canvas canvas old-parent))


;;; OPAQUE CANVAS VISUAL, FOREGROUND AND BACKGROUND

(defmethod dd-opaque-canvas-visual ((p XView) x)
  (XV:with-xview-lock 
    (let* ((xvo (device x))
	   (id (xview-object-id xvo)))
      (if id
	  (find (xv_get id XV_VISUAL_CLASS)
		(cdr (assoc (xv_get id WIN_DEPTH) (supported-depths (display x)) :test #'=))
		:key #'(lambda (visual)
			 (X11:visual-class (device visual)))
		:test #'=)
	(getf (xview-opaque-canvas-initargs xvo) :visual)))))

(defmethod (setf dd-opaque-canvas-visual) (value (p XView) x)
  (XV:with-xview-lock 
    (let* ((xvo (device x))
	   (id (xview-object-id xvo)))
      (if id
	  (error "X11 doesn't support chaning the visual of a realized opaque-canvas")
	(setf (getf (xview-opaque-canvas-initargs xvo) :visual) value)))))


;;; If a color with this index has already been realized then return it.  Otherwise
;;; try and create a new color instance with the specified XView CMS index and name
;;; and if that fails just return black.

(defun find-xview-color (object index name)
  (let* ((colormap (colormap object))
	 (cms (xview-colormap-id (device colormap)))
	 (cms-size (xv_get cms CMS_SIZE))
	 (pixel (xv_get cms CMS_PIXEL index)))
    (or (find index (allocated-colors colormap) 
	      :key #'(lambda (c) (xview-color-index (device c)))
	      :test #'=)
	(if (or (< pixel 0) (>=  pixel cms-size))
	    (find-color :name :black :colormap colormap)
	  (let* ((xcolors (malloc-foreign-pointer 
			   :type `(:pointer (:array X11:XColor (,cms-size)))))
		 (xc (progn
		       (xv_get cms CMS_X_COLORS (foreign-pointer-address xcolors))
		       (foreign-aref xcolors pixel))))
	    (prog1
		(xcolor-to-color (display object) (colormap object) xc name pixel index)
	      (free-foreign-pointer xcolors)))))))


(defmethod dd-opaque-canvas-foreground ((p XView) canvas)
  (XV:with-xview-lock 
    (let* ((xvo (device canvas))
	   (id (xview-object-id xvo)))
      (cond 
       ((xview-opaque-canvas-foreground xvo))
       (id
	(setf (xview-opaque-canvas-foreground xvo)
	      (find-xview-color canvas (xv_get id WIN_FOREGROUND_COLOR) "Foreground")))
       (t nil)))))


(defmethod dd-opaque-canvas-background ((p XView) canvas)
  (XV:with-xview-lock 
    (let* ((xvo (device canvas))
	   (id (xview-object-id xvo)))
      (cond 
       ((xview-opaque-canvas-background xvo))
       (id
	(setf (xview-opaque-canvas-background xvo)
	      (find-xview-color canvas (xv_get id WIN_BACKGROUND_COLOR) "Background")))
       (t nil)))))


(flet
 ((color-to-xview-index (value)
    (xview-color-index (device value))))

  (defmethod (setf dd-opaque-canvas-foreground) (value (p XView) x)
    (setf (xview-opaque-canvas-foreground (device x))
	  (set-xview-attr value x WIN_FOREGROUND_COLOR 'integer #'color-to-xview-index)))

  (defmethod (setf dd-opaque-canvas-background) (value (p XView) x)
    (setf (xview-opaque-canvas-background (device x))
	  (set-xview-attr value x WIN_BACKGROUND_COLOR 'integer #'color-to-xview-index))))


;;; OPAQUE CANVAS BACKING-STORE, BIT-GRAVITY, AND SAVE-UNDER


(defmethod dd-opaque-canvas-backing-store ((p XView) x)
  (xview-opaque-canvas-backing-store (device x)))

(defmethod (setf dd-opaque-canvas-backing-store) (value (p XView) x)
  (setf (xview-opaque-canvas-backing-store (device x))
	(set-xview-attr value x WIN_RETAINED 'boolean)))


(defmethod dd-opaque-canvas-save-under ((p XView) x)
  (xview-opaque-canvas-save-under (device x)))

(defmethod (setf dd-opaque-canvas-save-under) (value (p XView) x)
  (setf (xview-opaque-canvas-save-under (device x))
	(set-xview-attr value x WIN_SAVE_UNDER 'boolean)))


(defmethod dd-opaque-canvas-bit-gravity ((p Xview) x) 
  (xview-opaque-canvas-bit-gravity (device x)))

(defmethod (setf dd-opaque-canvas-bit-gravity) (value (p Xview) x) 
  (setf (xview-opaque-canvas-bit-gravity (device x))
	(set-xview-attr value x WIN_BIT_GRAVITY 'integer #'(lambda (v) (get v 'x-bit-gravity)))))


;;; WINDOW BORDER WIDTH


(defmethod (setf dd-window-border-width) (value (p XView) window)
  (if (or (= value 0) (= value 1))
      (XV:with-xview-lock 
	(let* ((xvo (device window))
	       (id (xview-object-id xvo)))
	  (when id 
	    (xv_set id WIN_BORDER value XV_NULL)
	    (xview-maybe-XFlush (xview-object-xvd xvo)))
	  (setf (xview-window-border-width xvo) value)))
    (error "XView only supports windows with :border-width = 0 or 1"))

  value)

(defmethod dd-window-border-width ((p XView) canvas)
  (xview-window-border-width (device canvas)))


;;; TOP LEVEL WINDOWS


(macrolet
 ((def-accessor (driver initarg string-attribute show-attribute)
    `(progn
       (defmethod ,driver ((p XView) x)
	 (XV:with-xview-lock 
	   (let* ((xvo (device x))
		  (id (xview-object-id xvo)))
	     (if (and id (= FALSE (xv_get id ,show-attribute)))
		 nil
	       (get-xview-initarg-attr x ,string-attribute ,initarg 'string)))))

       (defmethod (setf ,driver) (value (p XView) x)
	 (XV:with-xview-lock 
	   (let* ((xvo (device x))
		  (id (xview-object-id xvo)))
	     (if (and id (null value))
		 (xv_set id ,show-attribute FALSE XV_NULL)
	       (progn
		 (when id (xv_set id ,show-attribute TRUE XV_NULL))
		 (set-xview-initarg-attr value x ,string-attribute ,initarg 'string)))))
	 value))))

 (def-accessor dd-top-level-window-label 
   :label XV_LABEL FRAME_SHOW_LABEL)

 (def-accessor dd-top-level-window-left-footer 
   :left-footer FRAME_LEFT_FOOTER FRAME_SHOW_FOOTER)

 (def-accessor dd-top-level-window-right-footer 
   :right-footer FRAME_RIGHT_FOOTER FRAME_SHOW_FOOTER))


;;; If we're updating the slot only for the sake of clients that rely on (setf mapped)
;;; being called, i.e. this call is in response to a map/unmap notify event, then don't 
;;; actually ask XView to change the state of the window.

(defmethod (setf dd-canvas-mapped) (value (p XView) (x top-level-window))
  (if *notification-only*
      (setf (xview-canvas-mapped (device x)) value)
    (call-next-method)))


(defmethod dd-base-window-closed ((p XView) x)
  (xview-top-level-window-closed (device x)))

(defmethod (setf dd-base-window-closed) (value (p XView) x)
  (unless *notification-only*
    (setf (xview-top-level-window-closed (device x))
	  (set-xview-attr value x FRAME_CLOSED 'boolean)))
  value)


(defmethod dd-top-level-window-busy ((p XView) x)
  (xview-top-level-window-busy (device x)))

(defmethod (setf dd-top-level-window-busy) (value (p XView) x)
  (setf (xview-top-level-window-busy (device x))
	(set-xview-attr value x FRAME_BUSY 'boolean)))


(defmethod dd-top-level-window-owner ((p XView) x)
  (xview-top-level-window-owner (device x)))

(defmethod (setf dd-top-level-window-owner) (value (p XView) x)
  (flet
   ((top-level-window-owner-id (v)
     (or (if v (xview-object-id (device v)))
	 (xview-display-nil-parent-frame (device (display x))))))

   (setf (xview-top-level-window-owner (device x))
	 (set-xview-attr value x XV_OWNER 'integer #'top-level-window-owner-id))))


(defmethod dd-base-window-icon ((p XView) base-window)
  (xview-top-level-window-icon (device base-window)))

;;; This method is a little strange because XView does not support changing a
;;; windows icon.  To compensate for this base-windows are always created with an icon, 
;;; if the application doesn't supply an icon at initialization time we just create 
;;; a blank icon.   To set a base-windows icon we copy the Solo icons image and label 
;;; to the base-windows original icon and we change the xview-object-id of the Solo
;;; icon to the id of the base-windows original icon.

(defmethod (setf dd-base-window-icon) (icon (p XView) w)
  (XV:with-xview-lock 
    (let* ((xvo (device w))
	   (id (xview-object-id xvo)))
      (when id
	(let* ((new-xvi (xv_get id FRAME_ICON))
	       (icon-xvo (device icon))
	       (old-xvi (prog1 
			    (xview-object-id icon-xvo)
			  (setf (xview-object-id icon-xvo) new-xvi))))
	  (xv_set new-xvi
	    WIN_CMS (xv_get old-xvi WIN_CMS)
	    WIN_FOREGROUND_COLOR (xv_get old-xvi WIN_FOREGROUND_COLOR)
	    WIN_BACKGROUND_COLOR (xv_get old-xvi WIN_BACKGROUND_COLOR)
	    ICON_TRANSPARENT (xv_get old-xvi ICON_TRANSPARENT)
	    XV_LABEL (xv_get old-xvi XV_LABEL)
	    ICON_IMAGE (xv_get old-xvi ICON_IMAGE)
	    ICON_MASK_IMAGE (xv_get old-xvi ICON_MASK_IMAGE)
	    XV_NULL)))
      (setf (xview-top-level-window-icon xvo) icon))))


(defmethod dd-base-window-confirm-quit ((p XView) x)
  (xview-top-level-window-confirm-quit (device x)))

(defmethod (setf dd-base-window-confirm-quit) (value (p XView) x)
  (setf (xview-top-level-window-confirm-quit (device x))
	(set-xview-attr value x FRAME_NO_CONFIRM 'boolean #'not)))


;;; Before destroying the base-window we find all of the popup windows that it "owns".
;;; The popups are destroyed after the base-window.

(defmethod dd-destroy-canvas ((p XView) (x base-window))
  (let* ((ownees (mapcan #'(lambda (p)
			     (if (and (typep p 'top-level-window) (eq (owner p) x))
				 (list p)))
			 (children (root-canvas (display x)))))
	 (icon 
	  (xview-top-level-window-icon (device x)))
	 (icon-id 
	  (if icon (xview-object-id (device icon)))))
    (when icon-id
      (xv_set icon-id ICON_IMAGE 0 ICON_MASK_IMAGE 0 XV_NULL))
    (call-next-method)
    (dolist (p ownees)
      (setf (status p) :destroyed))))


;;; ICONS


(defmethod dd-initialize-icon ((p XView) icon &rest initargs &key label &allow-other-keys)
  (setf (device icon) 
	(apply #'make-xview-icon 
	       :label-string (typecase label
			       (string label)
			       (cons (find-if #'stringp label)))
	       :label-image (typecase label
			      (image label)
			      (cons (find-if #'(lambda (x) (typep x 'image)) label)))
	       :allow-other-keys t 
	       initargs)
	(slot-value icon 'status) :initialized))


(defmethod dd-realize-icon ((p XView) icon)
  (XV:with-xview-lock 
    (let* ((xvo (device icon))
	   (display (display icon))
	   (xvd (device display))
	   (colormap (colormap (root-canvas display)))
	   (white (find-color :name :white :colormap colormap))
	   (bg (xview-icon-background xvo))
	   (fg (or (xview-icon-foreground xvo) 
		   (setf (xview-icon-foreground xvo)
			 (find-color :name :black :colormap colormap)))))

      (using-resource (al xview-attr-list-resource (xview-display-root xvd) :icon)
	(push-xview-attrs al 
          WIN_CMS (xview-object-id (device colormap))
	  WIN_FOREGROUND_COLOR (xview-color-index (device fg))
	  WIN_BACKGROUND_COLOR (xview-color-index (device (if (typep bg 'color) bg white)))
	  ICON_TRANSPARENT (if (eq bg :transparent) TRUE FALSE))

	(let* ((string (xview-icon-label-string xvo))
	       (image (xview-icon-label-image xvo))
	       (image-id (if image (xview-object-id (device image))))
	       (mask (xview-icon-clip-mask xvo))
	       (mask-id (if mask (xview-object-id (device mask)))))
	  (when string
	    (push-xview-attrs al XV_LABEL (malloc-foreign-string string)))
	  (when image-id
	    (push-xview-attrs al ICON_IMAGE image-id))
	  (when mask-id
	    (push-xview-attrs al ICON_MASK_IMAGE mask-id)))

	(flush-xview-attr-list al)
	(let ((id (setf (xview-object-id xvo) (xview-attr-list-id al))))
	  (setf (xview-object-xid xvo) (xv_get id XV_XID)
		(xview-object-xvd xvo) xvd
		(xview-object-dsp xvo) (xview-display-dsp xvd)))))))
	      

(defmethod dd-destroy-icon ((p XView) icon)
  (XV:with-xview-lock 
    (let* ((xvo (device icon))
	   (id (xview-object-id xvo)))
      (when id
	(xv_set id ICON_IMAGE 0 ICON_MASK_IMAGE 0 XV_NULL)
	(destroy-xview-object icon xvo id)))))


(defmethod dd-icon-label ((p XView) icon)
  (let* ((xvo (device icon))
	 (string (xview-icon-label-string xvo))
	 (image (xview-icon-label-image xvo)))
    (if (and string image) 
	(list string image)
      (or string image))))

(defmethod (setf dd-icon-label) (label (p XView) icon)
  (XV:with-xview-lock 
    (let* ((xvo (device icon))
	   (id (xview-object-id xvo)))
      (when id
	(let* ((string 
		(typecase label
		  (string label)
		  (cons (find-if #'stringp label))))
	       (image
		(typecase label
		  (image label)
		  (cons (find-if #'(lambda (x) (typep x 'image)) label)))))
	  (when string
	    (setf (xview-icon-label-string xvo)
		  (set-xview-attr string icon XV_LABEL 'string)))
	  (when image
	    (setf (xview-icon-label-image xvo)
		  (set-xview-attr image icon ICON_IMAGE 'image)))))))
  label)



(defmethod dd-icon-foreground ((p XView) icon)
  (XV:with-xview-lock 
    (let* ((xvo (device icon))
	   (id (xview-object-id xvo)))
      (cond 
       ((xview-icon-foreground xvo))
       (id
	(setf (xview-icon-foreground xvo)
	      (find-xview-color icon (xv_get id WIN_FOREGROUND_COLOR) "Icon Foreground")))
       (t nil)))))

 (defmethod (setf dd-icon-foreground) (value (p XView) icon)
   (setf (xview-icon-foreground (device icon))
	 (set-xview-attr value 
			 icon 
			 WIN_FOREGROUND_COLOR 
			 'integer 
			 #'(lambda (v)
			     (xview-color-index (device v))))))


(defmethod dd-icon-background ((p XView) icon)
  (XV:with-xview-lock 
    (let* ((xvo (device icon))
	   (id (xview-object-id xvo)))
      (cond 
       ((xview-icon-background xvo))
       (id
	(setf (xview-icon-background xvo)
	      (if (/= 0 (xv_get id ICON_TRANSPARENT))
		  :transparent
		(find-xview-color icon (xv_get id WIN_BACKGROUND_COLOR) "Icon Background"))))
       (t nil)))))

(defmethod (setf dd-icon-background) (value (p XView) x)
  (XV:with-xview-lock 
    (let* ((xvo (device x))
	   (id (xview-object-id xvo)))
      (when id
	(if (typep value 'color)
	    (xv_set id WIN_BACKGROUND_COLOR (xview-color-index (device value)) XV_NULL)
	  (xv_set id ICON_TRANSPARENT (eq value :transparent) XV_NULL))
	(xview-maybe-XFlush (xview-object-xvd xvo)))
      (setf (xview-icon-background xvo) value))))


(defmethod dd-icon-clip-mask ((p XView) icon)
  (xview-icon-clip-mask (device icon)))

(defmethod (setf dd-icon-clip-mask) (value (p Xview) icon)
  (XV:with-xview-lock 
   (let* ((xvo (device icon))
	  (icon-id (xview-object-id xvo))
	  (mask-id (if value (xview-object-id (device value)))))
     (when (and icon-id mask-id)
       (xv_set icon-id ICON_MASK_IMAGE mask-id XV_NULL)
       (xview-maybe-XFlush (xview-object-xvd xvo)))
     (setf (xview-icon-clip-mask xvo) value))))


