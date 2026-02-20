;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;;  File: grapher-classes-2.lisp
;;;;
;;;;  Author: Philip McBride
;;;;
;;;;  This file contains the classes and class creation and 
;;;;  initialization code for the lispview grapher.
;;;;
;;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;;	See LEGAL_NOTICE file for terms of the license.
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package :grapher)

;;; Continuation of grapher classes.  Separated because of trouble
;;; with validate superclass...

;;; the main relation class
(defclass relation () ())

;; children relation class
(defclass children (relation) ())

;;; arc class is defined in the previous (graph object) section.

;;; mixin classes

(defclass children-arc (children arc) ()
  (:metaclass ftc-relation-meta)
  (:default-initargs :g-c *solid-arc-gc*))

(defclass lazy-children-arc (children arc) ()
  (:metaclass ltc-relation-meta)
  (:default-initargs :g-c *solid-arc-gc*))

;; just for testing...
(defclass dashed-children-arc (children arc) ()
  (:metaclass ftc-relation-meta)
  (:default-initargs :g-c *dashed-arc-gc*))

(defclass bold-children-arc (children arc) ()
  (:metaclass ftc-relation-meta)
  (:default-initargs :g-c *bold-arc-gc*))

;;;
;;; relation initialization methods
;;;

;; init the arcs--create an empty region object
(defmethod initialize-instance :after ((arc arc) &rest initargs)
  (declare (ignore initargs))
  (setf (region arc) (make-region :top 0 :left 0 :width 0 :height 0)))

;; update line in arc-gc classes if they are changed
(defmethod update-instance-for-different-class :after ((prev arc)
						       (curr arc)
						       &rest initargs)
  (declare (ignore initargs))
  ;; update the line-width and line-style slots of the new instance
  (let ((gcarg (assoc :g-c (class-default-initargs (class-of curr)))))
    (when gcarg
      (with-interrupts-allowed
       (setf (g-c curr) gcarg)))))



;;;
;;; graph classes
;;;

;;; The graph class represents the graph as a whole.  This includes
;;; pointing to all of the nodes and arcs as well as the graph
;;; behavior of layout, diplay, and various I/O.  The graph-layout
;;; class represents the layout of the graph.
;;;
;;;                                      __ centered-vertical-layout
;;;                     centered-layout /
;;;                   /                 \__ centered-horizontal-layout
;;;                  /
;;;                 /                                    __ left-right-layout
;;;                /               __ horizontal-layout /                    \
;;;               /               /                     \__ right-left-layout \
;;;  graph-layout __ side-layout /                                             \
;;;                              \                     __ top-bottom-layout     \
;;;                               \__ vertical-layout /                          \
;;;                                                   \__ bottom-top-layout       \
;;;                                                                                \
;;;                  __ graph _____________________________________________________ standard-graph
;;;  abstract-graph /
;;;                 \__ subgraph
;;;
;;; A graph is made up of the graph class mixed with one of the
;;; layout classes as is the case with standard-graph.
;;;
;;; **** maybe use layout slot instead of class mixing ****

