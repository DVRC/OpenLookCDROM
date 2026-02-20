;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; WINDOW GRAPHER example program.
;;;;      by Philip McBride and John Rose
;;;;
;;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;;	See LEGAL_NOTICE file for terms of the license.
;;;;
;;;; This example program corresponds to an example in the LispView
;;;; Grapher Document.  This is an example of a grapher application
;;;; that displays the hierarchy of LispView windows in the current
;;;; environment.
;;;;
;;;; To bring up this application on the root window, try the following:
;;;; (wg:make-window-graph)
;;;;
;;;;
;;;; There is only one user function from this application:
;;;;
;;;;   (make-window-graph &optional <window> <direction>)    [function]
;;;;
;;;;   <window> is a valid LispView window instance (the default is the
;;;;   root window).
;;;;
;;;;   <direction> is one of:
;;;;        :children -- this will make a left to right graph with
;;;;                     the root to the left and showing the children
;;;;                     to the right.
;;;;        :parents -- this will make a right to left graph with
;;;;                    the root to the right and showing the parents
;;;;                    to the left.
;;;;        :both -- this will make a centered graph with the root in
;;;;                 the center with the parents to the left and the
;;;;                 children to the right.
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package :window-grapher :nicknames '(:wg))

(export '(make-window-graph))


;;;
;;; Define the user function that can create the
;;; graphs defined below.
;;;

(defun make-window-graph (&optional window (dir :children))
  (let ((window (or window (lv::root-canvas lv::*default-display*))))
    (case dir
      (:children
       (make-instance 'c-window-graph :roots (list window)))
      (:parents
       (make-instance 'p-window-graph :roots (list window)))
      (:both
       (make-instance 'centered-window-graph :roots (list window)))
      (otherwise
       (format t "Illegal direction argument: ~a" dir)))))

;;;
;;; Window graph Variable
;;;

(defvar *window-graph-tool* nil)

(defvar *window-graph-tools* nil)


;;;
;;; Create the relation and arc classes
;;;

;; subwindow relation--corresponds to lv:children
(defclass subwindow (gr:relation) ())

;; superwindow relation--corresponds to lv:parent
(defclass superwindow (gr:relation) ())

;; subwindow arc--corresponds to subwindow relation
(defclass subw-arc (subwindow gr:arc) ()
  (:default-initargs :g-c gr:*solid-arc-gc*)
  (:metaclass gr:ftc-relation-meta))

;; superwindow arc--corresponds to superwindow relation
(defclass supw-arc (superwindow gr:arc) ()
  (:default-initargs :g-c gr:*solid-arc-gc*)
  (:metaclass gr:ftc-relation-meta))


;;;
;;; Create the graph classes
;;;

;; the abstract graph will be the superclass of the
;; window graph and the window subgraphs.
(defclass abstract-window-graph (gr:abstract-graph) ()
  (:default-initargs :depth-limit 2))

;; the basic window-graph class--class mixin needed for i/o
(defclass window-graph (abstract-window-graph gr:graph) ())

;; the window graph class used to graph the subwindow (children)
;; relation alone.
(defclass c-window-graph (window-graph gr:left-right-layout) ()
  (:default-initargs :relations (list (find-class 'subw-arc))))

;; the window graph class used to graph the superwindow (parent)
;; relation alone.
(defclass p-window-graph (window-graph gr:right-left-layout) ()
  (:default-initargs :relations (list (find-class 'supw-arc))))

;; the subgraph class used, as part of the centered graph below, to
;; graph the subwindow (children) relation.
(defclass c-window-subgraph (abstract-window-graph gr:subgraph gr:left-right-layout) ()
  (:default-initargs :relations (list (find-class 'subw-arc))))

;; the subgraph class used, as part of the centered graph below, to
;; graph the superwindow (parent) relation.
(defclass p-window-subgraph (abstract-window-graph gr:subgraph gr:right-left-layout) ()
  (:default-initargs :relations (list (find-class 'supw-arc))))

;; the centered window graph class used to graph both the superwindow and
;; subwindow relations.
(defclass centered-window-graph (window-graph gr:centered-horizontal-layout) ()
  (:default-initargs :ancestor-graph-class (find-class 'p-window-subgraph)
		     :descendant-graph-class (find-class 'c-window-subgraph)))


;;;
;;; window graph tool
;;;

(defclass window-graph-tool (gr:graph-tool) ()
  (:default-initargs :both-view-class (find-class 'centered-window-graph)
		     :ancestor-view-class (find-class 'p-window-graph)
		     :descendant-view-class (find-class 'c-window-graph)))


;;;
;;; Define the relation methods
;;;

;; the relation method used to get the next subwindows of a window
;; this uses the lispview children function.
(defmethod gr:get-range-objects ((relation subwindow) (domain lv::parent)
                              (graph abstract-window-graph))
  (lv::children domain))

;; the relation method used to get the next superwindows of a window
;; this uses the lispview parent function.
(defmethod gr:get-range-objects ((relation superwindow) (domain lv::parent)
			      (graph abstract-window-graph))
  (let ((parent (lv::parent domain)))
    (when parent
      (list parent))))


;;;
;;; Make a unique tool for the class grapher
;;;

(defmethod gr::make-tool ((graph window-graph))
  (or *window-graph-tool*
      (make-new-window-graph-tool)))

(defun make-new-window-graph-tool ()
  (let ((buffers (when *window-graph-tool* (gr:buffers *window-graph-tool*))))
    (setf *window-graph-tool* (make-instance 'window-graph-tool :title "Window Grapher"))
    (setf *window-graph-tools* (push *window-graph-tool* *window-graph-tools*))
    (setf (gr:buffers *window-graph-tool*) buffers))
  *window-graph-tool*)

(defun make-new-window-tool-window (tool)
  (let ((b (car (gr:buffers tool))))
    (if b
	(let ((graph (gr:graph b)))
	  (setf (gr:tool graph) tool)
	  (setf (gr:tool b) tool)
	  (gr:make-graph-window graph))
      (error "No Buffers exist in tool ~a" tool))))

(defun clone-window-tool ()
  (make-new-window-tool-window (make-new-window-graph-tool)))


;;;
;;; Define the classes and methods for the list node
;;;

(defclass list-node (gr:node)
  ((nodes :initarg :nodes :type list)
   (graph :initarg :graph :reader graph))
  (:default-initargs :border 1))

(defmethod nodes ((node list-node))
  (unless (slot-boundp node 'nodes)
    (setf (slot-value node 'nodes)
          (flet ((coerce-to-node (label)
                   (typecase label
                     (gr:node label)
                     (otherwise
                      (gr:make-node label (gr:object node) (graph node))))))
            (mapcar #'coerce-to-node (gr:label node)))))
  (slot-value node 'nodes))

(defmethod gr::label-width ((node list-node))
  (reduce #'max (mapcar #'gr:width (nodes node))))
(defmethod gr::label-height ((node list-node))
  (reduce #'+ (mapcar #'gr:height (nodes node))))

(defmethod gr::g-c ((node list-node))
  (or (call-next-method)
      (let ((node1 (first (nodes node))))
        (and node1 (gr::g-c node1)))
      gr:*plain-str-gc*))


(defmethod gr:make-node ((label list) object (graph abstract-window-graph) &rest initargs)
  (apply #'make-instance 'list-node :label label :object object :graph graph initargs))


;;;
;;; Define methods necessary for labels of list nodes
;;;

;; Define the label method for our nodes that will return a
;; list of strings.
(defmethod gr:label ((obj lv::parent))
  (delete nil
          (list (write-to-string (type-of obj) :escape nil :case :downcase)
                (and (typep obj 'lv:bounding-region)
                     (lv::print-lispview-bounding-region obj nil))
                (format nil "~X" (sys:%pointer obj)))))

;; Define the display-label method based on list nodes that
;; will correctly display the subnodes.
(defmethod gr:display-label ((node list-node) display)
  (let ((x (gr:x node))
        (y (gr:y node))
        (ymin (- (gr:y node) (gr:height node))))
    (dolist (subnode (slot-value node 'nodes))
      (setf (gr:x subnode) x)
      (setf (gr:y subnode) y)
      (gr:display-label subnode display)
      (decf y (gr:height subnode))
      (unless (>= y ymin)
        (return))
      )))


;;;
;;; Interface classes
;;;

(defclass window-graph-base-window (gr:graph-base-window)
  ((panel :accessor panel :initarg :panel)))

(defclass window-panel (lv:panel)
  ((tool :accessor tool :initarg :tool)))


;;;
;;; Define the interface methods (menus, buttons, and window)
;;;


;;; panel menu
(defmethod gr::make-panel-menu ((tool window-graph-tool))
  (labels ((get-current-buffer ()
             (gr:current-buffer (gr:current-viewer tool)))
	   (current-graph ()
             (gr:graph (get-current-buffer)))
	   (current-node (graph)
             (let ((sel (gr:selections (gr:buffer graph))))
	       (if sel
		   (car sel))))
	   (graph-relayout-fn ()
	     (gr:relayout (current-graph)))
	   (graph-redisplay-fn ()
	     (let ((canvas (gr:current-viewer tool)))
	       (let ((vregion (lv:view-region canvas)))
		 (lv:draw-rectangle canvas (lv:region-left vregion)
				 (lv:region-top vregion)
				 (lv:region-width vregion)
				 (lv:region-height vregion)
				 :fill-p t
				 :foreground (lv:background canvas)
				 :operation #.boole-1)
		 (lv:send-event canvas 
			     (lv:make-damage-event 
			      :regions 
			      (list vregion))))))
	   (select-all-fn ()
             (let* ((buffer (get-current-buffer))
		    (graph (gr:graph buffer)))
	       (loop for n in (gr:selections buffer)
		     do (gr:nodeselect n graph))
	       (loop for n in (gr:allnodes graph)
		     do (gr:nodeselect n graph :add))))
	   (node-relayout-fn () (graph-relayout-fn))
	   (node-collapse-fn ()
	     (let* ((graph (current-graph))
		    (node (current-node graph)))
	       (when node
		 (gr:collapse-node node graph))))
	   (graph-expand-all-fn ()
             (let ((graph (current-graph)))
	       (loop for root in (gr:rootnodes graph)
		     do (gr:expand root graph -1))))
	   (open-selections-fn ()
             (let* ((buffer (get-current-buffer))
		    (graph (gr:graph buffer))
		    (roots (loop for selection in (gr:selections buffer)
				 collect (gr:object selection))))
	       (when (and roots (car roots))
		 (make-instance 'centered-window-graph
				:roots roots))))
	   (object-inspect-fn ()
	     (let* ((graph (current-graph))
		    (node (current-node graph)))
	       (when node
		 ;; see object-to-inspect and object-to-edit 
		 ;; in grapher-interface.lisp
		 (let ((object (gr:object-to-inspect node graph)))
		   (when object
		     (make-process :name (format nil "Inspecting ~a" object)
				   :function #'(lambda () (inspect object))))))))
	   (clone-tool-fn ()
      	     (clone-window-tool))
	   (upward-branch-fn ()
             (let ((buffer (get-current-buffer)))
	       (gr::change-view buffer :ancestor)
	       (gr:center-graph-window (current-graph))))
	   (downward-branch-fn ()
             (let ((buffer (get-current-buffer)))
	       (gr::change-view buffer :descendant)
	       (gr:center-graph-window (current-graph))))
	   (both-branch-fn ()
             (let ((buffer (get-current-buffer)))
	       (gr::change-view buffer :both)
	       (gr:center-graph-window (current-graph))))
	   (previous-buffer-fn ()
             (let ((graph (current-graph)))
	       (gr:push-buffer (gr:previous-buffer graph) tool))
	     (graph-redisplay-fn))
	   (next-buffer-fn ()
             (let ((graph (current-graph)))
	       (gr:push-buffer (gr:next-buffer graph) tool))
	     (graph-redisplay-fn))
	   (node-expand-fn () 
	     (let* ((graph (current-graph))
		    (node (current-node graph)))
	       (when node
		 (gr:expand node graph)))))
    (setf (gr:panel-menu tool)
	  #'(lambda ()
	      (let ((parent (panel (gr:base tool))))
		(make-instance 'lv:menu-button :parent parent :label "Graph" :menu
		  (make-instance 'lv:menu :menu-spec
                    (list (list "Open" :menu
				(list (list "Selections" #'open-selections-fn)
				      (list "Previous" #'previous-buffer-fn)
				      (list "Next" #'next-buffer-fn)))
			  (list "Clone" #'clone-tool-fn))))
		(make-instance 'lv:menu-button :parent parent :label "View" :menu
		  (make-instance 'lv:menu :menu-spec
		    (list (list "Redisplay" #'graph-redisplay-fn)
			  (list "Expand" :menu
				(list (list "1 Level" #'node-expand-fn)
				      (list "Fully" #'graph-expand-all-fn)))
			  (list "Collapse" #'node-collapse-fn)
			  (list "Branching" :menu
				(list (list "Downward" #'downward-branch-fn)
				      (list "Upward" #'upward-branch-fn)
				      (list "Both" #'both-branch-fn)))
			  (list "Relayout" #'graph-relayout-fn))))
		(make-instance 'lv:menu-button :parent parent :label "Edit" :menu
		  (make-instance 'lv:menu :menu-spec
		    (list (list "Select All" #'select-all-fn)
			  (list "Inspect Window" #'object-inspect-fn)))))))))


;;; floating menus
(defmethod gr::make-graph-menus ((tool window-graph-tool))
  (labels ((get-current-buffer ()
             (gr:current-buffer (gr:current-viewer tool)))
	   (current-graph ()
             (gr:graph (get-current-buffer)))
	   (graph-relayout-fn ()
	     (gr:relayout (current-graph)))
	   (graph-redisplay-fn ()
	     (let ((canvas (gr:current-viewer tool)))
	       (let ((vregion (lv:view-region canvas)))
		 (lv:draw-rectangle canvas (lv:region-left vregion)
				 (lv:region-top vregion)
				 (lv:region-width vregion)
				 (lv:region-height vregion)
				 :fill-p t
				 :foreground (lv:background canvas)
				 :operation #.boole-1)
		 (lv:send-event canvas 
			     (lv:make-damage-event 
			      :regions 
			      (list vregion))))))
	   (select-all-fn ()
             (let* ((buffer (get-current-buffer))
		    (graph (gr:graph buffer)))
	       (loop for n in (gr:selections buffer)
		     do (gr:nodeselect n graph))
	       (loop for n in (gr:allnodes graph)
		     do (gr:nodeselect n graph :add))))
	   (node-relayout-fn () (graph-relayout-fn))
	   (graph-expand-all-fn ()
             (let ((graph (current-graph)))
	       (loop for root in (gr:rootnodes graph)
		     do (gr:expand root graph -1))))
	   (graph-depth-fn () nil)
	   (node-expand-n-fn ()
	     (node-expand-fn))
	   (open-selections-fn ()
             (let* ((buffer (get-current-buffer))
		    (graph (gr:graph buffer))
		    (roots (loop for selection in (gr:selections buffer)
				 collect (gr:object selection))))
	       (when (and roots (car roots))
		 (make-instance (class-of graph)
				:roots roots))))
	   (previous-buffer-fn ()
             (let ((graph (current-graph)))
	       (gr:push-buffer (gr:previous-buffer graph) tool))
	     (graph-redisplay-fn))
	   (next-buffer-fn ()
             (let ((graph (current-graph)))
	       (gr:push-buffer (gr:next-buffer graph) tool))
	     (graph-redisplay-fn)))
    (setf (gr:graph-menu tool)
	  (make-instance 'lv:menu :label "graph menu"
			 :menu-spec 
			 (list (list "Open" :menu
				     (list (list "Selections" #'open-selections-fn)
					   (list "Previous" #'previous-buffer-fn)
					   (list "Next" #'next-buffer-fn)))
			       (list "Relayout" #'graph-relayout-fn)
			       (list "Select All" #'select-all-fn)
			       (list "Expand All" #'graph-expand-all-fn)
			       (list "Redisplay" #'graph-redisplay-fn)))
	  (gr:node-menu tool) nil)))

;; Make the actual graph window complex associated with a tool.
(defmethod gr:make-graph-window ((graph window-graph))
  (let ((b (gr:buffer graph))
	(tool (gr:tool graph)))
    (let ((bw (make-instance 'window-graph-base-window 
			     :label (or (gr::title tool) "Window Grapher")
			     :width (gr:view-width graph) 
			     :height (+ 10 (gr:view-height graph))
			     :tool tool
			     :mapped nil)))
      (let ((panel (make-instance 'window-panel
				  :parent bw
				  :tool tool
				  :width (gr:view-width graph)
				  :height 30
				  :top 0
				  :left 0)))
	(let ((vp (make-instance 'gr:graph-viewport
				 :parent bw 
				 :tool tool
				 :output-region 
				 (lv:make-region :width (gr:output-width graph)
						 :left 0
						 :top 30
						 :height (- (gr:output-height graph) 29))
				 :container-region
				 (lv:make-region :width (gr:view-width graph)
						 :height (- (gr:view-height graph) 29))
				 :border-width 1
				 :vertical-scrollbar 
				 (make-instance 'lv:vertical-scrollbar) 
				 :horizontal-scrollbar 
				 (make-instance 'lv:horizontal-scrollbar))))
	  (gr:setup-interests graph vp)
	  (setf (gr:graph-damage vp) 
		#'(lambda (vp regions)
		    (let ((buffer (gr:current-buffer vp)))
		      (when buffer
			(let ((region (apply #'lv:region-bounding-region regions)))
			  (gr:display (gr:graph buffer)
				      vp region))))))
	  (setf (lv:icon bw) (make-instance 'lv:icon :label gr:*grapher-icon-image*))
	  (setf (lv:mapped bw) t)
	  (setf (panel bw) panel)
	  (setf (gr:current-buffer vp) b)
	  (setf (gr:canvas b) vp)
	  (setf (gr:current-viewer tool) vp)
	  (push vp (gr:viewers tool))
	  (setf (gr:base tool) bw)
	  ;; run the panel menu fn inside the tool's panel menu slot
	  (let ((panel-menu (gr:panel-menu tool)))
	    (if panel-menu
		(funcall panel-menu))))))
    (gr:center-graph-window graph)))

(defmethod (setf lv:bounding-region) :after (new-region (bw window-graph-base-window))
  (when (lv:mapped bw)
    (let ((canvas (gr:current-viewer (gr:tool bw)))
	  (panel (panel bw)))
      (let ((r (lv:container-region canvas))
	    (pr (lv:bounding-region panel)))
	(setf (lv:region-width pr) (lv:region-width new-region)
	      (lv:region-top pr) 0
	      (lv:region-left pr) 0
	      (lv:bounding-region panel) pr
	      (lv:region-width r) (lv:region-width new-region)
	      (lv:region-height r) (- (lv:region-height new-region) 29)
	      (lv:region-top r) 30
	      (lv:region-left r) 0
	      (lv:container-region canvas) r)))))
