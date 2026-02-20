;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;%W% %G%

;;; Cheap source code finder using textedit.
;;;
;;; USAGE: 
;;; Load this file and then type (make-instance 'demo:textedit-demo).


(in-package "DEMO" :use '("LISP" "CLOS" "LISPVIEW"))

(export '(textedit-demo))


(defun find-source-definition (edit-window name type)
  (let* ((anchors (case type
		    (function '("defun "))
		    (macro '("defmacro"))
		    (structure '("defstruct ""defstruct ("))
		    (class '("defclass "))
		    (t 
		     (if (and (consp type) (and (eq (car type) 'method)))
			'("defmethod ")
		       '("")))))
	 (matches 
	  (mapcan #'(lambda (anchor)
		      (list (format nil "~A~A" anchor (string-downcase name))
			    (format nil "~A~A" anchor name)))
		  (mapcan #'(lambda (anchor)
			      (list anchor (string-upcase anchor)))
			  anchors)))
	 (offset 
	  (let ((start (textedit-insertion-point edit-window))
		(end :last))
	    (flet 
	     ((find-offset (string)
		(textedit-find-string edit-window string :start start :end end)))

	     (or (some #'find-offset matches)
		 (progn (setf end start start :first) (some #'find-offset matches)))))))

    (when offset
      (setf (textedit-visible-text-offset edit-window :char) offset
	    (textedit-insertion-point edit-window) offset))))
    


(defun textedit-demo ()
  (let* ((window
	  (make-instance 'base-window 
	    :label "Source Code Demo"
	    :icon (make-instance 'icon 
		     :background (lv:find-color :name "lightsteelblue")
		     :label (if (probe-file "lispview-app.icon")
				(list "Finder"
				      (make-instance 'image 
					      :filename "lispview-app.icon"))
				"Finder"))
	    :left-footer ""
	    :mapped nil))
	 (panel
	  (make-instance 'panel 
	    :parent window
	    :height 28))
	 (edit-window
	  (make-instance 'textedit-window
	    :parent window
	    :read-only t))
	 (search-button 
	  (make-instance 'command-button
	    :parent panel
	    :label "Find Source Code"))
	 (definition-name-typein
	   (make-instance 'text-field
	     :parent panel
	     :label "Definition Name:"
	     :displayed-value-length 40))
	 (current-name nil)
	 (current-type nil))

    (flet
     ((find-sources ()
	(let ((name
	       (LCL:ignore-errors 
		 (read-from-string (string-upcase (value definition-name-typein))))))
	  (unless (or (null name) (eq name current-name))
	    (setf current-name name)
	    (let* ((source (car (LCL:get-source-file name nil t))))
	      (if source
		  (setf current-type (car source)
			(textedit-contents edit-window) (cdr source)
			(left-footer window) (format nil "~A" (car source))
			(right-footer window) (namestring (cdr source)))
		(setf (left-footer window) ""
		      (right-footer window) "No source file found"))))
	  (when current-type
	    (find-source-definition edit-window current-name current-type)))))

     (setf (command search-button) #'find-sources
	   (update-value definition-name-typein) #'(lambda (new-value) 
						     (declare (ignore new-value)) 
						     (find-sources))))

    (defmethod (setf bounding-region) (new-br (w (eql window)))
      (let ((w-br-width (region-width new-br))
	    (w-br-height (region-height new-br))
	    (panel-br (bounding-region panel))
	    (edit-window-br (bounding-region edit-window)))
	(with-output-buffering (display w)
	  (call-next-method)
	  (setf (region-width panel-br) w-br-width
		(region-width edit-window-br) w-br-width
		(region-height edit-window-br) (- w-br-height
						  (region-height panel-br))
		(bounding-region panel) panel-br
		(bounding-region edit-window) edit-window-br))))

    (setf (mapped window) t)))
		     
	  
(format t "~%To start this demo type: (demo:textedit-demo)~%")
