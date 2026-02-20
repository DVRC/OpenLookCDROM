;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)tty-defs.lisp	1.2 10/21/91

(in-package "LISPVIEW")

(defclass tty-window (window) ())


(deftype argv-sequence () 'sequence)

;;; All of the tty-window accessors listed below have the same type and semantics 
;;; as their XView counterparts.  Some of then differ in prefix, we've substituted
;;; tty- for xv- and win- (xv_ and win_ in C) for several attributes.

(eval-when (load eval compile)
  (defparameter xview-tty-attributes
    '((tty-left-margin (integer 0 *) (:create :get :set) "XV-")
      (tty-right-margin (integer 0 *) (:create :get :set) "XV-")
      (tty-bottom-margin (integer 0 *) (:create :get :set) "XV-")
      (tty-top-margin (integer 0 *) (:create :get :set) "XV-")
      (tty-margin (integer 0 *) (:create :get :set) "XV-")
      (tty-rows (integer 0 *) (:create :get :set) "WIN-")
      (tty-columns (integer 0 *) (:create :get :set) "WIN-")
      (tty-font font (:create :get :set) "XV-")
      (tty-console boolean (:create :set))
      (tty-argv argv-sequence (:create))      
      (tty-argv-do-not-fork argv-sequence (:create))
      (tty-page-mode boolean (:create :get :set))
      (tty-pid integer (:create :get :set))
      (tty-quit-on-child-death boolean (:create :set))
      (tty-tty-fd integer (:get)))))

(export (mapcar #'car xview-tty-attributes))


(defun tty-accessor-initarg (entry)
  (intern (subseq (string-upcase (car entry)) 4) 
	  (find-package "KEYWORD")))

(defun xview-tty-attribute (entry)
  (intern (format nil "~A~A" (or (cadddr entry) "TTY-") 
		             (subseq (string-upcase (car entry)) 4))
	  (find-package "KEYWORD")))

(defun xview-tty-attribute-type (entry)
  (cadr entry))

(defun xview-tty-attribute-proc-p (entry type)
  (member type (caddr entry)))
