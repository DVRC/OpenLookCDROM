;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;;  File: grapher-util.lisp
;;;;
;;;;  Author: Philip McBride
;;;;
;;;;  This file contains some utilities used by the grapher for
;;;;  construction, layout, and interface.
;;;;
;;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;;	See LEGAL_NOTICE file for terms of the license.
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package :grapher)


;; make a text method that works on all nodes
;; in the case of non image nodes, it uses label
;; for image, see above, it uses the text slot
(defmethod text ((node node))
  (label node))

;; get the parent nodes up the uplinks
(defmethod parent-nodes ((node node) &optional (include-cross-links t)
			 (include-back-links nil))
  (loop for fromarc in (fromarcs node) 
	when (or include-cross-links (not (cross-link fromarc)))
	  when (or include-back-links (not (back-link fromarc)))
	    when (display-p fromarc)
	      collect (fromnode fromarc)))
	
;; get the children nodes down the downlinks
(defmethod children-nodes ((node node) &optional (include-cross-links t)
			   (include-back-links nil))
  (loop for toarc in (toarcs node) 
	when (or include-cross-links (not (cross-link toarc)))
	  when (or include-back-links (not (back-link toarc)))
	    when (display-p toarc)
	      collect (tonode toarc)))

;; walk graph
(defmethod walk-graph ((graph abstract-graph) walk-method)
  (declare (compiled-function walk-method))
  (labels ((walk (node)
	     (funcall walk-method node graph)
	     (loop for child-node in (children-nodes node)
		   do (walk child-node))))
    (loop for root in (rootnodes graph) do
	  (walk root))))

