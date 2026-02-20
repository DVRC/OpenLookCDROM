;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)mp.lisp	3.3 10/11/91



(in-package "MULTIPROCESSING" :use '(lisp) :nicknames '("MP"))

;;;
;;; Multiprocessing Interface
;;;
;;; This file defines a complete lightweight Multiprocessing interface (MP) based on 
;;; the Lucid multitasking system.  This is essentially to isolate the MP symbols
;;; from the rest of the Lucid-Common-Lisp package and to make it easy for us to 
;;; shadow the LCL definitions.


;;; The 2 lexicals defined below, lcl-exports and mp-exports, define the symbols 
;;; that are just imported from LCL and exported from MP and the symbols that
;;; are defined in the MP package respectively.

(eval-when (eval compile load)
 (let ((lcl-exports
	'(LCL:activate-process 
	  LCL:*all-processes* 
	  LCL:check-stack-remaining
	  LCL:*initial-io*
	  LCL:*current-process* 
	  LCL:deactivate-process 
	  LCL:get-stack-remaining
	  LCL:*inhibit-scheduling* 
	  LCL:*initial-process* 
	  LCL:interrupt-process 
	  LCL:*keyboard-interrupt-process*
	  LCL:kill-process 
	  LCL:let-globally 
	  LCL:make-process 
	  LCL:process		
	  LCL:process-active-p 
	  LCL:process-allow-schedule 
	  LCL:process-in-the-debugger-p
	  LCL:process-initial-arguments
	  LCL:process-initial-function
	  LCL:process-interruptions
	  LCL:process-alive-p 
	  LCL:process-lock
	  LCL:process-name
	  LCL:processp
	  LCL:process-plist
	  LCL:process-state
	  LCL:process-unlock
	  LCL:process-wait 
	  LCL:process-wait-arguments
	  LCL:process-wait-forever 
	  LCL:process-wait-function
	  LCL:process-wait-with-timeout 
	  LCL:process-whostate
	  LCL:*quitting-lisp*
	  LCL:restart-process 
	  LCL:symbol-dynamically-boundp 
	  LCL:symbol-global-boundp 
	  LCL:symbol-global-value 
	  LCL:symbol-process-boundp 
	  LCL:symbol-process-value 
	  LCL:using-initial-io
	  LCL:with-interruptions-allowed 
	  LCL:with-interruptions-inhibited 
	  LCL:with-keyboard-interrupt-process
	  LCL:with-process-lock
	  LCL:with-scheduling-allowed 
	  LCL:with-scheduling-inhibited))
       (mp-exports
	'()))

   (import (set-difference lcl-exports mp-exports :key #'symbol-name :test #'string=))

   (export (mapcar #'intern 
		   (mapcar #'symbol-name 
			   (union lcl-exports mp-exports :key #'symbol-name :test #'string=))))))


