;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)scroll.lisp	3.27 10/11/91


(in-package "LISPVIEW")


;;; SCROLLBAR


(defmethod initialize-instance :after ((sb scrollbar)
				       &rest initargs
				       &key
				       (width 19)
				       (height 100)
				         parent
				       &allow-other-keys)
  (declare (dynamic-extent initargs))
  (apply #'dd-initialize-scrollbar (platform sb) sb :width width :height height initargs)

  (check-arglist (parent (or null canvas)))

  (when parent
    (insert sb :at 0 parent)))


(defmethod initialize-instance :around ((sb scrollbar) &key status &allow-other-keys)
  (prog1
      (call-next-method)
    (when (eq status :realized)
      (setf (status sb) :realized))))


(defmethod (setf status) ((value (eql :realized)) (sb scrollbar))
  (when (eq (status sb) :initialized)
    (let ((parent (parent sb)))
      (when (typep parent 'scrollbar)
	(case (status parent) 
	  (:destroyed 
	   (error "The parent specified for ~S, ~S, has been destroyed" sb parent))
	  (:initialized (realize sb)))))

    (unless (and (slot-boundp sb 'event-dispatch-process)
		 (typep (event-dispatch-process sb) 'event-dispatch-process))
      (setf (event-dispatch-process sb)
	    (find-event-dispatch-process sb)))

    (dd-realize-scrollbar (platform sb) sb)

    (prog1
	(setf (slot-value sb 'status) :realized)
      (let ((mapped (mapped sb)))
	(when mapped 
	  (setf (mapped sb) mapped))))))


(defmethod compute-view-start (client scrollbar motion elevator-position)
  (declare (ignore client scrollbar motion elevator-position))
  nil)
	    

(defmethod receive-event (canvas interest (event scroll-event))
  (declare (ignore interest))
  (scroll canvas (scroll-event-scrollbar event) 
	         (scroll-event-motion event) 
		 (scroll-event-view-start event)))


(defmethod scroll (client scrollbar motion new-view-start)
  (declare (ignore motion))
  (setf (view-start client scrollbar) new-view-start))


(defmethod (setf scrollbar-client) (new-client (sb scrollbar))
  (prog1 
      (setf (slot-value sb 'client) new-client)
    (dd-set-scrollbar-client (platform sb) sb new-client)))


(defmethod children ((x scrollbar)) nil)


(defmethod insert (node where sibling (parent scrollbar))
  (declare (ignore node where sibling))
  (error "Scrollbars can't have children"))


(defmethod insert ((x scrollbar) where sibling new-parent)
  (check-arglist (sibling (or null positive-fixnum tree-node))
		 (new-parent opaque-canvas))
  (call-next-method)
  (when new-parent 
    (dd-insert-scrollbar (platform x) x where sibling new-parent)))


(defmethod withdraw ((x scrollbar) parent1)
  (let ((parent2 (parent x)))
    (when (eq parent1 parent2)
      (when parent2
       (call-next-method)
       (dd-withdraw-scrollbar (platform x) x parent2)))))


(def-solo-accessor BOUNDING-REGION scrollbar
  :type region
  :driver dd-scrollbar-bounding-region)


(def-solo-accessor MAPPED scrollbar
  :driver dd-scrollbar-mapped)


(def-solo-accessor SCROLLBAR-SPLITTABLE scrollbar
  :driver dd-scrollbar-splittable)


(defmethod (setf status) ((value (eql :destroyed)) (sb scrollbar))
  (let ((old-status (status sb)))
    (setf (slot-value sb 'status) :destroyed)
    (withdraw sb (parent sb))
    (when (eq old-status :realized)
      (dd-destroy-scrollbar (platform sb) sb)))
  :destroyed)


(defmethod update-scrollbar ((sb scrollbar))
  (dd-update-scrollbar (platform sb) sb))



;;; VIEWPORT


(defmethod initialize-instance :after ((x viewport) 
				       &key 
				         vertical-scrollbar
					 horizontal-scrollbar
					 view-region
					 output-region
					 container-region
				       &allow-other-keys)
  (check-arglist (vertical-scrollbar (or null vertical-scrollbar))
		 (horizontal-scrollbar (or null horizontal-scrollbar))
		 (view-region (or null region cons))
		 (output-region (or null region cons))
		 (container-region (or null region cons))))



(defmethod (setf status) ((value (eql :realized)) (vp viewport))
  (flet
   ((check-and-maybe-realize (sb id)
      (when (typep sb 'scrollbar) 
	(case (status sb) 
	  (:destroyed 
	   (error "The ~A scrollbar specified for ~S, ~S, has been destroyed" id vp sb))
	  (:initialized (realize sb))))))

   (check-and-maybe-realize (vertical-scrollbar vp) "vertical")
   (check-and-maybe-realize (horizontal-scrollbar vp) "horizontal"))

  (call-next-method))


(def-solo-accessor container-region viewport 
  :type region
  :driver dd-viewport-container-region)


(def-solo-accessor bounding-region viewport 
  :type region
  :driver dd-viewport-bounding-region)


(def-solo-accessor view-region viewport 
  :type region
  :driver dd-viewport-view-region)


(def-solo-accessor output-region viewport 
  :type region
  :driver dd-viewport-output-region)


(def-solo-accessor vertical-scrollbar viewport 
  :type (or null vertical-scrollbar)
  :driver dd-viewport-vertical-scrollbar)


(def-solo-accessor horizontal-scrollbar viewport 
  :type (or null horizontal-scrollbar)
  :driver dd-viewport-horizontal-scrollbar)


(macrolet 
 ((def-accessor (accessor viewport-region hsb-region-edge vsb-region-edge)
    `(progn 

       (defmethod ,accessor ((vp viewport) (sb horizontal-scrollbar))
	 (the region-dimension (,hsb-region-edge (,viewport-region vp))))

       (defmethod (setf ,accessor) (value (vp viewport) (sb horizontal-scrollbar))
	 (check-type value region-dimension)
	 (let ((r (,viewport-region vp)))
	   (prog1
	       (setf (,hsb-region-edge r) value)
	     (setf (,viewport-region vp) r))))

       (defmethod ,accessor ((vp viewport) (sb vertical-scrollbar))
	 (the region-dimension (,vsb-region-edge (,viewport-region vp))))

       (defmethod (setf ,accessor) (value (vp viewport) (sb vertical-scrollbar))
	 (check-type value region-dimension)
	 (let ((r (,viewport-region vp)))
	   (prog1
	       (setf (,vsb-region-edge r) value)
	     (setf (,viewport-region vp) r)))))))
 (progn
   (def-accessor VIEW-MIN    output-region region-left  region-top)
   (def-accessor VIEW-MAX    output-region region-right region-bottom)
   (def-accessor VIEW-START  view-region   region-left  region-top)
   (def-accessor VIEW-LENGTH view-region   region-width region-height)))

(defun view-range (sb)
  (let ((client (scrollbar-client sb)))
    (abs (- (view-min client sb) (view-max client sb)))))



;;;; SCROLLING-WINDOW - Backwards Compatibility Only


(defmethod initialize-instance :after 
  ((x scrolling-window) 
   &rest initargs
   &key 
     viewports 
     viewport-class
   &allow-other-keys)

  (let ((display (display x)))
    (setf (children x) nil
	  (backing-store x) nil
	  (bit-gravity x) nil
	  (border-width x) 0
	  (interests x) nil
	  (cursor x) nil
	  (background x) (find-color :display display 
				     :name "bg1"
				     :if-not-found (find-color :display display 
							       :name "white"))))

  (if viewports
      (unless (and (= (length viewports) 1) (typep (car viewports) 'viewport))
	(error "the value of :viewports must be a list of one viewport"))
    (setf (slot-value x 'viewports)
	  (list (apply #'make-instance viewport-class
		       :status :initialized
		       :parent x
		       :mapped t
		       :left 0 
		       :top 0
		       initargs)))))


(defmethod (setf status) ((value (eql :realized)) (x scrolling-window))
  (let* ((vp (car (slot-value x 'viewports)))
	 (vr (view-region vp))
	 (mapped (mapped x)))
    (setf (mapped x) nil)
    (call-next-method)
    (setf (status vp) :realized)

    (let ((br (bounding-region x)))
      (if (and vr (> (region-width vr) 0) (> (region-height vr) 0))
	  (let ((cr (container-region vp)))
	    (setf (region-width br) (region-width cr)
		  (region-height br) (region-height cr)
		  (bounding-region x) br))
	(setf (region-left br) 0
	      (region-top br) 0
	      (container-region vp) br)))
    
    (setf (mapped x) mapped)
    :realized))


(defmethod (setf bounding-region) (new-br (x scrolling-window))
  (with-output-buffering (display x)
    (prog1
	(call-next-method)
      (let ((cr (make-region :width (region-width new-br)
			     :height (region-height new-br))))
	(setf (container-region (viewport x)) cr)))))


(defmethod viewports ((x scrolling-window)) (copy-list (slot-value x 'viewports)))

(defun viewport (x) (car (viewports x)))

