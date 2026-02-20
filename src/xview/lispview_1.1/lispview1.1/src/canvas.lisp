;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;%W %G


;;; Solo Bounding-Region, Canvas, Window, and Icon Interface


(in-package "LISPVIEW")



;;; BOUNDING-REGION 


;;; Return a property list that contains any or all of - :left :bottom :right 
;;; :top :width :height.  Only properties that are specified by keyword arguments
;;; or can be computed from the keyword arguments will be returned.  For example:
;;;
;;; (apply #'bounding-region-spec '(:left 10 :right 41 :top 31)) => 
;;; (:left 10 :right 41 :width 31 :top 31)


(defun bounding-region-spec (&key 
			       bounding-region
			       left bottom right top width height
			     &allow-other-keys)
  (if bounding-region 
      (macrolet 
       ((edge (name)
	  (let ((keyword (intern (string name) (find-package :keyword)))
		(region-edge (intern (format nil "REGION-~A" name))))
	    `(list ,keyword (,region-edge bounding-region)))))

       (nconc (edge left) (edge bottom) (edge right) (edge top) (edge width) (edge height)))
    (macrolet 
     ((edge (name)
	(let ((keyword (intern (string name) (find-package :keyword))))
	  `(if ,name (list ,keyword ,name)))))
     (with-default-region-dimensions (width height left top right bottom)
	(nconc (edge left) (edge bottom) (edge right) (edge top) (edge width) (edge height))))))   


;;; Non nil if any of the bounding-region keywords are present and non nil.

(defun bounding-region-spec-p (&key 
			         bounding-region
				 left bottom right top width height
			       &allow-other-keys)
  (or bounding-region left bottom right top width height))



;;; CANVAS


(defmethod initialize-instance :after ((x canvas) 
				       &rest initargs 
				       &key 
				         (parent (root-canvas (default-display)))
					 children 
					 interests
					 cursor
				       &allow-other-keys)
  (declare (dynamic-extent initargs))

  (apply #'dd-initialize-canvas (platform x) x initargs)

  (check-arglist (parent (or null canvas))
		 (children list)
		 (interests list)
		 (cursor (or null cursor)))

  (when parent
    (insert x :at 0 parent))
  (dolist (child (reverse children))
    (insert child :at 0 x))
  (dolist (interest interests)
    (insert interest :at 0 x)))


(defmethod initialize-instance :after ((x opaque-canvas) 
				       &key 
				         parent 
					 depth
					 foreground
					 background
					 backing-store
					 bit-gravity
					 colormap
				       &allow-other-keys)
  (check-arglist (parent (or null opaque-canvas))
		 (depth (or null fixnum))
		 (foreground (or null color))
		 (background (or null color))
		 (backing-store backing-store)
		 (bit-gravity bit-gravity)
		 (colormap (or null colormap))))


(defmethod initialize-instance :around ((x canvas) &key status &allow-other-keys)
  (prog1
      (call-next-method)
    (when (eq status :realized)
      (setf (status x) :realized))))


;;; Realize the canvas, realize all of its children, and then map the
;;; canvas if neccessary.

(defmethod (setf status) ((value (eql :realized)) (x canvas))
  (when (eq (status x) :initialized)
      (unless (and (slot-boundp x 'event-dispatch-process)
		   (typep (event-dispatch-process x) 'event-dispatch-process))
	(setf (event-dispatch-process x)
	      (find-event-dispatch-process x)))

      (flet
       ((check-and-maybe-realize (object type id)
	  (when (typep object type) 
	    (case (status object) 
	      (:destroyed 
	       (error "The ~A specified for ~S, ~S, has been destroyed" id x object))
	      (:initialized (realize object))))))

       (check-and-maybe-realize (parent x) 'canvas "parent")
       (check-and-maybe-realize (cursor x) 'cursor "cursor"))

      (dd-realize-canvas (platform x) x)

      (prog1
	  (setf (slot-value x 'status) :realized)
	(dolist (child (nreverse (children x)) )
	  (case (status child)
	    (:initialized (realize child))
	    (:realized (insert child :at 0 x))))
	(let ((mapped (mapped x)))
	  (when mapped 
	    (setf (mapped x) mapped))))))


(defmethod (setf status) ((value (eql :destroyed)) (c canvas))
  (prog1
      (setf (slot-value c 'status) :destroyed)
    (let ((parent (parent c)))
      (withdraw c parent)
      (dolist (child (children c))
	(setf (status child) :destroyed))
      (dd-destroy-canvas (platform c) c))))



;;; All of the canvas accessors defined below just foward to a driver
;;; routine named dd-class-slot, e.g. dd-opaque-canvas-depth.
;;;
;;; The accessor for CURSOR is defined in cursor.lisp

(def-solo-accessor BOUNDING-REGION canvas
  :type region
  :driver dd-canvas-bounding-region)

(def-solo-accessor DEPTH opaque-canvas 
  :type (or null positive-fixnum)
  :driver dd-opaque-canvas-depth)

(def-solo-accessor MAPPED canvas 
  :driver dd-canvas-mapped)

(def-solo-accessor FOREGROUND opaque-canvas 
  :type (or null color)
  :driver dd-opaque-canvas-foreground)

(def-solo-accessor BACKGROUND opaque-canvas 
  :type (or null color)
  :driver dd-opaque-canvas-background)

(def-solo-accessor BACKING-STORE opaque-canvas 
  :type backing-store 
  :driver dd-opaque-canvas-backing-store)

(def-solo-accessor BIT-GRAVITY opaque-canvas 
  :type bit-gravity 
  :driver dd-opaque-canvas-bit-gravity)

(def-solo-accessor SAVE-UNDER opaque-canvas 
  :driver dd-opaque-canvas-save-under)



;;; Visual

(defmethod visual ((x opaque-canvas))
  (dd-opaque-canvas-visual (platform x) x))


(defmethod (setf visual) (value (x opaque-canvas()))
  (let* ((depth (depth x))
	 (supported-visuals (cdr (assoc depth (supported-depths (display x)) :test #'=))))
    (unless (and (typep value 'visual)
		 (or (null depth)
		     (dolist (visual supported-visuals NIL)
		       (when (typep value (class-of visual))
			 (return T)))))
      (error "~S is not a supported visual type for ~S" value x)))
  (setf (dd-opaque-canvas-visual (platform x) x) value))
      

  

;;; Event Dispatch Process


(defun make-event-dispatch-process ()
  (let ((p (make-process :name "LispView Local Event Dispatch"
			 :function 'event-dispatch-loop)))
    (setf (process-event-queue p) (make-instance 'queue))
    p))


;;; Return the event dispatch process that belongs to the first ancestor that
;;; has a live one or the event dispatcher for the root-canvas if that's live
;;; or a new process.

(defmethod find-event-dispatch-process ((ed event-dispatch))
  (or (let ((process (if (slot-boundp ed 'event-dispatch-process)
			 (event-dispatch-process ed))))
	(if (typep process 'event-dispatch-process)
	    process))
      (if (parent ed) 
	  (find-event-dispatch-process (parent ed))
	(let* ((root (root-canvas (display ed)))
	       (process (event-dispatch-process root)))
	  (if (typep process 'event-dispatch-process)
	      process
	    (setf (event-dispatch-process root) (make-event-dispatch-process)))))))


;;; Each event dispatching process is associated with only one 
;;; event queue, this event queue is typically stored on the the
;;; processes plist.  

(defmethod (setf event-dispatch-process) (process (ed event-dispatch))
  (check-type process event-dispatch-process)
  (unless (process-event-queue process)
    (setf (process-event-queue process) (make-instance 'queue)))
  (setf (slot-value ed 'event-dispatch-queue) (process-event-queue process)
	(slot-value ed 'event-dispatch-process) process))



;;; Canvas Tree - parent, children, insert, withdraw


(defmethod withdraw ((x tree-node) parent)
  (check-arglist (parent tree-node))

  (setf (slot-value parent 'children) (delete x (slot-value parent 'children))
	(slot-value x 'parent) nil))


(defmethod insert ((x tree-node) where sibling new-parent)
  (check-arglist (where insert-relation)
		 (sibling (or null number tree-node))
		 (new-parent tree-node))

  (let* ((children (children new-parent))
	 (old-parent (parent x))
	 (action (cond 
		  ((and old-parent (not (eq old-parent new-parent)))
		   (withdraw x old-parent)
		   :move)
		  ((eq old-parent new-parent)
		   (setq children (delete x children))
		   :reorder)
		  (t ;; (null old-parent)
		   :insert))))
    (setf children (list-insert x where sibling children))
    (multiple-value-prog1
	(values children action)
      (setf (slot-value new-parent 'children) children
	    (slot-value x 'parent) new-parent))))


;;; If the node already has a non nil parent then withdraw it from the tree
;;; and then insert in its new home, if the nodes parent is nil then just
;;; insert.  Do nothing if the nodes parent is already eq to new-parent.

(defmethod (setf parent) (new-parent (x tree-node))
  (check-arglist (new-parent tree-node))

  (unless (eq new-parent (parent x))
    (insert x :after nil new-parent))
  new-parent)


(defmethod (setf parent) ((new-parent (eql nil)) (x tree-node))
  (let ((old-parent (parent x)))
    (when old-parent
      (withdraw x old-parent))))



;;; 1 - Each orphan has it's parent set to nil with withdraw
;;; 2 - The adpoted children with parents are removed from their 
;;;     original homes with withdraw.
;;; 3 - The new-children are added one at a time with insert.
;;;
;;; Step 3 could be substantially improved.  Ideally one would find the
;;; minimum number of insertions neccessary to reorder the original children
;;; and add the adopted children.  

(defmethod (setf children) (new-children (parent tree-node))
  (let ((orphans (set-difference (slot-value parent 'children) new-children :test #'eq))
	(adoptees (remove parent new-children :key #'parent :test #'eq)))
    (dolist (orphan orphans)
      (withdraw orphan parent))
    (dolist (adoptee adoptees)
      (let ((old-parent (parent adoptee)))
	(when old-parent
	  (withdraw adoptee old-parent))))
    (dolist (child (setf new-children (nreverse new-children)) (nreverse new-children))
      (insert child :after nil parent))))
  

(defmethod (setf children) (new-children (parent (eql nil)))
  (dolist (child new-children new-children)
    (when (parent child)
      (withdraw child (parent child)))))



(defmethod insert ((x canvas) where sibling new-parent)
  (check-arglist (sibling (or null positive-fixnum canvas))
		 (new-parent canvas))
  (prog1
      (call-next-method)
    (dd-insert-canvas (platform x) x where sibling new-parent)))


(defmethod withdraw ((x canvas) parent)
  (declare (ignore parent))
  (let ((parent (parent x)))
    (when parent
      (dd-withdraw-canvas (platform x) x parent)
      (call-next-method))))



(defun expose (canvas)
  (insert canvas :after nil (parent canvas)))

(defun bury (canvas)
  (insert canvas :before nil (parent canvas)))



;;; Root-Canvases

(defmethod (setf mapped) ((mapped (eql nil)) (rc root-canvas))
  (error "Can't unmap a root-canvas"))

(defmethod (setf mapped) (mapped (rc root-canvas))
  (declare (ignore mapped)))

(defmethod (setf status) ((value (eql :destroyed)) (rc root-canvas))
  (error "Can't destroy a root-canvas"))

(macrolet 
 ((def-cant-setf-slot-method (slot)
    `(defmethod (setf ,slot) (x (rc root-canvas))
       (declare (ignore x))
       (error ,(format nil "Can't set the ~A slot of a root-canvas" slot)))))
  (def-cant-setf-slot-method parent)
  (def-cant-setf-slot-method bounding-region)
  (def-cant-setf-slot-method backing-store)
  (def-cant-setf-slot-method bit-gravity)
  (def-cant-setf-slot-method interests))



;;; Windows, Top Level Windows

(def-solo-accessor BORDER-WIDTH window :type positive-fixnum 
  :driver dd-window-border-width)

(def-solo-accessor LABEL top-level-window :type string
  :driver dd-top-level-window-label)

(def-solo-accessor CLOSED base-window :type boolean
  :driver dd-base-window-closed)

(def-solo-accessor BUSY top-level-window 
  :driver dd-top-level-window-busy)

(def-solo-accessor OWNER top-level-window 
  :type (or null top-level-window)
  :driver dd-top-level-window-owner)

(def-solo-accessor LEFT-FOOTER top-level-window :type (or null string)
  :driver dd-top-level-window-left-footer)

(def-solo-accessor RIGHT-FOOTER top-level-window :type (or null string)
  :driver dd-top-level-window-right-footer)

(def-solo-accessor ICON base-window :type (or null icon)
  :driver dd-base-window-icon)

(def-solo-accessor CONFIRM-QUIT base-window 
  :driver dd-base-window-confirm-quit)

(def-solo-accessor KEYBOARD-FOCUS-MODE base-window :type keyboard-focus-mode
  :driver dd-keyboard-focus-mode)


(defmethod closed ((w popup-window))
  (let ((owner (owner w)))
    (if (typep owner 'base-window)
        (closed owner)
      (not (mapped w)))))


(defmethod (setf status) ((value (eql :destroyed)) (x base-window))
  (if (eq (status x) :realized)
      (macrolet ((funcallable-p (f) `(if (symbolp ,f) (fboundp ,f) (functionp ,f))))
	(let ((confirm-quit (confirm-quit x)))
	  (when (if (funcallable-p confirm-quit) (funcall confirm-quit x) t)
	    (call-next-method))))
    (call-next-method)))



(defvar *notification-only* nil)

(defmethod receive-event ((window base-window) interest (event closed-notification-event))
  (declare (ignore interest))
  (let ((*notification-only* t))
    (setf (closed window) (closed-notification-event-closed event))))

(defmethod receive-event ((window popup-window) interest (event closed-notification-event))
  (declare (ignore interest))
  (let ((*notification-only* t))
    (setf (mapped window) (not (closed-notification-event-closed event)))))




(defmethod receive-event (window interest (event bounding-region-notification-event))
  (declare (ignore interest))
  (let ((r (bounding-region-notification-event-region event)))
    (setf (bounding-region window) 
	  (make-notification-region (region-min-x r) (region-min-y r)
				    (region-max-x r) (region-max-y r)))))


(defmethod receive-event (window interest (event status-notification-event))
  (declare (ignore interest))
  (case (status-notification-event-status event)
    (:destroyed
     (setf (status window) :destroyed))))



;;; Icons

(defmethod initialize-instance :after ((x icon) 
				       &rest initargs
				       &key
				         foreground
					 background
					 label
					 clip-mask
				       &allow-other-keys)
  (declare (dynamic-extent initargs))

  (check-arglist (foreground (or null color))
		 (background (or null color (member :transparent)))
		 (label (satisfies icon-label-p))
		 (clip-mask (or null (satisfies bitmap-p))))

  (apply #'dd-initialize-icon (platform x) x initargs))


(defmethod initialize-instance :around ((i icon) &key status &allow-other-keys)
  (prog1
      (call-next-method)
    (when (eq status :realized)
      (setf (status i) :realized))))


(defmethod (setf status) ((value (eql :realized)) (i icon))
  (when (eq (status i) :initialized)
    (dd-realize-icon (platform i) i))
  (setf (slot-value i 'status) :realized))

(defmethod (setf status) ((value (eql :destroyed)) (i icon))
  (let ((old-status (status i)))
    (setf (slot-value i 'status) :destroyed)
    (when (eq old-status :realized)
      (dd-destroy-icon (platform i) i)))
  :destroyed)


(def-solo-accessor LABEL icon 
  :type (satisfies icon-label-p)
  :driver dd-icon-label)


(def-solo-accessor FOREGROUND icon 
  :type (or null color)
  :driver dd-icon-foreground)


(def-solo-accessor BACKGROUND icon 
  :type (or null color (member :transparent))
  :driver dd-icon-background)


(def-solo-accessor CLIP-MASK icon 
  :type (or null (satisfies bitmap-p))
  :driver dd-icon-clip-mask)


  



