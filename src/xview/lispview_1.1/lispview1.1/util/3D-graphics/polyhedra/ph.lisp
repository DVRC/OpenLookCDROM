;;; -*- Mode: Lisp; Package: PH -*-
;;;
;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.
;;;	
;;; Polyhedra stuff.  Defines points, polyhedra, vertices, edges, and faces.
;;; Heavily uses slots computed on demand (def-cached-slot).
;;;
;;; Author: Conal Elliott.  Last Modified Mon Nov  5 16:00:06 1990
;;;
;;; Sccs Id %W% %G%
;;;

(in-package :PH :use '(:point :model :xgl :generic :ffi :clos :lisp))

(export '(has-faces has-vertices has-edges has-ph
          faces vertices edges colors
          ph svertex vertex vertex-point face edge
          coloring-style calculate-face-color-index *monochrome-style*
          *edge-neighbors-distinct-style* *vertex-neighbors-distinct-style*
          src-vertex dst-vertex src-face dst-face dihedral-angle color-index
          vertex-points indexed-faces indexed-colors indexed-face-colors
          edge-inverse-p))

;;;; Color.  For now just consecutive colormap-indexed colors.  When I switch
;;;; to colormap double-buffering, this will change.

(defconstant max-colors 8
  "The maximum number of colors used.  Should be kept to a small power of to
allow colormap double buffering, which squares the required colormap entries.")

(defparameter *default-colors*
  (mapp #'(lambda (i) (make-xgl-color
                       :index (+ (* max-colors i) i)))
        (count-to max-colors))
  "The face colors to be used by default.  Just colors of index less than
max-colors.") 


;;;; Classes

;;; Container mixins.

(defclass has-faces ()
  ((faces :type (sequence-of face) :accessor faces :initarg :faces)))

(defclass has-vertices ()
  ((vertices :type (sequence-of vertex)
             :accessor vertices :initarg :vertices)))

(defclass has-edges ()
  ((edges :type (sequence-of edge) :accessor edges :initarg :edges)))

(defclass has-ph ()
  ;; The polyhedron I'm part of.  Somewhat useful.
  ((ph :type ph :accessor ph :initarg :ph)))

;;; The main classes.

(defclass svertex ()
  ;; This is used for polygons, currently in ph-uniform.lisp (10/10/90)
  ((vertex-point :type point :accessor vertex-point :initarg :point))
  (:documentation "A simple vertex, just containing a point."))

