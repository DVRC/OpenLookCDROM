;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)tty-demo.lisp	1.2 10/21/91


(in-package "LISPVIEW")


(defun tty-demo ()
  (let* ((window
	  (make-instance 'base-window
	    :keyboard-focus-mode :passive
	    :label "TTY Demo"
	    :mapped nil))
	 (panel 
	  (make-instance 'panel 
	    :parent window
	    :height 25))
	 (tty 
	  (make-instance 'tty-window 
	    :parent window))
	 (button
	  (make-instance 'command-button 
	    :parent panel
	    :label "Display Manual Page"))
	 (text-field
	  (make-instance 'text-field
	    :parent panel
	    :displayed-value-length 40)))

    (flet 
     ((man (&rest ignore)
	(declare (ignore ignore))
	(tty-input tty (format nil "clear; man ~A~%" (value text-field)))))

     (setf (update-value text-field) #'man
	   (command button) #'man))

    (tty-input tty (format nil "stty dec;setenv TERM vt100;tset~%"))
    (setf (mapped window) t)

    tty))
	    