;; get relation between two nodes
(defmethod relation-between ((parent node) (child node) (graph abstract-graph))
  (find-if #'(lambda (arc) (eq child (tonode arc))) (toarcs parent)))

;; compare two user objects
(defmethod object-equal (object1 object2)
  (eq object1 object2))

(defmethod object-equal ((object1 string) (object2 string))
  (string= object1 object2))

;; testing ...
(defmethod object-equal ((object1 t) (object2 cons))
  (object-equal object1 (car object2)))

;; testing ...
(defmethod object-equal ((object1 cons) (object2 t))
  (object-equal (car object1) object2))

;; get descendants of node
(defgeneric descendants (node graph)
  (:method ((node node) (graph left-right-layout))
    (node-subtree node graph))
  (:method ((node node) (graph right-left-layout))
    (node-supertree node graph))
  (:method ((node node) (graph bottom-top-layout))
    (node-supertree node graph))
  (:method ((node node) (graph top-bottom-layout))
    (node-subtree node graph))
  (:method ((node node) (graph centered-layout))
    (let ((dg (descendant-graph graph)))
      (if (root node)
	  (descendants (find-node (label node) dg) dg)
	  (let ((rg (associated-graph node graph)))
	    (let ((d (descendants node rg)))
	      (let ((more (loop for nd in d
				when (root nd)
				nconc (descendants 
				       (find-node (label nd) dg) 
				       dg))))
		(nconc d more))))))))

;; get ancestors of node
(defgeneric ancestors (node graph)
  (:method ((node node) (graph left-right-layout))
    (node-supertree node graph))
  (:method ((node node) (graph right-left-layout))
    (node-subtree node graph))
  (:method ((node node) (graph bottom-top-layout))
    (node-subtree node graph))
  (:method ((node node) (graph top-bottom-layout))
    (node-supertree node graph))
  (:method ((node node) (graph centered-layout))
    (let ((ag (ancestor-graph graph)))
      (if (root node)
	  (ancestors (find-node (label node) ag) ag)
	  (let ((rg (associated-graph node graph)))
	    (let ((d (ancestors node rg)))
	      (let ((more (loop for nd in d
				when (root nd)
				nconc (ancestors (find-node (label nd) ag) ag))))
		(nconc d more))))))))

;; collect subtree of nodes below node
(defmethod node-subtree ((node node) (graph abstract-graph)
			 &optional (include-cross-links t))
  (loop for node in (allnodes graph) do (setf (depth-set node) nil))
  (labels ((collect-subtree (node)
	     (or (loop for child in (children-nodes node include-cross-links)
		       nconc (cons child (collect-subtree child)))
		 (list node))))
    (remove-duplicates (remove node (collect-subtree node)))))

;; collect supertree of nodes above node
(defmethod node-supertree ((node node) (graph abstract-graph)
			   &optional (include-cross-links t))
  (loop for node in (allnodes graph) do (setf (depth-set node) nil))
  (labels ((collect-supertree (node)
	     (or (loop for parent in (parent-nodes node include-cross-links)
		       nconc (cons parent (collect-supertree parent)))
		 (list node))))
    (remove-duplicates (remove node (collect-supertree node)))))

;; collect siblings of node
(defmethod node-siblings ((node node) (graph abstract-graph))
  (loop for parent in (parent-nodes node)
	nconcing (loop for child in (children-nodes parent)
		       unless (eq child node)
		       collect child)))

;; get active roots
(defmethod graph-roots ((graph abstract-graph))
  (loop for node in (allnodes graph)
	with parents
	do (setq parents (parent-nodes node))
	unless (and parents
		  (loop for p in parents 
			always (display-p p)))
	collect node))

;; get active leaves
(defmethod graph-leaves ((graph abstract-graph))
  (loop for node in (allnodes graph)
	with children
	do (setq children (children-nodes node))
	unless (and children
		  (loop for c in children
			always (display-p c)))
	collect node))

;; find a node associated with a string in the graph.
(defmethod find-node ((string string) (graph graph-layout))
  (cdr (assoc string (nodelabels graph) :test #'string=)))

;; default method, just search through all nodes of a graph
;; for some label that is *equal* to a node's label.
(defmethod find-node (label (graph graph-layout))
  (loop for node in (allnodes graph)
	when (equal label (label node))
	do (return node)))

(defmethod scroll-to-node ((node node) (graph graph))
  (declare (restrictive-ftype (function (fixnum fixnum) fixnum) +)
	   (restrictive-ftype (function (fixnum fixnum) fixnum) floor))
  (let ((vp (canvas (buffer graph))))
    (let ((view (view-region vp))
	  (output (output-region vp)))
      (setf (region-right view :move) (+ (floor (region-width view) 2) 
					 (if node
					     (+ (x node)
						(floor (width node) 2))
					   (floor (region-right output) 2)))
	    (region-bottom view :move) (if (or (null node)
					       (region-contains-xy-p 
						view
						(x node) (y node)))
					   (region-bottom view)
					   (+ (floor (region-height view) 2)
					      (y node)
					      (floor (height node) 2)))
	    (view-region vp) view))))

(defgeneric region-to-node (x y graph)
  (:method (x y (graph graph-layout))
    (declare (fixnum x y))
    (cdr
     (find-if #'(lambda (tuple) 
		  (and (display-p (cdr tuple)) ;; should tuple be here in this case?
		       (region-contains-xy-p (car tuple) x y)))
	      (noderegions graph))))
  (:method (x y (graph centered-layout))
    (let ((node (call-next-method)))
      (if (and node (root node))
	  (let ((g1 (descendant-graph graph))
		(g2 (ancestor-graph graph)))
	    (values node
		    (region-to-node x y g1)
		    (region-to-node x y g2)))
	  node))))

(defmethod region-to-arc (x y (graph graph-layout))
  (declare (fixnum x y))
  (cdr
   (find-if #'(lambda (tuple) 
		(region-contains-xy-p (car tuple) x y))
	    (arcregions graph))))

(defgeneric associated-graph (node graph)
  (:method ((node node) (graph graph-layout))
    graph)
  (:method ((node node) (graph centered-layout))
   (if (root node)
       graph
       (let ((g1 (descendant-graph graph))
	     (g2 (ancestor-graph graph)))
	 (cond ((find node (allnodes g1))
		g1)
	       ((find node (allnodes g2))
		g2)
	       (t graph))))))

;;; buffer fns.  since buffers are pushed, previous and next
;;; are the opposite of what you would think--you silly person.

(defmethod push-buffer ((buffer graph-buffer) (display drawable))
  (let ((tool (tool display))
	(graph (graph buffer)))
    (when tool
      (update-gr-output graph display)
      (update-icon buffer (base tool))
      (setf (tool graph) tool)
      (setf (tool buffer) tool)
      (setf (canvas buffer) display)
      (setf (current-buffer display) buffer))))

(defmethod push-buffer ((buffer graph-buffer) (tool graph-tool))
  (let ((canvas (current-viewer tool))
	(graph (graph buffer)))
    (update-icon buffer (base tool))
    (setf (tool graph) tool)
    (setf (tool buffer) tool)
    (setf (canvas buffer) canvas)
    (setf (current-buffer canvas) buffer)
    (update-gr-output graph canvas)
    (center-graph-window graph)))

(defmethod update-icon ((buffer graph-buffer) (base graph-base-window-mixin))
  (let* ((icon (lv::icon base))
	 (label (lv::label icon))
	 (image (if (consp label) (second label) label)))
    (setf (lv::label icon)
	  (list (name buffer)
		image))))

(defmethod previous-buffer ((graph graph))
  (let ((buffer (buffer graph))
	(tool (tool graph)))
    (let ((pre (cdr (member buffer (buffers tool)))))
      (if pre
	  (car pre)
	  buffer))))

(defmethod next-buffer ((graph graph))
  (let ((buffer (buffer graph))
	(tool (tool graph)))
    (let ((post (cdr (member buffer (reverse (buffers tool))))))
      (if post
	  (car post)
	  buffer))))

;; method to change the view of a buffer
(defmethod change-view ((buffer graph-buffer) direction)
  (let ((graph (graph buffer)))
    (case direction
      (:both (switch-to-both buffer graph))
      (:ancestor (switch-to-ancestor buffer graph))
      (:descendant (switch-to-descendant buffer graph))
      (otherwise (cerror "Internal Error: Illegal direction for change-view: ~a~% Retry with one of :both, :ancestor, or :descendant" direction)))))

;; do nothing, already correct
(defmethod switch-to-both ((buffer graph-buffer) (graph centered-layout))
  nil)

(defmethod switch-to-ancestor ((buffer graph-buffer) 
			       (graph right-left-layout))
  nil)

(defmethod switch-to-descendant ((buffer graph-buffer) 
				 (graph left-right-layout))
  nil)

;; do the switching
(defmethod switch-to-both ((buffer graph-buffer) (graph graph))
  (let* ((both (centered-graph-view buffer))
	 (tool (unless both (tool buffer)))
	 (both-class (unless both (both-view-class tool))))
    (if both
	(setf (graph buffer) both)
	(setf both (make-instance both-class :buffer buffer :tool tool
				  :roots (roots graph))
	      (graph buffer) both
	      (centered-graph-view buffer) both))
    (relayout both)))

(defmethod switch-to-ancestor ((buffer graph-buffer) (graph graph))
  (let* ((anc (ancestor-graph-view buffer))
	 (tool (unless anc (tool buffer)))
	 (anc-class (unless anc (ancestor-view-class tool))))
    (if anc
	(setf (graph buffer) anc)
	(setf anc (make-instance anc-class :buffer buffer :tool tool
				 :roots (roots graph))
	      (graph buffer) anc
	      (ancestor-graph-view buffer) anc))
    (relayout anc)))

(defmethod switch-to-descendant ((buffer graph-buffer) (graph graph))
  (let* ((desc (descendant-graph-view buffer))
	 (tool (unless desc (tool buffer)))
	 (desc-class (unless desc (descendant-view-class tool))))
    (if desc
	(setf (graph buffer) desc)
	(setf desc (make-instance desc-class :buffer buffer :tool tool
				  :roots (roots graph))
	      (graph buffer) desc
	      (descendant-graph-view buffer) desc))
    (relayout desc)))


;;; depth cut off methods
(defmethod change-depth-level ((graph graph) level)
  (declare (fixnum level))
  (loop for node in (allnodes graph)
	when (> (depth node) level)
	do (setf (display-p node) nil))
  ;; insert a depth-label update call here...
  ;; insert update display here...
  )
