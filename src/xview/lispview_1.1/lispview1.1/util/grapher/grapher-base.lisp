;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;;  File: grapher-base.lisp
;;;;
;;;;  Author: Philip McBride
;;;;
;;;;  This file contains the globals, initialization code, and
;;;;  general utility code for the lispview grapher.
;;;;
;;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;;	See LEGAL_NOTICE file for terms of the license.
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package :grapher)

;;;
;;; Globals
;;;

;;; grapher init predicate--says whether grapher has been init'ed
(defvar *grapher-init* nil)

;;; font globals used by the grapher gc instances below.
(defvar *grapher-boldfont* nil)
(defvar *grapher-normalfont* nil)
(defvar *grapher-italicboldfont* nil)
(defvar *grapher-italicfont* nil)

;;; gc instances used by the string node subclasses
(defvar *image-node-gc* nil)
(defvar *plain-str-gc* nil)
(defvar *bold-str-gc* nil)
(defvar *italic-str-gc* nil)
(defvar *italicbold-str-gc* nil)

;;; gc instances used by the arc class
(defvar *solid-arc-gc* nil)
(defvar *bold-arc-gc* nil)
(defvar *doublebold-arc-gc* nil)
(defvar *dashed-arc-gc* nil)
(defvar *bolddashed-arc-gc* nil)

;;; graph tool globals
(defvar *graph-tool* nil)
(defvar *graph-tools* '())

;;; grapher icon var
(defvar *grapher-icon-image* nil)

;; window vars
(defvar *damage-interest* nil)
(defvar *select-mouse-interest* nil)
(defvar *menu-mouse-interest* nil)
(defvar *dummy-mouse-interest* nil)
(defvar *move-mouse-interest* nil)

;; loading dir to be used by icon loading
(defvar *icon-dir* *load-pathname*)


;;;
;;; grapher init function
;;;

;; Reset the font globals to some default fonts  also set the
;; grapher init global.  Some of these, like *grapher-init* could
;; be encapsulated with in the init proceedure.  It's always something.
(defun grapher-init ()
  (unless *grapher-init*
    (setf *grapher-init* t
	  (solo::click-travel)
	  5
	  *graph-tool*
	  (make-instance 'grapher-library-tool)
	  *graph-tools*
	  (list *graph-tool*)
	  *damage-interest*
	  (make-instance 'damage-interest)
	  *select-mouse-interest*
	  (make-instance 'select-mouse-interest)
	  *menu-mouse-interest*
	  (make-instance 'menu-mouse-interest)
	  *dummy-mouse-interest*
	  (make-instance 'dummy-mouse-interest)
	  *open-mouse-interest*
	  (make-instance 'open-mouse-interest)
	  *edit-mouse-interest*
	  (make-instance 'edit-mouse-interest)
	  *move-mouse-interest*
	  (make-instance 'move-mouse-interest)
	  *grapher-icon-image*
	  (make-instance 'image 
			 :filename 
			 (merge-pathnames "grapher.sicon" 
					  *icon-dir*)
			 :format :sun-icon)
	  *grapher-boldfont* 
	  (make-instance 'font :family "Times" :point-size 14
			 :weight :bold :slant :roman)
	  *grapher-normalfont*
	  (make-instance 'font :family "Times" :point-size 14
			 :weight :medium :slant :roman)
	  *grapher-italicboldfont*
	  (make-instance 'font :family "Times" :point-size 14
			 :weight :bold :slant :italic)
	  *grapher-italicfont*
	  (make-instance 'font :family "Times" :point-size 14
			 :weight :medium :slant :italic)
	  *image-node-gc*
	  (make-instance 'image-node-gc)
	  *plain-str-gc*
	  (make-instance 'string-node-gc :font *grapher-normalfont*)
	  *bold-str-gc*
	  (make-instance 'string-node-gc :font *grapher-boldfont*)
	  *italic-str-gc*
	  (make-instance 'string-node-gc :font *grapher-italicfont*)
	  *italicbold-str-gc*
	  (make-instance 'string-node-gc :font *grapher-italicboldfont*)
	  *solid-arc-gc*
	  (make-instance 'arc-gc :line-style :solid :line-width 1)
	  *bold-arc-gc*
	  (make-instance 'arc-gc :line-style :solid :line-width 2)
	  *doublebold-arc-gc*
	  (make-instance 'arc-gc :line-style :solid :line-width 4)
	  *dashed-arc-gc*
	  (make-instance 'arc-gc :line-style :dash :line-width 1)
	  *bolddashed-arc-gc*
	  (make-instance 'arc-gc :line-style :dash :line-width 2)
	  )))
