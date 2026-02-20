;;; -*- Mode: Lisp; Package: user -*-
;;;
;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.
;;;
;;; Created:       Tue Oct 15 08:47:04 1991 by Conal Elliott
;;; Last Modified: Mon Oct 21 15:11:06 1991 by Conal Elliott
;;;
;;;   Load the polyhedron system.
;;;
;;; Sccs Id %W% %G%
;;;

(in-package :user)

(defun load-polyhedra ()
  (flet ((do-load (file)
	   (load file :if-source-only :compile :if-source-newer :compile)))
    (do-load "generic")
    (do-load "point")
    (do-load "basics")
    (do-load "model")
    #| Double buffering.  See README
    (do-load "db-basics")
    (do-load "db-model")
    |#
    (do-load "ph")
    (do-load "ph-lib.lisp")
    (do-load "ph-opers")
    (shadowing-import '(
			ffi::load-foreign-files
			ffi::def-foreign-function
			ffi::load-foreign-libraries
			ffi::def-foreign-callable
			lv::name)
		      :user)
    (use-package '(:ffi :clos :generic :lv :xgl :model
		   :point :ph :ph-lib :ph-opers))
    (do-load "model-watcher.ui")
    (do-load "model-watcher")))


;;; Ignore FPEs.  (In particular, div-by-zero and underflow), since XGL 2.0
;;; currently does these.
(sys:setup-interrupt-handler 8 :ignore)

(load-polyhedra)
