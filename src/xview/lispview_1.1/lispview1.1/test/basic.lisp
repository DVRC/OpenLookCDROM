;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)basic.lisp	1.3 10/17/91


(in-package "LISPVIEW-TEST")


(defun check-features ()
  (unless (member :lispview *features*)
    (warn ":lispview isn't a member of *features*"))
  (when (member :solo *features*)
    (warn "obsolete feature, :solo, is still a member of *features*")))




(defun check-region-components (region left top width height)
  (unless (region-p region)
    (error "~S isn't a region (doesn't satisfy region-p)" region))

  (unless (and (= (region-left region) left)
	       (= (region-top region) top)
	       (= (region-width region) width)
	       (= (region-height region) height)
	       (= (region-right region) (+ left width))
	       (= (region-bottom region) (+ top height)))
    (error "The left,top,width,height dimensions of ~S aren't ~S ~S ~S ~S"
	   region left top width height)))



(def-test test-region-initargs  ()
  (let ((r (make-region)))
    (dependent-test 
     (region-p r)

     (independent-test
      (check-region-components r 0 0 0 0))

     (independent-test
      (setf r (make-region :left nil :top nil :width nil :height nil :right nil :bottom nil))
      (check-region-components r 0 0 0 0))

     (independent-test
      (setf r (make-region :left 10 :top 33))
      (check-region-components r 10 33 0 0))

     (independent-test
      (setf r (make-region :width 100 :height 1))
      (check-region-components r 0 0 100 1))

     (independent-test
      (setf r (make-region :right 20 :bottom 13))
      (check-region-components r 20 13 0 0))

     (independent-test
      (setf r (make-region :left -100 :top -100 :right -10 :bottom -10))
      (check-region-components r -100 -100 90 90))

     (independent-test
      (setf r (make-region :width -1))
      (check-region-components r 0 0 -1 0))

     (independent-test
      (setf r (make-region :height -1))
      (check-region-components r 0 0 0 -1))

     (independent-test
      (check-error (setf r (make-region :left .1)))
      (check-error (setf r (make-region :top  .1)))
      (check-error (setf r (make-region :right .1)))   
      (check-error (setf r (make-region :bottom .2)))   
      (check-error (setf r (make-region :width .2)))
      (check-error (setf r (make-region :height .2)))))))


