;;; -*- Mode: Lisp; Package: POINT -*-
;;;
;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.
;;;	
;;; Points.  For now only 3d, but will probably add 2d points here as well.
;;;
;;; Author: Conal Elliott.  Last Modified Mon Nov  5 16:03:46 1990
;;;
;;; Sccs Id %W% %G%
;;;

(in-package :POINT :use '(:generic #|:ergolisp|# :lisp))

(export '(point point-x point-y point-z point-distance
          point-between point-between-ratio
          *point-origin* point-magnitude point-average))


;;;; Points.  Should I allow side-effecting these?

(defstruct (point (:constructor point (x y z))
                  (:print-function print-point))
  x y z)

(defun print-point (point stream depth)
  (declare (ignore depth))
  (format stream "#<Point ~f,~f,~f>"
          (point-x point) (point-y point) (point-z point)))

#|

(defconstr point
  ((x float)
   (y float)
   (z float)))

|#


(defun point-distance (a b)
  "Compute the Euclidean distance between points A and B."
  (sqrt (+ (expt (- (point-x a) (point-x b)) 2)
           (expt (- (point-y a) (point-y b)) 2)
           (expt (- (point-z a) (point-z b)) 2))))

(defun point-between (src dst distance)
  "Find the point DISTANCE units from the points SRC and DST."
  (point-between-ratio src dst (/ distance (point-distance src dst))))

(defun point-between-ratio (src dst frac)
  "Find the point FRAC of the way from the  SRC to DST."
  (let ((1-frac (- 1 frac)))
    ;; Make a point each of whose coordinates is the right fraction between the
    ;; corresponding coordinate of SRC and DST.
    (point (+ (* 1-frac (point-x src)) (* frac (point-x dst)))
           (+ (* 1-frac (point-y src)) (* frac (point-y dst)))
           (+ (* 1-frac (point-z src)) (* frac (point-z dst))))))

(defvar *point-origin* (point 0.0 0.0 0.0)
  "The origin point.")

(defun point-magnitude (point)
  "The magnitude of POINT thought of as a vector.  The distance from
*point-origin* to POINT."
  (point-distance *point-origin* point))

(defun point-average (point-holders &optional (point-extractor #'identity))
  "Find the average point of a sequence POINT-HOLDERS, using the optional
argument POINT-EXTRACTOR (default #'identity) to access each point."
  (let ((num-holders (length point-holders)))
    (flet ((ave-coord (coord-extractor)
             ;; Find the average of a coordinate.
             ;; coord-extractor is a function to get x,y or z out of a point.
             (/ (reduce
                 #'(lambda (sum-so-far next-holder)
                     (+ sum-so-far
                        (funcall coord-extractor
                                 (funcall point-extractor next-holder))))
                        point-holders
                        :initial-value 0.0)
                num-holders)))
      (point (ave-coord #'point-x)
             (ave-coord #'point-y)
             (ave-coord #'point-z)))))
