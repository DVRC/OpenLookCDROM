;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)defs.lisp	1.11 10/17/91


(in-package "LISPVIEW-TEST")


(defvar *test-dir* 
  (make-pathname :directory (pathname-directory *load-pathname*)))

(defparameter *standard-tests*
  '(test-image-array                         ;; interactive tests
    test-passive-keyboard-focus
    test-locally-active-keyboard-focus
    test-color-output
    test-color-allocation
    test-pseudo-colormaps
    test-color-images
    test-button-click-interests
    test-button-click-usage
    keyboard-interest-matches-too-much-bug

    panel-item-foreground-ignored-bug

    test-choice-items                        ;; non-interactive-tests
    test-default-colormap
    test-region-initargs
    test-regions

    read-image-pixmap-depth-bug
    char-metrics-invalid-type-bug
    panel-has-nil-depth-bug
    viewport-background-default-initarg-ignored-bug
    available-font-creation-bug
    non-existant-glyph-char-metrics-bug
    damage-interests-dropped-bug
    monochrome-black-white-bug
    exclusive-scrolling-list-value-bug
    popup-bounding-region-unmapped-bug
    closed-windows-bug
    window-children-initarg-bug
    panel-with-nil-parent-fails-bug
    change-parent-canvas-insert-bug))


(defparameter *window-classes* 
  '(opaque-canvas
    transparent-canvas
    window
    viewport
    panel
    popup-window
    base-window))



;;; Multiple-value return the value of  (apply fn args) and a list that 
;;; summarizes the resources consumed by applying fn to arg, i.e. a list 
;;; of the values returned by LCL:time1.  If (apply fn args) signals an error then
;;; just return the condition object.

(defun test-function (fn &rest args)
  (block test-error-handler
    (let ((x nil))
      (handler-case 
         (let ((resource-usage-list 
		(multiple-value-list (LCL:time1 (setf x (apply fn args))))))
	   (values x resource-usage-list))
		  
	 (error (condition) 
	   (return-from test-error-handler condition))))))



(defun add-resource-usage-lists (list1 list2)
  (if (and list1 list2)
      (mapcar #'(lambda (n1 n2)
		  (if (and n1 n2)
		      (+ n1 n2)
		    (or n1 n2)))
	      list1
	      list2)
    (or list1 list2)))

  
;;; (def-test name args
;;;    [property-list]
;;;    <body>)
;;
;;; Defines an exported function that multiple-value returns nil if the test 
;;; signals an error (t otherwise), and a property-list that summarizes the test:
;;; 
;;; (:name test function name
;;;  :n-tests-completed integer
;;;  :errors list of condition objects
;;;  :resource-usage list of values returned by LCL:time1 
;;;  :date (get-universal-time))
;;; 
;;; The 3rd argument to def-test is an optional property-list, if present it is 
;;; added to the symbol-plist of name under the indicator :test-description.
;;; The test-description property-list must be a constant and it's indicators 
;;; must be keywords - so the macroexpander can distinguish it from a normal 
;;; code body.  The test driver and analysis functions use these properties to 
;;; sort test functions according to the following indicators:
;;; 
;;;    :type {:bug, :test, :performance}, default :test 
;;     :interactive t/nil, default nil
;;;
;;; If the function actually contains many "sub"tests then the macros dependent-test 
;;; and independent-test sould be used to execute the subtest code body.  If the subtest 
;;; fails it should signal an error, independent-test will just record the error and 
;;; carry on, dependent-test will cause the entire function to return.
;;;
;;; (independent-test &body body)
;;; (dependent-test &body body)