;;; main graph class
(defclass abstract-graph ()
  ((roots :accessor roots :initarg :roots :initform '())
   (nonroots :accessor nonroots :initarg :nonroots :initform '())
   (allnodes :accessor allnodes :initarg :allnodes :initform '())
   (objecttable :accessor objecttable :initarg :objecttable
		:initform (make-hash-table :test #'eq))
   (rootnodes :accessor rootnodes :initarg :rootnodes :initform '())
   (nonrootnodes :accessor nonrootnodes :initarg :nonrootnodes 
		 :initform '())
   (leafnodes :accessor leafnodes :initform '())
   (arcs :accessor arcs :initform '())
   (arcregions :accessor arcregions :initform '())    ;; region cache w/arc
   (noderegions :accessor noderegions :initform '())  ;; region cache w/node
   (nodelabels :accessor nodelabels :initform '())    ;; label cache w/region
   (relations :accessor relations :initform '() :initarg :relations)
   (depth-limit :accessor depth-limit :initarg :depth-limit
		:initform 3 :type fixnum)
   (expand-depth :accessor expand-depth :initarg :expand-depth
		:initform 1 :type fixnum)
   (sweeping :accessor sweeping :initform nil)        ;; region being sweeped
   (moving :accessor moving :initform '())            ;; nodes being moved
   (menu-node :accessor menu-node :initarg :menu-node :initform nil)
   (gcount :accessor gcount :initform 0 :type fixnum)   ;; node count
   (tool :accessor tool :initarg :tool :initform *graph-tool*)
   (buffer :accessor buffer :initarg :buffer :initform nil)))

;;; graph class
(defclass graph (abstract-graph)
  ((checkcycles :accessor checkcycles :initarg :checkcycles
		:initform t)              ;; check for cycles?
   (cycle-duplication :accessor cycle-duplication :initform nil
		      :initarg :cycle-duplication)))   ;; dup. cycles?

;;; graph subgraph class.  This class is for graphs that are subgraphs
;;; of a centered graph.
(defclass subgraph (abstract-graph)
  ((parent-graph :accessor parent-graph :initarg :parent-graph :initform nil)))

;;; graph layout classes
(defclass graph-layout ()
  ((root-depth :accessor root-depth :initarg :root-depth
	       :initform 0 :type fixnum)          ;; root depth position
   (graph-width :accessor graph-width :initform 0 :type fixnum)
   (graph-height :accessor graph-height :initform 0 :type fixnum)
   (horizontal-margin :accessor horizontal-margin :initform 20
		      :initarg :horizontal-margin :type fixnum)
   (vertical-margin :accessor vertical-margin :initform 20
		      :initarg :vertical-margin :type fixnum)
   (view-height :accessor view-height :initarg 
		:view-height :initform 280 :type fixnum)
   (view-width :accessor view-width :initarg 
	       :view-width :initform 480 :type fixnum)
   (output-height :accessor output-height :initarg 
		  :output-height :initform 2000 :type fixnum)
   (output-width :accessor output-width :initarg 
		 :output-width :initform 2000 :type fixnum)
   (node-gc :accessor node-gc :initarg :node-gc :initform nil)
   (ancestor-spacing :accessor ancestor-spacing 
		     :initarg :ancestor-spacing
		     :initform 50 :type fixnum)
   (sibling-spacing :accessor sibling-spacing 
		    :initarg :sibling-spacing
		    :initform 8 :type fixnum)))

(defclass side-layout (graph-layout) ())

(defclass centered-layout (graph-layout)
  ((ancestor-graph-class :accessor ancestor-graph-class
			 :initarg :ancestor-graph-class
			 :initform nil)
   (descendant-graph-class :accessor descendant-graph-class
			   :initarg :descendant-graph-class
			   :initform nil)
   (ancestor-graph :accessor ancestor-graph
		   :initarg :ancestor-graph :initform nil)
   (descendant-graph :accessor descendant-graph
		     :initarg :descendant-graph :initform nil))
  (:default-initargs :root-depth 1000))
		     
(defclass centered-vertical-layout (centered-layout) ())

(defclass centered-horizontal-layout (centered-layout) ())

(defclass horizontal-layout (side-layout) ())

(defclass vertical-layout (side-layout) ())

(defclass left-right-layout (horizontal-layout) ())

(defclass right-left-layout (horizontal-layout) ()
  (:default-initargs :root-depth 2000))

(defclass top-bottom-layout (vertical-layout) ())

(defclass bottom-top-layout (vertical-layout) ()
  (:default-initargs :root-depth 2000))

;;; graph mixin classes
(defclass standard-lr-graph (graph left-right-layout) ()
  (:default-initargs :relations (list (find-class 'children-arc))))

(defclass standard-lr-lazy-graph (graph left-right-layout) ()
  (:default-initargs :relations (list (find-class 'lazy-children-arc))))

(defclass standard-rl-graph (graph right-left-layout) ()
  (:default-initargs :relations (list (find-class 'children-arc))))

(defclass standard-tb-graph (graph top-bottom-layout) ()
  (:default-initargs :relations (list (find-class 'children-arc))))

(defclass standard-bt-graph (graph bottom-top-layout) ()
  (:default-initargs :relations (list (find-class 'children-arc))))


;;;
;;; graph creation and initialization methods
;;;

;; Initialize one sided graph by constructing the graph from any root objects.
(defmethod initialize-instance ((graph side-layout) &key roots rootnodes 
				checkcycles &allow-other-keys)
  ;; Seems like a good place to ensure that initialization has been
  ;; done.  Grapher-init avoids duplicate inits.
  (grapher-init)
  (let ((graph (call-next-method)))
    (cond (roots
	   (loop for root in roots do
		 (let ((rnode (make-node (label root) root graph :root t)))
		   (add-node rnode graph)))
	   (loop for rnode in (rootnodes graph)
		 do (loop for relation in (relations graph) do
			  (transitive-closure relation rnode graph))))
	  (rootnodes
	   (loop for rnode in rootnodes do
		 (add-node rnode graph))
	   (loop for rnode in (rootnodes graph)
		 do (loop for relation in (relations graph) do
			  (transitive-closure relation rnode graph)))))))

;; Additional initialization for the graph involves layout and display.
(defmethod initialize-instance :after ((graph graph) &key roots rootnodes
				       tool buffer cycle-duplication 
				       &allow-other-keys)
				       
  (let ((tool (or tool (make-tool graph)))
	(buffer (or buffer (make-buffer graph))))
    (setf (tool graph) tool)
    (add-buffer graph buffer)
    (when (or roots rootnodes)
      (layout graph cycle-duplication)
      (push-graph-window graph))))

;; Initialize centered graph by creating subgraphs with roots given to supergraph
(defmethod initialize-instance ((graph centered-layout) &key roots 
				&allow-other-keys)
  (let ((graph (call-next-method)))
    (loop for root in roots do
	  (let ((rnode (make-node (label root) root graph :root t)))
	    (add-node rnode graph)))
    (make-subgraphs graph)))

;; make centered graph's subgraphs (either horizontal or vertical)
(defmethod make-subgraphs ((graph centered-layout))
  (let ((a-rootnodes (loop for rn in (rootnodes graph)
			  collect (make-node (label rn) (object rn) 
					     graph :root t)))
	(d-rootnodes (loop for rn in (rootnodes graph)
			  collect (make-node (label rn) (object rn) 
					     graph :root t))))
    (setf (descendant-graph graph)
	  (make-instance (descendant-graph-class graph) :rootnodes d-rootnodes
			 :root-depth (root-depth graph) 
			 :parent-graph graph
			 :depth-limit (depth-limit graph))
	  (ancestor-graph graph)
	  (make-instance (ancestor-graph-class graph) :rootnodes a-rootnodes
			 :root-depth (root-depth graph)
			 :parent-graph graph
			 :depth-limit (depth-limit graph))
	  (nodelabels graph) 
	  (append (loop for n in (nonrootnodes (descendant-graph graph))
			collect (cons (label n) n))
		  (loop for n in (nonrootnodes (ancestor-graph graph))
			collect (cons (label n) n))
		  (loop for n in (rootnodes graph)
			collect (cons (label n) n)))
	  (arcregions graph) 
	  (append (arcregions (descendant-graph graph))
		  (arcregions (ancestor-graph graph)))
	  (arcs graph) 
	  (append (arcs (descendant-graph graph))
		  (arcs (ancestor-graph graph)))
	  (allnodes graph)
	  (append (nonrootnodes (descendant-graph graph))
		  (nonrootnodes (ancestor-graph graph))
		  (rootnodes graph))
	  (noderegions graph)
	  (append (loop for n in (nonrootnodes (descendant-graph graph))
			collect (cons (region n) n))
		  (loop for n in (nonrootnodes (ancestor-graph graph))
			collect (cons (region n) n))
		  (loop for n in (rootnodes graph)
			collect (cons (region n) n))))))

;; Upon change-class of the graph layout, relayout the graph and redisplay.
(defmethod update-instance-for-different-class :after ((prev-g side-layout)
						       (curr-g side-layout) 
						       &rest initargs)
  (declare (ignore initargs))
  (relayout curr-g)
  (let ((vp (canvas (buffer curr-g))))
    (send-event vp (make-damage-event :regions (list (view-region vp))))))



;;;
;;; graph buffer
;;;

(defclass graph-buffer ()
  ((name :accessor name :initarg :name :initform "*scratch*")
   (graph :accessor graph :initarg :graph :initform nil)
   (selections :accessor selections :initarg :selections :initform '())
   (canvas :accessor canvas :initarg :canvas :initform nil)
   (tool :accessor tool :initarg :tool :initform nil)
   ;;; these for views of centered graphs...
   (centered-graph-view :accessor centered-graph-view :initform nil)
   (ancestor-graph-view :accessor ancestor-graph-view :initform nil)
   (descendant-graph-view :accessor descendant-graph-view :initform nil)))

;; buffer printing
(defmethod print-object ((buffer graph-buffer) stream)
  (format stream "#<~:(~a~) ~a>" (class-name (class-of buffer)) (name buffer)))



;;;
;;; default window interface classes
;;;

(defclass graph-base-window-mixin ()
  ((tool :accessor tool :initarg :tool :initform nil)))

(defclass graph-base-window (base-window graph-base-window-mixin)
  ())

(defmethod (setf status) :before ((value (eql :destroyed)) 
				 (base graph-base-window-mixin))
  (cleanup-destroyed-base base))

(defmethod cleanup-destroyed-base ((base graph-base-window-mixin))
  (let ((tool (tool base)))
    (when tool
      (let ((viewers (viewers tool)))
	(when viewers
	  (loop for buffer in (buffers tool)
		when (member (canvas buffer) viewers :test #'eq)
		do (setf (canvas buffer) nil))
	  (loop for canvas in viewers
		do (setf (current-buffer canvas) nil)
		(setf (tool canvas) nil)))
	(unless viewers
	  (loop for buffer in (buffers tool)
		do (setf (canvas buffer) nil))))
      (setf (base tool) nil)
      (setf (current-viewer tool) nil)
      (setf (viewers tool) '()))))

(defclass graph-window-mixin ()
  ((graph-damage :accessor graph-damage
		 :initarg :graph-damage :initform nil)
   (current-buffer :accessor current-buffer :initform nil
		   :initarg :current-buffer)
   (vertical-scroll-incr :accessor vertical-scroll-incr
			 :initform 15 :initarg :vertical-scroll-incr)
   (horizontal-scroll-incr :accessor horizontal-scroll-incr
			 :initform 10 :initarg :horizontal-scroll-incr)
   (tool :accessor tool :initarg :tool :initform nil)))
  

;; define the method that determines the scrolling increments
;; that is, how much to scroll...
(defmethod compute-view-start ((client graph-window-mixin)
			       (scrollbar vertical-scrollbar)
			       motion point)
  (declare (ignore point))
  ;; add the max in (max & 0)
  (if (eq motion :line-forward)
      (max (+ (view-start client scrollbar) (vertical-scroll-incr client)) 0)
      (if (eq motion :line-backward)
	  (max (- (view-start client scrollbar) 
		  (vertical-scroll-incr client))
	       0))))

(defmethod compute-view-start ((client graph-window-mixin)
			       (scrollbar horizontal-scrollbar)
			       motion point)
  (declare (ignore point))
  ;; add the max in (max & 0)
  (if (eq motion :line-forward)
      (max (+ (view-start client scrollbar) (horizontal-scroll-incr client)) 0)
      (if (eq motion :line-backward)
	  (max (- (view-start client scrollbar) 
		  (horizontal-scroll-incr client))
	       0))))

(defclass graph-viewport (viewport graph-window-mixin)
  ())

(defclass graph-scrolling-window (scrolling-window graph-window-mixin)
  ())

;;;
;;; interest classes
;;;

;; up changed to down here and in receive event because of lispview
;; bug--up doesn't work by itself.
(defclass dummy-mouse-interest (mouse-interest) ()
  (:default-initargs :event-spec '(() ((or :left :middle) :up))))

(defclass select-mouse-interest (mouse-interest) ()
  (:default-initargs :event-spec '(() ((or :left :middle) :down))))

(defclass open-mouse-interest (mouse-interest) ()
  (:default-initargs :event-spec '(() (:left :click2))))

(defclass edit-mouse-interest (mouse-interest) ()
  (:default-initargs :event-spec '((:shift) (:left :click2))))

(defclass menu-mouse-interest (mouse-interest) ()
  (:default-initargs :event-spec '(() (:right :down))))

(defclass move-mouse-interest (mouse-interest) ()
  (:default-initargs :event-spec '((:left) :move)))


;;; graph tool class

(defclass graph-tool ()
  ((buffers :accessor buffers :initarg :buffers 
;	    :allocation :class  ;; shared amoung like tools
	    )
   ;; font size
   (graph-font :accessor graph-font :initarg :graph-font
	       :initform 'medium)
   ;; view default for centered graph tools
   (default-view :accessor default-view :initarg :default-view
               :initform :both)
   ;; view classes used by change-view
   (both-view-class :accessor both-view-class :initarg :both-view-class
		    :initform nil)
   (ancestor-view-class :accessor ancestor-view-class :initarg 
			:ancestor-view-class :initform nil)
   (descendant-view-class :accessor descendant-view-class :initarg 
			  :descendant-view-class :initform nil)
   ;; the rest...
   (graph-menu :accessor graph-menu :initarg :graph-menu :initform nil)
   (node-menu :accessor node-menu :initarg :node-menu :initform nil)
   (panel-menu :accessor panel-menu :initarg :panel-menu :initform nil)
   (base :accessor base :initarg :base :initform nil)
   (title :accessor title :initarg :title :initform "Graph Window")
   ;; actually the *current* canvas--i.e., the one with the focus
   (viewers :accessor viewers :initarg :viewers :initform '())
   (current-viewer :accessor current-viewer :initarg :current-viewer
		   :initform nil)))

(defclass grapher-library-tool (graph-tool)
  ((buffers :accessor buffers :initarg :buffers 
	    :allocation :class)  ;; shared amoung like tools
	    ))


(defmethod slot-unbound (class (inst graph-tool) (slotname (eql 'buffers)))
  nil)

;; tool constructor functions

(defmethod initialize-instance :after ((tool graph-tool) &rest initargs)
  (unless (or (graph-menu tool) (node-menu tool))
    (make-graph-menus tool))
  (unless (panel-menu tool)
    (make-panel-menu tool)))

;; Make a new graph tool by cloneing the current graph tool
;; (i.e., use it's buffers).  Note this is specific to the
;; default grapher (using *graph-tool*).
(defun make-new-graph-tool ()
  (let ((buffers (when *graph-tool* (buffers *graph-tool*))))
    (setf *graph-tool* (make-instance 'grapher-library-tool))
    (push *graph-tool* *graph-tools*)
    (setf (buffers *graph-tool*) buffers)))

;; Change the current graph tool focus to be tool.
(defun change-tool-focus (tool)
  (setq *graph-tool* tool))

(defmethod destroy-graph-tool ((tool graph-tool))
  (setf *graph-tools* (remove tool *graph-tools*))
  (when (eq tool *graph-tool*)
    (setf *graph-tool* (car *graph-tools*)))
  (loop for buffer in (buffers tool)
	do (when (eq (tool buffer) tool)
	     (setf (tool buffer) *graph-tool*)
	     (setf (tool (graph buffer)) *graph-tool*)))
  (setf (graph-menu tool) nil
	(node-menu tool) nil
	(panel-menu tool) nil
	(base tool) nil
	(viewers tool) nil
	(current-viewer tool) nil))
