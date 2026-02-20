;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;;  File: grapher-layout.lisp
;;;;
;;;;  Author: Philip McBride
;;;;
;;;;  This file contains the graph layout code.  This is the code
;;;;  that handles the geometric positioning of the nodes and arcs
;;;;  based on the layout graph mixin class and the geometry of the
;;;;  nodes and arcs.
;;;;
;;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;;	See LEGAL_NOTICE file for terms of the license.
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package :grapher)


;;;
;;; dimension methods
;;;

(defmethod label-width ((node t))
  0)

(defmethod label-height ((node t))
  0)

(defmethod label-height ((node image-node))
  (region-height (bounding-region (label node))))

(defmethod label-width ((node image-node))
  (region-width (bounding-region (label node))))

(defmethod label-height ((node string-node))
  (font-height node))

(defmethod label-width ((node string-node))
  (font-string-width node))

(defmethod font-height ((node string-node))
  (declare (restrictive-ftype (function (font) fixnum) font-ascent)
	   (restrictive-ftype (function (font) fixnum) font-descent))
  (let ((font (font (g-c node))))
    (+ (font-ascent font) (font-descent font))))

(defmethod font-string-width ((node string-node))
  (string-width (font (g-c node)) (label node)))


;;;
;;; layout methods
;;;

;;; Layout graphs using a modified form of the basic isi grapher layout 
;;; algorithm.  The coordinate system of a canvas and the dimensions of
;;; nodes is seen in the picture below.  The layout algorithm first init-
;;; ializes the x and y positions of the nodes to 0.  It then calculates
;;; all of the x coordinates from the end up (i.e., from the leaves).
;;; The y coordinates are then calculated from the roots.  The real
;;; layout has been done.  Following this, the arcs are layed out based
;;; on the nodes.  And finally, the regions of each node and arc are
;;; calculated based on their position and size.
;;;
;;;    x
;;; ________
;;; |
;;; |y
;;; |
;;;
;;;    ______               ______
;;;   |      |             |      |  -
;;;   |  N1  | ------------|  N2  | height
;;;   |______|             |______|  -
;;;  /\                     width
;;; x,y
;;;

;; layout graph
(defgeneric layout (graph &optional checkcycles)
  (:method ((graph centered-layout) &optional (cycle-duplication nil))
    (let ((g1 (descendant-graph graph))
	  (g2 (ancestor-graph graph)))
     (when cycle-duplication
       (remove-cycles g1)
       (remove-cycles g2))
     (centered-layout graph g1 g2)
     (update-graph-dimensions graph)))
  (:method ((graph side-layout) &optional (cycle-duplication nil))
    (when cycle-duplication
      (remove-cycles graph))
    ;; horizontal and vertical layout initialization
    (graph-layout-init graph)
    ;; depth and breadth layout
    (graph-depth-layout graph)
    (graph-breadth-layout graph)
    ;; arc layout
    (graph-arc-layout graph)
    ;; update regions for nodes and arcs
    (graph-update-regions graph)
    (update-graph-dimensions graph)))

;; relayout graph -- don't worry about cycles as above
(defmethod relayout ((graph graph-layout))
  (layout graph nil))

;; relayout graph after code to redisplay graph
(defmethod relayout :after ((graph graph))
  (re-display graph))

;; update the output region (have to update the view region
;; as well because lispview seems to update the view region
;; implicitly when the output region is modified--which
;; in turn scrolls)
(defmethod update-gr-output ((graph graph) canvas)
  (let ((oregion (output-region canvas))
	(vregion (view-region canvas)))
    (setf (region-width oregion) (max (region-width vregion) (graph-width graph))
	  (region-height oregion) (max (region-height vregion) (graph-height graph))
	  (output-region canvas) oregion
	  (view-region canvas) vregion)))

;; Update the dimensions of the graph after layout.  Based on
;; the max x and max y.
(defgeneric update-graph-dimensions (graph)
  (:method ((graph side-layout))
    (setf (graph-width graph)
	  (+ (loop for node in (allnodes graph) 
		   maximize (+ (x node) (width node)))
	     (* 2 (or (horizontal-margin graph) 20))))
    (setf (graph-height graph)
	  (+ (loop for node in (allnodes graph) 
		   maximize (+ (y node) (height node)))
	     (* 2 (or (vertical-margin graph) 20)))))
  (:method ((graph centered-layout))
    (let ((ag (ancestor-graph graph))
	  (dg (descendant-graph graph)))
      (update-graph-dimensions ag)
      (update-graph-dimensions dg)
      (setf (graph-width graph)
	    (max (graph-width ag) (graph-width dg)))
      (setf (graph-height graph)
	    (max (graph-height ag) (graph-height dg))))))
      
