;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;;  File: load-grapher.lisp
;;;;
;;;;  Author: Philip McBride
;;;;
;;;;  This file contains the code for loading the lispview grapher.
;;;;
;;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;;	See LEGAL_NOTICE file for terms of the license.
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package :grapher)

(defun load-grapher ()
  (load (merge-pathnames "grapher-pkg" *load-pathname*))
  (load (merge-pathnames "grapher-base" *load-pathname*))
  (load (merge-pathnames "grapher-classes" *load-pathname*))
  (load (merge-pathnames "grapher-classes-2" *load-pathname*))
  (load (merge-pathnames "grapher-util" *load-pathname*))	
  (load (merge-pathnames "grapher-construct" *load-pathname*))
  (load (merge-pathnames "grapher-layout" *load-pathname*))
  (load (merge-pathnames "grapher-interface" *load-pathname*))
  (load (merge-pathnames "class-grapher" *load-pathname*))
  (load (merge-pathnames "window-grapher" *load-pathname*)))

(let ((lcl::*load-if-source-only* :compile))
  (load-grapher))

