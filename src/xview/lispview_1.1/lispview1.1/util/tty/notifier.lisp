;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)notifier.lisp	1.3 10/21/91

(in-package "LISPVIEW")

;;; Support for polling file descriptors in the XView notifier process, especially 
;;; the X11 socket, with select.  The current list of file descriptors we're waiting
;;; for input on is returned by xview-notifier-fds, change with setf.  The unix select
;;; function is called xview-notifier-select which returns a list of the file descriptors
;;; that are ready to be read.

(defstruct xview-notifier-fd
  (fd 0 :type fixnum)
  (set-elt 0 :type fixnum)
  (set-bit 0 :type fixnum))

(let* ((nullfds (make-foreign-pointer :type '(:pointer fd-set) :address 0))
       (readfds (make-fd-set))
       (bits (fd-set-fds-bits readfds))
       (notifier-fds nil))
  (defun notifier-fds () notifier-fds)
  
  (defmethod XVIEW-NOTIFIER-FDS ()
    (mapcar #'xview-notifier-fd-fd notifier-fds))

  (defmethod (SETF XVIEW-NOTIFIER-FDS) (fds)
    (let* ((new-readfds (make-fd-set))
	   (new-bits (fd-set-fds-bits new-readfds))
	   (new-notifier-fds nil))
      (dolist (fd fds)
	(push (make-xview-notifier-fd
	       :fd fd
	       :set-elt (truncate fd n-fd-bits)
	       :set-bit (expt 2 (mod fd n-fd-bits)))
	      new-notifier-fds))

      (dotimes (i n-fd-set-ints)             ;; FD_ZERO(new-readfds)
       (setf (foreign-aref new-bits i) 0))

      (setf readfds new-readfds
	    bits new-bits
	    notifier-fds new-notifier-fds))
    fds)

  (defun XVIEW-NOTIFIER-SELECT (timeout)
    (declare (type-reduce number fixnum))
    (when notifier-fds
      (dolist (x notifier-fds)
	(let* ((set-elt (xview-notifier-fd-set-elt x))
	       (value (foreign-aref bits set-elt)))
	  (setf (foreign-aref bits set-elt) (logior value (xview-notifier-fd-set-bit x)))))

      (if (> (select n-fd-set-ints readfds nullfds nullfds timeout) 0)
	  (let ((active-fds nil))
	    (dolist (x notifier-fds active-fds)
	      (let ((bit (xview-notifier-fd-set-bit x))
		    (elt (xview-notifier-fd-set-elt x)))
		(when (= bit (logand bit (foreign-aref bits elt)))
		  (push (xview-notifier-fd-fd x) active-fds)))))
	NIL))))

		

(defvar *active-fd-handlers* nil)

(defmethod active-fd-handler (fd)
  (let ((x (cdr (assoc fd *active-fd-handlers* :test #'=))))
    (when x 
      (list (car x) (cdr x)))))

(defmethod (setf active-fd-handler) (object-interest fd)
  (unless (and (listp object-interest) (= (length object-interest) 2))
    (error "value must be a list: (target-object interest)"))
  (push (cons fd (cons (car object-interest) (cadr object-interest)))
	*active-fd-handlers*)
  object-interest)

(defun remove-active-fd-handler (fd object interest)
  (let ((target (cons fd (cons object interest))))
    (setf *active-fd-handlers*
	  (remove target *active-fd-handlers* :test #'equal))))

(defun xview-deliver-active-fd-events (active-fds x11-connection-fd)
  (declare (type-reduce number fixnum))
  (dolist (fd active-fds)
    (unless (= fd x11-connection-fd)
      (let ((target (dolist (x *active-fd-handlers*)
		      (when (= (car x) fd) 
			(return (cdr x))))))
	(when target
	  (deliver-event (car target) (cdr target) fd))))))
	      


;;; Solo Global Input Processs - XView Notifier Interface
;;;
;;; The notifier interface is just a loop that waits until some input is 
;;; available on the X server connection and then calls XV:notify-dispatch
;;; repeatedly until the input has been exhausted.

(defconstant xview-notifier-waiting-whostate "Waiting for Input")

(defvar *xview-notifier-timeout* 100000) ;; .1 seconds

(defun xview-notifier-loop (dsp)
  (declare (type-reduce number fixnum))
  (let ((fd (X11:XConnectionNumber dsp))
	(timeout (XV:make-timeval :tv-sec 0 :tv-usec *xview-notifier-timeout*))
	(active-fds nil))
    (push fd (xview-notifier-fds))
    (X11:XSync dsp 0)

    (flet 
     ((input-pending-p ()
	(or (/= 0 (logand XV:ndet-condition-change (foreign-value XV:*ndet-flags*)))
	    (setf active-fds (xview-notifier-select timeout)))))
     (loop
       (process-wait xview-notifier-waiting-whostate #'input-pending-p)
       (loop 
	(XV:with-xview-lock (XV:notify-dispatch))
	(when *xview-notifier-shouldnt-wait*
	  (setq *xview-notifier-shouldnt-wait* nil)
	  (process-allow-schedule))

	(when (and active-fds (or (cdr active-fds) (/= (car active-fds) fd)))
	  (xview-deliver-active-fd-events active-fds fd))

	 (unless (input-pending-p)
	   (return)))))))




