;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;;  File: grapher-classes.lisp
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


;;;
;;; Graphical Object and Context Classes
;;;

;;; The main objects are graph-object and grapher-gc.  The graph-object
;;; subclasses contain graph dimensions (size, position, etc).  The
;;; grapher-gc subclasses contain display information (fonts, line
;;; width, etc).  Actual graphical nodes are then "mixes" of a graph-object
;;; and a graph-gc.  Although the main arc and arc-gc classes are shown
;;; here, they are more fully defined and explained in the next section
;;; (see relations/arcs definitions below).
;;;
;;;               _____ arc
;;;  graph-object/           _____ string-node _____________
;;;              \_____ node/                               \
;;;                         \_____ image-node                \                  
;;;                                                           \
;;;             ___ arc-gc                                     \ plain-str-node
;;;  grapher-gc/            ___ image-node-gc                  /
;;;            \___ node-gc/                   ___ plain-str-gc
;;;                        \___ string-node-gc/___ bold-str-gc
;;;                                           \___ italic-str-gc
;;;                                            \__ italicbold-str-gc
;;;
;;;
;;; Actual nodes would then be subclasses of both a node and a node-gc.
;;; For example, plain-str-node would be a subclass of both string-node
;;; and plain-str-gc.
;;;
;;; ***** maybe later use gc slot instead of class mixing *****
;;; OK.  We're now using a gc slot instead of mixing in the classes.
;;; So, the above now looks like the following:
;;;
;;;
;;;               _____ arc
;;;  graph-object/           _____ string-node _____ plain-str-node
;;;              \_____ node/
;;;                         \_____ image-node 
;;; 
;;;             ___ arc-gc
;;;  grapher-gc/            ___ image-node-gc_ _ _ _ *image-node-gc*
;;;            \___ node-gc/                   _ _ _ *plain-str-gc*
;;;                        \___ string-node-gc/_ _ _ *bold-str-gc*
;;;                                           \_ _ _ *italic-str-gc*
;;;                                            \ _ _ *italicbold-str-gc*
;;;
;;; Where the node has a g-c slot that is filled with the obvious gc
;;; *instance*.  These instances are created at init time.
;;;
;;; Also, we now have a similar hierarchy of graph object structures
;;; for those users more concerned about space than about flexability.
;;; This looks like the following:
;;;
;;;                 _____ s-arc
;;;  s-graph-object/             _____ s-string-node _____ s-plain-str-node
;;;                \_____ s-node/
;;;                             \_____ s-image-node 
;;;
;;; *** add this later ****


;;; The main graphical object.  The superclass of nodes and arcs.
(defclass graph-object ()
 (
  (object :initarg :object :accessor object)     ;; object represented
  (label :initarg :label :accessor label)        ;; label displayed
  (display-p :initform t :accessor display-p)    ;; display this object?
  (g-c :initarg :g-c :accessor g-c :initform nil);; graphic context for object
  (region :accessor region)                      ;; region containing object
))

;;; Other graphical objects.

