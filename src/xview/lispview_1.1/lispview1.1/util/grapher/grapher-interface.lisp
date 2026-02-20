;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;;  File: grapher-interface.lisp
;;;;
;;;;  Author: Philip McBride
;;;;
;;;;  This file contains the graph interface code.  This is the code
;;;;  that handles the displaying of the graph, the input and output
;;;;  of keyboard and mouse events, and node selections, menus, and
;;;;  moving.  Also, temporarily, it contains the buffer code and
;;;;  classes and the interest classes...
;;;;  Also, some temporary window classes...
;;;;
;;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;;	See LEGAL_NOTICE file for terms of the license.
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package :grapher)

;;;
;;; re-dislpay method ... used to clear and then repaint the graph 
;;;  (note that the damage event causes the graph to be displayed via 
;;;   display--see below)
;;;
(defmethod re-display ((graph graph-layout))
  (let ((canvas (canvas (buffer graph))))
    (let ((vregion (view-region canvas)))
      (draw-rectangle canvas (region-left vregion)
		      (region-top vregion)
		      (region-width vregion)
		      (region-height vregion)
		      :fill-p t
		      :foreground (background canvas)
		      :operation #.boole-1)    
      (update-gr-output graph canvas)
      (send-event canvas
		  (make-damage-event :regions (list vregion))))))


;;;
;;; display methods
;;;

;; display a graph
(defmethod display ((graph graph-layout) (display drawable) (region region))
  (loop for arc in (arcs graph) do (display arc display region))
  (loop for node in (allnodes graph) do (display node display region)))

;; display a node
(defmethod display ((node node) (display drawable) (region region))
  (when (and (display-p node) 
	     (node-inclusion node region))
    (clear-node node display)
    (display-border node display)
    (display-label node display)
    (when (selected node)
      (highlight node (graph (current-buffer display))))))

;; display an arc
(defmethod display ((arc arc) (display drawable) (region region))
  (when (and (display-p (tonode arc))
	     (display-p (fromnode arc))
	     (arc-inclusion arc region))
    (display-arc arc display)))

(defmethod node-inclusion ((node node) (region region))
  (regions-intersect-p region (region node)))

(defmethod arc-inclusion ((arc arc) (region region))
  (regions-intersect-p region (region arc)))

(defmethod display-label ((node string-node) (display drawable))
  (declare (restrictive-ftype (function (fixnum &rest fixnum) fixnum) -))
  (let ((gc (g-c node)))
    (draw-string display (x node) (- (y node) (font-descent (font gc)))
		 (label node) :gc gc)))

;; clear region around region
(defmethod clear-node ((node node) (display drawable))
  (let ((region (region node)))
    (when region
      (draw-rectangle display (- (region-left region) 1)
		      (- (region-top region) 1)
		      (+ (region-width region) 1)
		      (+ (region-height region) 1)
		      :fill-p t
;		      :forground (background display)
		      :operation #.boole-clr
))))

(defmethod get-depth-label ((node string-node) (display drawable))
  (let* ((graph (graph (current-buffer (tool display))))
	 (realgraph (associated-graph node graph))
	 (subs (children-nodes node)))
    (if (or (expand-continuation node)
	    (and subs
		 (loop for sub in subs
		       never (display-p sub))))
	(get-graph-depth-label node realgraph)
        (label node))))

(defgeneric get-graph-depth-label (node graph)
  (:method ((node string-node) (graph graph-layout))
    (concatenate 'string (label node) "..."))
  (:method ((node string-node) (graph right-left-layout))
    (concatenate 'string "..." (label node))))

(defmethod display-label ((node image-node) (display drawable))
  (copy-area (label node) display 0 0 (width node)
	     (height node) (x node) (y node)))

(defmethod display-arc ((arc arc) (display drawable))
  (if (back-link arc)
      (display-back-arc arc display)
      (draw-line display (from-x arc) (from-y arc) 
		 (to-x arc) (to-y arc) :gc (g-c arc))))

;;;
;;; Drawing backward arcs in the grapher.  Algorithm by Alan Kostinsky.
;;;
;;; Given two nodes draw an arc made up of a fragment of a circle.  That
;;; is, give draw-arc what it needs.  First the x function draw-arc wants
;;; to have a circle bounded by a rectangle.  It wants the x,y point cor-
;;; responding to the upper left of the rectangle; it wants the starting
;;; position of the arc in the form of the angle from 3 o'clock; it wants
;;; the extent between the starting angle and the ending angle of the arc;
;;; and the function wants the width and height of the rectangle around
;;; the circle.  (These angles are in degrees.)
;;;
;;; We make several simplifying assumptions.  First we assume that the 
;;; triangle made from the given two points and the center of the circle 
;;; is equalateral.  That allows us to calculate the center of our circle
;;; by the following:  center-x = ((x2 + x1) - ((sqrt 3) * (y2 - y1)))/2
;;; and center-y = ((y2 + y1) + ((sqrt 3) * (x2 - x1)))/2.  And once we
;;; have the center we can calculate the width and height of the rectangle
;;; from the radius of the circle which is calculated by the sqrt of the
;;; sum of the sqares of the differences of the center point and either of
;;; the given points (i.e., (sqrt ((center-y - y2)**2 + (x2 - center-x)**2))).
;;; And from this we can also calculate the origin of the rectangle.  Now
;;; the only thing left is the starting angle and extent angle of the arc.
;;; The starting angle is the (arctan (center-y - y2)/(x2 - center-x)).
;;; (In our case, we want degrees so we must multiply this by 180/pi.)
;;; And finally, the extent is fixed at 60 degrees since we have choosen
;;; and equalateral triangle.
;;;
;;; There is a very different approach when the two nodes are the same.
;;; In that case we want a full circle draw of fixed size. 
;;;
;;; Note, we have not addressed the case when the x's are the same while
;;; the y's are different for the two given nodes.

;; The constants used by drawing the full simi-circle
(defconstant xsimidiff 11)
(defconstant ysimidiff 23)
(defconstant simidiam 25)

;; The constants used by drawing a back arc.
(defconstant sqrt-of-3 (sqrt 3))
(defconstant pi-into-180 (/ 180 pi))
(defconstant arc-extent 60)

;; The method for drawing back arcs.  This handles the case when
;; the arc is from one node to another and when the arc is from
;; a node to itself.
(defmethod display-back-arc ((arc arc) (display drawable))
  ;; if the nodes are the same, draw a simple, fixed simi-circle
  ;; otherwise draw a more complex arc from one node to the other.
  (if (eq (fromnode arc) (tonode arc))
      ;; then... draw the simi-circle
      (let ((x (from-x arc))
	    (y (from-y arc)))
	(draw-arc display (- x xsimidiff) (- y ysimidiff) 
		  simidiam simidiam 0 360 :gc (g-c arc)))
      ;; else... draw the full back arc.
      (let ((x1 (from-x arc))
	    (x2 (to-x arc))
	    (y1 (from-y arc))
	    (y2 (to-y arc))
	    temp)
	;; make sure x1,y1 is the point farthest to the left.
	(when (> x1 x2)
	  (setf temp x1
		x1 x2
		x2 temp
		temp y1
		y1 y2
		y2 temp))
	;; calculate the subexpressions needed for center point calculation
	(let ((x-plus (+ x2 x1))
	      (x-diff (- x2 x1))
	      (y-diff (- y2 y1))
	      (y-plus (+ y2 y1)))
	  ;; calculate the center of the circle.
	  (let ((orx (/ (- x-plus (* y-diff sqrt-of-3)) 2))
		(ory (/ (+ y-plus (* x-diff sqrt-of-3)) 2)))
	    ;; calculate differences used for theta calc.
	    (let ((Y2-diff (- ory y2))
		  (X2-diff (- x2 orx)))
	      ;; calculate the start angle.   --error check, x2, y2 can't both be 0
	      (let ((theta1 (* pi-into-180 (if (= 0 Y2-diff X2-diff)
					       0
					       (atan Y2-diff X2-diff))))
		    (theta2 arc-extent))
		;; radius of circle
		(let ((r (sqrt (+ (* X2-diff X2-diff)
				  (* Y2-diff Y2-diff)))))
		  ;; the x,y origin of the rectangle (square) around 
		  ;; the circle and the diameter of the circle.
		  (let ((X (- orx r))
			(Y (- ory r))
			(d (+ r r)))
		    ;; draw the arc.
		    (draw-arc display (floor X)  (floor Y) (floor d) 
			      (floor d) (floor theta1) (floor theta2)
			      :gc (g-c arc)))))))))))


(defmethod display-border ((node node) (display drawable))
  (let ((border (+ (border node)
		   (if (or (is-duplicated-by node) (duplicates node))
		       1
		       0))))
    (when (> border 0)
      (draw-rectangle display (- (x node) 1) (- (y node) (height node) 1)
		      (+ (width node) 1) (+ (height node) 1)
		      :line-width border))))
    

;;;
;;; Default grapher window methods (for making menus and windows)
;;; (Note make method called by initialize-instance :after method
;;;  on graphs is push-graph-window--the entry point.  See it below)
;;;
;;; An application really wants to specialize on  the following:
;;; make-panel-menu, make-graph-menus, and make-graph-window.
;;;

;;; Panel menu default is nil.  When a panel
;;; of buttons is desired, this could produce
;;; a function that when subsequently called,
;;; after the window is constructed, could
;;; construct the desired buttons.
(defmethod make-panel-menu ((tool graph-tool))
  nil)

;;; Menu defaults make simple floating menuds for 
;;; the graph window.  Note that these are constructed
;;; before the windows are made for convenience; this
;;; means they have no parents--these can be filled
;;; in later.
(defmethod make-graph-menus ((tool graph-tool))
  (labels ((get-current-buffer ()
             (current-buffer (current-viewer tool)))
	   (current-graph ()
             (graph (get-current-buffer)))
	   (graph-relayout-fn ()
	     (relayout (current-graph)))
	   (graph-redisplay-fn ()
	     (let ((canvas (current-viewer tool)))
	       (let ((vregion (view-region canvas)))
		 (draw-rectangle canvas (region-left vregion)
				 (region-top vregion)
				 (region-width vregion)
				 (region-height vregion)
				 :fill-p t
				 :foreground (background canvas)
				 :operation #.boole-1)
		 (send-event canvas 
			     (make-damage-event 
			      :regions 
			      (list vregion))))))
	   (node-select-fn ()
	     (let* ((graph (current-graph))
		    (node (menu-node graph)))
	       (nodeselect node graph)))
	   (node-select-a-fn ()
	     (let* ((graph (current-graph))
		    (node (menu-node graph)))
	       (nodeselect node graph)
	       (loop for n in (ancestors node graph)
		     do (nodeselect n graph :add))))
	   (node-select-s-fn ()
	     (let* ((graph (current-graph))
		    (node (menu-node graph)))
	       (nodeselect node graph)
	       (loop for n in (node-siblings node graph)
		     do (nodeselect n graph :add))))
	   (node-select-d-fn ()
	     (let* ((graph (current-graph))
		    (node (menu-node graph)))
	       (nodeselect node graph)
	       (loop for n in (descendants node graph)
		     do (nodeselect n graph :add))))
	   (select-all-fn ()
             (let* ((buffer (get-current-buffer))
		    (graph (graph buffer)))
	       (loop for n in (selections buffer)
		     do (nodeselect n graph))
	       (loop for n in (allnodes graph)
		     do (nodeselect n graph :add))))
	   (node-relayout-fn () (graph-relayout-fn))
	   (node-collapse-fn ()
	     (let* ((graph (current-graph))
		    (node (menu-node graph)))
	       (collapse-node node graph)))
	   (node-collapse-a-fn ()
	     (let* ((graph (current-graph))
		    (node (menu-node graph)))
	       (collapse-node node graph (ancestors node graph))))
	   (node-collapse-s-fn ()
	     (let* ((graph (current-graph))
		    (node (menu-node graph)))
	       (collapse-node node graph (node-siblings node graph))))
	   (node-collapse-se-fn ()
	     (let* ((graph (current-graph))
		    (node (menu-node graph)))
	       (collapse-node node graph (remove node (selections (buffer graph))))))
	   (node-depth-fn () nil)
	   (node-expand-all-fn ()
	     (let* ((graph (current-graph))
		    (node (menu-node graph)))
	       (expand node graph -1)))
	   (graph-expand-all-fn ()
             (let ((graph (current-graph)))
	       (loop for root in (rootnodes graph)
		     do (expand root graph -1))))
	   (graph-depth-fn () nil)
	   (node-expand-n-fn ()
	     (node-expand-fn))
	   (open-selections-fn ()
             (let* ((buffer (get-current-buffer))
		    (graph (graph buffer))
		    (roots (loop for selection in (selections buffer)
				 collect (object selection))))
	       (when (and roots (car roots))
		 (make-instance (class-of graph)
				:roots roots))))
	   (open-object-fn ()
	     (let* ((graph (current-graph))
		    (node (menu-node graph)))
	       (when node
		 (make-instance (class-of graph) 
				:roots (list (object node))))))
	   (previous-buffer-fn ()
             (let ((graph (current-graph)))
	       (push-buffer (previous-buffer graph) tool))
	     (graph-redisplay-fn))
	   (next-buffer-fn ()
             (let ((graph (current-graph)))
	       (push-buffer (next-buffer graph) tool))
	     (graph-redisplay-fn))
	   (node-expand-fn () 
	     (let* ((graph (current-graph))
		    (node (menu-node graph)))
	       (expand node graph))))
    (setf (graph-menu tool)
	  (make-instance 'menu :label "graph menu"
			 :menu-spec 
			 (list (list "Open" :menu
				     (list (list "Selections" #'open-selections-fn)
					   (list "Previous" #'previous-buffer-fn)
					   (list "Next" #'next-buffer-fn)))
			       (list "Relayout" #'graph-relayout-fn)
			       (list "Select All" #'select-all-fn)
			       (list "Expand All" #'graph-expand-all-fn)
			       (list "Depth.." #'graph-depth-fn)
			       (list "Redisplay" #'graph-redisplay-fn)))
	  (node-menu tool)
	  (make-instance 'menu :label "node menu"
			 :menu-spec 
			 (list 
			  (list "Open" :menu
				(list (list "Selection" #'open-object-fn)
				      (list "Previous" #'previous-buffer-fn)
				      (list "Next" #'next-buffer-fn)))
			  (list "Select" :menu
				(list (list "Node" #'node-select-fn)
				      (list "Ancestors" #'node-select-a-fn)
				      (list "Siblings" #'node-select-s-fn)
				      (list "descendants" #'node-select-d-fn)
				      (list "All" #'select-all-fn)))
			       (list "Expand" :menu
				     (list (list "1 Level" #'node-expand-fn)
					   (list "N Levels.." #'node-expand-n-fn)
					   (list "Fully" #'node-expand-all-fn)))
			       (list "Collapse" :menu
				     (list (list "Descendants" #'node-collapse-fn)
					   (list "Ancestors" #'node-collapse-a-fn)
					   (list "Siblings" #'node-collapse-s-fn)
					   (list "Selections" #'node-collapse-se-fn)))
			       (list "Depth.." #'node-depth-fn)
			       (list "Relayout" #'node-relayout-fn))))))

;;; The default push-graph-window method.  This method is the entry
;;; point for puting a new graph (and buffer) onto a window.  This
;;; is also the entry point if there is not yet a window for the tool.
;;; In that case, it calls make-graph-window (below).
;;; This method should do for most applications.  It's the make-graph-window
;;; that the application might want to change.
(defmethod push-graph-window ((graph graph))
  (let* ((tool (tool graph))
	 (canvas (current-viewer tool)))
    (if canvas
	(let ((vregion (view-region canvas))
	      (buffer (buffer graph)))
	  (update-gr-output graph canvas)
	  (setf (current-buffer canvas) buffer)
	  (setf (canvas buffer) canvas)
	  (update-icon buffer (base tool))
	  (draw-rectangle canvas (region-left vregion)
			  (region-top vregion)
			  (region-width vregion)
			  (region-height vregion)
			  :fill-p t
			  :foreground (background canvas)
			  :operation #.boole-1)
	  (center-graph-window graph)
	  (setf (mapped (base tool)) t)
	  (send-event canvas (make-damage-event :regions (list vregion)))
	  (setf (lv:closed (base tool)) nil)
	  (lv:expose (base tool)))
      (make-graph-window graph))))

;; Make the actual graph window complex associated with a tool.
(defmethod make-graph-window ((graph graph))
  (let ((b (buffer graph))
	(tool (tool graph)))
    (let ((bw (make-instance 'graph-base-window 
			     :label (or (title tool) "Graph Window")
			     :width (view-width graph) 
			     :height (view-height graph) 
			     :tool tool
			     :mapped nil)))
      (let ((vp (make-instance 'graph-viewport
			       :parent bw 
			       :tool tool
			       :output-region 
			       (make-region :width (output-width graph) 
					    :height (output-height graph))
			       :container-region
			       (make-region :width (view-width graph)
					    :height (view-height graph))
			       :border-width 1
			       :vertical-scrollbar 
			       (make-instance 'vertical-scrollbar) 
			       :horizontal-scrollbar 
			       (make-instance 'horizontal-scrollbar))))
	(setup-interests graph vp)
	(setf (graph-damage vp) 
	      #'(lambda (vp regions)
		  (let ((buffer (current-buffer vp)))
		    (when buffer
		      (let ((region (apply #'region-bounding-region regions)))
			(display (graph buffer)
			     vp region))))))
	(setf (icon bw) (make-instance 'icon :label *grapher-icon-image*))
	(setf (mapped bw) t)
	(setf (current-buffer vp) b)
	(setf (canvas b) vp)
	(setf (current-viewer tool) vp)
	(push vp (viewers tool))
	(setf (base tool) bw))))
  (center-graph-window graph))

;; setup the window interests
(defmethod setup-interests ((graph graph) (vp drawable))
  (push *damage-interest* (interests vp))
  (push *select-mouse-interest* (interests vp))
  (push *menu-mouse-interest* (interests vp))
  (push *open-mouse-interest* (interests vp))
  (push *edit-mouse-interest* (interests vp))
  (push *dummy-mouse-interest* (interests vp))
  (push *move-mouse-interest* (interests vp)))

;; center the graph onto the window
(defgeneric center-graph-window (graph)
  (:method ((graph graph-layout))
    nil)
  (:method ((graph left-right-layout))
    (let ((vp (canvas (buffer graph))))
      (let ((view (view-region vp))
	    (output (output-region vp)))
	(setf (region-left view :move) (region-left output)
	      (region-top view :move) 0
	      (view-region vp) view))))
  (:method ((graph right-left-layout))
    (let ((vp (canvas (buffer graph))))
      (let ((view (view-region vp))
	    (output (output-region vp)))
	(setf (region-right view :move) (region-right output)
	      (region-top view :move) 0
	      (view-region vp) view))))
  (:method ((graph centered-horizontal-layout))
    (declare (restrictive-ftype (function (fixnum fixnum) fixnum) +)
	     (restrictive-ftype (function (fixnum fixnum) fixnum) floor))
    (let ((vp (canvas (buffer graph))))
      (let ((view (view-region vp))
	    (root (car (rootnodes graph)))
	    (output (output-region vp)))
	(setf (region-right view :move) (+ (floor (region-width view) 2) 
					   (if root
					       (+ (x root)
						  (floor (width root) 2))
					       (floor (region-right output) 2)))
	      (region-top view :move) 0
	      (view-region vp) view))))
  (:method ((graph centered-vertical-layout))
    (declare (restrictive-ftype (function (region &optional t) fixnum) 
				region-bottom)
	     (restrictive-ftype (function (fixnum fixnum) fixnum) +)
	     (restrictive-ftype (function (fixnum fixnum) fixnum) floor))
    (let ((vp (canvas (buffer graph))))
      (let ((view (view-region vp))
	    (root (car (rootnodes graph)))
	    (output (output-region vp)))
	(setf (region-bottom view :move) (+ (floor (region-height view) 2) 
					    (if root
						(+ (y root)
						   (floor (height root) 2))
						(floor (region-bottom output) 2)))
	      (view-region vp) view))))
  (:method ((graph bottom-top-layout))
    (declare (restrictive-ftype (function (region &optional t) fixnum) 
				region-bottom))
    (let ((vp (canvas (buffer graph))))
      (let ((view (view-region vp))
	    (output (output-region vp)))
	(setf (region-bottom view :move) (region-bottom output)
	      (view-region vp) view)))))

;; lispview has a bug here...
(defmethod (setf bounding-region) :after (new-region (bw graph-base-window))
  (when (mapped bw)
    (let ((canvas (current-viewer (tool bw))))
      (let ((r (container-region canvas)))
	(setf (region-width r) (region-width new-region)
	      (region-height r) (region-height new-region)
	      (container-region canvas) r)))))



;;;
;;; selection methods
;;;

(defmethod highlight ((node node) (graph graph-layout) &optional display)
  (declare (restrictive-ftype (function (fixnum &rest fixnum) fixnum) +)
	   (restrictive-ftype (function (fixnum &rest fixnum) fixnum) -))
  (let ((region (region node))
	(window (or display (canvas (buffer graph)))))
    (setf (selected node) t)
    (draw-rectangle window 
		    (- (region-left region) 1)
		    (- (region-top region) 1)
		    (+ (region-width region) 1)
		    (+ (region-height region) 1)
		    :fill-p t
		    :operation #.boole-xor)))

(defmethod unhighlight ((node node) (graph graph-layout) &optional display)
  (declare (restrictive-ftype (function (fixnum &rest fixnum) fixnum) +)
	   (restrictive-ftype (function (fixnum &rest fixnum) fixnum) -))
  (let ((region (region node))
	(window (or display (canvas (buffer graph)))))
    (setf (selected node) nil)    
    (draw-rectangle window 
		    (- (region-left region) 1)
		    (- (region-top region) 1)
		    (+ (region-width region) 1)
		    (+ (region-height region) 1)
		    :fill-p t
		    :operation #.boole-xor)))

;; type is either :add :replace
(defmethod nodeselect ((node node) (graph abstract-graph) &optional (type :replace))
 (let ((buffer (buffer graph))
       (realgraph (associated-graph node graph)))
   (let ((canvas (canvas buffer)))
    (if (find-if #'(lambda (snode) (eq snode node)) (selections buffer))
	(progn (unhighlight node realgraph canvas)
	       (setf (selections buffer)
		     (remove node (selections buffer))))
        (progn
	  (highlight node realgraph canvas)
	  (if (eq type :replace)
	      (progn (loop for snode in (selections buffer) do
			   (unhighlight snode realgraph canvas))
		     (setf (selections buffer) (list node)))
	      (if (eq type :add)
		  (push node (selections buffer))
		  (progn (unhighlight node realgraph canvas)
			 (print 
			  (format nil "~a is not a legal selection type" type)
			  )))))))))

;; when nodeselect called with a subgraph, just call with the node in the
;; associated super graph
(defmethod nodeselect ((node node) (graph subgraph) &optional (type :replace))
  (let ((super (parent-graph graph)))
    (when super
      (let ((realnode (or (find-node (label node) super)
			  node)))
	(call-next-method realnode super type)))))

;;;
;;; receive event methods
;;;

(defmethod receive-event ((canvas graph-window-mixin) interest 
			  (event damage-event))
  (declare (ignore interest))
  (let ((damage-fn (graph-damage canvas)))
    (when damage-fn
      (let ((regions (damage-event-regions event)))
	(funcall damage-fn canvas regions)))))

(defmethod receive-event (canvas (interest dummy-mouse-interest) event)
  (multiple-value-bind (mods action) (mouse-event-gesture event)
    (declare (ignore mods))
    (let ((x (mouse-event-x event))
	  (y (mouse-event-y event)))
      (declare (fixnum x y))
      (done-selecting-mouse-event canvas action x y))))

;; action should be either '(:left :up) or '(:middle :up)
(defmethod done-selecting-mouse-event (canvas action x y)
  (declare (fixnum x y)
	   (restrictive-ftype (function (fixnum fixnum) fixnum) -))
  (let ((vregion (view-region canvas))
	(buffer (current-buffer canvas)))
    (when buffer
      (let ((graph (graph buffer)))
	(cond ((moving graph)
	       (move-arcs (moving graph) graph canvas)
	       (setf (moving graph) nil)
	       (draw-rectangle canvas (region-left vregion)
			       (region-top vregion)
			       (region-width vregion)
			       (region-height vregion)
			       :fill-p t
			       :foreground (background canvas)
			       :operation #.boole-1)
	       (send-event canvas 
			   (make-damage-event :regions 
					      (list vregion))))
	      ((sweeping graph)
	       (let ((sweep (sweeping graph)))
		 (multiple-value-bind (left right) 
		     (if (eq :left (third (first sweep)))
			 (values (first (first sweep)) 
				 (first (second sweep)))
			 (values (first (second sweep))
				 (first (first sweep))))
		   (declare (fixnum left right))
		   (multiple-value-bind (top bottom)
		       (if (eq :top (fourth (first sweep)))
			   (values (second (first sweep)) 
				   (second (second sweep)))
			   (values (second (second sweep))
				   (second (first sweep))))
		     (declare (fixnum top bottom))
		     (let ((region (make-region :left left
						:right right
						:top top
						:bottom bottom)))
		       (loop for node in (allnodes graph)
			     when (and (regions-intersect-p region 
							    (region node))
				       (display-p node))
			     do (nodeselect node graph :add))
		       (setf (sweeping graph) nil)
		       (draw-rectangle canvas left top (- right left) 
				       (- bottom top)
				       :operation #.boole-c1)
		       (draw-rectangle canvas (region-left vregion)
				       (region-top vregion)
				       (region-width vregion)
				       (region-height vregion)
				       :fill-p t
				       :foreground (background canvas)
				       :operation #.boole-1)
		       (send-event canvas 
				   (make-damage-event 
				    :regions 
				    (list vregion)))
		       ))))))))))

(defmethod receive-event (canvas (interest select-mouse-interest) event)
  (multiple-value-bind (mods action) (mouse-event-gesture event)
    (declare (ignore mods))
    (let ((x (mouse-event-x event))
	  (y (mouse-event-y event)))
      (declare (fixnum x y))
      (select-mouse-event canvas action x y))))

;; fix up old select mouse event so that it only selects
;; action should be either '(:left :down) or '(:middle :down)
(defmethod select-mouse-event (canvas action x y)
  (declare (fixnum x y)
	   (restrictive-ftype (function (fixnum fixnum) fixnum) -))
  (let ((vregion (view-region canvas))
	(buffer (current-buffer canvas)))
    (when buffer
      (let ((graph (graph buffer)))
	(when graph
	  (unless (or (moving graph) (sweeping graph))
	    (let ((node (region-to-node x y graph)))
	      (cond ((equal action '(:left :down))
		     (if node
			 (nodeselect node graph)
			 (loop for snode in (selections buffer)
			       do (nodeselect snode graph))))
		    ((equal action '(:middle :down))
		     (when node
		       (nodeselect node graph :add)))))))))))

(defmethod receive-event (canvas (interest menu-mouse-interest) event)
  (let ((x (mouse-event-x event))
	(y (mouse-event-y event)))
    (declare (fixnum x y))
    (menu-mouse-event canvas x y)))

;; for right button down's           *** paint-window slot access temp ***
(defmethod menu-mouse-event (canvas x y)
  (declare (fixnum x y))
  (let ((buffer (current-buffer canvas)))
    (when buffer
      (let ((graph (graph buffer))
	    (tool (tool canvas)))
	(let ((node (multiple-value-list (region-to-node x y graph))))
	  (if (moving graph)
	      (setf (moving graph) nil)
	      ;; if we can't send vars via menu-show, then set up
 	      ;; the node as a special...
	      (cond ((and (car node) (eq (length node) 1) (node-menu tool))
		     (setf (menu-node graph) (car node))
		     (let ((menu (node-menu tool)))
		       (when menu
			 (menu-show menu canvas :x x :y y))))
		    ((and (car node) (node-menu tool))
		     (setf (menu-node graph) (car node))
		     (let ((menu (node-menu tool)))
		       (when menu
			 (menu-show menu canvas :x x :y y))))
		    (t (let ((menu (graph-menu tool)))
			 (when menu
			   (menu-show menu canvas :x x :y y)))))))))))
			    
(defmethod receive-event (canvas (interest move-mouse-interest) event)
  (let ((x (mouse-event-x event))
	(y (mouse-event-y event)))
    (declare (fixnum x y))
    (move-mouse-event canvas x y)))

;; for move down's
(defmethod move-mouse-event (canvas x y)
  (declare (fixnum x y))
  (let ((buffer (current-buffer canvas)))
    (when buffer
      (let ((graph (graph buffer)))
	(let ((movingnode (moving graph))
	      (sweeping (sweeping graph)))
	  (cond (movingnode
		 (move movingnode graph x y))
		(sweeping
		 (sweep sweeping graph x y))
		(t 
		 (let ((node (region-to-node x y graph)))
		   (cond (node
			  (setf (moving graph) node)
			  (first-move node graph x y))
			 (t 
			  (loop for snode in (selections buffer)
				do (nodeselect snode graph))
			  (setf (sweeping graph) 
				(list (list x y :left :top) 
				      (list x y)))))))))))))

(defmethod sweep ((sweepvars list) (graph graph-layout) x y)
  (declare (fixnum x y)
	   (restrictive-ftype (function (fixnum fixnum) fixnum) -))
  (let ((origin-x (first (first sweepvars)))
	(origin-y (second (first sweepvars)))
	(old-x (first (second sweepvars)))
	(old-y (second (second sweepvars))))
    (declare (fixnum origin-x origin-y old-x old-y))
    (multiple-value-bind (left right) 
      (if (eq :left (third (first sweepvars)))
	  (values origin-x old-x)
	  (values old-x origin-x))
      (multiple-value-bind (top bottom)
	  (if (eq :top (fourth (first sweepvars)))
	      (values origin-y old-y)
	      (values old-y origin-y))
	(let ((display (canvas (buffer graph))))
	  ;; undraw old (use foreground/background)
	  ;; can I just keep track of bits underneth rectangle???
	  (unless (and (eq left right) (eq top bottom))
	    (draw-rectangle display left top (- right left) (- bottom top)
			    :foreground (background display)
			    :background (foreground display)))
	  ;; replace old-x and old-y with x and y then calculate orientation
	  (if (<= origin-x x)
	      (setf (third (first sweepvars)) :left
		    left origin-x right x)
	      (setf (third (first sweepvars)) :right
		    right origin-x left x))
	  (if (<= origin-y y)
	      (setf (fourth (first sweepvars)) :top
		    top origin-y bottom y)
	      (setf (fourth (first sweepvars)) :bottom
		    bottom origin-y top y))
	  (setf (second sweepvars) (list x y)
		(sweeping graph) sweepvars)
	  (draw-rectangle display left top (- right left) (- bottom top)))))))

(defmethod first-move ((node node) (graph centered-layout) x y &optional display)
  (declare (fixnum x y)
	   (restrictive-ftype (function (fixnum fixnum) fixnum) -))
  (if (root node)
      (let ((g1 (descendant-graph graph))
	    (g2 (ancestor-graph graph))
	    (x-diff (- (x node) x))
	    (y-diff (- (y node) y))
	    (display (or display (canvas (buffer graph)))))
	(move-node node graph display x y)
	(first-move (find-node (label node) g1) g1 x y display)
	(first-move (find-node (label node) g2) g2 x y display)
	(when (selected node)
	  (loop for snode in (selections (buffer graph))
		unless (eq node snode)
		do (first-move-adjacent snode (associated-graph snode graph) 
				  x-diff y-diff display))))
      (call-next-method)))

(defmethod move ((node node) (graph centered-layout) x y &optional display)
  (declare (fixnum x y)
	   (restrictive-ftype (function (fixnum fixnum) fixnum) -))
  (if (root node)
      (let ((g1 (descendant-graph graph))
	    (g2 (ancestor-graph graph))
	    (x-diff (- (x node) x))
	    (y-diff (- (y node) y))
	    (display (or display (canvas (buffer graph)))))
	(move-node node graph display x y)
	(move (find-node (label node) g1) g1 x y display)
	(move (find-node (label node) g2) g2 x y display)
	(when (selected node)
	  (loop for snode in (selections (buffer graph))
		unless (eq node snode)
		do (move-adjacent snode (associated-graph snode graph) 
				  x-diff y-diff display))))
      (call-next-method)))

(defmethod first-move ((node node) (graph graph-layout) x y &optional display)
  (declare (fixnum x y)
	   (restrictive-ftype (function (fixnum fixnum) fixnum) -))
  (let ((display (or display (canvas (buffer graph))))
	(x-diff (- (x node) x))
	(y-diff (- (y node) y)))
    (declare (fixnum x-diff y-diff))
    (loop for arc in (fromarcs node)
	  do (let ((gc (g-c arc)))
	       (draw-line display (from-x arc) (from-y arc) 
			  (to-x arc) (to-y arc) :gc gc
			  :foreground (background gc))))
    (loop for arc in (toarcs node)
	  do (let ((gc (g-c arc)))
	       (draw-line display (from-x arc) (from-y arc)
			  (to-x arc) (to-y arc) :gc gc
			  :foreground (background gc))))
    (move-node node graph display x y)
    (when (selected node)
      (let ((buffer (buffer graph)))
	(when buffer
	  (loop for snode in (selections buffer)
		unless (eq node snode)
		do (first-move-adjacent snode graph x-diff y-diff)))))))

(defmethod move ((node node) (graph graph-layout) x y &optional display)
  (declare (fixnum x y)
	   (restrictive-ftype (function (fixnum fixnum) fixnum) -))
  (let ((display (or display (canvas (buffer graph))))
	(x-diff (- (x node) x))
	(y-diff (- (y node) y)))
    (declare (fixnum x-diff y-diff))
    (move-node node graph display x y)
    (when (selected node)
      (let ((buffer (buffer graph)))
	(when buffer
	  (loop for snode in (selections buffer)
		unless (eq node snode)
		do (move-adjacent snode graph x-diff y-diff)))))))

(defmethod move-arcs ((node node) (graph centered-layout) display)
  (if (root node)
      (let ((g1 (ancestor-graph graph))
	    (g2 (descendant-graph graph)))
	(move-arcs (find-node (label node) g1) g1 display)
	(move-arcs (find-node (label node) g2) g2 display))
      (call-next-method)))

(defmethod move-arcs ((node node) (graph graph-layout) display)
  (loop for arc in (fromarcs node)
	do (arc-layout arc graph)
	   (update-arc-region arc graph))
  (loop for arc in (toarcs node)
	do (arc-layout arc graph)
	   (update-arc-region arc graph))
  (when (selected node)
    (let ((buffer (buffer graph)))
      (when buffer
	(loop for snode in (selections buffer)
	      unless (eq node snode)
	      do (adjacent-move-arcs node graph display))))))

(defmethod adjacent-move-arcs ((node node) (graph graph-layout) display)
  (loop for arc in (fromarcs node)
	do (arc-layout arc graph)
	   (update-arc-region arc graph))
  (loop for arc in (toarcs node)
	do (arc-layout arc graph)
	   (update-arc-region arc graph))
  )

(defmethod move-node ((node node) (graph abstract-graph) (display drawable) x y)
  (declare (fixnum x y)
	   (restrictive-ftype (function (fixnum fixnum) fixnum) -))
  (let* ((selected (selected node))
	 (realgraph (associated-graph node graph))
	 (gc (g-c node))
	 (background (background gc))
	 (foreground (foreground gc)))
    (when selected
      (unhighlight node realgraph display))
    (setf (background gc) foreground
	  (foreground gc) background
	  (g-c node) gc)
    (display-label node display)
    (setf (x node) x
	  (y node) y)
    (update-node-region node realgraph)   
    (setf (background gc) background
	  (foreground gc) foreground
	  (g-c node) gc)
    (display-label node display)    
    (when selected
      (highlight node realgraph display))))

(defmethod move-node ((node node) (graph subgraph) (display drawable) x y)
  (declare (fixnum x y))
  (cond ((root node)
	 (setf (x node) x
	       (y node) y)
	 (update-node-region node graph))
	(t (call-next-method))))

(defmethod first-move-adjacent ((node node) (graph centered-layout) 
			  x-diff y-diff &optional display)
  (declare (fixnum x-diff y-diff)
	   (restrictive-ftype (function (fixnum fixnum) fixnum) -))
  (if (root node)
      (let ((g1 (descendant-graph graph))
	    (g2 (ancestor-graph graph))
	    (display (or display (canvas (buffer graph)))))
	(move-node node graph display (- (x node) x-diff) (- (y node) y-diff))
	(first-move-adjacent (find-node (label node) g1) g1 x-diff y-diff display)
	(first-move-adjacent (find-node (label node) g2) g2 x-diff y-diff display))
      (call-next-method)))

(defmethod move-adjacent ((node node) (graph centered-layout) 
			  x-diff y-diff &optional display)
  (declare (fixnum x-diff y-diff)
	   (restrictive-ftype (function (fixnum fixnum) fixnum) -))
  (if (root node)
      (let ((g1 (descendant-graph graph))
	    (g2 (ancestor-graph graph))
	    (display (or display (canvas (buffer graph)))))
	(move-node node graph display (- (x node) x-diff) (- (y node) y-diff))
	(move-adjacent (find-node (label node) g1) g1 x-diff y-diff display)
	(move-adjacent (find-node (label node) g2) g2 x-diff y-diff display))
      (call-next-method)))

(defmethod first-move-adjacent ((node node) (graph graph-layout) 
			  x-diff y-diff &optional display)
  (declare (fixnum x-diff y-diff)
	   (restrictive-ftype (function (fixnum fixnum) fixnum) -))
  (let ((display (or display (canvas (buffer graph))))
	(x (- (x node) x-diff))
	(y (- (y node) y-diff)))
    (declare (fixnum x y))
    (loop for arc in (fromarcs node)
	  do (let ((gc (g-c arc)))
	       (draw-line display (from-x arc) (from-y arc)
			  (to-x arc) (to-y arc) :gc gc
			  :foreground (background gc))))
    (loop for arc in (toarcs node)
	  do (let ((gc (g-c arc)))
	       (draw-line display (from-x arc) (from-y arc)
			  (to-x arc) (to-y arc) :gc gc
			  :foreground (background gc))))
    (move-node node graph display x y)))

(defmethod move-adjacent ((node node) (graph graph-layout) 
			  x-diff y-diff &optional display)
  (declare (fixnum x-diff y-diff)
	   (restrictive-ftype (function (fixnum fixnum) fixnum) -))
  (let ((display (or display (canvas (buffer graph))))
	(x (- (x node) x-diff))
	(y (- (y node) y-diff)))
    (declare (fixnum x y))
    (move-node node graph display x y)))

(defmethod receive-event (canvas (interest open-mouse-interest) event)
  (let ((x (mouse-event-x event))
	(y (mouse-event-y event)))
    (declare (fixnum x y))
    (open-mouse-event canvas x y)))

(defmethod open-mouse-event (canvas x y)
  (let ((buffer (current-buffer canvas)))
    (when buffer
      (let ((graph (graph buffer)))
	(when graph
	  (let ((node (region-to-node x y graph)))
	    (when node
	      (expand node graph))))))))

(defmethod receive-event (canvas (interest edit-mouse-interest) event)
  (let ((x (mouse-event-x event))
	(y (mouse-event-y event)))
    (declare (fixnum x y))
    (edit-mouse-interest canvas x y)))

(defmethod edit-mouse-interest (canvas x y)
  (let ((buffer (current-buffer canvas)))
    (when buffer
      (let ((graph (graph buffer)))
	(when graph
	  (let ((node (region-to-node x y graph)))
	    (when node
	      (let ((object (object-to-edit node graph)))
		(when object
		  ;; should be edit (say a remote call to gnuemacs)!
		  (make-process :name (format nil "Inspect ~a" object)
				:function #'(lambda () (inspect object))))))))))))

;; object to edit for a symbol
(defmethod object-to-edit ((object symbol) (graph graph))
  (let ((node (or (find-node (format nil "~(~a~)" object) graph)
		  (find-node (format nil "~(~a~)..." object) graph)
		  (find-node (format nil "...~(~a~)" object) 
			     graph))))
    (and node (object node))))

(defmethod object-to-edit ((node node) (graph graph))
  (object node))

;; inspect a symbol
(defmethod object-to-inspect ((object symbol) (graph graph))
  (let ((node (or (find-node (format nil "~(~a~)" object) graph)
		  (find-node (format nil "~(~a~)..." object) graph)
		  (find-node (format nil "...~(~a~)" object) 
			     graph))))
    (and node (object node))))

(defmethod object-to-inspect ((node node) (graph graph))
  (object node))
