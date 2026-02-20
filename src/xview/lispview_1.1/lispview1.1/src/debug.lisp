;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.


(in-package :SOLO)


(LCL:defadvice (LUCID::enter-debugger nosched) (&rest args)
   (LCL:with-scheduling-inhibited
     (LCL:apply-advice-continue args)))



(defun jobs (&optional (max-name-width 40))
  "Print a display of all processes."
  (let ((width (min 
		 (apply 'max (mapcar 'length 
				     (mapcar 'LCL:process-name 
					     LCL:*all-processes*)))
		 max-name-width))
	(n 0))
    (dolist (p LCL:*all-processes* (values))
      (let ((process-name (LCL:process-name p)))
	(format T "~& [~D]~5T ~A ~A ~8T~? ~A"
		(prog1 n (incf n))
		(cond 
		  ((eql p LCL:*current-process*) 
		   "+")
		  ((eql (LCL:process-state p) :active)
		   (if (equal (LCL:process-whostate p) "Run") " " "-"))
		  ((eql (LCL:process-state p) :inactive)
		   "=")
		  (t 
		    (format nil "<~S>" (LCL:process-state p))))
		(cond ((LUCID::process-interruptions p)
		       "I")
		      (t 
			" "))
		(format nil "~~~DA" (1+ width))
		(list
		  (if (> (length process-name) width)
		      (format nil "~A..." (subseq process-name 0 (- width 3)))
		    process-name))
		(LCL:process-whostate p))))))


(defun debug (n)
  (let ((p (elt LCL:*all-processes* n)))
    (if p
	(when (y-or-n-p "Break process ~A" (LCL:process-name p))
	  (LCL:interrupt-process p 'break "Debugging"))
      (warn "~D does not correspond to a known process" n))))


(defun ikill ()
  (let ((all-processes (remove-if #'(lambda (p)
				      (member (LCL:process-name p)
					      '("Initial" "Wholine" "Idle")
					      :test 'string=))
				  LCL:*all-processes*))
	(LCL:*print-structure* t))
    (LCL:with-scheduling-inhibited;
      (dolist (p (copy-list all-processes))
	(when (y-or-n-p "Kill ~S?" p)
	  (LCL:kill-process p)
	  (delete p all-processes)))) ))