(defclass node (graph-object)
  (
   (toarcs :accessor toarcs :initform '())             ;; list of arcs
   (fromarcs :accessor fromarcs :initform '())         ;; list of arcs
   (x :initform 0 :accessor x :type fixnum)            ;; position of region 
   (y :initform 0 :accessor y :type fixnum)            ;;    (left bottom)
   (depth-set :initform nil :accessor depth-set)       ;; depth (x) layed out?
   (breadth-set :initform nil :accessor breadth-set)   ;; breadth (y) layed out?
   (root :accessor root :initarg :root :initform nil)  ;; root object predicate
   (width :initform 0 :accessor width :type fixnum)    ;; width of object
   (height :initform 0 :accessor height :type fixnum)  ;; height of object
   (depth :initform 0 :accessor depth                  ;; depth of node
	  :initarg :depth :type fixnum) 
   (border :initform 0 :accessor border                ;; for label
	   :initarg :border :type fixnum) 
   (selected :accessor selected :initform nil)         ;; object selected?
   (depth-limit :initform nil :accessor depth-limit    ;; overrides graph
		:initarg :depth-limit :type fixnum) 
   (gcount :accessor gcount :initform 0 :initarg :gcount  ;; count (creation order)
	  :type fixnum)
   (gancestors :accessor gancestors :initform '()        ;; list of ancestors
	      :initarg :gancestors)                     ;;    for cycle finding
   (expand-continuation :initform '()                  ;; before exp.
			:accessor expand-continuation) 
   (collapse :initform '() :accessor collapse)         ;; nodes collasped
   (duplicates :initform '() :accessor duplicates      ;; copies of this node
	       :initarg :duplicates)
   (is-duplicated-by :initform '()                     ;; node this copies
		     :accessor is-duplicated-by)
))

(defclass arc (graph-object) 
  (
   (fromnode :initform nil :accessor fromnode)        ;; ancestor node
   (tonode :initform nil :accessor tonode)            ;; descendent node
   (cross-link :initform nil :accessor cross-link     ;; cross link
	       :initarg :cross-link)
   (back-link :initform nil :accessor back-link       ;; back link
	      :initarg :back-link)
   (from-x :initform 0 :accessor from-x :type fixnum) ;; from position
   (from-y :initform 0 :accessor from-y :type fixnum)
   (to-x :initform 0 :accessor to-x :type fixnum)     ;; to position
   (to-y :initform 0 :accessor to-y :type fixnum)
))

;; here the label is a string
(defclass string-node (node)
  ((depth-label :accessor depth-label :initform nil))
  (:default-initargs :g-c *plain-str-gc*))

;; here the label is an image
(defclass image-node (node)
  ((text :initform nil :accessor text               
	 :initarg :text))
  (:default-initargs :g-c *image-node-gc*))

;; string node subclasses -- each associated with a gc
(defclass plain-str-node (string-node) ())

(defclass bold-str-node (string-node) ()
  (:default-initargs :g-c *bold-str-gc*))

(defclass italic-str-node (string-node) ()
  (:default-initargs :g-c *italic-str-gc*))

(defclass italicbold-str-node (string-node) ()
  (:default-initargs :g-c *italicbold-str-gc*))

;;; Graphic context classes.

;;; The main graphical context (with a default bold font)
(defclass grapher-gc (graphics-context) ()
  (:default-initargs :font *grapher-normalfont*))

;;; The other graphcal contexts
(defclass arc-gc (grapher-gc) ())

(defclass node-gc (grapher-gc) ())

(defclass image-node-gc (node-gc) ())

(defclass string-node-gc (node-gc) ())


;;;
;;; graph object initialization methods
;;;

;; node printing...
(defmethod print-object ((node node) stream)
	(format stream "#<~:(~a~) ~a>" (class-name (class-of node)) (text node)))

;; arc printing...
(defmethod print-object ((arc arc) stream)
  (let ((tonode (tonode arc))
	(fromnode (fromnode arc)))
    (format stream "#<~:(~a~) From:~a To:~a>" 
	    (class-name (class-of arc))
	    (when fromnode (text fromnode))
	    (when tonode (text tonode)))))

;; update font in string-gc classes if they are changed
(defmethod update-instance-for-different-class :after ((prev string-node) 
						       (curr string-node)
						       &rest initargs)
  (declare (ignore initargs))
  ;; update the font slot of the new string-node-gc instance
  (let ((gcarg (assoc :g-c (class-default-initargs (class-of curr)))))
    (when gcarg
      (with-interrupts-allowed
       (setf (g-c curr) gcarg)))))

;; initialize the node--calculate width, height, 
;; and region (region to be updated)
(defmethod initialize-instance :after ((node node) &rest initargs)
  (declare (ignore initargs))
  (setf (width node) (label-width node)
	(height node) (label-height node)
	(region node) (make-region :top 0 :left 0 
				   :width (width node) 
				   :height (height node))))


;;;
;;; Relation/Arc Classes
;;;

;;; As seen above, the arc class is a subclass of the graph-object
;;; superclass.  Arcs are more complex than that however.  Arcs not
;;; only embody the node link information and graphic context information,
;;; they also must handle more complex relation information (this
;;; also includes how to handle the transitive closure of a relation).
;;; This is layed out in the following two class hierarchies.  The arc 
;;; and arc-gc classes are carried over from the above graph.
;;;
;;; The firt hierarchy corresponds to the relation metaclass and
;;; transitive closure metaclasses mixins.  These are metaclasses
;;; because many methods must work off of the relation class (e.g.,
;;; the children relation, or children-arc subclass) like the
;;; transitive-closure and get-range-object methods.  The transitive
;;; closure classes are mixed in with the relation meta.  All relation
;;; classes (i.e., at least the leaf classes) *must* use a relation-meta 
;;; (w/ transitive closure mixed in) metaclass.
;;;
;;; The second hierarchy covers the main arc and relation classes
;;; and mixins.

;;;
;;;                     ___ full-t-c ________
;;; transitive-closure /___ lazy-t-c _______ \
;;;                    \___ background-t-c_ \ \
;;;                 _______________________\_\_\ ftc-relation-meta
;;;                /                        \ \
;;; relation-meta /__________________________\_\ ltc-relation-meta
;;;               \                           \
;;;                \___________________________\ btc-relation-meta
;;;

;;;
;;;   relation --- children ____________________
;;;                                             \
;;;   arc _______________________________________ children-arc
;;;                                             /
;;;   geometry --- straight-line ___ __________/
;;;                                           /
;;;           ___ solid-arc-gc ______________/
;;;   arc-gc /___ bold-arc-gc
;;;          \___ dashed-arc-gc
;;;
;;; A subclass from each of the four top level superclasses is joined
;;; to form a relation/arc class as seen in the default children-arc.
;;; 
;;; **** maybe later add geo, relation, tc, etc. slots to ****
;;; **** arc instead of class mixing                      ****
;;; OK, gc is not a slot of an arc, not a mixin.  So, the gc
;;; hierarchy looks like:
;;;
;;;           _ _ _ *solid-arc-gc*
;;;   arc-gc /_ _ _ *bold-arc-gc*
;;;          \_ _ _ *dashed-arc-gc*
;;;
;;; Also, the geo stuff has been taken out.  If an application
;;; needs some different shape (geo), then they can just
;;; specialize arc and make their own display (and layout) methods.

;;; relation metaclass
(defclass relation-meta (standard-class) ())

;;; transitive closure metaclasses
(defclass transitive-closure (standard-class) ())

(defclass full-t-c (transitive-closure) ())

(defclass lazy-t-c (transitive-closure) ())

(defclass background-t-c (transitive-closure) ())

;;; metaclass mixed classes (mixed from relation-meta and trans.)
(defclass ftc-relation-meta (relation-meta full-t-c) ())

(defclass ltc-relation-meta (relation-meta lazy-t-c) ())

(defclass btc-relation-meta (relation-meta background-t-c) ())

;;; compatability  ...need both class and standard-class?
(defmethod validate-superclass ((c1 ftc-relation-meta) (c2 class)) t)
(defmethod validate-superclass ((c1 ftc-relation-meta) (c2 standard-class)) t)
(defmethod validate-superclass ((c1 ltc-relation-meta) (c2 class)) t)
(defmethod validate-superclass ((c1 ltc-relation-meta) (c2 standard-class)) t)
(defmethod validate-superclass ((c1 btc-relation-meta) (c2 class)) t)
(defmethod validate-superclass ((c1 btc-relation-meta) (c2 standard-class)) t)


