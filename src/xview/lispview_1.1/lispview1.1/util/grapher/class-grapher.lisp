;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; CLASS GRAPHER example program.
;;;;      By Philip McBride
;;;;
;;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;;	See LEGAL_NOTICE file for terms of the license.
;;;;
;;;; This example program corresponds to an example in the LispView
;;;; Grapher Document.  This is an example of a grapher application
;;;; that displays the hierarchy of CLOS classes.
;;;;
;;;; To bring up this application on a class, try the following:
;;;; (cg:make-class-graph (find-class 'gr::abstract-graph))
;;;;
;;;;
;;;; There is only one user function from this application:
;;;;
;;;;   (make-class-graph &optional <class> <direction>)    [function]
;;;;
;;;;   <class> is a valid CLOS class object (via find-class).
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

(in-package :class-grapher :nicknames '(:cg))

(export '(make-class-graph))

;;;
;;; Define the user function that can create the
;;; graphs defined below.
;;;

(defun make-class-graph (&optional class (dir :children))
  (let ((class (or class (clos::find-class 't))))
    (case dir
      (:children
       (make-instance 'subclass-graph :roots (list class)))
      (:parents
       (make-instance 'superclass-graph :roots (list class)))
      (:both
       (make-instance 'centered-class-graph :roots (list class)))
      (otherwise
       (format t "Illegal direction argument: ~a" dir)))))

;;;
;;; Class graph Variable
;;;

(defvar *class-graph-tool* nil)

(defvar *class-graph-tools* nil)

;;;
;;; Create the relation and arc classes
;;;

(defclass subclasses (gr:relation) ())

(defclass superclasses (gr:relation) ())

(defclass subclasses-arc (subclasses gr:arc) ()
  (:default-initargs :g-c gr:*solid-arc-gc*)
  (:metaclass gr:ltc-relation-meta))

(defclass superclasses-arc (superclasses gr:arc) ()
  (:default-initargs :g-c gr:*solid-arc-gc*)
  (:metaclass gr:ltc-relation-meta))


;;;
;;; Create the graph classes
;;;

(defclass abstract-class-graph (gr:abstract-graph) ())

(defclass class-graph (abstract-class-graph gr:graph) ()
)

(defclass class-subgraph (abstract-class-graph gr:subgraph) ())

(defclass subclass-graph (class-graph gr:left-right-layout) ()
  (:default-initargs :relations (list (find-class 'subclasses-arc))))

(defclass superclass-graph (class-graph gr:right-left-layout) ()
  (:default-initargs :relations (list (find-class 'superclasses-arc))))

(defclass subclass-subgraph (class-subgraph gr:left-right-layout) ()
  (:default-initargs :relations (list (find-class 'subclasses-arc))))
  
(defclass superclass-subgraph (class-subgraph gr:right-left-layout) ()
  (:default-initargs :relations (list (find-class 'superclasses-arc))))

(defclass centered-class-graph (class-graph gr:centered-horizontal-layout) ()
  (:default-initargs :ancestor-graph-class (find-class 'superclass-subgraph)
		     :descendant-graph-class (find-class 'subclass-subgraph)
		     :depth-limit 2))


;;;
;;; class graph tool
;;;

(defclass class-graph-tool (gr:graph-tool) ()
  (:default-initargs :both-view-class (find-class 'centered-class-graph)
		     :ancestor-view-class (find-class 'superclass-graph)
		     :descendant-view-class (find-class 'subclass-graph)))


;;;
;;; Define the relation methods
;;;

(defmethod gr:get-range-objects ((relation subclasses) domain-obj 
			      (graph gr:graph-layout))
  (clos::class-direct-subclasses domain-obj))

(defmethod gr:get-range-objects ((relation superclasses) domain-obj 
			      (graph gr:graph-layout))
  (clos::class-direct-superclasses domain-obj))

;;;
;;; Make a unique tool for the class grapher
;;;

(defmethod gr::make-tool ((graph class-graph))
  (or *class-graph-tool*
      (make-new-class-graph-tool)))

(defun make-new-class-graph-tool ()
  (let ((buffers (when *class-graph-tool* (gr:buffers *class-graph-tool*))))
    (setf *class-graph-tool* (make-instance 'class-graph-tool :title "Class Grapher"))
    (setf *class-graph-tools* (push *class-graph-tool* *class-graph-tools*))
    (setf (gr:buffers *class-graph-tool*) buffers))
  *class-graph-tool*)

(defun change-class-tool-focus (tool)
  (setq *class-graph-tool* tool))

(defun make-new-class-tool-window (tool)
  (let ((b (car (gr:buffers tool))))
    (if b
	(let ((graph (gr:graph b)))
	  (setf (gr:tool graph) tool)
	  (setf (gr:tool b) tool)
	  (gr:make-graph-window graph))
      (error "No Buffers exist in tool ~a" tool))))

(defun clone-class-tool ()
  (make-new-class-tool-window (make-new-class-graph-tool)))

;;;
;;; Node and label methods
;;;

(defmethod gr:label ((obj class))
  (format nil "~(~a~)" (clos::class-name obj)))

(defmethod gr:make-node ((label string) (class class) (graph class-graph) 
		      &rest initargs)
  (apply #'make-instance 'gr:plain-str-node :label label :object class
;	 :g-c (gr:node-gc graph) 
initargs))

(defmethod gr:make-node ((label string) (class class) (graph class-subgraph) 
		      &rest initargs)
  (apply #'make-instance 'gr:plain-str-node :label label :object class
;	 :g-c (gr:node-gc (gr::parent-graph graph)) 
initargs))


;;;
;;; Interface classes
;;;

(defclass class-graph-base-window (gr:graph-base-window)
  ((panel :accessor panel :initarg :panel)))

(defclass class-panel (lv:panel)
  ((tool :accessor tool :initarg :tool)))


;;;
;;; Define the interface methods (menus, buttons, and window)
;;;

;;; object to edit (to be used when editing a class via M-.)
;;; Note: we are not currently making use of this, a good thing
;;; to do would be to hook the object-edit-fn subfunction inside
;;; the name-panel-menu actually send a remote call to emacs!
(defmethod gr:object-to-edit ((node gr:node) (graph class-graph))
  (let ((object (gr:object node)))
    (and object
	 (typep object 'class)
	 (class-name object))))

;;; I just couldn't resist this one...
;;; Function to use for editing a class.  This function will do
;;; some nasty things to get an emacs to edit a file and go
;;; to the proper location.  This assumes an gnuemacs like
;;; elisp and command line.  This would be much nicer if
;;; we took the time to make some sort of remote procedure
;;; call to reuse the current emacs instead of making a
;;; new one each time.
(defun edit-class (class-name)
  (let ((sf (get-source-file class-name nil t)))
    (let ((source (if sf (namestring (cdar sf)))))
      (when source
	;; the emacs .el file for the class searching function:
	;; create the file, create the text for the file, and write it
	(let* ((file-name (format nil "~a.el" (gensym "tempemacs")))
	       (emacsfile-string
		(format nil "(defun myfind ()~&(find-file ~s)~&(re-search-forward ~s)~&(beginning-of-line)~&(point))"
			source (format nil "(defclass[  	~~%]*~(~a~)" class-name)))
	       (shell-string (format nil "emacs -l ~s -f myfind&" 
				     (format nil "/tmp/~a" file-name))))
	  (with-open-file (ofile (merge-pathnames "/tmp/" file-name)
				 :direction :output)
	    (write-string emacsfile-string ofile))
	  (make-process :name "Edit Class" 
			:function #'(lambda () (shell shell-string))))))))


;;; panel menu
(defmethod gr::make-panel-menu ((tool class-graph-tool))
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
		 (make-instance 'centered-class-graph
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
	   (object-edit-fn ()
             (let* ((graph (current-graph))
		    (node (current-node graph)))
	       (when node
		 (let ((object (gr:object-to-edit node graph)))
		   (edit-class object)))))
	   (clone-tool-fn ()
      	     (clone-class-tool))
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
			  (list "Inspect Class" #'object-inspect-fn)
			  (list "Find Source" #'object-edit-fn)))))))))


;;; floating menus
(defmethod gr::make-graph-menus ((tool class-graph-tool))
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
(defmethod gr:make-graph-window ((graph class-graph))
  (let ((b (gr:buffer graph))
	(tool (gr:tool graph)))
    (let ((bw (make-instance 'class-graph-base-window 
			     :label (or (gr::title tool) "Class Grapher")
			     :width (gr:view-width graph) 
			     :height (+ 10 (gr:view-height graph))
			     :tool tool
			     :mapped nil)))
      (let ((panel (make-instance 'class-panel
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

(defmethod (setf lv:bounding-region) :after (new-region (bw class-graph-base-window))
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
