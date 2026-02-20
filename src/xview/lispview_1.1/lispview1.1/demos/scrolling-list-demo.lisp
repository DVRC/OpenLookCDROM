;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;; USAGE: To start the demo, type: (make-instance 'demo:tree-fractals)


(in-package :demo :use '(lisp clos lispview))

(export '(scrolling-list-demo))

(defun scrolling-list-demo (&key
			    (directory "/usr/include/images")
			    (extension "icon")
			    (max 25))
  (let ((files (directory (format nil "~A/*.~A" directory extension)))
	base-window choices choice-height panel scrolling-list)
    (if files
	(progn
	  (setq base-window
		(make-instance 'base-window :label "Images"
		      :icon (make-instance 'icon 
			     :background (lv:find-color :name "lightsteelblue")
			     :label (if (probe-file "lispview-app.icon")
					(list "Image List"
					 (make-instance 'image 
					      :filename "lispview-app.icon"))
					"Image List"))
		      :left-footer "")
		choices
		(mapcar #'(lambda (filename)
			    (cons (setf (left-footer base-window) 
					(namestring filename))
				  (make-instance 'image :filename filename)))
			(subseq files 0 (min max (length files))))
		choice-height
		(apply #'max (mapcar #'region-height 
				     (mapcar #'bounding-region 
					     (mapcar #'cdr choices))))
		panel
		(make-instance 'panel :parent base-window)

		scrolling-list 
		(make-instance 'exclusive-scrolling-list
			       :parent panel
			       :choices choices
			       :read-only t
			       :choice-height (+ 6 choice-height)
			       :choice-label-callback
			       #'(lambda (choice)
				   (values (car choice) (cdr choice)))))

	  (defmethod (setf status) ((value (eql :destroyed)) 
				    (w (eql base-window)))
	    (map nil #'destroy (mapcar #'cdr choices)))

	  (let ((bw-br (bounding-region base-window))
		(sl-br (bounding-region scrolling-list)))
	    (setf (region-width bw-br) (+ 4 (region-width sl-br))
		  (region-height bw-br) (+ 4 (region-height sl-br))
		  (bounding-region base-window) bw-br
		  (left-footer base-window) ""))
	  (format t "~D choice~:P listed." (length choices)))
	(warn "No files with :extension ~S found in :directory ~A"
	      extension directory))))
	   

(format t "
;;; To start this demo, type: (demo:scrolling-list-demo)
;;; or (demo:scrolling-list-demo :directory \"/usr/yourdir\" :extension \"xbm\")~%~%")
