;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;;  File: grapher-construct.lisp
;;;;
;;;;  Author: Philip McBride
;;;;
;;;;  This file contains the graph construction code that deals
;;;;  with the creation of the graph and the nodes and arcs of the
;;;;  graph.  It also contains the transitive closure code--the code
;;;;  that handles how to construct the graph based on relatiosn.
;;;;
;;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;;	See LEGAL_NOTICE file for terms of the license.
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package :grapher)


;;;
;;; node methods
;;;

;; create node for illegal label
(defmethod make-node (label object (graph abstract-graph) &rest initargs)
  (declare (ignore initargs))
  (error "Error: Illegal Graph Label: ~a for Object: ~a" 
	 label object))

;; create string node
(defmethod make-node ((label string) object (graph abstract-graph) &rest initargs)
  (apply #'make-instance 'plain-str-node :label label :object object initargs))

;; create image node
(defmethod make-node ((label image) object (graph abstract-graph) &rest initargs)
  (apply #'make-instance 'plain-image-node :label label :object object initargs))

;; add/remove node to graph
(defmethod add-node ((node node) (graph abstract-graph))
  (let ((obj (object node)))
    (cond ((root node)
	   (pushnew node (rootnodes graph))
	   (pushnew obj (roots graph)))
	  (t (pushnew node (nonrootnodes graph))
	     (pushnew obj (nonroots graph))))
    (pushnew node (allnodes graph))
    (setf (gethash obj (objecttable graph)) node)
    (pushnew (cons (region node) node) (noderegions graph))
    (setf (gcount graph)
	  (setf (gcount node)
		(1+ (gcount graph))))))

(defmethod add-node ((node string-node) (graph abstract-graph))
  (call-next-method)
  (pushnew (cons (label node) node) (nodelabels graph)))
  
;; dummy for now--should unlink-ancestor-nodes and unlink-descendant-nodes.
(defmethod remove-node ((node node) (graph abstract-graph))
  t)

;;; label method for a couple of object types
(defgeneric label (object)
  (:method (object)
    (format nil "~a" object))
  (:method ((object cons))
    (label (car object)))
  (:method ((object string))
    object)
  (:method ((object image))
    object)
  (:method ((object symbol))
    (format nil "~(~a~)" obj)))

;;;
;;; arc methods
;;;

(defmethod make-arc ((relation relation-meta) (graph abstract-graph) 
		     &rest initargs)
  (apply #'make-instance relation initargs))

(defmethod add-arc ((arc arc) (graph abstract-graph))
  (pushnew arc (arcs graph))
  (pushnew (cons (region arc) arc) (arcregions graph)))

(defmethod remove-arc ((arc arc) (graph abstract-graph))
  (setf (arcs graph) (remove arc (arcs graph)))
  (setf (arcregions graph) (remove (cons (region arc) arc)
				   (arcregions graph))))

(defmethod link-nodes ((domain node) (range node) (arc arc) 
		       (graph abstract-graph))
  (let ((back-link (back-link? domain range arc graph)))
    (push arc (toarcs domain))
    (push arc (fromarcs range))
    (setf (fromnode arc) domain)
    (setf (tonode arc) range)
    (if back-link
	(setf (back-link arc) t)
        (add-ancestors domain range arc graph))))

(defmethod back-link? ((domain node) (range node) (arc arc) 
		       (graph abstract-graph))
  (or (back-link arc)
      (eq domain range)
      (member (gcount range) (gancestors domain) :test #'=)))

(defmethod add-ancestors ((domain node) (range node) 
					(arc arc) (graph abstract-graph))
  (let ((ancestors (gancestors range)))
    (loop for count in (gancestors domain)
	  do (pushnew count ancestors)
	  finally (pushnew (gcount domain) ancestors)
	  (setf (gancestors range) ancestors))
    (let ((newancestors (cons (gcount range) ancestors)))
      (loop for child in (children-nodes range)
	    do (incremental-update-ancestors 
		child graph newancestors)))))

(defmethod unlink-descendant-nodes ((domain node) (range node) 
			 (arc arc) (graph abstract-graph))
  (setf (toarcs domain) (remove arc (toarcs domain)))
  (setf (fromarcs range) (remove arc (fromarcs range)))
  (setf (tonode arc) nil)
  (setf (fromnode arc) nil)
  (unless (back-link arc)
    (update-ancestors range graph)))

(defmethod unlink-ancestor-nodes ((domain node) (range node) 
			 (arc arc) (graph abstract-graph))
  (setf (toarcs domain) (remove arc (toarcs domain)))
  (setf (fromarcs range) (remove arc (fromarcs range)))
  (setf (tonode arc) nil)
  (setf (fromnode arc) nil))

(defmethod incremental-update-ancestors ((node node) (graph abstract-graph) ancestors)
  (let ((newancestors (gancestors node)))
    (loop for count in ancestors
	  do (pushnew count newancestors)
	  finally (setf (gancestors node) newancestors))
    (let ((final (cons (gcount node) newancestors)))
      (loop for child in (children-nodes node)
	    do (incremental-update-ancestors 
		child graph final)))))

;; recalculate ancestors of node
;; this is used after range unlinked from domain
(defmethod update-ancestors ((node node) (graph abstract-graph))
  (loop for parent in (parent-nodes node)
	with ancestors = '()
	do (loop for ancestor in (gancestors parent)
		 do (pushnew ancestor ancestors))
	finally (pushnew (gcount parent) ancestors)
	        (setf (gancestors node) ancestors))
  (loop for child in (children-nodes node)
	do (update-ancestors child graph)))


;;;
;;; relation construction methods
;;;

;;; full transitive closure
(defmethod transitive-closure ((relation-class full-t-c) (domain node) 
			       (graph abstract-graph) &optional (depth 0))
  (declare (fixnum depth))
  (let ((relations (relations graph))
	(descendants (get-range-objects relation-class (object domain) graph))
	(limit (or (depth-limit domain) (depth-limit graph))))
    (declare (fixnum limit))
    ;; if there are descendants then add the descendant to the graph and recur.
    (loop for descendant in descendants 
	  with anynew = nil and anyold = nil do
	  (multiple-value-bind (range old)
	      (add-descendant relation-class domain 
			      descendant graph depth)
	    ;; run into any old nodes?
	    (setf anyold (or anyold old))
	    ;; loop for all relations to recur.
	    (unless old
	      (setf anynew t)
	      (loop for rel-class in relations do
		    (transitive-closure rel-class range graph (1+ depth)))))
	  finally (unless (or anynew                  ;; leaf?
			      (and anyold
				   (not 
				    (loop for arc in (toarcs domain)
					  always (back-link arc)))))
		    (pushnew domain (leafnodes graph)))
	          (when (and descendants (= depth limit) ;; virtual leaf?
			     (null anyold))
		    (make-depth-label domain graph)))))  ;; soon to be replaced
	  
;;; lazy transitive closure
(defmethod transitive-closure ((relation-class lazy-t-c) (domain node) 
			       (graph abstract-graph) &optional (depth 0))
  (declare (fixnum depth))
  (let ((relations (relations graph))
	(limit (or (depth-limit domain) (depth-limit graph))))
    (declare (fixnum limit))
    (cond ((< depth limit)
	   (loop for descendant
		 in (get-range-objects relation-class (object domain) graph) 
		 with anyold = nil and anynew = nil do
		 (multiple-value-bind (range oldnode)
		     (add-descendant relation-class domain 
				     descendant graph depth)
		   ;; any old nodes?
		   (setf anyold (or anyold oldnode))
		   ;; loop for all relations to recur.
		   (unless oldnode
		     (setf anynew t)
		     (loop for rel-class in relations do
			   (transitive-closure rel-class range
					       graph (+ 1 depth)))))
		 finally (unless 
			     (or anynew                     ;; leaf?
				 (and anyold
				      (not
				       (loop for arc in (toarcs domain)
					     always (back-link arc)))))
			   (pushnew domain (leafnodes graph)))))
	  (t (push (make-expand-continuation domain relation-class graph)
		   (expand-continuation domain))
	     (pushnew domain (leafnodes graph))
	     (make-depth-label domain graph)))))

;;; Main get range object method for the relation class.  This method
;;; just calls itself on the class prototype--hack alert.
(defmethod get-range-objects ((relation-class relation-meta) 
			      domain-obj (graph abstract-graph))
  (get-range-objects (class-prototype relation-class) domain-obj graph))

;;; get range objects for the default relation--children--for a cons object.
(defmethod get-range-objects ((relation children) (domain-obj cons) 
			      (graph abstract-graph))
  (cdr domain-obj))

;;; get range objects for the default relation--children--for a string object.
(defmethod get-range-objects ((relation children) (domain-obj string) 
			      (graph abstract-graph))
  nil)

;;; get range objects for the default relation--children--for a symbol object.
(defmethod get-range-objects ((relation children) (domain-obj symbol) 
			      (graph abstract-graph))
  nil)

(defmethod add-descendant ((relation relation-meta) (domain node) 
			   (range-object t) (graph abstract-graph) 
			   &optional (depth 0))
  (declare (fixnum depth))
  (let ((oldnode t))
    (let ((range (or (gethash range-object (objecttable graph))
		     (setf oldnode nil)
		     (make-node (label range-object) range-object graph
				:depth (1+ depth) 
				:depth-limit (depth-limit domain))))
	  (arc (make-arc relation graph))
	  (limit (or (depth-limit domain) (depth-limit graph))))
      (unless oldnode
	(when (>= depth limit)
	  (setf (display-p range) nil))
	(add-node range graph))
      (add-arc arc graph)
      (link-nodes domain range arc graph)
      (values range oldnode))))

;; remove the linkage between two nodes and throw away the arc.
(defmethod remove-descendant ((arc arc) (domain node) 
			      (range node) (graph abstract-graph))
  (unlink-descendant-nodes domain range arc graph)
  (remove-arc arc graph))


;;;
;;; relation depth limit handling code
;;;

(defmethod make-expand-continuation ((domain node) (rel-class lazy-t-c) 
				     (graph graph-layout))
  #'(lambda ()
      (declare (restrictive-ftype (function (node) fixnum) depth)
	       (restrictive-ftype (function (graph) fixnum) expand-depth)
	       (restrictive-ftype (function (graph) fixnum) limit-depth)
	       (restrictive-ftype (function (fixnum fixnum) fixnum) +))
      (let ((d (depth domain)))
	(declare (fixnum d))
	(setf (depth-limit domain) 
	      (+ d (expand-depth graph)))
	(setf (leafnodes graph)
	      (remove domain (leafnodes graph) :test #'eq))
	(transitive-closure rel-class domain graph d))))

(defmethod ungroup ((node node) (graph graph-layout))
  (loop for collapsed in (collapse node)
	do (setf (display-p collapsed) t))
  (setf (collapse node) '()))

(defmethod run-expand-continuation ((node node) (graph graph-layout) &optional depth)
  (let ((limit (or depth (expand-depth graph))))
    (cond ((expand-continuation node)
	   (unmake-depth-label node graph)
	   (loop for cont in (expand-continuation node) 
		 do (funcall cont))
	   (setf (expand-continuation node) '())
	   (multiple-value-bind (center sub centered-p)
	       (get-centered-and-sub node graph)
	     (when centered-p
	       (add-expanded-to-centered node center sub))))
	  ((not (= limit 0))
	   (unmake-depth-label node graph)
	   (loop for child in (children-nodes node)
		 do (run-expand-continuation child graph (1- limit)))))))

;; return centered and subgraph associated with node and graph
(defgeneric get-centered-and-sub (node graph)
  (:method (node graph)
    (declare (ignore node graph))
    (values nil nil nil))
  (:method ((node node) (graph centered-layout))
    (values graph (associated-graph node graph) t))
  (:method ((node node) (graph subgraph))
    (values (parent-graph graph) graph t)))

;; clean up centered graph nodes and arcs list after expand cont.
(defmethod add-expanded-to-centered ((node node) (cgraph centered-layout) 
				     (sgraph side-layout))
  (loop for n in (allnodes sgraph)
	unless (root n)
	do (pushnew n (allnodes cgraph) :test #'eq))
  (loop for n in (noderegions sgraph)
	unless (root (cdr n))
	do (pushnew n (noderegions cgraph) :test #'equal))
  (loop for n in (nodelabels sgraph)
	unless (root (cdr n))
	do (pushnew n (nodelabels cgraph) :test #'equal))
  (loop for a in (arcs sgraph)
	do (pushnew a (arcs cgraph) :test #'eq)))

;; expand the subgraph already created to the expand limit
(defmethod run-expand-subgraph ((node node) (graph graph-layout) &optional depth)
  (declare (fixnum depth)
	   (restrictive-ftype (function (graph) fixnum) expand-depth))
  (let ((limit (or depth (expand-depth graph)))
	(children (children-nodes node)))
    (cond ((eq limit 0)
	   (when (and children (notany #'display-p children))
	     (make-depth-label node graph)))
	  (t 
	   (unmake-depth-label node graph)
	   (loop for subnode in children do
		 (setf (display-p subnode) t)
		 (run-expand-subgraph subnode graph (1- limit)))))))

(defgeneric group (node graph &optional collapse-nodes)
  (:method ((node node) (graph graph-layout) &optional collapse-nodes)
    (let ((cnodes (or collapse-nodes (descendants node graph))))
      (when cnodes
	(make-depth-label node graph))
      (loop for n in cnodes
	    do (when (selected n)
		 (nodeselect n graph))
	    (setf (display-p n) nil))
      (loop for n in cnodes
	    do (push n (collapse node)))))
  (:method ((node node) (graph centered-layout) &optional collapse-nodes)
    (if (root node)
	(let ((g1 (descendant-graph node))
	      (g2 (ancestor-graph node)))
	  (let ((g1coll (loop for node in collapse-nodes
			      when (find-node (label node) g1)
			      collect node))
		(g2coll (loop for node in collapse-nodes
			      when (find-node (label node) g2)
			      collect node)))
	    (collapse-node node g1 g1coll)
	    (collapse-node node g2 g2coll)))
	(call-next-method))))

(defmethod group :after ((node node) (graph graph-layout) 
				 &optional collapse-nodes)
  (relayout graph))


;;; expand and collapse methods

(defgeneric expand (node graph &optional depth dont-layout)
  (:method (node (graph graph-layout) &optional depth dont-layout);; expand from roots
    (unless node
      (loop for rootnode in (rootnodes graph)
	    do (expand rootnode graph depth dont-layout))))
  (:method ((node node) (graph centered-layout) &optional depth dont-layout)
    (if (root node)
	(let ((g1 (ancestor-graph graph))
	      (g2 (descendant-graph graph)))
	  (expand (find-node (label node) g1) g1 depth t)
	  (expand (find-node (label node) g2) g2 depth t))
	(call-next-method)))
  (:method ((node node) (graph graph-layout) &optional depth dont-layout)
    (ungroup node graph)                       ;; expand collapsed
    (if (eq depth -1)                          ;; expand subgraph if not created
	(let ((oldexpand (expand-depth graph)))
	  (setf (expand-depth graph) 1000)
	  (run-expand-continuation node graph depth)
	  (setf (expand-depth graph) oldexpand))
        (run-expand-continuation node graph depth))
    (run-expand-subgraph node graph depth)     ;; expand subgraph
    (unmake-depth-label node graph)))

(defmethod expand :after ((node node) (graph graph-layout) 
			  &optional depth dont-layout)
  (unless dont-layout
    (relayout graph)))                            ;; relayout graph

(defgeneric collapse-node (node graph &optional collapse-nodes dont-layout)
  (:method ((node node) (graph graph-layout) &optional collapse-nodes dont-layout)
	   (if collapse-nodes
	       (group node graph collapse-nodes)
	       (let ((cnodes (node-subtree node graph)))
		 (when cnodes
		   (unless (root node)
		     (make-depth-label node graph)))
		 (loop for n in cnodes
		       do (when (selected n)
			    (nodeselect n graph))
		       (setf (display-p n) nil)))))
  (:method ((node node) (graph centered-layout) &optional collapse-nodes dont-layout)
	   (if (root node)
	       (let ((g1 (descendant-graph graph))
		     (g2 (ancestor-graph graph)))
		 (let ((g1coll (loop for node in collapse-nodes
				     when (find-node (label node) g1)
				     collect node))
		       (g2coll (loop for node in collapse-nodes
				     when (find-node (label node) g2)
				     collect node)))
		   (let ((node1 (find-node (label node) g1))
			 (node2 (find-node (label node) g2)))
		     (collapse-node node1 g1 g1coll)
		     (collapse-node node2 g2 g2coll))))
	       (call-next-method))))

(defmethod collapse-node :after ((node node) (graph graph-layout) 
				 &optional collapse-nodes dont-layout)
  (unless (or collapse-nodes dont-layout)
    (relayout graph)))

;;;
;;; graph buffer construction
;;;

(defmethod make-buffer ((graph abstract-graph) &optional name &rest initargs)
  (let ((name (or name 
		  (format nil "*~a Graph*" 
			  (text (car (rootnodes graph)))))))
    (apply #'make-instance 'graph-buffer :graph graph
	   :name name initargs)))

(defmethod add-buffer ((graph abstract-graph) (buffer graph-buffer))
  (let ((tool (tool graph)))
    (unless (member buffer (buffers tool))
      (push buffer (buffers tool)))
    (setf (tool buffer) tool)
    (add-view graph buffer)
    (setf (buffer graph) buffer)))

(defgeneric add-view (graph buffer)
  (:method ((graph centered-layout) (buffer graph-buffer))
    (setf (centered-graph-view buffer) graph))
  (:method ((graph left-right-layout) (buffer graph-buffer))
    (setf (descendant-graph-view buffer) graph))
  (:method ((graph top-bottom-layout) (buffer graph-buffer))
    (setf (descendant-graph-view buffer) graph))
  (:method ((graph right-left-layout) (buffer graph-buffer))
    (setf (ancestor-graph-view buffer) graph))
  (:method ((graph bottom-top-layout) (buffer graph-buffer))
    (setf (ancestor-graph-view buffer) graph)))

(defmethod remove-buffer ((graph abstract-graph) (buffer graph-buffer))
  (let ((tool (tool graph)))
    (setf (buffers tool) (remove buffer (buffers tool)))
    (setf (tool buffer) nil)
    (setf (buffer graph) nil)
    (setf (selections buffer) '())
    (setf (graph buffer) nil)))


;;;
;;; graph tool construction
;;;

;; The default make-tool method.  This method simply retrieves the
;; *graph-tool* tool.  This assumes that grapher-init has been done
;; and, hence, there is a *graph-tool*.
(defmethod make-tool ((graph graph))
  *graph-tool*)

      