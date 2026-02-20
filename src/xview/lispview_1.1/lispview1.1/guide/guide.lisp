;;; -*- Mode: LISP; Syntax: Common-Lisp; Package: GUIDE; Base: 10 -*-
;;;
;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

(in-package :guide)

;;; ========================================================================
;;; This file contains code for both glv and lvg:
;;; glv is a translator from Devguide to LispView
;;; lvg is a translator from LispView to Devguide
;;; ========================================================================
;;; glv: Globals:
;;; =============
(export '(convert-gil-file generate-lv-code glv))

(defvar *gil-version* 2)
(defvar *output-format* "pprint")
(defvar *defclass-format* "Accessors")
(defvar *version-skew-warning-displayed* nil)

;;; The name of the class that contains all the user interface components
;;; is derived from the filename specified when saving the interface in
;;; Devguide.
(defvar *application-class-name* nil) ; just in case you load "guide" b4 
                                      ; pressing "load" button

;;; The list of forms to be generated at the top of the ui file.
(defparameter *ui-file-forms* nil)
(defparameter *my-path-to-icon-set* nil) ; do it once only

;;; This list will contain the names of function stubs to be generated.
;;; The function body will simply contain an informative print statement.
(defparameter *list-of-user-functions* nil)

;;; This list will contain verbatum lisp code that will be written
;;; to the output file.
(defparameter *code-gen-list* nil)

;;; A list of top level windows that need to be mapped after their
;;; children are instantiated.
(defparameter *last-code-in-initialize-instance* nil)

;;; This variable will contain the name of the top-level window that
;;; was the first window dropped in Devguide - used as the :owner of
;;; menus requiring a pin.
(defparameter *menu-owner-window-name* nil)
(defparameter *menu-owner-list* nil)
(defparameter *menu-owner-and-deps-list* nil)
;;; ========================================================================
;;; lvg: Globals:
;;; =============
(export '(lvg generate-gil-code *interested-in-converting-code*))

(defvar *gil-version-for-file* "GIL-2")
(defvar *top-window* nil)
(defvar *panel* nil)
(defvar *menu-list* nil)
(defvar *interested-in-converting-code* nil)
(defparameter *window-names* nil)
#|
========================================================================
Notes for glv - A translator from GIL to LispView
========================================================================
This version will handle the new GIL-2 format of Devguide 1.1

The following facilities are available in Devguide but not in LispView:
using any of these will generate warnings:
      events for buttons, sliders, gauges, messages, text-fields, settings,
             scrolling lists.
      menus other than command menus
      scrolling list menus
      help text
      keyboard-left keyboard-right keyboard-top events

Notes:
      Notify Handlers translate to :command for buttons and :update-value
          for other items.
      User data is supported - for example, in a button item in Devguide
          using your favorite text editor, you could type
          :user-data   (:class my-button :default-initargs (:label "foo"))
          This will generate a make-instance for my-button instead.
          Devguide does not parse nested ()s so you need to "backslash"
          these if you want to read the file back into Devguide.


The user interface part of this code is at the end of this file.
It was generated with this program using glv.G. The resulting glv.ui.lisp
file was inserted at the end of this file. Loading glv.G back into
Devguide requires some edits to the appropriate :user-data fields:
glv-directory, and glv-version.

Devguide always produces a complete list of attributes - this
program may make assumptions that these attributes are present.

========================================================================
Notes for lvg - A translator from LispView to GIL
========================================================================
Moving from Lisp back to Devguide requires that you identify a
list of windows (Base Windows and Popup Windows).  These windows
and their children will be converted back to a GIL format file.

Problems:
There are 2 kinds of UI applications in LispView, one written entirely by
hand, and the other, the result of some Devguide translation.  This program
attempts to convert generic LispView applications back to GIL format and
does not assume a containing class for the application.  The Devguide
translator (glv) allocates a container class from the filename and slotnames
from the Devguide "name" field.  If your application was written by hand,
you don't have a container class and thus no names.  Therefore lvg must 
"invent" names when going back to GIL.

If you have attached an icon to a base-window or to any other object,
I don't know how to find out the filename of this icon (required by Devguide)
result: you loose your icon (or must re-attach manually in Devguide).

Notes:
Footer for base-window is always visually present in the Devguide editor.

The user interface part of this code is at the end of this file.
It was generated with this program using lvg.G. The resulting lvg.ui.lisp
file was inserted at the end of this file. Loading lvg.G back into
Devguide requires some edits to the appropriate :user-data fields:
lvg-directory, and lvg-window-list.

|#

;;; ========================================================================
;;; icon arrays for GLV and LVG
;;; ========================================================================

(defvar *glv-data*
#2A(#*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000111111111000000000000000000000010000 #*0000000000000000000000000000100000001100000000000000000000100000 #*0000000000000000000000000000100000101010000000000000000001010000 #*0000000001110000000000000000100000101001000000000000000010100000 #*0000111100011111111111100000100000101000100000000000000101010000 #*0000000001111100000000000000100000101111110000000000001010100000 #*0000111100000111111111100000100000100000010000000000010101010000 #*0000000000001110000000000000101111111110010000000000101010100000 #*0000111111100011111111100000101000001110010000000001010101010000 #*0000000000000111000000000000101000011110010000000010101010100000 #*0000111111100001111111100000100111111100010000000101010101010000 #*0000000000001111100000000000100010011000010000001010101010100000 #*0000111111000000111111100000100010011000010000010101010101010000 #*0000000000011101110000000000100011111000010000101010101010100000 #*0000111110000100011111100000100100011100010001111111111101010000 #*0000000000111100111000000000100011111000010010100000001110100000 #*0000111100001110001111100000100000000000010101100000001011010000 #*0000000001111000011100000000111111111111111010100111001001100000 #*0000111000011111000001100000000000000000010101101111101000110000 #*0000000011110000000011000000000000000000101010100111101111110000 #*0000110000111111100111100000000000000001010101100000110000010000 #*0000000000000000000000000000000000000010101010100000110000010000 #*0000000000000000000000000000000000000101010101100001111000010000 #*0000000000000000000000000000000000001010101010100001111000010000 #*0000000000000000000000000000000000010101010101100011111000010000 #*0000000000000000000000000000000000101010101010100011101100010000 #*0000000000000000000000000000000001010101010101100111001100010000 #*0000000000000000000000000000000010101010101010100111001100010000 #*0000000000000000000000000000000101010101010101101110000111010000 #*0000000000000000000000000000001010101010101010101110000110010000 #*0000000000000000000000000000010101010101010101100000000000010000 #*0000000000000000000000000000101010101010101010111111111111110000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000))

(defvar *glv-mask-data*
#2A(#*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000111111111000000000000000000000010000 #*0000000000000000000000000000111111111100000000000000000000100000 #*0000000000000000000000000000110101111010000000000000000001010000 #*0000000001110000000000000000111010101101000000000000000010100000 #*0000111100011111111111100000110101111110100000000000000101010000 #*0000000011111100000000000000111010101111110000000000001010100000 #*0000111101100111111111100000110101110101010000000000010101010000 #*0000000000011110000000000000111111111110110000000000101010100000 #*0000111111110011111111100000111111111111010000000001010101010000 #*0000000000001111000000000000111111111110110000000010101010100000 #*0000111111110001111111100000110111111101010000000101010101010000 #*0000000000011111100000000000111011111010110000001010101010100000 #*0000111111100000111111100000110111111101010000010101010101010000 #*0000000000111111110000000000111011111010110000101010101010100000 #*0000111111000110011111100000110111111101010001111111111101010000 #*0000000001111101111000000000111011111010110010111111111110100000 #*0000111110001111001111100000110101010101010101111111111011010000 #*0000000011111000111100000000111111111111111010111111111101100000 #*0000111100011111100001100000000000000000010101111111111110110000 #*0000000111110000010011000000000000000000101010111111101111110000 #*0000111000111111110111100000000000000001010101111111111100010000 #*0000000000000000000000000000000000000010101010111111110111110000 #*0000000000000000000000000000000000000101010101111111111111110000 #*0000000000000000000000000000000000001010101010111111111011110000 #*0000000000000000000000000000000000010101010101111111111011110000 #*0000000000000000000000000000000000101010101010111111101111110000 #*0000000000000000000000000000000001010101010101111111001101110000 #*0000000000000000000000000000000010101010101010111111011101110000 #*0000000000000000000000000000000101010101010101111110011111110000 #*0000000000000000000000000000001010101010101010111110111110010000 #*0000000000000000000000000000010101010101010101111000111100110000 #*0000000000000000000000000000101010101010101010111111111111110000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000))

(defvar *lvg-data*
#2A(#*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000101010101010101010111111111010100000 #*0000000000000000000000000000010101010101010101100000001101010000 #*0000000000000000000000000000001010101010101010100000101010100000 #*0000000001110000000000000000000101010101010101100000101001010000 #*0000111100011111111111100000000010101010101010100000101000100000 #*0000000001111100000000000000000001010101010101100000101111110000 #*0000111100000111111111100000000000101010101010100000100000010000 #*0000000000001110000000000000000000010101010101101111111110010000 #*0000111111100011111111100000001110001010101010101000001110010000 #*0000000000000111000000000000011111100101010101101000011110010000 #*0000111111100001111111100000011111110010101010100111111100010000 #*0000000000001111100000000000001111110001010101100010011000010000 #*0000111111000000111111100000000001111000101010100010011000010000 #*0000000000011101110000000000000000011000010101100011111000010000 #*0000111110000100011111100000000000011100001010100100011100010000 #*0000000000111100111000000000000000001100000101100011111000010000 #*0000111100001110001111100000000000011100000010100000000000010000 #*0000000001111000011100000000000000011110000001111111111111110000 #*0000111000011111000001100000000000111110000000101010101010100000 #*0000000011110000000011000000000000111110000000010101010101010000 #*0000110000111111100111100000000001111111000000001010101010100000 #*0000000000000000000000000000000001110011000000000101010101010000 #*0000000000000000000000000000000011110011000000000010101010100000 #*0000000000000000000000000000000011100011100000000001010101010000 #*0000000000000000000000000000000111100001100000000000101010100000 #*0000000000000000000000000000000111000001100000000000010101010000 #*0000000000000000000000000000001111000001110000000000001010100000 #*0000000000000000000000000000001110000001110000000000000101010000 #*0000000000000000000000000000011110000000111000000000000010100000 #*0000000000000000000000000000011100000000111110000000000001010000 #*0000000000000000000000000000111100000000111100000000000000100000 #*0000000000000000000000000000000000000000010000000000000000010000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000))

(defvar *lvg-mask-data*
#2A(#*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000101010101010101010111111111010100000 #*0000000000000000000000000000010101010101010101111111111101010000 #*0000000000000000000000000000001010101010101010111111111010100000 #*0000000001110000000000000000000101010101010101111111101101010000 #*0000111100011111111111100000000010101010101010111111101110100000 #*0000000011111100000000000000000001010101010101111111101111110000 #*0000111101100111111111100000000000101010101010111111101111110000 #*0000000000011110000000000000000000010101010101111111111111110000 #*0000111111110011111111100000001110001010101010111111111110110000 #*0000000000001111000000000000011111100101010101111111111110110000 #*0000111111110001111111100000011111110010101010111111111100110000 #*0000000000011111100000000000001111110001010101111111111001110000 #*0000111111100000111111100000000001111000101010111111111011110000 #*0000000000111111110000000000000000011000010101111111111011110000 #*0000111111000110011111100000000000011100001010111111111101110000 #*0000000001111101111000000000000000001100000101111111111001110000 #*0000111110001111001111100000000000011100000010111110000011110000 #*0000000011111000111100000000000000011110000001111111111111110000 #*0000111100011111100001100000000000111110000000101010101010100000 #*0000000111110000010011000000000000111110000000010101010101010000 #*0000111000111111110111100000000001111111000000001010101010100000 #*0000000000000000000000000000000001110011000000000101010101010000 #*0000000000000000000000000000000011110011000000000010101010100000 #*0000000000000000000000000000000011100011100000000001010101010000 #*0000000000000000000000000000000111100001100000000000101010100000 #*0000000000000000000000000000000111000001100000000000010101010000 #*0000000000000000000000000000001111000001110000000000001010100000 #*0000000000000000000000000000001110000001110000000000000101010000 #*0000000000000000000000000000011110000000111000000000000010100000 #*0000000000000000000000000000011100000000111110000000000001010000 #*0000000000000000000000000000111100000000111100000000000000100000 #*0000000000000000000000000000000000000000010000000000000000010000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000 #*0000000000000000000000000000000000000000000000000000000000000000))


;;; ========================================================================
;;; common - code shared by both glv and lvg.
;;; ========================================================================

;;; File name support
;;; =================
(defun check-and-add-G-extension (filename)
  (check-type filename string)
  (let ((pos (search ".G" filename)))
    (if (and pos (= (+ 2 pos) (length filename)))
	filename
	(format nil "~A.G" filename))))

(defun check-and-remove-G-extension (filename)
  (check-type filename string)
  (let ((pos (search ".G" filename)))
    (if (and pos (= (+ 2 pos) (length filename)))
	(subseq filename 0 pos)
	filename)))

;;; Footer messages
;;; =================
(defun file-failure (window file msg)
;; try last "msg-length" chars of file name
  (let ((msg-length 52))
    (setf (lv:left-footer window) 
	  (format nil "~A~A" 
		  (subseq file (max 0 (- (length file) msg-length)))
		  msg))))

(defun set-footer (window msg)
  (setf (lv:left-footer window)  msg))


;;; ***********************************************************************
;;; Begin code for glv.
;;; ***********************************************************************

(defun get-application-name (filename)
;; Used to name the container class in the generated ui file
  (setq filename (check-and-remove-G-extension filename))
  (let ((pos (search "/" filename :from-end t)))
    (intern (string-upcase 
	     (if pos
		 (subseq filename (1+ pos) (length filename))
		 filename)))
    ))

(defun read-gil (filename)
  (with-open-file (s (check-and-add-G-extension filename)
		     :direction :input)		     
    (read s)))

(defun setup-menu-owner-data (gil-lst)
;;; This is a first pass to setup the potential owners of menus.
;;; The idea is for objects that have menus (buttons, canvas panel) to
;;; record the menu (name . owner) for later use.
;;; This does not catch menus with pins that are "free floating"
;;; Also, menus without pins, are also ordered by ref even though not
;;; required.
  (setq *menu-owner-list* nil)
  (setq *menu-owner-and-deps-list* nil)
  (let (menu current-object-owner)
    (mapc #'(lambda(gil-obj)
	      (let ((obj-type (cadr gil-obj))
		    (obj-name (cadddr gil-obj)))
		; menus can only ne owned by base-windows
		(if (eq :base-window obj-type)
		    (setq current-object-owner obj-name) 
		    (when (and (member obj-type 
				       '(:button :control-area :canvas-pane))
			       (setq menu (getf gil-obj :menu)))
		      ; record owners for pinned menus and their dependants
		      (push (cons menu current-object-owner) *menu-owner-list*)
		      (mapc #'(lambda(m)
				(when (getf (find m gil-lst :key 'cadddr)
					    :pinnable)
				  (push (cons m current-object-owner) 
					*menu-owner-and-deps-list*)))
			    (all-deps menu gil-lst))
		      ))))
	  gil-lst))
  nil)

(defun top-level-window-first (gil-lst)
;;; find the first base-window
;;; failing that, the first popup-window - and place at the start
  (if (or (eq :base-window (cadr (car gil-lst)))
	  (eq :popup-window (cadr (car gil-lst))))
      gil-lst
      (let (temp)
	(setq temp (find :base-window gil-lst :key 'cadr))
	(unless temp
	  (setq temp (find :popup-window gil-lst :key 'cadr)))
	(if temp
	    (cons temp (remove temp gil-lst))
	    (format t ";;; Failed to find a BASE or POPUP window"))
	)))

(defun convert-gil-file (filename)
;;; Returns a list of LispView attributes converted from the Devguide file
;;; The contents of *list-of-user-functions*, *code-gen-list* 
;;; and *last-code-in-initialize-instance* do not
;;; affect the result returned by this function.  They are used as hints for
;;; the translator section of this utility.
  (setq *list-of-user-functions* nil)
  (setq *code-gen-list* nil)
  (setq *ui-file-forms* nil)
  (setq *my-path-to-icon-set* nil)
  (setq *last-code-in-initialize-instance* nil)
  (setq *version-skew-warning-displayed* nil)
;;; only want the application name - no dirs and no .G
  (setq *application-class-name* (get-application-name filename))
;;; want to end up with a leading top-level window, followed by an
;;; ordered list of the menus/objects that are in order of reference/owner
   (remove :unsupported
	   (mapcar #'(lambda (gil-object) 
			   (cons (getf gil-object :name)
				 (apply 'convert 
					 (getf gil-object :type) 
					 (cddr gil-object))))
		       (top-level-window-first
			(reorder-gil-names 
			(let ((input-list (read-gil filename)))
			  (setup-menu-owner-data input-list)
			  input-list)
			)))
	   :key 'cadr))

;; Warning, ordering the GIL items is non trivial.
;; Current algorithm: extract menus from the rest of the UI, since
;; Devguide lumps them in arbitrary order at the head of the GIL file.
;; {Order the menus by dependency: [a (nil)] < [b (a)] < [c (b)]}
;; Find which menus have owners, and insert each menu (+ dependants)
;; after the owner in the remaining list.

(defun direct-deps (name gil-lst)
  (remove nil (getf (find name gil-lst :key 'cadddr) 
		    :menu-item-menus)))

(defun all-deps (lst gil-lst)
  (cond ((null lst) nil)
	((atom lst)
	 (let ((dd (direct-deps lst gil-lst)))
	   (if (null dd)
	       (list lst)
	       (cons lst (all-deps dd gil-lst)))))
	(t (append (all-deps (car lst) gil-lst) (all-deps (cdr lst) gil-lst)))
	))

(defun reorder-gil-names (gil-lst)
;;; order the leading menus by reference.
;;; ensure menus are tweaked into the list since some menus require owners.
  (let* ((rest (member :menu gil-lst :test-not 'eq :key 'cadr))
	 (unsorted-menus (ldiff gil-lst rest)))
    (setq *menu-owner-window-name* (getf (car rest) :name))
    (mapcar 
     #'(lambda (pair)
;;; move menus and their dependants
	 (mapcar #'(lambda(menu-name)
		     (let ((m (find menu-name unsorted-menus :key 'cadddr))
			   p p-from-end post-lst)
		       (when m
			 (setq p (position (cdr pair) rest :key 'cadddr))
			 (when p
			   (setq p-from-end (- (length rest) (1+ p)))
			   (setq post-lst (nthcdr (1+ p) rest))
			   (nbutlast rest p-from-end) ; kill the tail
			   (setq unsorted-menus (delete m unsorted-menus))
			   (nconc rest (list m) post-lst)
			   )))
		     )
		 (all-deps (car pair) unsorted-menus))
		)
	    *menu-owner-list*)
    (append (sort-gil-names unsorted-menus nil) rest)))

;;; This sort function is only required for "floating menus" (without owners)
(defun sort-gil-names (unsorted sorted)
  (if (null unsorted)
      (reverse sorted)
      (sort-gil-names (mapcan #'(lambda(x)
				   (if (menu-ref-in x sorted)
				       (progn (push x sorted)
					      nil)
				       (list x)))
			       unsorted)   
	   sorted)))

(defun menu-ref-in (menu menu-lst)
  (let ((menu-wants (remove nil (getf menu :menu-item-menus)))
	(menus-available (mapcar #'(lambda(m)(getf m :name)) menu-lst)))
    (every #'(lambda(name)
	       (member name menus-available))
	   menu-wants)
    ))

;;; ==========================================
;;; The following called by convert
;;; ==========================================


(defun get-label (label type)
  (if (eq type :string)
      label
      `(make-instance 'lv:image :filename ,label)))

(defun convert-type (lv-class user-data)
;;; check :user-data slot for user class override
  (list 'quote
	(if (member :class user-data)
	    (getf user-data :class)
	    lv-class)))

(defun version-warning ()
  (unless *version-skew-warning-displayed*
    (warn "The \".G\" file you are attempting to convert appears to ~
    ~%have been created with an older version of Devguide.~%You may want to ~
    \"Load\" and \"Save\" the file using~%the latest version of Devguide.")
    (setq *version-skew-warning-displayed* t)))

(defun debug-advice (msg filename owner)
  (lv:notice-prompt :message (format nil 
   "~A~%If you would like to investigate this error~%in more detail, ~
   type:~%(guide:generate-lv-code ~S)~%in the Lisp Listener." msg filename)
		      :choices '((:yes "Continue"))
		      :owner owner :x 114 :y 36))

(defun debug-advice-for-eval (msg try-this owner)
  (lv:notice-prompt :message (format nil 
   "~A~%If you would like to investigate this error~%in more detail, ~
   type:~%~A~%in the Lisp Listener." msg try-this)
		      :choices '((:yes "Continue"))
		      :owner owner :x 255 :y 28))

(defun user-default-initargs (data)
  (getf data :default-initargs))

(defun convert-color (attribute color)
  (when (and color (string/= "" color))
    `(,attribute (lv:find-color :name
		   ,(intern (string-upcase (delete " " color :test 'string=))
			    'keyword)))))

(defun convert-footer (show-footer)
;; this code is run by base and popup windows only
  (when show-footer
    (list :left-footer "" :right-footer "")))

(defun convert-string (str)
  (read-from-string str))

(defun convert-proc (string-or-proc-name) 
;;; Contains side effect on *list-of-user-functions*
;;; Devguide provides a string for inline code
  (when string-or-proc-name
    (if (stringp string-or-proc-name)
	(let ((str (convert-string string-or-proc-name)))
	  (if (eq 'function (car str))
	      str
	      `#'(lambda() ,str)))
	(progn
	  (pushnew string-or-proc-name *list-of-user-functions*)
	  (list 'quote string-or-proc-name)))))


(defun convert-popup-menu (menu name)
  (when menu
    `(:interests (list ,(list-popup-menu menu name)))))

(defun list-popup-menu (menu name)
;; returns value and has side-effect
;; this code is run by canvases and panels only
  (when menu
    (let ((event-name 
	   (intern (string-upcase 
		    (format nil "~A-popup-~A-menu" 
			    *application-class-name* name)))))
      (push `(defmethod lv:receive-event (,(intern "WINDOW") 
					    (,(intern "I") ,event-name) 
					    ,(intern "EVENT"))
	       (lv:menu-show (slot-value ,(intern "I") ',(intern "MENU"))
			       ,(intern "WINDOW")
			       :x (lv:mouse-event-x ,(intern "EVENT")) 
			       :y (lv:mouse-event-y ,(intern "EVENT"))))
	    *code-gen-list*)
      (push `(defclass ,event-name (lv:mouse-interest) ((,(intern "MENU")
							 :initarg :menu))
	       (:default-initargs :event-spec '(() (:right :down))))
	    *code-gen-list*)
      `(make-instance ',event-name :menu ,menu)
      )))

(defun list-damage-event (repaint-proc name)
;; returns value and has side-effect
;; this code is run by canvases and panels only
  (when repaint-proc
    (let ((event-name 
	   (intern (string-upcase 
		    (format nil "~A-~A-damage" 
			    *application-class-name* name)))))
      (push `(defmethod lv:receive-event (,(intern "WINDOW") 
					    (,(intern "I") ,event-name) 
					    ,(intern "EVENT"))
	       ,(if (stringp repaint-proc)
		    (convert-string repaint-proc)
		    (progn 
		      (push `(defun ,repaint-proc 
			       (,(intern "VIEWPORT") &rest 
				,(intern "DAMAGED-REGIONS"))
			       (print ',repaint-proc))
			    *code-gen-list*)
		      `(,repaint-proc ,(intern "WINDOW") (lv:damage-event-regions ,(intern "EVENT"))))
		      ))
	    *code-gen-list*)
      (push `(defclass ,event-name (lv:damage-interest) ()) *code-gen-list*)
      `(make-instance ',event-name)
      )))

(defun canvas-interest-list-etc (menu events event-handler name repaint-proc)
  (let ((m (list-popup-menu menu name))
	(e (list-events events event-handler name))
	(d (list-damage-event repaint-proc name)))
;;; the order here allows the menu event preference over the button event
;;; just happens to be the order the events are matched.
    (when (or m e d)
      `(:interests (list ,@e ,@(when m (list m)) ,@(when d (list d)))))))
	
(defun convert-events-and-menus (menu events event-handler name)
  (let ((m (list-popup-menu menu name))
	(e (list-events events event-handler name)))
    (cond ((and m e)
;;; the order here allows the menu event preference over the button event
;;; just happens to be the order the events are matched.
	   `(:interests (list ,@e ,m)))
	  (e
	   `(:interests (list ,@e)))
	  (m
	   `(:interests (list ,m))))
    ))

;;; if you want to do something interesting with keyboard events 
;;; in your application, use:
#+ignore (defmethod lv:receive-event (canvas (i app-keyboard-event) event)
           (let ((char (lv:keyboard-event-char event)))
             (print char)))

(defun do-all-events (gil-events event-handler name)
;; added :keyboard to the list of unsupported items since LispView has a
;; more sophisticated input model than that provided by Devguide
  (let ((supported-events 
	 (mapcan #'(lambda(gil-event)
		     (if (member gil-event 
				 '(:keyboard :keyboard-left :keyboard-right 
					     :keyboard-top))
			 (warn "~A event is not currently translated." 
			       gil-event)
			 (list gil-event))
		     )
		 gil-events))
	event-function)
    (when supported-events
;;; Create a function name to be called when the event occurs.
      (setq event-function 
	    (if event-handler
		(if (stringp event-handler)
		    (convert-string event-handler);; may change
		    (progn
		      (pushnew event-handler *list-of-user-functions*)
		      (list event-handler)))
		`(format t "Event in ~A - no handler specified~%" ',name)))
      (mapcar #'(lambda(gil-event)
		  (do-one-event gil-event name event-function))
	      supported-events))
    ))

(defun list-events (events event-handler name)
;;; events supported by Devguide:
;;; :keyboard :keyboard-left :keyboard-right :keyboard-top :mouse
;;; :mouse-enter :mouse-exit :mouse-drag :mouse-move 
;;; Translator/LispView currently can't handle: :keyboard<xxx> events
  (mapcar #'(lambda(event-name)
	      `(make-instance ',event-name))		   
	  (do-all-events events event-handler name)))

(defun convert-events (events event-handler name)
;;; Returns a value and has side-effect
;;; This code is run by base-windows and popups only
  (let ((lst (list-events events event-handler name)))
    (when lst
      `(:interests (list ,@lst)))
    ))

(defun do-one-event (gil-event name event-function)
;;; Create a class name from the name of the object in which the event occurs
;;; concatenated with "-type-event".
  (let ((event-name (intern (string-upcase (format nil "~A-~A-event" 
						   name (string gil-event))))))
    (push `(defmethod lv:receive-event (,(intern "WINDOW") 
					  (,(intern "I") ,event-name) 
					  ,(intern "EVENT"))
	     (,@event-function))
	  *code-gen-list*)
    (if (eq :keyboard gil-event)
	(push `(defclass ,event-name (lv:keyboard-interest) ())
	      *code-gen-list*)
	(push `(defclass ,event-name (lv:mouse-interest) ()
		 (:default-initargs 
		  :event-spec (quote ,(convert-to-event-spec
				       gil-event))))
	      *code-gen-list*))
    event-name
    ))

;;; A reasonable interpretation of generic mouse events in my mind is
;;; Left or Middle button going Down - Alternatively, I could have done all
;;; e.g. (or :left :middle :right) (or :up :down)
(defun convert-to-event-spec (gil-event)
  (case gil-event
    (:mouse '(() ((or :left :middle)
		  :down)) )
    (:mouse-enter '(() :enter) )
    (:mouse-exit '(() :exit) )
    (:mouse-drag '((:left) :move) )
    (:mouse-move '(() :move) )
  ))

;;; ==================
;;; convert
;;; ==================

;;; input: a list of attribute value pairs e.g. (:x 1 :y 2 ...)
;;; output: a list with LispView type and LispView attribute value pairs
;;; e.g ('lv:base-window :a 1 :b 2 ...)
;;; GIL types are converted to LispView types by first
;;; converting the type then any specific attributes for that item
;;; followed by generic attributes, applicable to more than one item.


	  
;;; ==================
;;; groups (ignore)
;;; ==================

(defmethod convert ((type (eql :group)) &rest args
		    )
  '(:unsupported))

;;; ==================
;;; base windows
;;; ==================

(defmethod convert ((type (eql :base-window)) &rest args
		    &key user-data  events event-handler name
		    mapped icon-file icon-mask-file 
		    show-footer resizable 
		    &allow-other-keys)

  (unless icon-mask-file
    (version-warning))

; allows finer control over mapping (see code generator for use.)
  (push `(setf (lv:mapped ,name) t) *last-code-in-initialize-instance*)

  `(,(convert-type 'lv:base-window user-data)
    ,@(user-default-initargs user-data)
    :mapped nil  ; guide has no control over this attribute we set it to t
		 ; later when all the other objects are created
    :closed ,(not mapped) ;; Devguide unfortunately mixes the terminology
                          ;; because of the way XView behaves
    :show-resize-corners ,resizable
    ,@(convert-footer show-footer)
    ,@(when (and (string/= "" icon-file) (string/= " " icon-file))
      (list :icon 
	 `(make-instance 'lv:icon
       ,@(when (and icon-mask-file (string/= "" icon-mask-file))
	       (list :clip-mask
		     (if (and (search "/" icon-mask-file)
			      (zerop (search "/" icon-mask-file)))
			 `(if (probe-file ,icon-mask-file)
			      (make-instance 'lv:image
						   :filename ,icon-mask-file)
			      (progn 
				(warn "Icon Mask File: ~A not found.~%" 
				      ,icon-mask-file)
				nil))
			 (progn
			   (unless *my-path-to-icon-set*
			     (push `(setq ,(intern "*MY-PATH-TO-ICON*") 
					  lcl:*load-pathname*)
				   *ui-file-forms*)
			     (push `(defvar ,(intern "*MY-PATH-TO-ICON*"))
				   *ui-file-forms*)
			     (setq *my-path-to-icon-set* t))
			   `(let ((,(intern "F") 
				   (merge-pathnames ,icon-mask-file
						    (make-pathname :directory 
								   (pathname-directory
								    ,(intern 
								      "*MY-PATH-TO-ICON*"))))))
			      (if (probe-file ,(intern "F"))
				  (make-instance 'lv:image
						       :filename ,(intern "F"))
				  (progn 
				(warn "Icon Mask File: ~A not found.~%" 
				      ,icon-mask-file)
				nil)))))))
       :label 
       ,(if (and (search "/" icon-file)
		 (zerop (search "/" icon-file)))
	    `(if (probe-file ,icon-file)
		 (list (make-instance 'lv:image
				      :filename ,icon-file)
		       ,(prin1-to-string 
			 *application-class-name*))
		 ,(prin1-to-string *application-class-name*))
	    (progn
	      (unless *my-path-to-icon-set*
		(push `(setq ,(intern "*MY-PATH-TO-ICON*") 
			     lcl:*load-pathname*)
		      *ui-file-forms*)
		(push `(defvar ,(intern "*MY-PATH-TO-ICON*"))
		      *ui-file-forms*)
		(setq *my-path-to-icon-set* t))
	      `(let ((,(intern "F") 
		      (merge-pathnames ,icon-file
				       (make-pathname :directory 
						      (pathname-directory
						       ,(intern 
							 "*MY-PATH-TO-ICON*"))))))
		 (if (probe-file ,(intern "F"))
		     (list (make-instance 'lv:image
					  :filename ,(intern "F"))
			   ,(prin1-to-string 
			     *application-class-name*))
		     ,(prin1-to-string 
		       *application-class-name*)))))
			 )))
    ,@(convert-events events event-handler name)
    ,@(apply 'convert (cons :generic args))
    ))

;;; ==================
;;; popup windows
;;; ==================

(defmethod convert ((type (eql :popup-window)) &rest args
		    &key user-data events event-handler done-handler name
		    show-footer resizable pinned mapped owner
		    &allow-other-keys)

  (when mapped  ;; if the user wants mapped, setf mapped only after creation.
    (push `(setf (lv:mapped ,name) t) *last-code-in-initialize-instance*))

  (when done-handler
    (push `(defmethod (setf lv:mapped) :after 
	     ((,(intern "MAP") (eql nil)) (,(intern "WINDOW") (eql ,name)))
	     ,(if (stringp done-handler)
		  (read-from-string done-handler)
		  (progn
		    (pushnew done-handler *list-of-user-functions*)
		    (list done-handler)
		    )))
	  *last-code-in-initialize-instance*))

  `(,(convert-type 'lv:popup-window user-data)
    ,@(user-default-initargs user-data)
    ,@(convert-footer show-footer)
    :mapped nil   ;; here the guide "mapped" terminology is used correctly
    :show-resize-corners ,resizable
    :pushpin ,(if pinned :in :out)
    ,@(convert-events events event-handler name)
    :owner ,owner
    ;; :owner is used later to indicate "parent", so it must be removed
    ,@(apply 'convert (cons :generic (progn (remf args :owner) args)))
    ))

;;; ==================
;;; panels
;;; ==================

;; mapped was forced previously
(defmethod convert ((type (eql :control-area)) &rest args
		    &key user-data events event-handler name
		    show-border menu
		    &allow-other-keys)

  `(,(convert-type 'lv:panel user-data)
    ,@(user-default-initargs user-data)
    ,@(when show-border
	(list :border-width 1))
    ,@(convert-events-and-menus menu events event-handler name)
;;;    ,@(convert-events events event-handler name)
;;;    ,@(convert-popup-menu menu name)
    ,@(apply 'convert (cons :generic args))
    ))

;;; ==================
;;; canvases
;;; ==================

(defmethod convert ((type (eql :canvas-pane)) &rest args
		    &key user-data events event-handler name
		    x y width height
		    horizontal-scrollbar vertical-scrollbar
		    repaint-proc menu
		    &allow-other-keys)

;;; since we set :border-width 1 (because XView does) in windows, we need to
;;; adjust the width and height--XView uses outer dim. LispView, inner dim.

  `(,(if (or horizontal-scrollbar vertical-scrollbar)
	 (convert-type 'lv:viewport user-data)
	 (progn (decf width) (decf height)
		(convert-type 'lv:window user-data)))
    ,@(user-default-initargs user-data)
    ,@(if (or horizontal-scrollbar vertical-scrollbar)
	  `(:container-region (lv:make-region 
			       ; LispView off by one?
			       :width ,width 
			       :height ,height 
			       :top ,y :left ,(prog1 x ; (remf args :x)
						       ; (remf args :y)
						       (remf args :width)
						       (remf args :height)))
	    ,@(if (and horizontal-scrollbar vertical-scrollbar)
;;; 800 is arbitrary
	      `(:output-region (list :width 800 :height 800) 
		:horizontal-scrollbar
		(make-instance 'lv:horizontal-scrollbar)
		:vertical-scrollbar
		(make-instance 'lv:vertical-scrollbar))
	      (if horizontal-scrollbar
		  `(:output-region (list :width 800)
		    :horizontal-scrollbar
		    (make-instance 'lv:horizontal-scrollbar))
		  `(:output-region (list :height 800)
		    :vertical-scrollbar
		    (make-instance 'lv:vertical-scrollbar))
		)))
	) ;;  border is user convenience for windows only -- same as gxv.
;    `(:border-width 1)
    :border-width 1
    ,@(canvas-interest-list-etc menu events event-handler name repaint-proc)
;    ,@(convert-events-and-menus menu events event-handler name)
    ,@(apply 'convert (cons :generic args))
    ))

#+ignore(list :repaint
		      (if (stringp repaint-proc)
			  `#'(lambda(,(intern "VIEWPORT") &rest 
				     ,(intern "DAMAGED-REGIONS")) 
			       ,(convert-string repaint-proc))
			  (progn 
			    (push `(defun ,repaint-proc 
				     (,(intern "VIEWPORT") &rest 
				      ,(intern "DAMAGED-REGIONS"))
				     (print ',repaint-proc))
				  *code-gen-list*)
			    (list 'quote repaint-proc)
			    )))

;;; ==================
;;; text subwindows
;;; ==================

(defmethod convert ((type (eql :text-pane)) &rest args
		    &key user-data events
		    show-border read-only
		    &allow-other-keys)

  (unless (find-class 'lv::textedit-window nil)
    (warn ";;; You must load the textedit utility from util/textedit/~%"))

  (when events
    (warn "events are not available for ~A in LispView." 
	  "textedit-window"))

  `(,(convert-type 'lv::textedit-window user-data)  ;; really use internal
						    ;; symbol? LispView
    ,@(user-default-initargs user-data)
    ,@(when read-only
	(list :read-only t))
    ,@(when show-border
	(list :border-width 1))
    ,@(apply 'convert (cons :generic args))
    ))

;;;  (warn "Text Panes are not supported by LispView.")
;;;  '(:unsupported))

;;; ==================
;;; term subwindows
;;; ==================

(defmethod convert ((type (eql :term-pane)) &rest args
		    &key user-data events
		    show-border
		    &allow-other-keys)

  (unless (find-class 'lv::tty-window nil)
    (warn ";;; You must load the tty utility from util/tty/~%"))

  (when events
    (warn "events are not available for ~A in LispView." 
	  "tty-window"))

  `(,(convert-type 'lv::tty-window user-data)  ;; really use internal
					       ;; symbol? LispView
    ,@(user-default-initargs user-data)
    ,@(when show-border
	(list :border-width 1))
    ,@(apply 'convert (cons :generic args))
    ))

;;;  (declare (ignore args user-data))
;;;  (warn "Terminal Panes are not supported by LispView.")
;;;  '(:unsupported))

;;; ==================
;;; menus
;;; ==================

;;; the global vars *menu-owner-and-deps-list* and 
;;; *menu-owner-window-name* are referenced here.
;;; *menu-owner-and-deps-list* contains the list of (menu . owner) for the 
;;; objetcs menu-buttons, panels and canvases
;;; *menu-owner-window-name* is used for "floating menus": (without owner)
;;; Note: this control is only required for pinned menus.

(defmethod convert ((type (eql :menu)) &rest args
		    &key user-data name
		    menu-title columns pinnable
		    menu-type menu-handler
		    menu-item-defaults
		    menu-item-labels menu-item-label-types
		    menu-item-handlers menu-item-menus menu-item-colors
		    &allow-other-keys)

  (when (some #'(lambda(c)(not (string= c ""))) menu-item-colors)
    (warn "Individual colors for menu items are not available in LispView."))

  (unless (eq :command menu-type)
    (warn "Menu Type: ~A is not supported by LispView, using type :command."
	  menu-type))
  (when menu-handler
    (warn "Menu Handler is not supported by LispView."))

  `(,(convert-type 'lv:menu user-data)
    ,@(user-default-initargs user-data)
    ,@(when (member t menu-item-defaults)
	    (list :default (position t menu-item-defaults)))
    :choices 
      (list ,@(mapcar #'(lambda(l type h m) 
		 (if m
		     `(make-instance 'lv:submenu-item
				     :label ,(get-label l type)
				     :menu ,m)
		     `(make-instance 'lv:command-menu-item
				     ;;; If A Blank Label, user never
				     ;;; intends to select item	     
				     ,@(let ((lbl (get-label l type)))
					(if (and (stringp lbl)
						 (string= lbl ""))
					    (list :mapped nil)
					    (list :label lbl)))
				     :command ,(convert-proc h))))
	     menu-item-labels
	     menu-item-label-types
	     menu-item-handlers
	     menu-item-menus))

;;; GIL provides a label and a menu-title, the label is never used
;;; by Devguide or us - unless some deal with an image label comes into play. 
;;; Watch for null label, if so drop the title from the menu

    ,@(when (and menu-title (string/= "" menu-title))
	(list :label menu-title))
    :choices-ncols ,columns
    :pushpin ,pinnable
    ,@(when pinnable  
	(list :owner (or (cdr (assoc name *menu-owner-and-deps-list*))
			 *menu-owner-window-name*)))
;;; :label is a generic attribute, so remove it here
    ,@(apply 'convert (cons :generic (progn (remf args :label) args)))
  ))


;;; ==================
;;; buttons
;;; ==================
      
(defmethod convert ((type (eql :button)) &rest args
		    &key user-data events
		    menu constant-width width
		    notify-handler button-type
		    &allow-other-keys)

  (when events
    (warn "events are not available for ~A in LispView." 
	  :button))

  (unless (eq :normal button-type)
    (if (null button-type)
	(version-warning)
	(warn "Abbreviated buttons are not available in LispView--try a setting.")))

  `(,(if menu
	     (convert-type 'lv:menu-button user-data)
	     (convert-type 'lv:command-button user-data))
    ,@(user-default-initargs user-data)
    ,@(when menu
	(list :menu menu))
    ,@(when constant-width
	(list :label-width width))
    ,@(when notify-handler
	(remf args :notify-handler) ;; notify-handler is used in generic conv.
	(list :command (convert-proc notify-handler)))
    ,@(apply 'convert (cons :generic args))
    ))



;;; ==================
;;; sliders
;;; ==================

(defmethod convert ((type (eql :slider)) &rest args
		    &key user-data events 
		    min-value max-value
		    slider-width show-range show-value
		    show-endboxes
		    (orientation :horizontal) ticks
		    &allow-other-keys)
  (when events
    (warn "events are not available for ~A in LispView." 
	  :slider))

  `(,(if (eq :horizontal orientation)
	 (convert-type 'lv:horizontal-slider user-data)
	 (convert-type 'lv:vertical-slider user-data))
    ,@(user-default-initargs user-data)
    :min-value ,min-value
    :max-value ,max-value
    :gauge-length ,slider-width
    :show-end-boxes ,show-endboxes
    :show-range ,show-range
    :show-value ,show-value
    ,@(when ticks (list :nticks ticks))
    ,@(apply 'convert (cons :generic args))
    ))

;;; ==================
;;; gauges
;;; ==================

(defmethod convert ((type (eql :gauge)) &rest args
		    &key user-data events 
		    min-value max-value
		    slider-width show-range show-value
		    (orientation :horizontal) ticks
		    &allow-other-keys)
  (when events
    (warn "events are not available for ~A in LispView." 
	  :slider))

  `(,(if (eq :horizontal orientation)
	 (convert-type 'lv:horizontal-gauge user-data)
	 (convert-type 'lv:vertical-gauge user-data))
    ,@(user-default-initargs user-data)
    :min-value ,min-value
    :max-value ,max-value
    :gauge-length ,slider-width
    :show-range ,show-range
    :show-value ,show-value
    ,@(when ticks (list :nticks ticks))
    ,@(apply 'convert (cons :generic args))
    ))

;;; ==================
;;; messages
;;; ==================

(defmethod convert ((type (eql :message)) &rest args
		    &key user-data events
		    label-bold
		    &allow-other-keys)
  (when events
    (warn "events are not available for ~A in LispView." 
	  :message))

  `(,(convert-type 'lv:message user-data)
    ,@(user-default-initargs user-data)
    :label-bold ,label-bold
    ,@(apply 'convert (cons :generic args))
    ))

;;; ==================
;;; text fields
;;; ==================

(defmethod convert ((type (eql :text-field)) &rest args
		    &key user-data events
		    text-type value-length stored-length read-only
		    min-value max-value
		    &allow-other-keys)
  (when events
    (warn "events are not available for ~A in LispView." 
	  :text-field))

  `(,(if (eq :alphanumeric text-type)
	 (convert-type 'lv:text-field user-data)
	 (convert-type 'lv:numeric-field user-data))
    ,@(user-default-initargs user-data)
    :displayed-value-length ,value-length    
    :stored-value-length ,stored-length    
    ,@(when min-value
	(list :min-value min-value :max-value max-value))
    ,@(when read-only
	(list :read-only t))
    ,@(apply 'convert (cons :generic args))
    ))

;;; ==================
;;; settings
;;; ==================

;;; the case for when choices are images is not available in Devguide.

(defmethod convert ((type (eql :setting)) &rest args
		    &key user-data events
		    setting-type rows columns
		    choices choice-label-types choice-colors
		    &allow-other-keys)

  (when (and choices (null choice-label-types))
    (version-warning))
  (when events
    (warn "events are not available for ~A in LispView." 
	  :setting))

  (when (some #'(lambda(c)(not (string= c ""))) choice-colors)
    (warn "Individual colors for choices are not available in LispView."))

  `(,(case setting-type
       (:check (convert-type 'lv:check-box user-data))
       (:exclusive (convert-type 'lv:exclusive-setting user-data))
       (:nonexclusive (convert-type 'lv:non-exclusive-setting user-data))
       (:stack (convert-type 'lv:abbreviated-exclusive-setting user-data))
       (otherwise (warn ":setting-type ~A is not supported" setting-type)))
    ,@(user-default-initargs user-data)
    ,@(when (and rows (> rows 0))
	(list :choices-nrows rows))
    ,@(when (and columns (> columns 0))
	(list :choices-ncols columns))
    ,@(when choices
	`(:choices (list ,@(mapcar #'(lambda(ch typ)
				   (if (eq typ :string)
				       ch
				       (progn
					 (unless (probe-file ch)
					   (warn "cannot find file ~A" ch))
					 `(make-instance 'lv:image 
							 :filename ,ch 
							 ))
				     ))
			       choices choice-label-types))))
    ,@(apply 'convert (cons :generic args))
    ))


;;; ==================
;;; scrolling lists
;;; ==================

;;; the case for when choices are images is not available in Devguide.

(defmethod convert ((type (eql :scrolling-list)) &rest args
		    &key user-data events
		    multiple-selections selection-required read-only
		    rows width menu notify-handler
		    &allow-other-keys)

  (when events
    (warn "events are not available for ~A in LispView." 
	  :scrolling-list))

  (when menu
    (warn ":menu is not currently available for ~A in LispView."
	  :scrolling-list))

  `(,(if multiple-selections
	 (convert-type 'lv:non-exclusive-scrolling-list user-data)
	 (convert-type 'lv:exclusive-scrolling-list user-data)) 
    ,@(user-default-initargs user-data)
    :nchoices-visible ,rows
    :choice-width ,width
    ,@(when read-only
	(list :read-only t))
    ,@(when selection-required
	(if multiple-selections
	    (warn ":selection-required is only available for exclusive~
                    -scrolling-lists")
	    (list :selection-required selection-required)))
    ,@(when notify-handler
	(list :update-value
	      (if (stringp notify-handler)
		  (let ((str (convert-string notify-handler)))
		    (if (eq 'function (car str))
			str
			`#'(lambda(,(intern "VALUE") ,(intern "OPERATION")) 
			     ,str)))
		  (progn 
		    (push `(defun ,notify-handler (,(intern "VALUE") 
						   ,(intern "OPERATION"))
			     (format t "~A value: ~A operation: ~A~%" 
				     ',notify-handler ,(intern "VALUE") 
				     ,(intern "OPERATION")))
			  *code-gen-list*)
		    (list 'quote notify-handler)
		    ))))
	 
    ,@(apply 'convert (cons :generic (progn (remf args :notify-handler) args)))
    ))

;;;==========================
;;; generic 
;;;==========================
;;; The following should probably not appear in arglist below: 
;;;     mapped

(defmethod convert ((type (eql :generic)) 
		    &key x y 
		    width height
		    owner foreground-color background-color
		    notify-handler
		    layout-type label label-type
		    &allow-other-keys)
  `(,@(when x   ;; x,y not present in top level windows and menus
	(list :left x :top y))
    ,@(when width
	(list :width width :height height))
    ,@(when layout-type
	(list :layout layout-type))
    ,@(when label
	(list :label
	      (get-label label label-type)))
    ,@(when owner
	(list :parent owner))
    ,@(convert-color :foreground foreground-color)
    ,@(convert-color :background background-color)
    ,@(when notify-handler
	(list :update-value
	      (if (stringp notify-handler)
		  (let ((str (convert-string notify-handler)))
		    (if (eq 'function (car str))
			str
			`#'(lambda(,(intern "VALUE")) 
			     ,str)))
		  (progn 
		    (push `(defun ,notify-handler (,(intern "VALUE"))
			     (format t "~A value: ~A~%" ',notify-handler
				     ,(intern "VALUE")))
			  *code-gen-list*)
		    (list 'quote notify-handler)
		    ))))

    ))
    
;;; =====================================================================
;;;                        Generate code
;;; =====================================================================

;;; ================
;;; access functions
;;; ================

(defun item-id (lv-item) ;; i.e. window1
  (car lv-item))

(defun item-type (lv-item)  ;; i.e. base-window
  (second (item-type-lst lv-item)))

(defun item-type-lst (lv-item)  ;; i.e. (quote base-window)
  (second lv-item))

(defun item-make-instance (lv-item) ;; (make-instance 'lv:.......)
  (cons 'make-instance (cdr lv-item))) ;; cdr because car is the name

;;; end access fns

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;; Support for glv-pp - an attempt to "pretty print" the generated code.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;; pprint tends to generate too many lines (one for each attribute).
;;; Problems with glv-pp: Makes assumptions about the structure of
;;; the generated code.
;;; A blank line is skiped if the value of an attribue is too long to fit
;;; on that line - the result is a blank line followed by a line that wraps.

;;; Bug: Stream of T is equated here with first FORMAT arg of NIL, which is
;;; not correct.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;; Routines to handle our concept of "fresh line"
;;;
;;; These functions assume that prin1, princ, and format will not leave the
;;; printing position on a "fresh line" when done.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 

;;; Line position or NIL if not on a "fresh" line (no printing characters on
;;; it yet).
(defvar *fresh-line-pos* 0)

(defun to-fresh-line (&optional stream)
  (when (not *fresh-line-pos*)
    (terpri stream)
    (setq *fresh-line-pos* 0)))

(defun spaces (n &optional stream)
  (if *fresh-line-pos*
      (incf *fresh-line-pos* n)
    (format (or stream t) "~@VT" n)))

(defun indent (n)
  (if *fresh-line-pos*
      (setf *fresh-line-pos* n)
    (warn "Indenting in inappropriate context (middle of line)")))

(defun start-print (&optional stream)
  (when *fresh-line-pos*
    (dotimes (i *fresh-line-pos*)
      (princ " " stream))
    (setq *fresh-line-pos* nil)))

(defun glv-prin1 (thing &optional stream)
  (start-print stream)
  (prin1 thing stream))

(defun glv-princ (thing &optional stream)
  (start-print stream)
  (princ thing stream))

(defun glv-format (stream &rest stuff)
  (start-print (if (eq stream t) nil stream))
  (apply #'format stream stuff))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;; The printing routines themselves
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 

(defun print-att-list (lst pos &optional stream)
  (flet ((prin1 (thing &optional stream)
		(glv-prin1 thing stream))
	 (princ (thing &optional stream)
		(glv-princ thing stream))
	 (format (stream &rest stuff)
		 (apply #'glv-format stream stuff)))
    (let (pair-len (current-pos pos)(max-line-len 70))
      (to-fresh-line stream)
      (indent pos)
      (if (consp lst)
	  (loop for att in lst by #'cddr
		and val in (cdr lst) by #'cddr do
		(setq pair-len (+ 1 (length (prin1-to-string att))
				  (length (prin1-to-string val))))
		(when (> (+ pair-len current-pos) max-line-len)
		  (to-fresh-line stream) (setq current-pos pos)
		  (indent current-pos))
		(prin1 att stream)
		(princ " " stream)
		(prin1 val stream)
		(princ " " stream)
		(incf current-pos (1+ pair-len)))
	(prin1 lst stream)))))

(defun glv-pp (lst &optional stream)
  (flet ((prin1 (thing &optional stream)
		(glv-prin1 thing stream))
	 (princ (thing &optional stream)
		(glv-princ thing stream))
	 (format (stream &rest stuff)
		 (apply #'glv-format stream stuff)))
    (let* ((w-slots (car (last lst)))
	   (setf-lst (cadddr w-slots))
	   (rest (cddddr w-slots)))
      (format (or stream t) "(defmethod initialize-instance :after ~S~%   ~
                                (~S ~S~%     ~S~%     (~S"
	      (cadddr lst)
	      (car w-slots) (cadr w-slots) (caddr w-slots) 
	      (car setf-lst))
      (to-fresh-line stream)	
      (loop for name in (cdr setf-lst) by #'cddr and
	    mki-form in (cddr setf-lst) by #'cddr do
	    (spaces 8 stream)
	    (prin1 name stream) (to-fresh-line stream)
	    (spaces 12 stream)
	    (format (or stream t) "(~S '~S" (car mki-form) 
		    (cadadr mki-form))
	    (print-att-list (cddr mki-form) 16 stream)
	    (princ ")" stream) (to-fresh-line stream))		    
      (format (or stream t) "           )") ; setf
      (to-fresh-line stream)
      (mapcar #'(lambda(r)
		  (spaces 5 stream)
		  (prin1 r stream)
		  (to-fresh-line stream))
	      rest)
      (format (or stream t) "    ))") ; with-slots/defmethod
      )))

;;; =============
;;; Generate Code
;;; =============

(defun generate-lv-code (filename &key omit-ui-file omit-stub-file)
  (check-type filename string)
  (let* ((lv-lst (convert-gil-file filename))
	 (gil-filename (check-and-remove-G-extension filename))
	 (ui-filename (format nil "~A.ui.lisp" gil-filename))
	 (stub-filename (format nil "~A.stub.lisp" gil-filename))
	 (*print-case* :downcase) ; temp change to lower case
	 (*print-level* nil)      ; and ensure generated code is loadable
	 (*print-length* nil)
	 (ui-file-header
";;; This file produced by GLV
;;; do not edit by hand unless you are satisfied
;;; with the layout of these objects,
;;; instead, use Devguide to edit ~A.G
"))
    (unwind-protect ;;; I believe this is to preserve global print settings
	(progn
	  (if (not (or (eq (item-type (car lv-lst)) 'lv:base-window)
		       (eq (item-type (car lv-lst)) 'lv:popup-window)))
	      (format t ";;; Observation: The first item in your application~
		         ;;; is not a base-window or a popup-window"))
	  (unless omit-ui-file
		(with-open-file (f ui-filename :direction :output)
		  (format f ui-file-header gil-filename)
		  (print `(in-package ,(package-name *package*)) f)
		  (terpri f)
;;;; Don't do this because the var will not be lexically bound in
;;;; the after method on initialize-instance.  I.e. LIVE WITH THE
;;;; COMPILER WARNING!
;;;		  (print `(defvar ,*application-class-name*) f)
;;;		  (terpri f)
;; this would be a good place to put var declarations.
		  (when *ui-file-forms*
		    (mapcar #'(lambda(form)
				(pprint form f)
				(terpri f))
			    *ui-file-forms*)
		    (terpri f))
		  (if (string= "Slots" *defclass-format*)
		      (let ((lst (generate-lv-class lv-lst)))
			(format f "~%(~S ~S ~:S~%  ~S)"
				(car lst) (cadr lst) (caddr lst) (cadddr
								  lst)))
		      
		      (pprint (generate-lv-class lv-lst) f))
		  (terpri f)
		  (terpri f)
		  (if (string= "pprint" *output-format*)
		      (pprint (generate-lv-init-instance lv-lst) f)
		      (glv-pp (generate-lv-init-instance lv-lst) f))
		  )
		(format t ";;; ~A~%" ui-filename))
	  (unless omit-stub-file
		(with-open-file (f stub-filename :direction :output)
		  (print `(in-package ,(package-name *package*)) f)
		  (terpri f)
		  (terpri f)
		  (mapcar #'(lambda(def)
			      (pprint def f)
			      (terpri f))
			  *code-gen-list*)
		  (generate-function-calls f *list-of-user-functions*)
		  (terpri f)
		  (format f "(format t \"~A\")~%"
			  (generate-lv-make-instance)))
		(format t ";;; ~A~%" stub-filename))
	      ))
      nil))

;;; appears in ..ui.lisp
;;; ====================
;;; class name used to be: ,(item-id (car lv-lst))
(defun generate-lv-class (lv-lst)
  (progn
    `(defclass ,*application-class-name* ()
       ,(if (string= "Slots" *defclass-format*)
	    (current-slot-names lv-lst)
	    (gen-slots lv-lst))
                ;;; (:default-initargs ,@(item-initargs (car lv-lst)))
       )
    ))

(defun generate-lv-init-instance (lv-lst)
  `(defmethod initialize-instance :after ((,*application-class-name*
					    ,*application-class-name*)
					   &rest ,(intern "ARGS"))
     (with-slots ,(current-slot-names lv-lst) ,*application-class-name*
		 (setf 
		  ,@(gen-setfs lv-lst))
		 ,@*last-code-in-initialize-instance*)
     ))


(defun gen-slots (lv-lst)
  (mapcar #'(lambda(x)
	      (list x :accessor x))
	  (current-slot-names lv-lst)))

(defun current-slot-names (lv-lst)
  (mapcar #'(lambda(x) (item-id x)) lv-lst))

(defun gen-setfs (lv-lst)
  (mapcan #'(lambda(x)
	      (list (item-id x)
		    (item-make-instance x)))
	  lv-lst))
  

;;; stub.lisp
;;; =========
(defun generate-function-calls (f userfns)
  (mapcar #'(lambda(fn)
	      (pprint `(defun ,fn () (print ',fn)) f)
	      (terpri f))
	  userfns))

(defun generate-lv-make-instance ()
  `(setq ,*application-class-name*
	   (make-instance ',*application-class-name*
		    )))

;;; support functions
;;; =================
; used to generate eval line text
(defun generate-lv-make-instance-string (filename)
  (let ((name (get-application-name filename)))
    (format nil "(setq ~A (make-instance '~A))"
	    name name)))

(defun set-text-line (container str)
  (let ((obj (slot-value container 'glv-eval-field)))
    (setf (lv:value obj) str)))



;;; These functions referenced from the user interface file
;;; =======================================================

(defparameter *first-invocation-of-glv-props* t)

(defun display-props (container)
  (let ((props-br (lv:bounding-region (slot-value container 'glv-popup)))
	(br (lv:bounding-region (slot-value container 'glv-window))))
    (reset-props container)
;;; want to place this at same loc as parent
    (when *first-invocation-of-glv-props*
      (setf (lv:region-left props-br) (lv:region-left br)
	    (lv:region-top props-br) (lv:region-top br)
	    (lv:bounding-region 
	     (slot-value container 'glv-popup)) props-br
	     *first-invocation-of-glv-props* nil))
    (setf (lv:mapped (slot-value container 'glv-popup)) t)))

(defun reset-props (container)
#+ignore  (setf (lv:value (slot-value container 'glv-version))
	(if (eql *gil-version* 1)
	    "GIL-1"
	    "GIL-2"))
  (setf (lv:value (slot-value container 'glv-output-format))
	*output-format*)
  (setf (lv:value (slot-value container 'glv-defclass-format))
	*defclass-format*)
  )

(defun apply-props (container)
#+ignore  (setq *gil-version*
	(if (string= "GIL-1" (lv:value (slot-value container 'glv-version)))
	    1
	    2))
  (setq *output-format*
	(lv:value (slot-value container 'glv-output-format)))
  (setq *defclass-format*
	(lv:value (slot-value container 'glv-defclass-format)))
  )

(defun convert-to-lisp (glv-dir glv-file glv-win)
  (let* ((d (lv:value glv-dir))
	 (trailing-slash (position "/" d :from-end t :test 'string=))
	 (f (lv:value glv-file))
	 (fullname (if (and trailing-slash (eq (length d) (1+ trailing-slash)))
		       (format nil "~A~A" d f)
		       (if (string= "" d)
			   f
			   (progn
			     ;; probe-file can't handle ~ but can handle ~/
			     (setq d (format nil "~A/" d)) 
			     (format nil "~A~A" d f)))))
	 (ok t)) ; this should be nil if using lcl:ignore-errors
    (set-footer glv-win "Converting...")
    (if (probe-file (check-and-add-G-extension fullname))
;;; new code
	(progn 
	  (catch 'conversion-error-occurred
		 (lucid::handler-bind 
		  ((lucid::serious-condition 
		    #'(lambda (condition)
			(debug-advice
			 (with-output-to-string (*error-output*)
			   (lucid::condition-report condition *error-output*))
			 f glv-win)
			(setq ok nil)
			(file-failure glv-win f " could not be converted")
			(throw 'conversion-error-occurred condition)
			)))
		  (generate-lv-code fullname)))
	  (when ok
	    (setf (lv:left-footer glv-win)
		  (format nil "File package: ~A" (package-name *package*)))))
;;; end new code
#+ignore	(progn
	  (lcl:ignore-errors 
	   (generate-lv-code fullname)
	   (setq ok t))

	  (if ok
	      (setf (lv:left-footer glv-win)
		    (format nil "File package: ~A" (package-name *package*)))
	      (progn
		(debug-advice "" glv-file)
		(file-failure glv-win f " could not be converted"))))



	(if (probe-file d)
	    (file-failure glv-win (check-and-add-G-extension f) " not found")
	    (set-footer glv-win "Directory does not exist")))
    ))


(defun load-lisp-files (container file-types)
  (let* ((d (lv:value (slot-value container 'glv-directory)))
	 (trailing-slash (position "/" d :from-end t :test 'string=))
	 (f (check-and-remove-G-extension
	     (lv:value (slot-value container 'glv-filename))))
	 (fullname (if (and trailing-slash (eq (length d) (1+ trailing-slash)))
		       (format nil "~A~A" d f)
		       (if (string= "" d)
			   f
			   (progn
			     ;; probe-file can't handle ~ but can handle ~/
			     (setq d (format nil "~A/" d)) 
			     (format nil "~A~A" d f)))))
	 (w (slot-value container 'glv-window))
	 (ok nil))
    (set-footer w "Loading...")
    (set-text-line container "") ; clear eval line
    (if (probe-file d)
	(progn 
	  (catch 'both-loaded
	    (mapc #'(lambda(file)
		      (setq file (concatenate 'string fullname 
					      (subseq file 3)))
		      (if (probe-file (format nil "~A.lisp" file))
			  (progn	  
			    (lcl:ignore-errors 
			     (load file :if-source-newer :load-source)
			     (setq ok 'ok))
			    (unless ok
			      (file-failure w file " failed to load")
			      (throw 'both-loaded (setq ok nil))))
			  (progn 
			    (file-failure w file ".lisp not found")
			    (throw 'both-loaded (setq ok nil))))
		      )
		  file-types))
	  (when ok
	    (set-footer w "Loading Done.")
	    (set-text-line container
			   (generate-lv-make-instance-string fullname)
			   )))
	(set-footer w "Directory does not exist"))
    ))

(defun eval-text-line (line window)
  (let ((ok t))
    (set-footer window "Evaluating...")
    (catch 'eval-error-occurred
		 (lucid::handler-bind 
		  ((lucid::serious-condition 
		    #'(lambda (condition)
			(debug-advice-for-eval
			 (with-output-to-string (*error-output*)
			   (lucid::condition-report condition *error-output*))
			 (lv:value line) window)
			(setq ok nil)
			(throw 'eval-error-occurred condition)
			)))
		  (eval (read-from-string (lv:value line)))   ))

#+ignore(lcl:ignore-errors 
     (eval (read-from-string (lv:value line)))	   
     (setq ok t))

    (if ok
	(set-footer window "Evaluating Done.")
	(setf (lv:left-footer window)
	      (format nil "Could not evaluate")))
    ))

;;; ***********************************************************************
;;; Begin code for lvg:
;;; ***********************************************************************

(defun help ()
  (format t "~%To select the translation of :command and :update-value code
back to Devguide (GIL), you could type:
  (setq guide:*interested-in-converting-code* t)
That's all the help currently available.~%"))

(defun register-and-name-obj (obj)
  (let ((data (assoc obj *window-names*)))
;;; if registered, return name
;;; else register and allocate name
    (if data
	(cdr data)
	(let ((name (if (typep obj 'lv:popup-window)
			(gentemp "POPUP")
			(gentemp "WINDOW")
		      )))
	  (push (cons obj name) *window-names*)
	  name))
    ))

;;; assume at this stage the file can be written - UI must display notice.
;;; check if obj is a base-window
;;; No check for obj type because one can specify more than one obj
;;; Is the order important? must base-window come before popups?
;;; what about base-windows owned by other base-windows?
(defun generate-gil-code (obj-or-list &optional (filename "~/lvg-temp.G"))
  (when obj-or-list
    (setq *menu-list* nil) 
;; need to get the base-windows, up font because Devguide will set owner
;; of a popup that appears before a base-window to nil
    (when (listp obj-or-list)
      (setq obj-or-list (sort obj-or-list #'(lambda(x y)
					      (declare (ignore y))
					      (typep x 'lv:base-window)))))
					; walk has side-effect on *menu-list*
    (let ((walk-result (remove nil (walk obj-or-list)))) 
      (out-file (append *menu-list* walk-result)
		filename)
      )))

(defun walk (lst)
  (cond ((null lst) nil)
	((atom lst)
	 (let ((ch (lv:children lst)))
	   (if (null ch)
	       (list (conv lst))
	       (cons (conv lst) (walk ch)))))
	(t (append (walk (car lst)) (walk (cdr lst))))
	))

;;;=======================================================================
;;;  Colors
;;;=======================================================================
#|
Since LispView uses no space in color names, we have to reinsert the space
for Devguide.  Looks like the Suffixes: Blue, Green, Red, Grey and Gray
and the Prefixes: Dark, Light, Medium and 1 instance each of Blue and Green.
Convert :MEDIUMSLATEBLUE to "Medium Slate Blue"
|#
(defvar *prefixes* '("DARK" "LIGHT" "MEDIUM" "BLUE" "GREEN"))
(defvar *suffixes* '("BLUE" "GREEN" "RED" "GREY" "GRAY"))

(defun expand-suffix (suffix str)
  (let (len pos)
    (if (and (setq pos (search suffix str :from-end t))
	     (not (eq (setq len (length suffix)) (length str)))
	     (eq pos (- (length str) len)) ; really at end
	     (not (eq (position #\space str :from-end t) (1- pos)))) ; no sp b4
	(concatenate 'string (subseq str 0 pos) " " suffix)
       )
    ))

(defun expand-prefix (prefix str)
  (let (len pos)
    (if (and (setq pos (search prefix str))
	     (zerop pos)
	     (not (eq (setq len (length prefix)) (length str)))
	     (not (eq (position #\space str) len)))
	(concatenate 'string prefix " " (subseq str len))
       )
    ))

(defun do-suffix (str)
  (or (some #'(lambda(p) (expand-suffix p str))
	    *suffixes*)
      str))

(defun do-prefix (str)
  (or (some #'(lambda(p) (expand-prefix p str))
	    *prefixes*)
      str))

(defun convert-lv-color (name)
  (string-capitalize (do-prefix (do-suffix (string name)))))

(defun gil-foreground (obj)
  (let ((col (lv:foreground obj)))
    (if col
      (convert-lv-color (lv:name col))
      "")))

(defun gil-background (obj)
  (let ((col (lv:background obj)) n)
    (if col
	(progn 
	  (setq n (lv:name col))  ; this is a limitation in XView/LispView
	  (if (eq n :white)       ; where panel backgrounds come out WHITE
	      ""
	      (convert-lv-color n) ))
	"")))

#+ignore (defun gil-foreground (obj)
  (let ((fg (lv:foreground obj))
	n)
    (when (null fg)
      (setq fg (lv:foreground (lv:parent obj))))
    (if fg
	(progn 
	  (setq n (lv:name fg))
;;	  (convert-lv-color n)
	  (if (or (eq n :black) ;; not clear if this is right
		  (eq n :white))
	      ""
	      (convert-lv-color n))
	  )
	(progn (warn "Foreground color not found")
	       ""))
    ))

#+ignore(defun gil-background (obj)
  (let ((fg (lv:background obj))
	n)
    (when (null fg)
      (setq fg (lv:background (lv:parent obj))))
    (if fg
	(progn 
	  (setq n (lv:name fg))
;;	  (convert-lv-color n)
	  (if (or (eq n :black)
		  (eq n :white))
	      ""
	      "")
	  )
	(progn (warn "Background color not found")
	       ""))
    ))

;; One may want to replace prin1-to-string with something simple.
(defun convert-choices (obj)
  (mapcar #'(lambda(c)
	      (if (stringp c)
		  c
		  (prin1-to-string (lv:label c))))
	  (lv:choices obj)))

(defun convert-choice-label-types (obj)
;; can't deal with IMAGES - LispView
  (mapcar #'(lambda(c)
	      (declare (ignore c))
	      :string)
	  (lv:choices obj)))

(defun convert-label (obj)
;; Items labels are slots in LispView.
;; The protocol for "label" in LispView could be better defined
;; and thus the following checks could be reexamined.
  (if (slot-boundp obj 'lv:label)
      (let ((tmp (lv:label obj)))
	(cond ((null tmp) "")
	      ((stringp tmp) tmp)
	      (t "Uknown"))) ; probably an image
      ""))

(defun get-command (obj)
  (when *interested-in-converting-code*
    (let ((code (when (slot-boundp obj 'lv:command)
		  (lv:command obj))) source)
      (when (and code (setq source (lucid::source-code code)))
	(when (> (length (prin1-to-string source)) 256)
	  (warn "Source code for ~A ~S~%  ~  
               :command slot truncated to 256 chars~%  ~ 
               You must edit the Notify Handler field in Devguide" obj
		 (lv:label obj)))
	(format nil "#'~A" source))
      )))

(defun get-update-value (obj)
  (when *interested-in-converting-code*
    (let ((code (when (slot-boundp obj 'lv:update-value)
		  (lv:update-value obj))) source)
      (when (and code (setq source (lucid::source-code code)))
	(when (> (length (prin1-to-string source)) 256)
	  (warn "Source code for ~A ~S~%  ~ 
               :update-value slot truncated to 256 chars~% ~
               You must edit the Notify Handler field in Devguide" 
		obj (lv:label obj)))
	(format nil "#'~A" source))
      )))

;;;=======================================================================
;;;  Convert Back Objects
;;;=======================================================================
(defmethod conv ((obj lv:base-window))
  (let ((name (setq *top-window* (register-and-name-obj obj)))
	(br (lv:bounding-region obj)))
    (list :type :base-window
	  :name name 
	  :owner (let ((owner (lv:owner obj)))
		   (if (or (null owner)
			   (eq owner (lv:root-canvas lv:*default-display*)))
		       nil	
		       (register-and-name-obj owner)))
	  :width (lv:region-width br) :height (lv:region-height br)
	  :background-color (gil-background obj)
	  :foreground-color (gil-foreground obj)
	  :label (lv:label obj) 
	  :label-type :string
	  :mapped (not (lv:closed obj)) 
	  :show-footer (if (or (lv:left-footer obj) (lv:right-footer obj))
			   t
			   nil)
	  :resizable t ; there is no accessor for this attribute in LispView
	  :icon-file ""			; can't get filename from LispView
	  :icon-mask-file ""		; can't get filename from LispView
	  :event-handler nil
	  :events ()
	  :user-data ()
	  )
    ))

;;; ownership is important.
;;; so lets make some assumptions here - how about store the name of the
;;; last base-window (assuming you parsed the bw already) and use this
;;; as the owner - naw, lets keep a small dbase of (window name, instance)
;;; say as an alist, then store/lookup as needed.
;;; We may have to do a pass to set this info up ahead - otherwise we
;;; run into problems like those of menus, which must be added later.
;;; note the menus were coded when we did one pass only - if time, consider
;;; a redesign.

(defmethod conv ((obj lv:popup-window))
  (let ((name (setq *top-window* (register-and-name-obj obj)))
	(br (lv:bounding-region obj)))
    (list :type :popup-window
	  :name name 
	  :owner (let ((owner (lv:owner obj)))
		   (if (or (null owner)
			   (eq owner (lv:root-canvas lv:*default-display*)))
			 nil	
		       (register-and-name-obj owner)))	
	  :width (lv:region-width br) :height (lv:region-height br)
	  :background-color (gil-background obj)
	  :foreground-color (gil-foreground obj)
	  :label (lv:label obj)
	  :label-type :string
	  :mapped (lv:mapped obj)
	  :show-footer (if (or (lv:left-footer obj) (lv:right-footer obj))
			   t
			   nil)
	  :resizable              t	; No LispView accessor
	  :pinned                 t	; No LispView accessor
; No LispView accessor for done-handler.  This is done with a (setf (mapped
; and for simplicity is ignored here
	  :done-handler           nil	
	  
	  :event-handler nil
	  :events ()
	  :user-data ()
	  )
    ))

(defmethod conv ((obj lv:panel))
  (let ((name (setq *panel* (gentemp "CONTROLS")))
	(br (lv:bounding-region obj)))
    (list :type :control-area
	  :name name :owner *top-window*
	  :help ""
	  :x (lv:region-left br) :y (lv:region-top br) 
	  :width (lv:region-width br) :height (lv:region-height br)
	  :background-color (gil-background obj)
	  :foreground-color (gil-foreground obj)
	  :show-border      (if (zerop (lv:border-width obj))
				nil
				t)
	  :menu                   nil
	  :event-handler          nil
	  :events                 ()
	  :user-data              ()
	  )
    ))

;; ======== Canvases ========

(defmethod conv ((obj lv:horizontal-scrollbar))  ())
(defmethod conv ((obj lv:vertical-scrollbar))  ())

(defmethod conv ((obj lv:viewport))
  (conv-canvas obj t t))

(defmethod conv ((obj lv:scrolling-window))
  (warn "Scrolling Window should be a Viewport, ignored."))
  
(defmethod conv ((obj lv:window))
  (conv-canvas obj nil nil))
  
(defmethod conv ((obj lv:opaque-canvas))
  (conv-canvas obj nil nil))
  
(defun conv-canvas (obj scrollable viewport?)
 (let* ((name (gentemp "CANVAS"))
	(br (if viewport? (lv:container-region obj) (lv:bounding-region obj)))
	(left (lv:region-left br))
	(top (lv:region-top br))
	)
    (list :type :canvas-pane
	  :name name :owner *top-window*
	  :help ""
	  :x (if (= 1 left)
		 0
		 left)
	  :y (if (= 1 top)
		 0
		 top)
	  :width (lv:region-width br)
	  :height (lv:region-height br)
	  :background-color (gil-background obj)
	  :foreground-color (gil-foreground obj)
	  :menu                   nil
	  :horizontal-scrollbar   (when scrollable 
				    (if viewport?
					(if (lv:horizontal-scrollbar obj)
					    t
					    nil)
					(some #'(lambda(x)
						  (typep 
						   x
						   'lv:horizontal-scrollbar))
					      (lv:children obj))))
	  :scrollable-width (lv:region-width br)
	  :vertical-scrollbar     (when scrollable
				    (if viewport?
					(if (lv:vertical-scrollbar obj)
					    t
					    nil)
					(some #'(lambda(x)
						  (typep 
						   x
						   'lv:vertical-scrollbar))
					      (lv:children obj))))
	  :scrollable-height (lv:region-height br)
	  :repaint-proc           nil
	  :event-handler          nil
	  :events                 ()
	  :drawing-model          :xview
	  :user-data              ()
	  )
    ))

#| could be useful, like slider
(defmethod conv ((obj lv:button))
  (warn "You made an instance of the abstract class \"button\", ~
             using command-button instead.")
  (convert-button obj :command))
|#

(defmethod conv ((obj lv:command-button))
  (let ((name (gentemp "BUTTON"))
	(br (lv:bounding-region obj)))
    (list :type :button
	  :name name :owner *panel*
	  :help ""
	  :x (lv:region-left br) :y (lv:region-top br) 
	  :constant-width         nil
	  :button-type            :normal
	  :width (lv:region-width br) :height (lv:region-height br)
	  :foreground-color (gil-foreground obj)
	  :label (convert-label obj)
	  :label-type :string
	  :menu                   nil ; this is menu name for menu-button
	  :notify-handler         (get-command obj)
	  :event-handler          nil
	  :events                 ()
	  :user-data              ()
	  )
    ))

(defmethod conv ((obj lv:menu-button))
  (let ((name (gentemp "BUTTON"))
	(menu-name (gentemp "MENU"))
	(br (lv:bounding-region obj)))
    (conv-menu (lv:menu obj) menu-name)
    (list :type :button
	  :name name :owner *panel*
	  :help ""
	  :x (lv:region-left br) :y (lv:region-top br) 
	  :constant-width         nil
	  :button-type            :normal ; abbrev not supported in LispView
	  :width (lv:region-width br) :height (lv:region-height br)
	  :foreground-color (gil-foreground obj)
	  :label (convert-label obj)
	  :label-type :string
	  :menu                   menu-name
	  :notify-handler         nil
	  :event-handler          nil
	  :events                 ()
	  :user-data              ()
	  )
    ))


; Curently, LispView does not keep track of panel and canvas menus.
; In order for "free floating" menus to be converted back to Devguide,
; LispView must keep a list of these menus (say attached to a display)
(defun conv-menu (obj name)
;; can't support glyph filenames
  (let ((c (lv:choices obj)) 
	(default (lv:default obj))
	(menu-label (convert-label obj))
	menu-data)
    (setq menu-data 
	  (mapcar #'(lambda(item)
		      (if (typep item 'lv:submenu-item)
			  (let ((m-name (gentemp "MENU")))
			    (conv-menu (lv:menu item) m-name)
			    (list m-name nil))
			  (list nil (get-command item))))
		  c))
    (push (list :type                   :menu
		:name                   name
		:help                   ""
		:columns                1
		:label                  ""
		:label-type             :string
		:menu-type              :command
		:menu-handler           nil
		:menu-title             (if (null menu-label) "" menu-label)
		:menu-item-labels       (mapcar #'(lambda(i) 
					     (convert-label i)) c)
		:menu-item-label-types  (mapcar #'(lambda(x) 
						    (declare (ignore x))
						    :string) c)
		:menu-item-defaults     (loop for i from 0 as temp in c do 
					      collect (if (eql i default) 
							  t 
							  nil))
		:menu-item-handlers     (mapcar 'cadr menu-data)
		:menu-item-menus        (mapcar 'car menu-data)
		:menu-item-colors       (mapcar #'(lambda(x) ; no col supp.
						    (declare (ignore x))
						    "") menu-data) ; in LispV.
		:pinnable               (if (lv:pushpin obj) t nil)
		:user-data              ()
		)
	  *menu-list*)
    ))


(defmethod conv ((obj lv:exclusive-setting))
  (conv-setting obj :exclusive))

(defmethod conv ((obj lv:non-exclusive-setting))
  (conv-setting obj :nonexclusive))

(defmethod conv ((obj lv:check-box))
  (conv-setting obj :check))

(defmethod conv ((obj lv:abbreviated-exclusive-setting))
  (conv-setting obj :stack))

(defun conv-setting (obj setting-type)
  (let ((name (gentemp "SETTING"))
	(br (lv:bounding-region obj)))
    (list :type :setting
	  :name name :owner *panel*
	  :help ""
	  :x (lv:region-left br) :y (lv:region-top br) 
	  :width (lv:region-width br) :height (lv:region-height br)
	  :value-x                30 ;; don't know - bugtraq rfe no: 1038996
	  :value-y                (lv:region-top br)
	  :layout-type            (lv:layout obj) 
	  :foreground-color       (gil-foreground obj)
	  :setting-type           setting-type
	  :rows                   (lv:choices-nrows obj) ; undocumented
	  :columns                (lv:choices-ncols obj) ; undocumented
	  :label                  (convert-label obj)
	  :label-type             :string
	  :notify-handler         (get-update-value obj)
	  :event-handler          nil
	  :events                 ()
	  :choices                (convert-choices obj)
	  :choice-label-types     (convert-choice-label-types obj)
	  :choice-colors          (mapcar #'(lambda(x)
					      (declare (ignore x))
					      "") (convert-choices obj))
	  :user-data              ()
	  )
    ))

(defmethod conv ((obj lv:text-field))
  (let ((name (gentemp "TEXTFIELD"))
	(br (lv:bounding-region obj)))
    (list :type :text-field
	  :name name :owner *panel*
	  :help ""
	  :x (lv:region-left br) :y (lv:region-top br) 
	  :width (lv:region-width br) :height (lv:region-height br)
	  :foreground-color       (gil-foreground obj)
	  :text-type              :alphanumeric
	  :label                  (convert-label obj)
	  :label-type             :string
	  :value-x                30 ;; don't know - bugtraq rfe no: 1038996
	  :value-y                (lv:region-top br)
	  :layout-type            (lv:layout obj) 
	  :value-length           (lv:displayed-value-length obj)
	  :stored-length          (lv:stored-value-length obj)
	  :read-only              (lv:read-only obj)
	  :notify-handler         (get-update-value obj)
	  :event-handler          nil
	  :events                 ()
	  :user-data              ()
	  )
    ))

(defmethod conv ((obj lv:numeric-field))
  (let ((name (gentemp "TEXTFIELD"))
	(br (lv:bounding-region obj)))
    (list :type :text-field
	  :name name :owner *panel*
	  :help ""
	  :x (lv:region-left br) :y (lv:region-top br) 
	  :width (lv:region-width br) :height (lv:region-height br)
	  :foreground-color       (gil-foreground obj)
	  :text-type              :numeric
	  :label                  (convert-label obj)
	  :label-type             :string
	  :value-x                30 ;; don't know - bugtraq rfe no: 1038996
	  :value-y                (lv:region-top br)
	  :layout-type            (lv:layout obj) 
	  :value-length           (lv:displayed-value-length obj)
	  :stored-length          (lv:stored-value-length obj)
	  :max-value              (lv:max-value obj)
	  :min-value              (lv:min-value obj)
	  :read-only              (lv:read-only obj)
	  :notify-handler         (get-update-value obj)
	  :event-handler          nil
	  :events                 ()
	  :user-data              ()
	  )
    ))

(defmethod conv ((obj lv:message))
  (let ((name (gentemp "MESSAGE"))
	(br (lv:bounding-region obj)))
    (list :type :message
	  :name name :owner *panel*
	  :help ""
	  :x (lv:region-left br) :y (lv:region-top br) 
	  :width (lv:region-width br) :height (lv:region-height br)
	  :foreground-color       (gil-foreground obj)
	  :label                  (convert-label obj)
	  :label-type             :string
	  :label-bold             t	; LispView can't support this
	  :event-handler          nil
	  :events                 ()
	  :user-data              ()
	  )
    ))


(defmethod conv ((obj lv:slider))
  (warn "You made an instance of the abstract class \"slider\", ~
             using horizontal-slider instead.")
  (convert-slider obj :horizontal))

(defmethod conv ((obj lv:horizontal-slider))
  (convert-slider obj :horizontal))

(defmethod conv ((obj lv:vertical-slider))
  (convert-slider obj :vertical))

(defun convert-slider (obj orientation)
  (let ((name (gentemp "SLIDER"))
	(br (lv:bounding-region obj)))
    (list :type :slider
	  :name name :owner *panel*
	  :help ""
	  :x (lv:region-left br) :y (lv:region-top br) 
	  :width (lv:region-width br) :height (lv:region-height br)
	  :value-x                30 ;; don't know - bugtraq rfe no: 1038996
	  :value-y                (lv:region-top br)
	  :slider-width           (lv:gauge-length obj)
	  :foreground-color (gil-foreground obj)
	  :label                  (convert-label obj)
	  :label-type             :string
	  :layout-type            (lv:layout obj)
	  :orientation            orientation
	  :show-endboxes          (lv:show-end-boxes obj)
	  :show-range             (lv:show-range obj)
	  :show-value             (lv:show-value obj)
	  :min-value              (lv:min-value obj)
	  :max-value              (lv:max-value obj)
	  :ticks                  (lv:nticks obj)
	  :notify-handler         (get-update-value obj)
	  :event-handler          nil
	  :events                 ()
	  :user-data              ()
	  )
    ))

(defmethod conv ((obj lv:vertical-gauge))
  (convert-gauge obj :vertical))

(defmethod conv ((obj lv:horizontal-gauge))
  (convert-gauge obj :horizontal))

(defun convert-gauge (obj orientation)
  (let ((name (gentemp "GAUGE"))
	(br (lv:bounding-region obj)))
    (list :type :gauge
	  :name name :owner *panel*
	  :help ""
	  :x (lv:region-left br) :y (lv:region-top br) 
	  :width (lv:region-width br) :height (lv:region-height br)
	  :value-x                30 ;; don't know - bugtraq rfe no: 1038996
	  :value-y                (lv:region-top br)
	  :slider-width           (lv:gauge-length obj)
	  :foreground-color       (gil-foreground obj)
	  :label                  (convert-label obj)
	  :label-type             :string
	  :layout-type            (lv:layout obj)
	  :orientation            orientation
	  :show-range             (lv:show-range obj)
	  :min-value              (lv:min-value obj)
	  :max-value              (lv:max-value obj)
	  :ticks                  (lv:nticks obj)
	  :user-data              ()
	  )
    ))

(defmethod conv ((obj lv:exclusive-scrolling-list))
  (conv-scrolling-list obj nil))

(defmethod conv ((obj lv:non-exclusive-scrolling-list))
  (conv-scrolling-list obj t))

(defun conv-scrolling-list (obj multiple-selections)
  (let ((name (gentemp "LIST"))
	(br (lv:bounding-region obj)))
    (list :type :scrolling-list
	  :name name :owner *panel*
	  :help ""
	  :x (lv:region-left br) :y (lv:region-top br) 
	  :width (lv:choice-width obj) :height (lv:region-height br)
	  :foreground-color       (gil-foreground obj)
	  :label                  (convert-label obj)
	  :label-type             :string
	  :layout-type            (lv:layout obj) 
	  :rows                   (lv:nchoices-visible obj)
	  :read-only              (lv:read-only obj)
	  :multiple-selections    multiple-selections
	  :selection-required     (unless multiple-selections
				    (lv:selection-required obj))
	  :menu                   nil ; not available in LispView
	  :notify-handler         (get-update-value obj)
	  :event-handler          nil
	  :events                 ()
	  :user-data              ()
	  )
    ))

;;;========================================================================
;;; Output to Disk
;;;========================================================================

(defun object-out (lst f)
  (format f "(~%")
  (loop for attribute in lst by #'cddr and
	value in (cdr lst) by #'cddr do
	(if (member attribute '(:events :user-data :menu-item-defaults
					:menu-item-handlers
					:menu-item-menus))
	    (format f "~A~S~25T~:S~%" #\tab attribute value)
	    (format f "~A~S~25T~S~%" #\tab attribute value)))
  (princ ")" f)
  )

(defun out-file (application-list filename)
  (let ((*print-case* :downcase))
    (with-open-file (f filename :direction :output)
      (format f ";~A~%(~%" *gil-version-for-file*)
      (mapc #'(lambda(lst)
		(object-out lst f)
		)
	    application-list)
      (format f "~%)"))
    ))
    
;;;======================================================================
;;; Stubs
;;;======================================================================

(defun lvg-values (lst)
;; added Jan 31st
  (lvg-update-list lst nil)
  (mapcar 'lvg-choice-window (lv:value lst)))

(defun lvg-convert-to-gil (lst container)
  (let* ((d (lv:value (slot-value container 'lvg-directory)))
	 (trailing-slash (position "/" d :from-end t :test 'string=))
	 (f (lv:value (slot-value container 'lvg-filename)))
	 (fullname (if (and trailing-slash (eq (length d) (1+ trailing-slash)))
		       (format nil "~A~A" d f)
		       (if (string= "" d)
			   f
			   (progn
			     ;; probe-file can't handle ~ but can handle ~/
			     (setq d (format nil "~A/" d)) 
			     (format nil "~A~A" d f)))))
	 (list-of-windows (lvg-values lst))
	 (w (slot-value container 'lvg-window)))
    (set-footer w "")
  (when list-of-windows
    (if (probe-file d)
	(if (or (string= "" f) (string= " " f))
	    (set-footer w "No Interface File specified.")
	    (let ((ok-to-write t)
	      (name-and-extension (check-and-add-G-extension fullname)))
	  (when (probe-file name-and-extension)
	    (setq ok-to-write
		  (lv:notice-prompt :message 
				 (format nil "File ~S exists, you can:"
					 (check-and-add-G-extension f))
				 :choices '((:yes "Overwrite" t) 
					    (:no "Cancel" nil))
				 :owner w :x 100 :y 45)))
	  (when ok-to-write
	    (set-footer w "Translating...")	  
	    (generate-gil-code list-of-windows name-and-extension)
	    (set-footer w "Done."))))
	(set-footer w "Directory does not exist."))
    )))

(defun flash-item (item current-state)
  (lv:expose item)
  (dotimes (i 2)
    (sleep .1)
    (setf (lv:busy item) (not current-state))
    (sleep .1)
    (setf (lv:busy item) current-state)))

(defun map-and-flash (item current-state current-mapped)
  (if current-mapped
		    (flash-item item current-state)
		    (progn
		      (setf (lv:mapped item) t)
		      (flash-item item current-state)
		      (setf (lv:mapped item) nil)
		      )))

(defun lvg-identify-window (lst container)
  (declare (ignore container))
  (mapcar #'(lambda(item)
	      (let* ((current-state (lv:busy item))
		     (current-mapped (lv:mapped item)))
;; I need to map/unmap items because they may initially be unmapped and
;; thus not visible
		(if (typep item 'lv:base-window)
		    (if (lv:closed item)
			(progn
			  (setf (lv:closed item) nil)
			  (map-and-flash item current-state current-mapped)
			  (setf (lv:closed item) t))
			(map-and-flash item current-state current-mapped))
		    (let ((o (lv:owner item)))
		      (if (and o (lv:closed o))
					;open bw, flash, close
			  (progn 
			    (setf (lv:closed o) nil)
			    (map-and-flash item current-state
					   current-mapped)
			    (setf (lv:closed o) t))
			  (map-and-flash item current-state
					 current-mapped))
		      ))
		))
	  (lvg-values lst)))

(defun lvg-update-list (lst container)
  (declare (ignore container))
  (let ((present-value (lv:value lst)))
    (setf (lv:mapped lst) nil)
    (setf (lv:choices lst) (update-choice-list (lv:choices lst)))
    (setf (lv:value lst) present-value)
    (setf (lv:mapped lst) t)
    ))

(defstruct lvg-choice window)

;; Previously the print object of a base-window was fairly terse,
;; with LispView 1.1, much more info is present.  In fact, it is
;; probably sufficient to use the object as the label now.

#+ignore(defmethod lv:label ((x lvg-choice))
  (let* ((w (lvg-choice-window x))
	 (l (lv:label w)))
    (format nil "~A~VT~A" w (if (typep w 'lv:base-window) 30 28)
	    (if (string= "" l) "untitled" l))
    ))

(defmethod lv:label ((x lvg-choice))
  (prin1-to-string (lvg-choice-window x)))

(defun tlw ()
  (lv:children (lv:root-canvas lv:*default-display*)))

(defun update-choice-list (current-list)
  (mapcar #'(lambda(win)
	      (let ((found (some #'(lambda(s)
				     (when
					 (eq win (lvg-choice-window s))
				       s))
				 current-list)))
		(if found
		    found
		    (make-lvg-choice :window win))))
	      (tlw)))

(defun lvg-make-choices ()
  (mapcar #'(lambda(w) (make-lvg-choice :window w)) (tlw)))


;;; When editing the glv.G file, don't forget to backslash the user-data
;;; entrie for glv-directory before loading into Devguide.
;;; insert file glv.ui.lisp - the result of running this translator on glv.G
;;; Note: you can select "slots" as defclass format in the prop sheet
;;; remove the "in-package ..." line.

;;; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;;; glv: User Interface 
;;; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;;; This file produced by GLV
;;; do not edit by hand unless you are satisfied
;;; with the layout of these objects,
;;; instead, use Devguide to edit /home/lisp/solo/guide/glv.G

(defclass glv
          nil
          ((glv-window :accessor glv-window)
            (glv-load-menu :accessor glv-load-menu)
            (glv-panel :accessor glv-panel)
            (glv-display-props :accessor glv-display-props)
            (glv-convert :accessor glv-convert)
            (glv-load :accessor glv-load)
            (glv-evaluate :accessor glv-evaluate)
            (glv-eval-field :accessor glv-eval-field)
            (glv-directory :accessor glv-directory)
            (glv-filename :accessor glv-filename)
            (glv-popup :accessor glv-popup)
            (glv-popup-panel :accessor glv-popup-panel)
            (glv-defclass-format :accessor glv-defclass-format)
            (glv-output-format :accessor glv-output-format)
            (glv-apply :accessor glv-apply)
            (glv-reset :accessor glv-reset)))


(defmethod initialize-instance
           :after
           ((glv glv) &rest args)
           (with-slots
             (glv-window glv-load-menu
                         glv-panel
                         glv-display-props
                         glv-convert
                         glv-load
                         glv-evaluate
                         glv-eval-field
                         glv-directory
                         glv-filename
                         glv-popup
                         glv-popup-panel
                         glv-defclass-format
                         glv-output-format
                         glv-apply
                         glv-reset)
             glv
             (setf glv-window
                   (make-instance 'solo:base-window
                                  :icon
                                  (make-instance 'solo:icon
                                                 :clip-mask
                                                 (make-instance 'solo:image
                                                                :data
                                                                *glv-mask-data*)
                                                 :label
                                                 (list
                                                   (make-instance 'solo:image
                                                                  :data
                                                                  *glv-data*)
                                                   "GLV"))
                                  :mapped
                                  nil
                                  :closed
                                  nil
                                  :show-resize-corners
                                  t
                                  :left-footer
                                  " "
                                  :right-footer
                                  " "
                                  :width
                                  514
                                  :height
                                  100
                                  :label
                                  "GLV  Devguide to LispView Conversion")
                   glv-load-menu
                   (make-instance 'solo:menu
                                  :default
                                  3
                                  :choices
                                  (list
                                    (make-instance 'solo:command-menu-item
                                                   :label
                                                   "only app"
                                                   :command
                                                   #'(lambda nil
                                                      (load-lisp-files glv
                                                       '("app"))))
                                    (make-instance 'solo:command-menu-item
                                                   :label
                                                   "ui only"
                                                   :command
                                                   #'(lambda nil
                                                      (load-lisp-files glv
                                                       '("app.ui"))))
                                    (make-instance 'solo:command-menu-item
                                                   :label
                                                   "app & ui "
                                                   :command
                                                   #'(lambda nil
                                                      (load-lisp-files glv
                                                       '("app.ui" "app"))))
                                    (make-instance 'solo:command-menu-item
                                                   :label
                                                   "stub & ui"
                                                   :command
                                                   #'(lambda nil
                                                      (load-lisp-files glv
                                                       '("app.ui" "app.stub")))))
                                  :choices-ncols
                                  1
                                  :pushpin
                                  nil)
                   glv-panel
                   (make-instance 'solo:panel
                                  :left
                                  0
                                  :top
                                  0
                                  :width
                                  514
                                  :height
                                  100
                                  :parent
                                  glv-window)
                   glv-display-props
                   (make-instance 'solo:command-button
                                  :command
                                  #'(lambda nil (display-props glv))
                                  :left
                                  12
                                  :top
                                  9
                                  :width
                                  61
                                  :height
                                  19
                                  :label
                                  "Props..."
                                  :parent
                                  glv-panel)
                   glv-convert
                   (make-instance 'solo:command-button
                                  :command
                                  #'(lambda nil
                                     (convert-to-lisp glv-directory
                                      glv-filename glv-window))
                                  :left
                                  90
                                  :top
                                  9
                                  :width
                                  66
                                  :height
                                  19
                                  :label
                                  "Convert"
                                  :parent
                                  glv-panel)
                   glv-load
                   (make-instance 'solo:menu-button
                                  :menu
                                  glv-load-menu
                                  :left
                                  162
                                  :top
                                  9
                                  :width
                                  60
                                  :height
                                  19
                                  :label
                                  "Load"
                                  :parent
                                  glv-panel)
                   glv-evaluate
                   (make-instance 'solo:command-button
                                  :command
                                  #'(lambda nil
                                     (eval-text-line glv-eval-field glv-window))
                                  :left
                                  243
                                  :top
                                  9
                                  :width
                                  46
                                  :height
                                  19
                                  :label
                                  "Eval:"
                                  :parent
                                  glv-panel)
                   glv-eval-field
                   (make-instance 'solo:text-field
                                  :displayed-value-length
                                  26
                                  :stored-value-length
                                  80
                                  :left
                                  289
                                  :top
                                  11
                                  :width
                                  217
                                  :height
                                  15
                                  :layout
                                  :horizontal
                                  :label
                                  ""
                                  :parent
                                  glv-panel)
                   glv-directory
                   (make-instance 'solo:text-field
                                  :value
                                  (namestring (pwd))
                                  :displayed-value-length
                                  47
                                  :stored-value-length
                                  80
                                  :left
                                  55
                                  :top
                                  46
                                  :width
                                  451
                                  :height
                                  15
                                  :layout
                                  :horizontal
                                  :label
                                  "Directory:"
                                  :parent
                                  glv-panel)
                   glv-filename
                   (make-instance 'solo:text-field
                                  :displayed-value-length
                                  47
                                  :stored-value-length
                                  80
                                  :left
                                  13
                                  :top
                                  71
                                  :width
                                  493
                                  :height
                                  15
                                  :layout
                                  :horizontal
                                  :label
                                  "Interface Name:"
                                  :parent
                                  glv-panel)
                   glv-popup
                   (make-instance 'solo:popup-window
                                  :mapped
                                  nil
                                  :show-resize-corners
                                  nil
                                  :pushpin
                                  :out
                                  :owner
                                  glv-window
                                  :width
                                  290
                                  :height
                                  147
                                  :label
                                  "GLV: Properties")
                   glv-popup-panel
                   (make-instance 'solo:panel
                                  :left
                                  0
                                  :top
                                  0
                                  :width
                                  290
                                  :height
                                  147
                                  :parent
                                  glv-popup)
                   glv-defclass-format
                   (make-instance 'solo:exclusive-setting
                                  :choices-nrows
                                  1
                                  :choices
                                  (list "Slots" "Accessors")
                                  :left
                                  16
                                  :top
                                  32
                                  :width
                                  241
                                  :height
                                  23
                                  :layout
                                  :horizontal
                                  :label
                                  "Defclass Format:"
                                  :parent
                                  glv-popup-panel)
                   glv-output-format
                   (make-instance 'solo:exclusive-setting
                                  :choices-nrows
                                  1
                                  :choices
                                  (list "pprint" "glv-pp")
                                  :left
                                  28
                                  :top
                                  67
                                  :width
                                  223
                                  :height
                                  23
                                  :layout
                                  :horizontal
                                  :label
                                  "Output Format:"
                                  :parent
                                  glv-popup-panel)
                   glv-apply
                   (make-instance 'solo:command-button
                                  :command
                                  #'(lambda nil (apply-props glv))
                                  :left
                                  90
                                  :top
                                  107
                                  :width
                                  53
                                  :height
                                  19
                                  :label
                                  "Apply"
                                  :parent
                                  glv-popup-panel)
                   glv-reset
                   (make-instance 'solo:command-button
                                  :command
                                  #'(lambda nil (reset-props glv))
                                  :left
                                  153
                                  :top
                                  107
                                  :width
                                  51
                                  :height
                                  19
                                  :label
                                  "Reset"
                                  :parent
                                  glv-popup-panel))
             (setf (solo:mapped glv-window)
                   t)))

;;; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
;;; end UI for glv 
;;; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

(format t "
To create the Devguide to LispView translator window, type:
(make-instance 'guide:glv)
To create the LispView to Devguide translator window, type:
(make-instance 'guide:lvg)
")

;;; insert file lvg.ui.lisp - the result of running this translator on lvg.G
;;; Note: you can select "slots" as defclass format in the prop sheet
;;; remove the "in-package ..." line, and 
;;; (defparam *my-path..) line, (setq *my-path-to-icon* *load-pathname*) line
#|
Is this old:?? Insert this code for the generated code
                                              (if (probe-file f)
                                                       (list
                                                         (make-instance
                                                           'solo:image
                                                           :filename
                                                           f
                                                           :format
                                                           :sun-icon)
                                                         "LVG")
                                                       "LVG")
|#
;;; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;;; lvg: User Interface 
;;; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;;; This file produced by GLV
;;; do not edit by hand unless you are satisfied
;;; with the layout of these objects,
;;; instead, use Devguide to edit /home/lisp/solo/guide/lvg.G

(defclass lvg
          nil
          ((lvg-window :accessor lvg-window) (view-menu :accessor view-menu)
                                             (lvg-panel :accessor lvg-panel)
                                             (lvg-view :accessor lvg-view)
                                             (lvg-convert :accessor
                                                          lvg-convert)
                                             (lvg-directory :accessor
                                                            lvg-directory)
                                             (lvg-filename :accessor
                                                           lvg-filename)
                                             (lvg-window-list :accessor
                                                              lvg-window-list)))


(defmethod initialize-instance
           :after
           ((lvg lvg) &rest args)
           (with-slots
             (lvg-window view-menu
                         lvg-panel
                         lvg-view
                         lvg-convert
                         lvg-directory
                         lvg-filename
                         lvg-window-list)
             lvg
             (setf lvg-window
                   (make-instance 'solo:base-window
                                  :icon
                                  (make-instance 'solo:icon
                                                 :clip-mask
                                                 (make-instance 'solo:image
                                                                :data
                                                                *lvg-mask-data*)
                                                 :label
                                                 (list
                                                   (make-instance 'solo:image
                                                                  :data
                                                                  *lvg-data*)
                                                   "LVG"))
                                  :mapped
                                  nil
                                  :closed
                                  nil
                                  :show-resize-corners
                                  t
                                  :left-footer
                                  " "
                                  :right-footer
                                  " "
                                  :width
                                  516
                                  :height
                                  240
                                  :label
                                  "LVG  LispView to Devguide Conversion")
                   view-menu
                   (make-instance 'solo:menu
                                  :default
                                  0
                                  :choices
                                  (list
                                    (make-instance 'solo:command-menu-item
                                                   :label
                                                   "Update List"
                                                   :command
                                                   #'(lambda nil
                                                      (lvg-update-list
                                                       lvg-window-list lvg)))
                                    (make-instance 'solo:command-menu-item
                                                   :label
                                                   "Associated Window"
                                                   :command
                                                   #'(lambda nil
                                                      (lvg-identify-window
                                                       lvg-window-list lvg))))
                                  :choices-ncols
                                  1
                                  :pushpin
                                  nil)
                   lvg-panel
                   (make-instance 'solo:panel
                                  :left
                                  0
                                  :top
                                  0
                                  :width
                                  516
                                  :height
                                  240
                                  :parent
                                  lvg-window)
                   lvg-view
                   (make-instance 'solo:menu-button
                                  :menu
                                  view-menu
                                  :left
                                  13
                                  :top
                                  6
                                  :width
                                  62
                                  :height
                                  19
                                  :label
                                  "View"
                                  :parent
                                  lvg-panel)
                   lvg-convert
                   (make-instance 'solo:command-button
                                  :command
                                  #'(lambda nil
                                     (lvg-convert-to-gil lvg-window-list lvg))
                                  :left
                                  90
                                  :top
                                  6
                                  :width
                                  66
                                  :height
                                  19
                                  :label
                                  "Convert"
                                  :parent
                                  lvg-panel)
                   lvg-directory
                   (make-instance 'solo:text-field
                                  :value
                                  (namestring (pwd))
                                  :displayed-value-length
                                  46
                                  :stored-value-length
                                  80
                                  :left
                                  56
                                  :top
                                  38
                                  :width
                                  443
                                  :height
                                  15
                                  :layout
                                  :horizontal
                                  :label
                                  "Directory:"
                                  :parent
                                  lvg-panel)
                   lvg-filename
                   (make-instance 'solo:text-field
                                  :displayed-value-length
                                  46
                                  :stored-value-length
                                  80
                                  :left
                                  14
                                  :top
                                  62
                                  :width
                                  485
                                  :height
                                  15
                                  :layout
                                  :horizontal
                                  :label
                                  "Interface Name:"
                                  :parent
                                  lvg-panel)
                   lvg-window-list
                   (make-instance 'solo:non-exclusive-scrolling-list
                                  :choices
                                  (lvg-make-choices)
                                  :nchoices-visible
                                  6
                                  :choice-width
                                  470
                                  :selection-required
                                  nil
				  :read-only t
                                  :left
                                  13
                                  :top
                                  93
                                  :width
                                  470
                                  :height
                                  145
                                  :layout
                                  :vertical
                                  :label
                                  "Top Level Windows:"
                                  :parent
                                  lvg-panel))
             (setf (solo:mapped lvg-window)
                   t)))
;;; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
;;; end UI for lvg 
;;; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

