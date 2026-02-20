;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

(in-package "LISPVIEW")

(export '(list-viewer 
	  exclusive-list-viewer 
	  non-exclusive-list-viewer 
	  lv-n-choices
	  lv-nth-choice
	  lv-choice-height
	  lv-draw-choice
	  lv-highlight-choice
	  lv-select-choice
	  lv-viewable-choices
	  lv-choice-object
	  lv-choice-row
	  lv-choice-highlight
	  lv-choice-region
	  lv-first-viewable-row
	  lv-update-choices
	  viewport
	  view-region
	  value
	  menu))
	       


(defclass viewable-choices ()
  ((viewable-choices :type list :initform nil)))


(defclass select-viewer-choice (mouse-interest) ()
  (:default-initargs
   :event-spec '(() (:left :down))))

(defclass repaint-viewer (damage-interest) ())

(defvar *viewer-interests*
  (mapcar #'make-instance '(select-viewer-choice repaint-viewer)))

(defclass viewer-viewport (viewable-choices viewport)
  ((viewer :type viewer :initarg :viewer :reader viewer)
   (gc :type graphics-context))
  (:default-initargs 
   :border-width 1
   :vertical-scrollbar (make-instance 'vertical-scrollbar)))


(defclass list-viewer (viewable-choices)
  ((lock :initform nil)
   (viewport :type viewer-viewport)
   (n-choices :initarg :n-choices :type fixnum :reader lv-n-choices)
   (value :type list :initform nil)))

(defmacro with-viewer-locked (viewer &body body)
  (let ((viewer-var (gensym)))
    `(let ((,viewer-var ,viewer))
       (MP:with-process-lock ((slot-value ,viewer-var 'lock))
	 ,@body))))

(defmacro choice-region (viewer x y choice)
  `(make-region :width (region-width (view-region (slot-value ,viewer 'viewport)))
		:height (lv-choice-height ,viewer ,choice)
		:left ,x
		:top ,y))

(defclass exclusive-list-viewer (list-viewer) 
  ((selection-required :initarg :selection-required :accessor selection-required))
  (:default-initargs 
   :selection-required nil))

(defclass non-exclusive-list-viewer (list-viewer) ())


(defstruct (viewer-choice (:copier %copy-viewer-choice))
  object
  row 
  region
  highlight)

(defun copy-viewer-choice (choice &optional x y)
  (let ((copy (%copy-viewer-choice choice)))
    (setf (viewer-choice-region copy) 
	  (copy-region (viewer-choice-region copy) :top y :left x))
    copy))
  
(defun render-viewer-choice (viewer canvas choice)
  (let ((object (viewer-choice-object choice))
	(region (viewer-choice-region choice))
	(row (viewer-choice-row choice)))
    (lv-draw-choice viewer canvas (region-left region) (region-top region) object row)
    (when (viewer-choice-highlight choice)
      (lv-highlight-choice viewer canvas region object row :draw))))
  
(macrolet 
 ((def-viewer-choice-accessor (name accessor)
    `(defun ,name (x)
       (check-type x viewer-choice "an element of the list returned by lv-viewable-choices")
       (,accessor x))))
 
 (def-viewer-choice-accessor LV-CHOICE-OBJECT viewer-choice-object)
 (def-viewer-choice-accessor LV-CHOICE-ROW viewer-choice-row)
 (def-viewer-choice-accessor LV-CHOICE-HIGHLIGHT viewer-choice-highlight)
 (def-viewer-choice-accessor LV-CHOICE-REGION viewer-choice-region))


(defvar *updating-viewer-status* nil)

(defmethod (setf status) ((value (eql :realized)) (x viewer-viewport))
  (unless *updating-viewer-status*
    (let ((*updating-viewer-status* t))
      (setf (status (slot-value x 'viewer)) value)))
  (call-next-method)
  (setf (slot-value x 'gc) (make-instance 'graphics-context
			     :display (display x)
			     :foreground (background x))))

(defmethod (setf status) ((value (eql :destroyed)) (x viewer-viewport))
  (unless *updating-viewer-status*
    (let ((*updating-viewer-status* t))
      (setf (status (slot-value x 'viewer)) value)))
  (call-next-method)
  (destroy (slot-value x 'gc)))



(defmethod view-start ((vp viewer-viewport) (sb vertical-scrollbar))
  (let ((x (car (slot-value (slot-value vp 'viewer) 'viewable-choices))))
    (if x (viewer-choice-row x) 0)))
	

(defun setf-viewer-view-start (viewer vp gc old-choices new-choices)
  (let* ((old-first-row (viewer-choice-row (car old-choices)))
	 (last-old-choice (car (last old-choices)))
	 (old-last-row (viewer-choice-row last-old-choice))
	 (new-first-row (viewer-choice-row (car new-choices)))
	 (new-last-row (viewer-choice-row (car (last new-choices))))
	 (choices-region 
	  (make-region :left 0 :top 0 
		       :width (region-width (view-region vp))
		       :bottom (region-bottom (viewer-choice-region last-old-choice)))))
    (if (and (< old-first-row new-last-row) (> old-last-row new-first-row))
	(macrolet 
	 ((row-edge (row region-edge)
	    `(,region-edge 
	      (viewer-choice-region (nth (- ,row new-first-row) new-choices)))))

	 (let ((r (copy-region choices-region)))
	   (if (> new-first-row old-first-row)
	       (setf (region-bottom r) (row-edge old-last-row region-bottom))
	     (setf (region-top r) (row-edge old-first-row region-top)))
	   (copy-area vp vp 
		      0 0 
		      (region-width r) (region-height r) 
		      (region-left r) (region-top r)
		      :gc gc))

	 (let ((r (copy-region choices-region)))
	   (if (> new-first-row old-first-row)
	       (setf (region-top r) (row-edge old-last-row region-bottom))
	     (setf (region-bottom r) (row-edge old-first-row region-top)))
	   (draw-rectangle vp 
			   (region-left r) (region-top r)
			   (region-width r) (region-height r)
			   :gc gc
			   :fill-p t))

	 (multiple-value-bind (first-row last-row)
	     (if (> new-first-row old-first-row)
		 (values (1+ old-last-row) new-last-row)
	       (values new-first-row (1- old-first-row)))
	   (do ((row first-row (1+ row))
		(choices (nthcdr (- first-row new-first-row) new-choices) (cdr choices)))
	       ((> row last-row))
	     (render-viewer-choice viewer vp (car choices)))))
      (progn
	(draw-rectangle vp 0 0 
			(region-width choices-region) (region-height choices-region) 
			:gc gc 
			:fill-p t)
	(dolist (choice new-choices)
	  (render-viewer-choice viewer vp choice))))))



(defmethod (setf view-start) (value (vp viewer-viewport) (sb vertical-scrollbar))
  (let* ((viewer (slot-value vp 'viewer))
	 (new-choices (with-viewer-locked viewer
		        (mapcar #'copy-viewer-choice (slot-value viewer 'viewable-choices)))))
    (with-slots ((old-choices viewable-choices) gc) vp
      (when (and old-choices new-choices)
	(unless (= (viewer-choice-row (car new-choices))
		   (viewer-choice-row (car old-choices)))
	  (with-output-buffering (display vp)
	    (setf-viewer-view-start viewer vp gc old-choices new-choices))
	  (setf old-choices new-choices)))))

  value)




(defmethod view-length ((vp viewer-viewport) (sb vertical-scrollbar))
  (length (slot-value (slot-value vp 'viewer) 'viewable-choices)))
	
(defmethod view-min ((vp viewer-viewport) (sb vertical-scrollbar))
  0)
	
(defmethod view-max ((vp viewer-viewport) (sb vertical-scrollbar))
  (lv-n-choices (slot-value vp 'viewer)))


(defmethod receive-event (vp (i repaint-viewer) event)
  (let ((damage-region (apply #'region-bounding-region (damage-event-regions event)))
	(viewer (slot-value vp 'viewer)))
    (with-output-buffering (display vp)
      (dolist (choice (slot-value vp 'viewable-choices))
	(let ((choice-region (viewer-choice-region choice)))
	  (when (regions-intersect-p damage-region choice-region)
	    (render-viewer-choice viewer vp choice)))))))



(defmethod receive-event (vp (i select-viewer-choice) event)
  (dolist (choice (slot-value vp 'viewable-choices))
    (let ((x (mouse-event-x event))
	  (y (mouse-event-y event)))
      (when (region-contains-xy-p (viewer-choice-region choice) x y)
	(lv-select-choice (slot-value vp 'viewer) vp x y 
			  (viewer-choice-object choice) 
			  (viewer-choice-row choice))
	(return)))))




;;; The method updates the viewers list of viewable choices and returns the row
;;; number of the first visible row.

(defmethod compute-view-start ((client viewer-viewport) scrollbar motion point)
  (declare (ignore scrollbar))
  (let* ((viewer (slot-value client 'viewer))
	 (choices (slot-value viewer 'viewable-choices)))
    (if (null choices)
	0
      (progn
	(macrolet 
	 ((first-row ()
	    `(viewer-choice-row (car choices)))
	  (last-row () 
	   `(viewer-choice-row (car (last choices)))))

	 (case motion
	   (:absolute (scroll-viewer-forward viewer point))
	   (:to-start (scroll-viewer-forward viewer 0))
	   (:line-forward (scroll-viewer-forward viewer (1+ (first-row))))
	   (:line-backward (scroll-viewer-forward viewer (1- (first-row))))
	   (:page-forward (scroll-viewer-forward viewer (1+ (last-row))))
	   (:page-backward (scroll-viewer-backward viewer (1- (first-row))))
	   (:to-end (scroll-viewer-backward viewer (1- (lv-n-choices viewer))))
	   (:point-to-view-start (scroll-viewer-forward viewer point))
	   (:view-start-to-point (scroll-viewer-forward viewer point))))

	(viewer-choice-row (car (slot-value viewer 'viewable-choices)))))))



(defun scroll-viewer-forward (viewer first-row)
  (with-slots (viewport viewable-choices value) viewer
    (let ((n-choices (lv-n-choices viewer)))
      (when (and (>= first-row 0) (< first-row n-choices))
	(let ((view-height (region-height (view-region viewport)))
	      (y 0)
	      (choices nil)
	      (choices-cdr viewable-choices))
	  (do ((row first-row (1+ row)))
	      ((or (<= view-height 0) (>= row n-choices)))
	    (let* ((choice 
		    (or (do ((lp choices-cdr (cdr lp)))
			    ((or (null lp) (> (viewer-choice-row (car lp)) row))
			     (progn (setf choices-cdr lp) nil))
			  (when (= row (viewer-choice-row (car lp)))
			    (setf choices-cdr (cdr lp))
			    (return (copy-viewer-choice (car lp) 0 y))))
			(let ((object (lv-nth-choice viewer row)))
			  (make-viewer-choice 
			    :object object
			    :row row 
			    :region (choice-region viewer 0 y object)
			    :highlight (member object value :test #'eq)))))
		   (r (viewer-choice-region choice)))
	      (decf view-height (region-height r))
	      (setf y (region-bottom r))
	      (push choice choices)))

	  (with-viewer-locked viewer
	    (setf viewable-choices (nreverse choices))))))))



(defun scroll-viewer-backward (viewer last-row)
  (with-slots (viewport viewable-choices value) viewer
    (when (>= last-row 0)
      (let* ((vr (view-region viewport))
	     (view-height (region-height vr))
	     (choices nil))
	(do ((row last-row (1- row)))
	    ((or (<= view-height 0) (< row 0)))
	  (let* ((choice 
		  (let* ((object (lv-nth-choice viewer row))
			 (region (choice-region viewer 0 0 object)))
		    (make-viewer-choice 
		      :object object 
		      :row row
		      :region region
		      :highlight (member object value :test #'eq))))
		 (r (viewer-choice-region choice)))
	    (decf view-height (region-height r))
	    (push choice choices)))

	(if (> view-height 0)
	    (scroll-viewer-forward viewer 0)
	  (let* ((r (viewer-choice-region (car (setf choices (nreverse choices)))))
		 (y (progn 
		      (setf (region-bottom r) (region-bottom vr))
		      (region-top r))))
	    (dolist (choice (cdr choices))
	      (let ((r (viewer-choice-region choice)))
		(setf (region-bottom r) y
		      y (region-top r))))

	    (with-viewer-locked viewer
   	      (setf viewable-choices (nreverse choices)))))))))


(defmethod initialize-instance :after ((v list-viewer)
				       &rest initargs
				       &key 
				         parent
					 (mapped t)
					 interests
					 view-width view-height
					 (first-viewable-row 0)
					 n-choices)
  (check-arglist (first-viewable-row (integer 0 *))
		 (n-choices (integer 0 *)))
  
  (with-slots (viewport viewable-choices) v
    (setf viewport (make-instance 'viewer-viewport
		     :viewer v
		     :parent parent
		     :view-region (list :width view-width :height view-height)
		     :container-region initargs
		     :backing-store nil
		     :interests (append *viewer-interests* interests)
		     :mapped nil))
    (scroll-viewer-forward v first-viewable-row)
    (setf (slot-value viewport 'viewable-choices) (copy-list viewable-choices))
    (update-scrollbar (vertical-scrollbar viewport))
    (setf (mapped viewport) mapped)))


(defmethod lv-viewable-choices ((v list-viewer))
  (copy-list (slot-value (slot-value v 'viewport) 'viewable-choices)))


(defmethod lv-first-viewable-row ((v list-viewer))
  (let ((choice (car (slot-value (slot-value v 'viewport) 'viewable-choices))))
    (if choice
	(values (viewer-choice-row choice)
		(viewer-choice-object choice))
      (values 0 nil))))

(defmethod (setf lv-first-viewable-row) (value (v list-viewer))
  (check-type value integer)
  (scroll-viewer-forward v value)
  (with-slots (viewport) v
    (setf (view-start viewport (vertical-scrollbar viewport)) value))
  value)
  

(defmethod view-region ((v list-viewer))
  (view-region (slot-value v 'viewport)))

(defmethod (setf view-region) (value (v list-viewer))
  (check-type value region)
  (let* ((vp (slot-value v 'viewport))
	 (vr (view-region vp)))
    (setf (region-width vr) (region-width value)
	  (region-height vr) (region-height value)
	  (view-region vp) vr
	  (output-region vp) vr)
    (scroll-viewer-forward v (lv-first-viewable-row v)))
  value)


(defmethod display ((v list-viewer)) 
  (display (slot-value v 'viewport)))


(defmethod bounding-region ((v list-viewer))
  (container-region (slot-value v 'viewport)))


(defmethod (setf bounding-region) (new-br (v list-viewer))
  (let* ((vp (slot-value v 'viewport))
	 (old-br (container-region vp)))
    (when (or (/= (region-width new-br) (region-width old-br))
	      (/= (region-height new-br) (region-height old-br)))
      (with-output-buffering (display v)
	(setf (container-region vp) new-br
	      (output-region vp) (view-region vp))
	(lv-update-choices v))))

  new-br)


(defmethod mapped ((v list-viewer))
  (mapped (slot-value v 'viewport)))

(defmethod (setf mapped) (value (v list-viewer))
  (setf (mapped (slot-value v 'viewport)) value))


(defmethod status ((v list-viewer))
  (status (slot-value v 'viewport)))

(defmethod (setf status) (status (v list-viewer))
  (unless *updating-viewer-status*
    (let ((*updating-viewer-status* t))
      (setf (status (slot-value v 'viewport)) status))))


(defmethod lv-select-choice ((v exclusive-list-viewer) canvas x y choice row)
  (declare (ignore canvas x y row))
  (setf (value v) (cond
		   ((selection-required v) choice)
		   ((eq choice (value v)) nil)
		   (t choice))))


(defmethod lv-select-choice ((v non-exclusive-list-viewer) canvas x y choice row)
  (declare (ignore canvas x y row))
  (if (find choice (value v) :test #'eq)
      (setf (value v) (remove choice (value v) :test #'eq))
    (push choice (value v))))


(defmethod value ((v non-exclusive-list-viewer))
  (slot-value v 'value))

(defmethod value ((v exclusive-list-viewer))
  (car (slot-value v 'value)))


(defun maybe-highlight-choice (viewer object op)
  (with-slots (viewport (viewer-choices viewable-choices)) viewer
    (with-slots ((viewport-choices viewable-choices)) viewport
     (let ((choice (find object viewer-choices :key #'viewer-choice-object :test #'eq)))
       (when choice
	 (setf (viewer-choice-highlight choice) (eq op :draw))
	 (lv-highlight-choice viewer viewport 
			      (viewer-choice-region choice)
			      (viewer-choice-object choice)
			      (viewer-choice-row choice)
			      op)))
     (let ((choice (find object viewport-choices :key #'viewer-choice-object :test #'eq)))
       (when choice
	 (setf (viewer-choice-highlight choice) (eq op :draw)))))))


(defmethod (setf value) (new-value (v non-exclusive-list-viewer))
  (with-slots ((old-value value)) v
    (dolist (choice (set-difference old-value new-value))
      (maybe-highlight-choice v choice :erase))
    (dolist (choice (set-difference new-value old-value))
      (maybe-highlight-choice v choice :draw))
    (setf old-value new-value)))



(defmethod (setf value) (new-value (v exclusive-list-viewer))
  (with-slots ((old-value value)) v
    (maybe-highlight-choice v (car old-value) :erase)
    (setf old-value (list new-value))
    (maybe-highlight-choice v new-value :draw)))



(defmethod lv-highlight-choice ((v list-viewer) viewport region choice row operation)
  (declare (ignore row choice))
  (draw-rectangle 
     viewport
     (region-left region) (region-top region)
     (1- (region-width region)) (1- (region-height region))
     :gc (slot-value viewport 'gc)
     :foreground (if (eq operation :draw) 
		     (foreground viewport) 
		   (background viewport))))



(defmethod lv-update-choices ((v list-viewer) 
			      &key 
			        (n-choices (lv-n-choices v))
				(first-viewable-row 
				 (min (lv-first-viewable-row v) (1- n-choices))))
  (with-viewer-locked v
    (with-slots (viewable-choices viewport) v
      (with-output-buffering (display v)
	(setf (slot-value v 'n-choices) n-choices
	      viewable-choices nil
	      (lv-first-viewable-row v) first-viewable-row
	      (slot-value viewport 'viewable-choices) (copy-list viewable-choices))
	(update-scrollbar (vertical-scrollbar viewport))
	(clear viewport)
	(send-event viewport (make-damage-event
			       :regions (list (view-region viewport))))))))