;; basic centered graph layout.  Given subgraphs layout each out.
(defmethod centered-layout ((graph centered-layout) (g1 subgraph) (g2 subgraph))
  (graph-layout-init g1)
  (graph-layout-init g2)
  ;; depth and breadth layout g1
  (graph-depth-layout g1)
  (graph-breadth-layout g1)
  ;; depth and breadth layout g2
  (graph-depth-layout g2)
  (graph-breadth-layout g2)
  ;; adjust subgraphs
  (adjust-subgraphs graph g1 g2)
  (loop for rn in (rootnodes g1)
	do (let ((centered (or (find-node (label rn) graph)
			       (find-node (concatenate 'string (label rn) "...") 
					  graph)
			       (find-node (concatenate 'string "..." (label rn))
					  graph))))
	     (when centered
	       (setf (x centered) (x rn)
		     (y centered) (y rn))
	       (update-node-region centered graph))))
  ;; arc layout
  (graph-arc-layout g1)
  (graph-arc-layout g2)
  ;; update regions for nodes and arcs
  (graph-update-regions g1)
  (graph-update-regions g2))

;; adjust subgraphs
(defgeneric adjust-subgraphs (graph g1 g2)
  (:method ((graph centered-horizontal-layout) (g1 subgraph) (g2 subgraph))
    (let ((g1rnodes (rootnodes g1))
	  (g2rnodes (rootnodes g2)))
      (loop for r1 in g1rnodes
	    do (let ((r2 (or (find-node (label r1) g2)
			     (find-node (concatenate 'string (label r1) "...") g2)
			     (find-node (concatenate 'string "..." (label r1)) 
					g2)))
		     (rest1 (member r1 g1rnodes)))
		 (when r2
		   (let ((rest2 (member r2 g2rnodes))
			 (r1-y (y r1))
			 (r2-y (y r2)))
		     (adjust-subtrees-x (list r2) g2 (- (x r1) (x r2)))
		     (cond ((> r1-y r2-y)
			    (adjust-subtrees-y rest2 g2 (- r1-y r2-y)))
			   ((< r1-y r2-y)
			    (adjust-subtrees-y rest1 g1 (- r2-y r1-y))))))))))
  (:method ((graph centered-vertical-layout) (g1 subgraph) (g2 subgraph))
    (let ((g1rnodes (rootnodes g1))
	  (g2rnodes (rootnodes g2)))
      (loop for r1 in (rootnodes g1)
	    do (let ((r2 (or (find-node (label r1) g2)
			     (find-node (concatenate 'string (label r1) "...") g2)
			     (find-node (concatenate 'string "..." (label r1)) 
					g2)))
		     (rest1 (member r1 g1rnodes)))
		 (when r2
		   (let ((rest2 (member r2 g2rnodes))
			 (r1-x (x r1))
			 (r2-x (x r2)))
		     (adjust-subtrees-y (list r2) g2 (- (y r1) (y r2)))
		     (cond ((> r1-x r2-x)
			    (adjust-subtrees-x rest2 g2 (- r1-x r2-x)))
			   ((< r1-x r2-x)
			    (adjust-subtrees-x rest1 g1 (- r2-x r1-x)))))))))))

(defmethod adjust-subtrees-x ((nodes list) (graph graph-layout) x-diff)
  (loop for root in nodes
	do (setf (x root) (+ (x root) x-diff))
	   (loop for node in (node-subtree root graph nil)
		 do (setf (x node) (+ (x node) x-diff)))))

(defmethod adjust-subtrees-y ((nodes list) (graph graph-layout) y-diff)
  (loop for root in nodes
	do (setf (y root) (+ (y root) y-diff))
	   (loop for node in (node-subtree root graph nil)
		 do (setf (y node) (+ (y node) y-diff)))))

;; Initialize the layout flags of each node to nil.
(defmethod graph-layout-init ((graph side-layout))
  (loop for node in (allnodes graph) 
	do (setf (depth-set node) nil 
		 (breadth-set node) nil))
  (loop for arc in (arcs graph)
	do (setf (cross-link arc) nil)))


;;; Depth layout -- layout the dimension of the graph corresponding
;;; to the depth of the graph tree.  In horizontal layouts this is
;;; the x dimension, in vertical layouts this is the y dimension.

;; Layout the depth of the graph by walking the graph from the leaves
;; to the parents.
(defmethod graph-depth-layout ((graph side-layout))
  (loop for node in (leafnodes graph) 
	do (depth-layout node graph)))

;; Layout depth of each node by laying out parents first, then using the
;; furthest parent and the ancestor spacing to layout node.
(defmethod depth-layout ((node node) (graph side-layout))
  (unless (depth-set node)
    (loop for parent in (parent-nodes node)
	  with anyparents = nil
	  do (setf anyparents t)
	     (depth-layout parent graph)
	  finally (when (display-p node)
		    (if anyparents
			(depth-node-layout node graph)
		        (depth-root-layout node graph))))))

;; Layout depth of node based on parents.  Varies by layout.
(defgeneric depth-node-layout (node graph)
  (:method ((node node) (graph left-right-layout))
	   (declare (restrictive-ftype (function (fixnum &rest fixnum) fixnum) +))
	   (setf (depth-set node) t
		 (x node)
		 (+ (loop for parent in (parent-nodes node)
			  maximize (+ (x parent) (width parent)) fixnum)
		    (ancestor-spacing graph))))
  (:method ((node node) (graph right-left-layout))
	   (declare (restrictive-ftype (function (fixnum &rest fixnum) fixnum) -)
		    (restrictive-ftype (function (node) fixnum) x))
	   (setf (depth-set node) t
		 (x node)
		 (- (loop for parent in (parent-nodes node)
			  minimize (x parent) fixnum)
		    (width node)
		    (ancestor-spacing graph))))
  (:method ((node node) (graph top-bottom-layout))
	   (declare (restrictive-ftype (function (fixnum &rest fixnum) fixnum) +))
	   (setf (depth-set node) t
		 (y node)
		 (+ (loop for parent in (parent-nodes node)
			  maximize (+ (y parent) (height parent)) fixnum)
		    (ancestor-spacing graph))))
  (:method ((node node) (graph bottom-top-layout))
	   (declare (restrictive-ftype (function (fixnum &rest fixnum) fixnum) -)
		    (restrictive-ftype (function (node) fixnum) y))
	   (setf (depth-set node) t
		 (y node)
		 (- (loop for parent in (parent-nodes node)
			  minimize (y parent) fixnum)
		    (height node)
		    (ancestor-spacing graph)))))

;; Layout root.  Varies by layout.
(defgeneric depth-root-layout (node graph)
  (:method ((node node) (graph right-left-layout))
	   (declare (restrictive-ftype (function (fixnum &rest fixnum) fixnum) -))
	   (setf (depth-set node) t
		 (x node) (- (root-depth graph) (width node))))
  (:method ((node node) (graph left-right-layout))
	   (setf (depth-set node) t
		 (x node) (root-depth graph)))
  (:method ((node node) (graph top-bottom-layout))
	   (declare (restrictive-ftype (function (fixnum &rest fixnum) fixnum) +))
	   (setf (depth-set node) t
		 (y node) (+ (root-depth graph) (height node))))
  (:method ((node node) (graph bottom-top-layout))
	   (setf (depth-set node) t
		 (y node) (root-depth graph))))

;;; Breadth layout -- layout the dimension of the graph corresponding
;;; to the breadth of the graph tree.  In horizontal layouts this is
;;; the y dimension, in vertical layouts this is the x dimension.  In
;;; both layouts, the last variable (last breadth position) initially
;;; starts at the origin (0).

;; Breadth layout via root nodes making sure to keep the last
;; breadth of the graph.
(defmethod graph-breadth-layout ((graph side-layout))
  (loop for node in (rootnodes graph) 
	with last fixnum = 0
	when (display-p node)
	do (setf last (breadth-layout node graph last))))

;; Layout each node breadth dimension by first laying out the breadth 
;; of the children and then laying out the node breadth as their average.
(defmethod breadth-layout ((node node) (graph side-layout) last)
  (declare (fixnum last))
  (loop for child in (children-nodes node)
	with unsetchildren = nil
	when (breadth-set child)
	do (setf (cross-link (relation-between node child graph)) t)
	unless (or (breadth-set child) (not (display-p child)))
	do (setf unsetchildren t)
	   (setf last (breadth-layout child graph last))
	finally (unless (breadth-set node)
		  (if unsetchildren
		      (setf last (breadth-parent-layout node graph last))
		      (setf last (breadth-node-layout node graph last)))))
  last)

;; Layout breadth dimension of parent based on children.
(defgeneric breadth-parent-layout (node graph last)
  (:method ((node node) (graph horizontal-layout) last)
	   (declare (fixnum last)
		    (restrictive-ftype (function (node) fixnum) y)
		    (restrictive-ftype (function (fixnum fixnum) fixnum) floor))
	   (let ((breadth (floor (loop for child in (children-nodes node nil) 
				       sum (y child))
				 (length (children-nodes node nil)))))
	     (when (and (> (length (children-nodes node nil)) 1)
			(loop for child in (children-nodes node nil)
			      always (= breadth (y child))))
	       (setq breadth (+ breadth (height node))))
	     (setf (breadth-set node) t (y node) breadth)
	     ;; return the greater of breadth or last as the new last
	     (if (>= breadth last) breadth last)))
  (:method ((node node) (graph vertical-layout) last)
	   (declare (fixnum last)
		    (restrictive-ftype (function (node) fixnum) x)
		    (restrictive-ftype (function (fixnum fixnum) fixnum) +)
		    (restrictive-ftype (function (node) fixnum) width)
		    (restrictive-ftype (function (fixnum fixnum) fixnum) floor))
	   (let ((breadth (floor (loop for child in (children-nodes node nil) 
				       sum (x child))
				 (length (children-nodes node nil)))))
	     (when (and (> (length (children-nodes node nil)) 1)
			(loop for child in (children-nodes node nil)
			      always (= breadth (x child))))
	       (setq breadth (+ breadth (width node))))
	     (setf (breadth-set node) t (x node) breadth)
	     ;; return the greater of breadth or last as the new last
	     (let ((newbreadth (+ breadth (width node))))
	       (if (>= newbreadth last) newbreadth last)))))

;; Layout breadth dimension of node (usually leaf) based on last.
(defgeneric breadth-node-layout (node graph last)
  (:method ((node node) (graph horizontal-layout) last)
	   (declare (fixnum last)
		    (restrictive-ftype (function (fixnum &rest fixnum) fixnum) +)
		    (restrictive-ftype (function (node) fixnum) y))
	   (setf (breadth-set node) t
		 (y node) 
		 (+ last (height node) (sibling-spacing graph))))
  (:method ((node node) (graph vertical-layout) last)
	   (declare (fixnum last)
		    (restrictive-ftype (function (fixnum &rest fixnum) fixnum) +)
		    (restrictive-ftype (function (node) fixnum) x))
	   (setf (breadth-set node) t
		 (x node) 
		 (+ last (sibling-spacing graph)))
	   ;; last is last node plus it's width
	   (+ (x node) (sibling-spacing graph) (width node))))


;;; Center the breadth of the graph in the view region by taking the
;;; center of the roots and adjusting the entire graph (the breadth
;;; dimension).

;; Center roots of graph.  Horizontal layouts.
(defmethod graph-breadth-centered ((graph horizontal-layout))
  (declare (restrictive-ftype (function (node) fixnum) y)
	   (restrictive-ftype (function (fixnum fixnum) fixnum) -)
	   (restrictive-ftype (function (fixnum fixnum) fixnum) +)
	   (restrictive-ftype (function (fixnum fixnum) fixnum) floor))
  (let ((roots (rootnodes graph))
	(view-breadth (view-height graph)))
    (let ((root-breadth (- (loop for root in roots 
				 maximize (y root) fixnum)
			   (loop for root in roots
				 minimize (y root) fixnum))))
      (let ((adjustment (- (floor view-breadth 2) root-breadth)))
	(loop for node in (allnodes graph)
	      do (setf (y node)
		       (+ (y node) adjustment)))))))

;; Center roots of graph.  Vertical layouts.
(defmethod graph-breadth-centered ((graph vertical-layout))
  (declare (restrictive-ftype (function (node) fixnum) x)
	   (restrictive-ftype (function (fixnum fixnum) fixnum) -)
	   (restrictive-ftype (function (fixnum fixnum) fixnum) +)
	   (restrictive-ftype (function (fixnum fixnum) fixnum) floor))
  (let ((roots (rootnodes graph))
	(view-breadth (view-width graph)))
    (let ((root-breadth (- (loop for root in roots 
				 maximize (x root) fixnum)
			   (loop for root in roots
				 minimize (x root) fixnum))))
      (let ((adjustment (- (floor view-breadth 2) root-breadth)))
	(loop for node in (allnodes graph)
	      do (setf (x node)
		       (+ (x node) adjustment)))))))

;;; Layout the arc based on the nodes that make up the endpoints.


;; graph arc layout
(defmethod graph-arc-layout ((graph side-layout))
  (loop for arc in (arcs graph) do (arc-layout arc graph)))
  
;; Arc layout.  Varies by layout.
(defgeneric arc-layout (arc graph)
  (:method ((arc arc) (graph left-right-layout))
	   (declare (restrictive-ftype (function (fixnum fixnum) fixnum) +)
		    (restrictive-ftype (function (fixnum fixnum) fixnum) -)
		    (restrictive-ftype (function (arc) fixnum) to-x)
		    (restrictive-ftype (function (arc) fixnum) to-y)
		    (restrictive-ftype (function (arc) fixnum) from-x)
		    (restrictive-ftype (function (arc) fixnum) from-x)
		    (restrictive-ftype (function (fixnum fixnum) fixnum) floor))
	   (let ((fromnode (fromnode arc))
		 (tonode (tonode arc)))
	     (when (and (display-p fromnode) (display-p tonode))
	       (setf (from-x arc) (+ (x fromnode) (width fromnode) 2)
		     (from-y arc) (- (y fromnode) (floor (height fromnode) 2))
		     (to-x arc) (- (x tonode) 4)
		     (to-y arc) (- (y tonode) (floor (height tonode) 2))))))
  (:method ((arc arc) (graph right-left-layout))
	   (declare (restrictive-ftype (function (fixnum &rest fixnum) fixnum) +)
		    (restrictive-ftype (function (fixnum fixnum) fixnum) -)
		    (restrictive-ftype (function (arc) fixnum) to-x)
		    (restrictive-ftype (function (arc) fixnum) to-y)
		    (restrictive-ftype (function (arc) fixnum) from-x)
		    (restrictive-ftype (function (arc) fixnum) from-x)
		    (restrictive-ftype (function (fixnum fixnum) fixnum) floor))
	   (let ((fromnode (fromnode arc))
		 (tonode (tonode arc)))
	     (when (and (display-p fromnode) (display-p tonode))
	       (setf (from-x arc) (- (x fromnode) 4)
		     (from-y arc) (- (y fromnode) (floor (height fromnode) 2))
		     (to-x arc) (+ (x tonode) (width tonode) 2)
		     (to-y arc) (- (y tonode) (floor (height tonode) 2))))))
  (:method ((arc arc) (graph top-bottom-layout))
	   (declare (restrictive-ftype (function (fixnum &rest fixnum) fixnum) -)
		    (restrictive-ftype (function (fixnum fixnum) fixnum) +)
		    (restrictive-ftype (function (arc) fixnum) to-x)
		    (restrictive-ftype (function (arc) fixnum) to-y)
		    (restrictive-ftype (function (arc) fixnum) from-x)
		    (restrictive-ftype (function (arc) fixnum) from-x)
		    (restrictive-ftype (function (fixnum fixnum) fixnum) floor))
	   (let ((fromnode (fromnode arc))
		 (tonode (tonode arc)))
	     (when (and (display-p fromnode) (display-p tonode))
	       (setf (from-x arc) (+ (x fromnode) (floor (width fromnode) 2))
		     (from-y arc) (+ (y fromnode) 2)
		     (to-x arc) (+ (x tonode) (floor (width tonode) 2))
		     (to-y arc) (- (y tonode) (height tonode) 2)))))
  (:method ((arc arc) (graph bottom-top-layout))
	   (declare (restrictive-ftype (function (fixnum &rest fixnum) fixnum) -)
		    (restrictive-ftype (function (fixnum fixnum) fixnum) +)
		    (restrictive-ftype (function (arc) fixnum) to-x)
		    (restrictive-ftype (function (arc) fixnum) to-y)
		    (restrictive-ftype (function (arc) fixnum) from-x)
		    (restrictive-ftype (function (arc) fixnum) from-x)
		    (restrictive-ftype (function (fixnum fixnum) fixnum) floor))
	   (let ((fromnode (fromnode arc))
		 (tonode (tonode arc)))
	     (when (and (display-p fromnode) (display-p tonode))
	       (setf (from-x arc) (+ (x fromnode) (floor (width fromnode) 2))
		     (from-y arc) (- (y fromnode) (height fromnode) 2)
		     (to-x arc) (+ (x tonode) (floor (width tonode) 2))
		     (to-y arc) (+ (y tonode) 2)))))
  (:method ((arc arc) (graph centered-layout))
	   (let ((g1 (ancestor-graph graph))
		 (g2 (descendant-graph graph)))
	     (let ((g (cond ((find arc (arcs g1)) g1)
			    ((find arc (arcs g2)) g2))))
	       (when g
		 (arc-layout arc g))))))

;; New version of remove-cycles.  This version simply assumes
;; that the back arcs have already been marked during the
;; graph construction (otherwise must run a graph walker that
;; constructs the ancestor lists (update-ancestors), etc.) and
;; so only needs to find those back arcs and duplicate.
(defmethod remove-cycles ((graph side-layout))
  (loop for arc in (arcs graph)
	when (back-link arc)
	do (duplicate (fromnode arc) (tonode arc) graph)))

(defmethod remove-cycles ((graph centered-layout))
  (remove-cycles (ancestor-graph graph))
  (remove-cycles (descendant-graph graph)))

;; dup child node as a subnode of node
(defmethod duplicate ((node node) (child node) (graph abstract-graph))
  (let ((dup (make-node (label child) (object child) graph
			:duplicates child))
	(relation (relation-between node child graph)))
    (setf (is-duplicated-by child) dup)
    (remove-descendant relation node child graph)
    (if (member node (leafnodes graph) :test #'eq)
	(setf (leafnodes graph)
	      (substitute dup node (leafnodes graph) :test #'eq)))
    (let ((arc (make-arc (class-of relation) graph))
	  (depth (depth node))
	  (limit (or (depth-limit node) (depth-limit graph))))
      (setf (depth-limit dup) (depth-limit node))
      (when (>= depth limit)
	(setf (display-p dup) nil))
      (add-node dup graph)
      (add-arc arc graph)
      (link-nodes node dup arc graph))))


;;;
;;; updatete node and arc regions after layout
;;;
  
;; Update arc and node regions.
(defmethod graph-update-regions ((graph graph-layout))
  (loop for arc in (arcs graph) do (update-arc-region arc graph))
  (loop for node in (allnodes graph) do (update-node-region node graph)))

;; Update the arc regions.
(defmethod update-arc-region ((arc arc) (graph graph-layout))
  (declare (restrictive-ftype (function (arc) fixnum) from-x)
	   (restrictive-ftype (function (fixnum fixnum) fixnum) min)
	   (restrictive-ftype (function (fixnum fixnum) fixnum) max)
	   (restrictive-ftype (function (arc) fixnum) from-y)
	   (restrictive-ftype (function (arc) fixnum) to-x)
	   (restrictive-ftype (function (arc) fixnum) to-y))
  (let ((region (region arc)))
    (setf (region-left region :stretch) (min (from-x arc) (to-x arc))
	  (region-right region :stretch) (max (from-x arc) (to-x arc))
	  (region-top region :stretch) (min (from-y arc) (to-y arc))
	  (region-bottom region :stretch) (max (from-y arc) (to-y arc))
	  (region arc) region)))

;; Update the node region.  .. completely
(defmethod update-node-region ((node node) (graph graph-layout))
  (declare (restrictive-ftype (function (node) fixnum) x)
	   (restrictive-ftype (function (node) fixnum) y)
	   (restrictive-ftype (function (region) fixnum) region-left)
	   (restrictive-ftype (function (region) fixnum) region-bottom)
	   (restrictive-ftype (function (region) fixnum) region-width)
	   (restrictive-ftype (function (region) fixnum) region-height))
  (let ((region (region node)))
    (setf (region-width region) (width node)
	  (region-height region) (height node)
	  (region-left region) (x node)
	  (region-bottom region) (y node)
	  (region node) region)))


;;;
;;; change node labels for depth
;;;

(defmethod make-depth-label (node graph) nil)

(defmethod unmake-depth-label (node graph) nil)

;; change string node label (used to show depth)
(defgeneric make-depth-label (node graph)
  (:method ((node string-node) (graph graph-layout))
    (change-label node (concatenate 'string (label (object node)) "...")))
  (:method ((node string-node) (graph right-left-layout))
    (change-label node (concatenate 'string "..." (label (object node)))))
  (:method ((node string-node) (graph centered-layout))
    (let ((rg (associated-graph node graph)))
      (if (eq graph rg) 
	  (call-next-method)
	  (make-depth-label node rg)))))

(defmethod unmake-depth-label ((node string-node) (graph graph-layout))
  (let ((str (label node)))
    (change-label node (label (object node)))))

(defmethod change-label ((node string-node) (string string))
  (let ((r (region node)))
    (setf (label node) string
	  (width node) (label-width node)
	  (height node) (label-height node)
	  (region-width r) (width node)
	  (region-height r) (height node)
	  (region node) r)))