(def-test test-regions ()
  (let ((r (make-region :width 100 :height 30)))

    (macrolet 
     ((check-setf-region-edge (setf-form &rest tests)
       `(independent-test
	  ,setf-form
	  (unless (and ,@tests)
	    (error "~S failed for ~S, the following assertions are no longer true:~%~
		    ~;;; ~{~<~%;;; ~1:; ~A~>~^~}"
		   ',setf-form
		   r
		   ',tests)))))

      (check-setf-region-edge                  ;; Testing :move region setfs
       (setf (region-left r :move) 111)
       (= (region-left r) 111)
       (= (region-width r) 100)) 

      (check-setf-region-edge 
       (setf (region-right r :move) 333)
       (= (region-right r) 333)
       (= (region-width r) 100))


      (check-setf-region-edge 
       (setf (region-top r :move) 222)
       (= (region-top r) 222)
       (= (region-height r) 30))

      (check-setf-region-edge 
       (setf (region-bottom r :move) 444)
       (= (region-bottom r) 444)
       (= (region-height r) 30))

      (check-setf-region-edge                  ;;; Checking setf :stretch setfs
       (setf (region-left r :stretch) 100)
       (= (region-right r) 333))

      (check-setf-region-edge 
       (setf (region-right r :stretch) 999)
       (= (region-left r) 100))

      (check-setf-region-edge
       (setf (region-top r :stretch) 200)
       (= (region-bottom r) 444))

      (check-setf-region-edge
       (setf (region-bottom r :stretch) 888)
       (= (region-top r) 200)))

    (independent-test
     (unless (and (region-contains-xy-p r 100 200)
		  (not (region-contains-xy-p r 99 201)))
       (error "region-contains-xy-p failed")))

    (macrolet
     ((mr-ltrb (left top right bottom)
	`(make-region :left ,left :top ,top :right ,right :bottom ,bottom))
      (mr-ltwh (left top width height)
	`(make-region :left ,left :top ,top :width ,width :height ,height)))

     (independent-test
      (unless 
	  (and (region-contains-region-p r (mr-ltrb 100 200 999 888))
	       (region-contains-region-p r (mr-ltwh 101 201 9 8))
	       (not (region-contains-region-p r (mr-ltrb 10 20 999 888))))
	(error "region-contains-region-p failed")))

     (independent-test
      (unless (and 
	       (equalp r (region-bounding-region r))
	       (let ((r1 (mr-ltwh 10 11 100 100))
		     (r2 (mr-ltrb 20 5 200 50))
		     (r3 (make-region :left 5 :top 30 :width 50 :bottom 150)))
		 (equalp (region-bounding-region r1 r2 r3) (mr-ltrb 5 5 200 150))))
	(error "region-bounding-region failed")))

     (independent-test
      (unless (and 
	       (equalp (region-intersection r) r)
	       (equalp (region-intersection (mr-ltrb 5 5 100 110) (mr-ltrb 10 11 110 115))
		       (mr-ltrb 10 11 100 110))
	       (equalp (region-intersection (mr-ltrb 5 5 100 110) (mr-ltrb 10 11 110 115))
		       (mr-ltrb 10 11 100 110)))
	(error "region-intersection failed"))))))




(defun check-panel-item-state (item)
  (let ((initial-state (state item)))
    (unless (typep initial-state 'item-state)
      (error "Value of (state ~S), ~S, isn't a legal panel item state"
	     item initial-state))

    (unless (and (check-accessor state item :active)
		 (check-accessor state item :inactive)
		 (check-accessor state item initial-state))
     (error "Panel item state accessor failed for ~S" item))))


(defun check-panel-item-mapped (item)
  (let ((initial-value (mapped item)))
    (unless (and (check-accessor mapped item :mapped)
		 (check-accessor mapped item nil)
		 (check-accessor mapped item initial-value))
      (error "Panel item mapped accessor failed for ~S" item))))


(def-test test-choice-items ()
  (with-paneled-base-window (p :label "Choice Item Tests")
    (let* ((choice-item-classes
	   '(exclusive-setting
	     abbreviated-exclusive-setting
	     check-box
	     non-exclusive-setting
	     abbreviated-exclusive-setting
	     exclusive-scrolling-list
	     non-exclusive-scrolling-list))
	  (initargs
	   '(:label "Multiple Choice Test"
	     :status :initialized)))

     (labels
      ((check-choices (item choices)
	 (independent-test 
	   (let ((x (choices item)))
	     (unless (equal x choices)
	       (error "Value of (choices ~S) ~S should have been equal to ~S" item x choices))
	     (check-accessor choices item '(one two free four))
	     (check-accessor choices item x))))

       (make-choice-item (class choices)
         (let ((make-instance-args (list* class :choices choices :parent p initargs)))
	   (independent-test 
	     (let ((x (apply #'make-instance make-instance-args)))
	       (check-choices x choices)
	       (setf (status x) :realized)
	       (check-choices x choices)
	       x))))

       (zero-choices (class) (make-choice-item class nil))

       (one-choice (class) (make-choice-item class '(1)))

       (seven-choices (class) (make-choice-item class '(none two 3 four cinco six seven))))


      (dolist (fn (list #'zero-choices #'one-choice #'seven-choices) T)
	(let ((items (mapcar fn choice-item-classes)))
	  (dolist (item items)
	    (unless (typep item 'condition)
	      (independent-test (check-panel-item-state item))
	      (independent-test (check-panel-item-mapped item))
	      (independent-test (destroy item))))))))))
     

