;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)textedit-defs.lisp	1.2 10/21/91


(in-package "LISPVIEW")


(defclass textedit-window (window) ())

(deftype textedit-location () 
  '(or (member :first :last) (integer 0 *)))

(deftype textedit-insert-makes-visible ()
  '(member :always :if-auto-scroll))

(deftype textedit-line-break-action ()
  '(member :clip :wrap-at-char :wrap-at-word))


(defvar textedit-actions 
  '(:caps-lock 
    :changed-directory
    :edited-file
    :edited-memory
    :file-is-readonly
    :loaded-file
    :tool-close
    :tool-destroy
    :tool-quit
    :tool-mgr
    :using-memory))

(deftype textedit-action ()
  `(member ,@textedit-actions))


  
;;; All of the textedit-window accessors listed below have the same type and semantics 
;;; as their XView counterparts.  The names only differ in the prefix: LispView uses 
;;; "textedit-" instead of the exact XView translation which would be: "textsw-" for
;;; all of the names except the font and left,right,bottom,top margin accessors whose 
;;; XView prefix is "XV-". The table lists the LispView name of each accessor and 
;;; it's type.

(eval-when (load eval compile)
  (defvar literal-xview-textedit-accessors
    '((textedit-left-margin (integer 0 *) "XV-")
      (textedit-right-margin (integer 0 *) "XV-")
      (textedit-bottom-margin (integer 0 *) "XV-")
      (textedit-top-margin (integer 0 *) "XV-")
      (textedit-margin (integer 0 *) "XV-")
      (textedit-font font "XV-")
      (textedit-again-recording boolean)
      (textedit-auto-indent boolean)
      (textedit-auto-scroll-by  (integer 0 *))
      (textedit-blink-caret  boolean)
      (textedit-browsing boolean)
      (textedit-checkpoint-frequency (integer 0 *))
      (textedit-confirm-overwrite boolean)
      (textedit-control-chars-use-font boolean)
      (textedit-disable-cd boolean)
      (textedit-disable-load boolean)
      (textedit-history-limit (integer 0 *))
      (textedit-ignore-limit (integer 0 *))
      (textedit-insert-makes-visible (member :always :if-auto-scroll))
      (textedit-line-break-action (member :wrap-at-char :wrap-at-word))
      (textedit-lower-context (integer -1 *))
      (textedit-memory-maximum (integer 0 *))
      (textedit-multi-click-space (integer 0 *))
      (textedit-multi-click-timeout (integer 0 *))
      (textedit-store-changes-file boolean)
      (textedit-submenu-edit menu)
      (textedit-submenu-file menu)
      (textedit-submenu-find menu)
      (textedit-submenu-view menu)
      (textedit-upper-context (integer -1 *))
      (textedit-read-only boolean))))

(defun textedit-accessor-initarg (entry)
  (intern (subseq (string-upcase (car entry)) 9) 
	  (find-package "KEYWORD")))

(defun xview-textedit-attribute (entry)
  (intern (format nil "~A~A" (or (caddr entry) "TEXTSW-") 
		             (subseq (string-upcase (car entry)) 9))
	  (find-package "KEYWORD")))

(defun xview-textedit-attribute-type (entry)
  (cadr entry))


#+ignore
(defun print-literal-accessors-table ()
  (let* ((entries 
	  (append
	   '(("LispView Accessor" "XView Attribute" "Type")
	     ("-----------------" "---------------" "----"))
	   (mapcar #'(lambda (x)
		       (list 
			 (string-downcase (car x))
			 (substitute #\_ #\- (string (xview-textedit-attribute x)))
			 (string-downcase (prin1-to-string (cadr x)))))
		   literal-xview-textedit-accessors)))

	 (format-string
	  (format nil "~~~DA   ~~~DA   ~~~DA~%"
		  (apply #'max (mapcar #'length (mapcar #'car entries)))
		  (apply #'max (mapcar #'length (mapcar #'cadr entries)))
		  (apply #'max (mapcar #'length (mapcar #'caddr entries))))))

    (dolist (x entries)
      (apply #'format t format-string x))))


(export (append (mapcar #'car literal-xview-textedit-accessors)
		'(textedit-modified-p
		  textedit-insertion-point
		  textedit-contents
		  textedit-contents-length
		  textedit-insert
		  textedit-delete
		  textedit-visible-text-offset
		  textedit-filename
		  textedit-save
		  textedit-reset
		  textedit-find-string
		  textedit-window
		  textedit-location)))