(defclass vertex (svertex has-ph has-faces has-edges)
  ()
  (:documentation
   "A vertex knows its point, containing polyhedron, the faces surrounding it
in clockwise order, and the edges emanating from it in clockwise order.  Each
edge has the vertex as its src-vertex.  The i-th face is the dst-face of the
i-th edge."))

(defclass face (has-vertices has-edges)
  ((color-index :type fixnum :accessor color-index :initarg color-index))
  (:documentation
   "A face has vertices and edges, listed in clockwise order.  Each edge has
the face as its src-face.  The i-th edge has the i-th vertex as its src-vertex
and the (i+1)-th (with wrap around) vertex as its dst-vertex.  Also has a
color index."))

(defclass edge ()
  ((src-vertex :type vertex :accessor src-vertex :initarg :src-vertex)
   (dst-vertex :type vertex :accessor dst-vertex :initarg :dst-vertex)
   (src-face :type face :accessor src-face :initarg :src-face)
   (dst-face :type face :accessor dst-face :initarg :dst-face)
   (inverse-edge :type edge :accessor inverse-edge :initarg :inverse-edge)
   (dihedral-angle :type float
                   :accessor dihedral-angle :initarg dihedral-angle))
  (:documentation
   "An edge has a source and destination face and vertex plus an inverse edge,
i.e., edges are directed.  Also carries the dihedral angle, which is being
phased in.  (10/10/90)"))


;;; Face coloring styles.

(defclass coloring-style () ())

(defgeneric calculate-face-color-index (face coloring-style color-limit)
  (:documentation
   "Find a color for this face according to the given coloring-style, using
color indices greater than zero (the background) and less than max-colors.
Returns a value for (color-index FACE)."))

(defclass monochrome-colored (coloring-style)
  ()
  (:documentation "The style of all faces having color index 1."))

(defvar *monochrome-style* (make-instance 'monochrome-colored))

(defmethod calculate-face-color-index (face (style monochrome-colored)
                                            color-limit)
  "Always use color 1.  Assume color-limit>1."
  (declare (ignore face color-limit))
  1)

(defclass edge-neighbors-distinctly-colored (coloring-style)
  ()
  (:documentation
   "The style of making sure no two neighbor faces that share edge have the
same color"))

(defvar *edge-neighbors-distinct-style*
  (make-instance 'edge-neighbors-distinctly-colored))

(defclass vertex-neighbors-distinctly-colored (coloring-style)
  ()
  (:documentation
   "The style of making sure no two neighbor faces that share vertex have the
same color"))

(defvar *vertex-neighbors-distinct-style*
  (make-instance 'vertex-neighbors-distinctly-colored))


;;; The polyhedron class.
(defclass ph (has-faces has-vertices has-edges)
  ((colors :type (sequence-of xgl-color) :accessor colors
           :initarg :colors :initform *default-colors*)
   (vertex-points :type (sequence-of point)
                  :accessor vertex-points :initarg :vertex-points)
   (indexed-faces :type (sequence-of (sequence-of fixnum))
                  :accessor indexed-faces :initarg :indexed-faces)
   (indexed-face-colors :type (sequence-of fixnum)
                        :accessor indexed-face-colors
                        :initarg :indexed-face-colors)
   (coloring-style :accessor coloring-style
                   :initarg :coloring-style
                   :initform *vertex-neighbors-distinct-style*)
   (render-args :accessor render-args))
  (:documentation
   "A ph (polyhedron) has faces, vertices, edges, and colors.  Especially for
convenience of construction, it also can have a sequence of vertex points, and
a sequence of indexed faces, each of which is just a sequence of indices into
the vertex sequence.  Similarly, it can have a sequence of face color
indices.  Alternatively to giving the face color indices, one can specify a
coloring-style.  The default is of the class neighbors-distinctly-colored.
Given this information, the rest can be automatically computed.  Also has a
sequence of face colors, each of which is just an index whose interpretation is
left open."))


;;; Rendering

(defmethod render-geometry (ctx (ph ph))
  "Render in the xgl context CTX the polyhedron ph.  Low level method,
which assumes that the transformation stuff has already been done."
  (apply #'xgl-multi-simple-polygon
         ctx
         (render-args ph)))


(def-cached-slot render-args (ph ph)
  (polyhedron-multi-simple-polygon-args
   (vertex-points ph)
   (indexed-faces ph)
   (mapp #'(lambda (i) (elt (colors ph) i))
     (indexed-face-colors ph))))


;;; Polyhedron cached slots.

(def-cached-slot vertices (ph ph)
  (cond ((slot-boundp ph 'faces)
         (mapp-union #'vertices (faces ph)))
        ((slot-boundp ph 'edges)
         ;; Collect all of the source vertices.  Assumes that ph is closed.
         (mapp-setify #'src-vertex (edges ph)))
        ((slot-boundp ph 'vertex-points)
         (mapp #'(lambda (pt)
                   (make-instance 'vertex :point pt :ph ph))
               (vertex-points ph)))
        (t (error "Cannot compute (vertices ~s) ~
without knowing faces, edges, or vertex-points"
                  ph))))

(def-cached-slot faces (ph ph)
  ;; Construct the faces out of the indexed-faces
  (if (slot-boundp ph 'indexed-faces)
      (mapp #'(lambda (point-indices)
                (make-instance
                 'face
                 :vertices (mapp #'(lambda (index)
                                     (elt (vertices ph) index))
                                 point-indices)))
            (indexed-faces ph))
      (error "Cannot compute (faces ~s) without knowing indexed-faces" ph)))

(defun edge-inverse-p (edge other-edge)
  "Decide whether EDGE and OTHER-EDGE are inverses."
  (and (eq (src-vertex edge)
           (dst-vertex other-edge))
       (eq (dst-vertex edge)
           (src-vertex other-edge))))

(def-cached-slot edges (ph ph)
  ;; Collect the edges from the faces of ph, forming the inverse-edge
  ;; associations.
  (let ((edges (mapp-concat #'edges (faces ph))))
    (map nil
         #'(lambda (edge)
             ;; If we've already established this edge as the inverse of a
             ;; previous one, then don't bother.
             (unless (slot-boundp edge 'inverse-edge)
               (let ((inverse
                      (or (find edge edges
                                :test #'edge-inverse-p)
                          (error "No inverse found for ~s" edge))))
                 (setf (inverse-edge edge) inverse)
                 (setf (inverse-edge inverse) edge))))
         edges)
    edges))

(def-cached-slot vertex-points (ph ph)
  (mapp #'vertex-point (vertices ph)))

(def-cached-slot indexed-faces (ph ph)
  (if (slot-boundp ph 'faces)
      (mapp #'(lambda (face)
                (mapp #'(lambda (face-vertex)
                          (position face-vertex (vertices ph) :test #'eq))
                      (vertices face)))
            (faces ph))
      (error "Cannot compute (indexed-faces ~s) without knowing faces" ph)))

(def-cached-slot indexed-face-colors (ph ph)
  ;; If the face colors are not given, they will have to be computed for each
  ;; face and then extracted.
  (mapp #'color-index (faces ph)))


;;; Face cached slots.

(def-cached-slot edges (face face)
  ;;(if (slot-boundp face 'vertices)
  (mapp #'(lambda (this-vertex next-vertex)
            (make-instance 'edge
                           :src-vertex this-vertex
                           :dst-vertex next-vertex
                           :src-face face))
        (vertices face) (seq-rotate-right (vertices face)))
  ;;(error "Cannot compute (edges ~s) without knowing vertices" face))
  )

(def-cached-slot vertices (face face)
  (if (slot-boundp face 'edges)
      (mapp #'src-vertex (edges face))
      (error "Cannot compute (vertices ~s) without knowing edges" face)))

(def-cached-slot color-index (face face)
  ;; Remember, vertices know the containing polyhedron.
  (let ((ph (ph (elt (vertices face) 0))))
    ;; If the polyhedron has its indexed-face-colors, find the position of this
    ;; face, look up the index into the colors list.
    (if (slot-boundp ph 'indexed-face-colors)
        (elt (indexed-face-colors ph)
             (position face (faces ph)))
        (calculate-face-color-index face
                                    (coloring-style ph)
                                    (length (colors ph))))))

(defmethod calculate-face-color-index
    (face (style vertex-neighbors-distinctly-colored) color-limit)
  (neighbor-coloring face color-limit #'face-vertex-neighbors
                     *edge-neighbors-distinct-style*))

(defmethod calculate-face-color-index
    (face (style edge-neighbors-distinctly-colored) color-limit)
  (neighbor-coloring face color-limit #'face-edge-neighbors
                     *monochrome-style*))

(defun neighbor-coloring (face color-limit neighbor-function backup-style)
  ;; Compute the coloring of face without, using neighbor-function to construct
  ;; the collection of neighbor faces, and resorting to backup-style on
  ;; failure.
  ;; Try each color (except background 0) from 1 to (1- color-limit).
  (let ((neighbor-color-indices (neighbor-color-indices face
                                                        neighbor-function)))
    (labels ((try (i)
               (cond ((>= i color-limit)
                      (calculate-face-color-index face
                                                  backup-style
                                                  color-limit))
                     ((not (find i neighbor-color-indices))
                      i)
                     (t (try (1+ i))))))
      (try 1))))

(defun neighbor-color-indices (face neighbor-function)
  "Constructs list of color-indices of the face's neighbors, putting in nil
where the color has not yet been assigned.  Use neighbor-function to construct
the collection of neighbors."
  (mapp #'(lambda (neighbor-face)
            (and (slot-boundp neighbor-face 'color-index)
                 (color-index neighbor-face)))
    (funcall neighbor-function face)))

(defun face-vertex-neighbors (face)
  "All of the faces that share a vertex with this one."
  (mapp-union #'faces (vertices face)))

(defun face-edge-neighbors (face)
  "All of the faces that share an edge with this one."
  (mapp #'dst-face (edges face)))


;;; Edge cached slots

(def-cached-slot dst-face (edge edge)
  (src-face (inverse-edge edge)))

(def-cached-slot dihedral-angle (edge edge)
  (dihedral-angle (inverse-edge edge)))

(def-cached-slot inverse-edge (edge edge)
  ;; Force assignment of all inverses.
  (edges (ph (src-vertex edge)))
  (assert (slot-boundp edge 'inverse-edge)
          ()
          "Bad bug: inverse-edge still not bound")
  (inverse-edge edge))


;;; Vertex cached slots

(def-cached-slot edges (vertex vertex)
  ;; Start with any edge of the containing polyhedron whose source vertex is
  ;; the given one.  Build up the list of edges backwards (counterclockwise).
  ;; At each step, the next edge is determined as follows: The current edge
  ;; has a src-face, which has an edge whose dst-vertex is the one we're
  ;; considering.  The inverse of that edge is the next edge.  Keep going until
  ;; we get back to the first (last) edge.
  (let ((first-edge (find vertex (edges (ph vertex))
                          :key #'src-vertex :test #'eq)))
    (labels ((add-edges (edges-so-far)
               (let* ((face (src-face (first edges-so-far)))
                      (next-edge (inverse-edge
                                  (find vertex (edges face)
                                        :key #'dst-vertex :test #'eq))))
                 (if (eq next-edge first-edge)
                     (convert-seq edges-so-far)
                     (add-edges (cons next-edge edges-so-far))))))
      (add-edges (list first-edge)))))

(def-cached-slot faces (vertex vertex)
  (mapp #'dst-face (edges vertex)))
