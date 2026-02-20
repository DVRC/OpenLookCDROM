;;; -*- Mode: Lisp; Package: PH-OPERS -*-
;;;
;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.
;;;	
;;; Polyhedron operations.  Truncation, dualing.
;;;
;;; Author: Conal Elliott.  Last Modified Mon Nov  5 16:03:19 1990
;;;
;;; Sccs Id %W% %G%
;;;

(in-package :PH-OPERS :use '(:ph :point :generic :clos :lisp))

(export '(truncation dual))


;;; Truncation

(defmethod truncation ((old-ph ph) &key tweener distance
                       (fraction (default-truncation-fraction old-ph)))
  "Form the truncation of OLD-PH.  To determine how much to remove from the
ends of each edge, takes any one of the keyword arguments :fraction, :distance,
and :tweener.  The final one is a function of two points that generates a new
point."
  ;; Approach: First, for each old vertex, make a new face whose vertices are
  ;; found partway down the corresponding edge of the old vertex.
  (let ((tweener (cond (tweener tweener)
                       (distance #'(lambda (point-a point-b)
                                     (point-between point-a point-b
                                                    distance)))
                       (t #'(lambda (point-a point-b)
                              (point-between-ratio point-a point-b
                                                   fraction))))))
    (let* ((new-ph (make-instance 'ph))
           (vert-faces
            (mapp #'(lambda (old-vertex)
                      (make-instance
                       'face
                       :vertices
                       ;;(nreverse
                       (mapp #'(lambda (old-edge)
                                 (make-instance
                                  'vertex
                                  :point
                                  (funcall tweener
                                           (vertex-point
                                            (src-vertex old-edge))
                                           (vertex-point
                                            (dst-vertex old-edge)))
                                  :ph new-ph))
                             (edges old-vertex))
                       ;;)
                       ))
                  (vertices old-ph)))
           ;; Then for each old face, make a new face, replacing each vertex of
           ;; the old face by the swapped end-vertices of the new edge that
           ;; replaced the old vertex in the corresponding new face.
           (face-faces
            (mapp #'(lambda (old-face)
                      (make-instance
                       'face
                       :vertices
                       ;; This nreverse is here because I wrongly assumed that
                       ;; front faces have clockwise ordered vertices.  Change
                       ;; that assumption globally and then take out this
                       ;; nreverse.
                       (nreverse
                        (mapp-concat
                         #'(lambda (old-v)
                             (let* ((vert-face
                                     (seq-translate old-v (vertices old-ph)
                                                    vert-faces :test #'eq))
                                    (vert-face-edge
                                     (seq-translate old-face (faces old-v)
                                                    (edges vert-face)
                                                    :test #'eq)))
                               ;; This should be dst,src.  Swap when I make the
                               ;; orientation fix.
                               (list (src-vertex vert-face-edge)
                                     (dst-vertex vert-face-edge))))
                         (vertices old-face))
                        )
                       ))
                  (faces old-ph))))
      (setf (faces new-ph)
            (concatt vert-faces face-faces)
            ;;vert-faces
            ;;face-faces
            ;;(subseq face-faces 0 1)
            )
      new-ph)))

(defun default-truncation-fraction (ph)
  "Default truncation cut distance for polyhedron PH.  If applied to a Platonic
solid, this makes the faces come out regular."
  ;; See how many, n, sides there are in one of the faces.
  (let* ((n (length (edges (elt (faces ph) 0))))
         ;; then, theta, half of the subtended (?) angle,
         (theta (/ pi n))               ; (2 pi) / (2 n)
         ;; then the distance, l, from the center of a regular n-gon to the
         ;; midpoint of one of its edges, assuming side length 2, using
         ;; tan theta = 1 / l
         (l (/ 1 (tan theta)))
         ;; Then the length of the side of a regular 2n-gon formed by trucating
         ;; the regular n-gon, using tan (theta/2) = new-half-side/l
         (new-half-side (* l (tan (/ theta 2))))
         ;; Then the difference between the old and new half sides, which is
         ;; the ratio
         (shrinkage (- 1 new-half-side)))
    ;;(format t "~&theta is ~s~%" theta)
    ;;(format t "~&l is ~s~%" l)
    ;;(format t "~&new-half-side is ~s~%" new-half-side)
    ;;(format t "~&shrinkage is ~s~%" shrinkage)
    ;; Then the truncation fraction is the quotient of shrinkage and the
    ;; original side length (2).
    (/ shrinkage 2)))


(defun edge-length (edge)
  "Calculate the length of an edge."
  (point-distance (vertex-point (src-vertex edge))
                  (vertex-point (dst-vertex edge))))


;;; Dual formation

(defmethod dual ((old-ph ph) &optional (radius (default-dual-radius old-ph)))
  "Form the dual of OLD-PH, optionally giving the radius of the sphere through
which to dual.  The radius defaults to something tame for now but right later."
  (make-instance
   'ph
   :vertex-points
   (mapp #'(lambda (old-face) (dual-point old-face radius))
         (faces old-ph))
   :indexed-faces
   (mapp #'(lambda (old-vertex)
             (mapp #'(lambda (old-vertex-face)
                       (position old-vertex-face (faces old-ph)))
                   (faces old-vertex)))
         (vertices old-ph))))

(defun dual-point (face radius)
  "Find the point of the vertex dual to FACE through RADIUS."
  ;; Find the average point and then project through it from the origin by a
  ;; distance of radius^2 divided by the distance of the average point from the
  ;; origin.
  (let ((ave-point (point-average (vertices face) #'vertex-point)))
    (point-between *point-origin* ave-point
                   (/ (* radius radius)
                      (point-magnitude ave-point)))))

(defun default-dual-radius (ph)
  "Compute the default dual radius.  This version takes it to be the distance
between the origin and the midpoint of some edge."
  (let* ((edge (elt (edges ph) 0))
         (midpoint (point-average (list (src-vertex edge)
                                        (dst-vertex edge))
                                  #'vertex-point)))
    (point-magnitude midpoint)))