(defmacro def-test (name args &body body)
  (let* ((errors-var (gensym))
	 (n-tests-completed-var (gensym))
	 (test-block-name (gensym))
	 (apply-test-fn (gensym))
	 (resource-usage-var (gensym))
	 (maybe-plist (car body))
	 (plist-p (keywordp (car maybe-plist))))

    `(progn 
       (export '(,name))

       (setf (get ',name :test-description)
	     ,(if plist-p `',maybe-plist `'(:type :test)))

       (defun ,name ,args 
	(let ((,errors-var nil)
	      (,n-tests-completed-var 0)
	      (,resource-usage-var nil))
	  (block ,test-block-name
	    (flet
	     ((,apply-test-fn (function dependent)
		 (multiple-value-bind (x resource-usage)
		     (test-function function)
		   (incf ,n-tests-completed-var)
		   (if (typep x 'LCL:condition)
		       (progn 
			 (push x ,errors-var)
			 (when dependent 
			   (return-from ,test-block-name nil)))
		     (setf ,resource-usage-var
			   (add-resource-usage-lists resource-usage ,resource-usage-var)))
		   x)))

	     (macrolet
	      ((independent-test (&body body)
		 `(,',apply-test-fn (function (lambda () ,@body)) nil))

	       (dependent-test (&body body)
		 `(,',apply-test-fn (function (lambda () ,@body)) t)))

	      (,apply-test-fn (function (lambda () ,@(if plist-p (cdr body) body))) t))))

	  (values (not ,errors-var)
		  (list :name ',name
			:errors ,errors-var
			:n-tests-completed ,n-tests-completed-var
			:resource-usage ,resource-usage-var
			:date (get-universal-time))))))))


(defmacro def-bug-test (name args description &body body)
  `(def-test ,name ,args (:type :bug ,@description) ,@body))



(defmacro with-paneled-base-window ((panel &rest base-window-initargs) &body body)
  (let ((base-window-var (gensym)))
    `(let* ((,base-window-var 
	     (apply #'make-instance 'base-window :status :initialized (list ,@base-window-initargs)))
	    (,panel 
	     (make-instance 'panel :status :initialized :parent ,base-window-var)))
       (unwind-protect
	   (progn
	     (setf (status ,base-window-var) :realized)
	     (setf (status ,panel) :realized)
	     ,@body)
	 (progn 
	   (map nil #'destroy (list ,base-window-var ,panel))
	   nil)))))

    
(defmacro check-accessor (name object value)
  `(and (eq (setf (,name ,object) ,value) ,value)
	(eq (,name ,object) ,value)))



;;; If evaluating the body DOESN'T signal an error than signal an error.

(defmacro check-error (&body body)
  (let ((flag (gensym)))
    `(unless (eq (block ,flag
			(handler-case (progn ,@body)
			  (error (c) 
			    (declare (ignore c))
			    (return-from ,flag ',flag))))
		 ',flag)
       (error "This form should have signalled an error: ~S" ',(cons 'progn body)))))



(defun universal-time-string (x)
  (multiple-value-bind (i minute hour date month year)
      (decode-universal-time x)
    (declare (ignore i))
    (format nil "~D:~D ~A ~D/~D/~D"
	    (if (<= hour 12) hour (mod hour 12))
	    minute
	    (cond ((< hour 12) "AM") ((= hour 12) "Noon") (t "PM"))
	    month
	    date
	    (mod year 100))))


(defun universal-time-difference (x1 x2)
  (multiple-value-bind (i0 m1 h1 d1)
      (decode-universal-time x1)
    (declare (ignore i0))
    (multiple-value-bind (i1 m2 h2 d2)
	(decode-universal-time x2)
      (declare (ignore i1))
      (truncate (- (+ m2 (* 60 (if (> d2 d1) (+ 24 h2) h2)))
		   (+ m1 (* 60 h1)))
		60))))


(defun print-test-summary (x)
  (format t ";;; LispView Test Results for ~A (~A), ~A ~A~%"
	  (getf x :machine-instance)
	  (getf x :machine-type)
	  (getf x :lisp-implementation-type)
	  (getf x :lisp-implementation-version))

  (multiple-value-bind (hours minutes)
      (universal-time-difference (getf x :start-time) (getf x :stop-time))
    (format t ";;; Test started: at ~A, total time: ~A~%"
	    (universal-time-string (getf x :start-time))
	    (if (= hours 0)
		(format nil "~D minute~:P" minutes)
	      (format nil "~D hour~:P, ~D minute~:P" hours minutes))))

  (let* ((results (getf x :results))
	 (n-tests 
	  (apply #'+ (mapcar #'(lambda (r) (getf r :n-tests-completed)) results)))
	 (n-errors 
	  (apply #'+ (mapcar #'(lambda (r) (length (getf r :errors))) results))))
    (format t ";;; ~D Failure~:P in ~D Test~:P, ~D% of the tests failed~%"
	    n-errors
	    n-tests
	    (if (> n-tests 0)
		(truncate (* 100 (/ (float n-errors) (float n-tests))))
	      0))
    (when (> n-errors 0)
      (format t ";;; Failed Tests:~%")
      (flet 
       ((symbol-to-string (x)
	  (if (eq (symbol-package x) (find-package "LISPVIEW-TEST"))
	      (format nil "LVT:~A" (symbol-name x))
	    (princ-to-string x))))

       (dolist (r results)
	 (let* ((errors (getf r :errors))
		(n-errors (length errors)))
	   (when (> n-errors 0)
	     (format t ";;;   ~A: ~{~<~%;;;   ~1:; ~A~>~^~}~%"
		     (symbol-to-string (getf r :name))
		     (mapcar #'princ-to-string 
			     (if (> n-errors 4) 
				 (append (subseq errors 0 4)
					 (list (format nil " ... ~D more" (- n-errors 4))))
			       errors))))))))))



(defun test-lispview (&key 
		        display-initargs
		        (verbose t)
			(output-file "lispview-test-summaries.lisp")
			(record-results nil)
			(interactive t)  ;; t/nil 
			(non-interactive t)  ;; t/nil 
			(types t) ;; list of test types or T for all tests
			(tests *standard-tests*))
  (flet 
   ((filter-test (fn)
      (let ((pl (get fn :test-description)))
	(when (and (if (getf pl :interactive) interactive non-interactive)
		   (or (eq types t) (member (getf pl :type) types)))
	  (list fn))))

    (run-test (fn)
      (if (fboundp fn)
	  (multiple-value-bind (passed summary)
	      (funcall fn)
	    (when verbose
	      (format t ";;; Test ~A ~A~%"
		      (string-downcase (getf summary :name))
		      (if passed
			  "OK"
			(let ((n0 (getf summary :n-tests-completed))
			      (n1 (length (getf summary :errors))))
			  (if (= 1 n0 n1)
			      "Failed"
			    (format nil "~D of ~D tests failed" n1 n0))))))
	    summary)
	(warn "Skipping test ~S" fn))))

   (unless (and (boundp '*default-display*) *default-display*)
     (apply #'make-instance 'display display-initargs))

   (check-features)

   (let* ((start-time (get-universal-time))
	  (pwd (pwd))
	  (results 
	   (progn
	     (unless (equal (truename *test-dir*) (truename pwd))
	       (warn "Temporarily changing working directory: ~A" (cd *test-dir*)))
	     (unwind-protect
		 (mapcar #'run-test (mapcan #'filter-test tests))
	       (cd pwd))))
	  (summary
	   (list :stop-time (get-universal-time)
	         :start-time start-time
		 :machine-instance (machine-instance)
		 :machine-type (machine-type)
		 :lisp-implementation-type (lisp-implementation-type)
		 :lisp-implementation-version (lisp-implementation-version)
		 :features *features*
		 :results results)))

     (when record-results
       (with-open-file (s output-file 
			  :direction :output
			  :if-exists :append
			  :if-does-not-exist :create)
	 (pprint summary s)))

     (when verbose
       (format t "~2%")
       (print-test-summary summary)
       (format t "~2%"))

     summary)))
