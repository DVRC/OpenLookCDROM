;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)input.lisp	3.9 10/11/91


(in-package "LISPVIEW")


;;; Return the cross product of a list of lists of "tokens".  For 
;;; example (cross-product '((a b) (c d))) => ((a c) (a d) (b c) (b d)).

(defun cross-product (lists)
  (if (cdr lists)
      (let ((result nil))
	(dolist (y (cross-product (cdr lists)) result)
	  (dolist (x (car lists))
	    (push (cons x y) result))))
    (mapcar 'list (car lists))))


(defun and-or-clause-p (x) 
  (and (consp x) (member (car x) '(and or) :test #'eq)))


;;; Replace redundant top level clauses with their arguments, remove empty 
;;; clauses, and replace singleton clauses by their argument. For example: 
;;; (OR a b (OR c d) (OR) (AND) (AND e)) => (OR a b c d e).  

(defun simplify-expr (expr)
  (if (and-or-clause-p expr)
      (cond
       ((or (null expr) (null (cdr expr)))   ;; (OR), (AND) => nil
	nil)
       ((null (cddr expr))                   ;; (AND x), (OR x) => x
	(simplify-expr (cadr expr)))
       (t
	(let* ((op (car expr))          ;; simplify subexpressions and
	       (simplified-expr         ;; remove redundant clauses
		(mapcan #'(lambda (se)
			    (let ((expr (simplify-expr se)))
			      (cond 
			       ((null expr) nil)
			       ((and (listp expr) (eq (car expr) op)) (cdr expr))
			       (t (list expr)))))
			(cdr expr))))
	  (if simplified-expr
	      (cons op simplified-expr)))))
    expr))



;;; Given an expression with this syntax:
;;;
;;;     expr := atom | (AND expr*) | (OR expr*)
;;;
;;; For example: (AND :meta 
;;;                   (OR :shift :control) 
;;;                   (OR :left :middle))
;;; 
;;; Convert the expression to an equivalent one with this syntax:
;;;
;;;     expr := (OR (AND keyword+)+) 
;;;
;;; For example: (OR (AND :meta :shift :left)
;;;                  (AND :meta :shift :middle)
;;;                  (AND :meta :control :left)
;;;                  (AND :meta :control :middle))

(defun canonicalize-expr (expr)
  (cond 
    ((not (and-or-clause-p expr))
     (list 'OR (list 'AND expr)))
    ((eq (car expr) 'OR)
     (cons 'OR (mapcan #'(lambda (e)
			   (cdr (canonicalize-expr e)))
		       (cdr expr))))
    ((eq (car expr) 'AND)
     (let* ((or-clauses nil)
	    (and-clause 
	      (delete-if #'(lambda (sc)
			     (if (and (consp sc) (eq (car sc) 'OR))
				 (push (cdr (canonicalize-expr (copy-list sc)))
				       or-clauses)))
			 expr)))
       (cond
	 (or-clauses
	   (cons 'OR
		 (mapcar #'(lambda (x)
			     (let ((expr (simplify-expr (append and-clause x))))
			       (if (keywordp expr) (list 'and expr) expr)))
			 (cross-product or-clauses))))
	 ((cdr and-clause)
	  (list 'OR and-clause)))))))


;;; Return the event-spec expression in "canonical" form.
;;; Canonical form just means that the modifiers and button
;;; names (not the button action) are transformed into expression like this:
;;;
;;; (OR (AND ...) (AND ...) ...).
;;;
;;; And any button or modifier names that correspond to synonyms listed in the
;;; alists *button-name-synonyms* or *modifier-name-synonyms* have been 
;;; translated.
;;;
;;; For example applying parse-mouse-event-spec to 
;;;   '((:control (or :shift :meta)) ((or :left :right) :down)))
;;; yields:
;;;    ((or (and :control :shift) (and :control meta))
;;;     ((or (and :button0) (:and :button2)) :down))

(defun parse-mouse-event-spec (spec)
  (let ((modifiers (nth 0 spec))
	(action (nth 1 spec)))
    (flet ((xlate-modifier-name (name)
	      (or (cdr (assoc name *modifier-name-synonyms* :test #'eq))
		  name)))
      (list
	(typecase modifiers
	  (null '(or (and nil)))
	  (keyword `(or (and ,(xlate-modifier-name modifiers))))
	  (t
	   (labels
	    ((insert-and (expr)
	       (if (consp expr)
		   (if (or (member (nth 0 expr) '(and or) :test #'eq)
			   (member (nth 1 expr) 
				   '(:up :down (or :up :down) (or :down :up))
				   :test #'equal))
		       (mapcar #'insert-and expr)
		     (cons 'and (mapcar #'insert-and expr)))
		 (xlate-modifier-name expr))))
	    (canonicalize-expr (insert-and modifiers)))))

	(if (typep action 'mouse-action)
	    action
	  (labels 
	    ((xlate-button-names (expr)
	       (cond
		((and (symbolp expr) 
		      (not (member expr '(and or :up :down) :test #'eq)))
		 (or (cdr (assoc expr *button-name-synonyms* :test #'eq))
		     expr))
		((consp expr)
		 (mapcar #'xlate-button-names expr))
		(t 
		 expr))))
	    (list (canonicalize-expr (xlate-button-names (nth 0 action)))
		  (nth 1 action))))))))
	

;;; Non  nil if the spec isn't a mouse-event-spec according to the documented
;;; syntax.  This test recursively descends the modifiers and button-name 
;;; expressions, circularities will undoubtedly cause it to collapse.

(defun mouse-event-spec-p (spec)
  (labels 
   ((modifiers-expr-p (expr)
      (if (consp expr)
	  (every #'(lambda (x) 
		     (or (typep x 'modifier)
			 (modifiers-expr-p x)))
		 (if (member (car expr) '(and or) :test #'eq)
		     (cdr expr)
		   expr))
	(null expr)))
    
    (button-expr-p (expr)
      (if (consp expr)
	  (and (member (car expr) '(and or) :test #'eq)
	       (every #'(lambda (x) 
			  (or (typep x 'button-name)
			      (button-expr-p x)))
		      (cdr expr)))
	(typep expr 'button-name))))

   (and (consp spec)
	(= (length spec) 2)
	(modifiers-expr-p (nth 0 spec))
	(let ((action (nth 1 spec)))
	  (or (typep action 'mouse-action)
	      (and (consp action)
		   (= (length action) 2)
		   (button-expr-p (nth 0 action))
		   (typep (nth 1 action) 'button-action)))))))


		  

(defmethod initialize-instance :after ((i mouse-interest) 
				       &key 
				         event-spec
				       &allow-other-keys)
  (check-type event-spec (satisfies mouse-event-spec-p))
  (setf (slot-value i 'parsed-event-spec) (parse-mouse-event-spec event-spec)))


(defmethod initialize-instance :after ((i keyboard-interest) 
				       &key 
				         event-spec
				       &allow-other-keys)
  (check-type event-spec (satisfies keyboard-event-spec-p)))


;;; Destructively insert object in list at the position specified by relation 
;;; and relative.  If relation is :at then relative must be the integer
;;; position of object in the new list.  If relation is :before or :after
;;; then relative must be eq to an element of the current list or NIL.
;;; Note that :before NIL means object belongs at the end of the list, 
;;; :after NIL means the object belongs at the front.

(defun list-insert (object relation relative list)
  (ecase relation
    (:at
     (check-type relative (integer 0 *))
     (if (= relative 0)
	 (cons object list)
       (let ((ip (nthcdr (1- relative) list)))
	 (if ip
	     (progn (push object (cdr ip)) list)
	   (error "~S isn't a legal insertion position for ~S" relative list)))))
    (:before
     (cond 
      ((null relative)
       (nconc list (list object)))
      ((eq (car list) relative)
       (cons object list))
      (t
	(do ((ip list (cdr ip)))
	    ((or (null (cdr ip))
		 (eq relative (cadr ip)))
	     (if ip
		 (progn (push object (cdr ip)) list)
	       (error "Couldn't find an element of ~S eq to ~S" list relative)))))))
    (:after
     (if (null relative)
	 (cons object list)
       (let ((ip (member relative list :test #'eq)))
	 (if ip
	     (progn (push object (cdr ip)) list)
	   (error "Couldn't find an element of ~S eq to ~S" list relative)))))))


(defmethod insert ((i interest) relation relative canvas)
  (check-arglist (relation insert-relation) (canvas canvas))
  (with-slots (interests) canvas
    (dd-insert-interest (platform canvas) i relation relative canvas)
    (setf interests (list-insert i relation relative interests)))
  canvas)


(defmethod withdraw ((i interest) canvas)
  (check-arglist (canvas canvas))
  (with-slots (interests) canvas
    (dd-withdraw-interest (platform canvas) i  canvas)
    (setf interests (delete i interests :test #'eq)))
  canvas)


(defmethod interests (object)
  (copy-list (slot-value object 'interests)))

(defmethod (setf interests) (interests object)
  (let* ((old-interests (slot-value object 'interests))
	 (new-interests (coerce interests 'list))
	 (common (intersection new-interests old-interests)))
    (dolist (i (set-difference old-interests common))
      (withdraw i object))
    (let ((added-interests (set-difference new-interests common))
	  (after nil))
      (dolist (i new-interests)
	(when (member i added-interests :test #'eq)
	  (insert i :after after object))
	(setf after i))))
  interests)
    



(defmacro incf-queue-index (index buffer)
  `(if (= ,index (1- (length ,buffer)))
       (setf ,index 0)
     (incf ,index)))

(defmethod queue-full-p ((q queue))
  (declare (type-reduce number fixnum) (optimize (speed 3) (safety 0)))
  (/= (slot-value q 'in) (slot-value q 'out)))

(defmethod queue-get ((q queue))
  (declare (type-reduce number fixnum) (optimize (speed 3) (safety 0)))
  (with-slots (in out buffer) q
    (if (/= in out)
	(prog1
	    (svref buffer out)
	  (incf-queue-index out buffer)))))

(defmethod queue-put ((q queue) value)
  (declare (type-reduce number fixnum) (optimize (speed 3) (safety 0)))
  (with-slots (in out buffer) q
    (prog1
	(setf (svref buffer in) value)
      (incf-queue-index in buffer))))

(defmethod queue-peek ((q queue))
  (declare (type-reduce number fixnum) (optimize (speed 3) (safety 0)))
  (with-slots (in out buffer) q
    (if (/= in out)
	(svref buffer out))))




(defmethod deliver-event (object interest event)
  (setf (event-object event) object
	(event-interest event) interest)
  (queue-put (event-dispatch-queue object) event))

(defmethod match-event (object event)
  (declare (ignore object event)))

(defun send-event (object event)
  (let ((interest (match-event object event)))
    (when interest
      (deliver-event object interest event))))

(defmethod receive-event (canvas interest event)
  (declare (ignore canvas interest event)))


(defun event-dispatch-loop ()
  (let ((process *current-process*))
    (loop
      (process-wait "Input Wait" 
		    #'(lambda ()
			(let ((q (process-event-queue process)))
			  (and q (queue-full-p q)))))
      (let ((q (process-event-queue process)))
	(loop
	  (if (and q (queue-full-p q))
	      (let ((event (queue-get q)))
		(when (typep event 'mouse-moved-event)
		  (loop 
		   (if (typep (queue-peek q) 'mouse-moved-event)
		       (setq event (queue-get q))
		     (return))))
		(receive-event (event-object event) (event-interest event) event))
	    (return)))))))



(defmethod mouse-state (display &optional relative-to-canvas)
  (dd-mouse-state (platform display) display relative-to-canvas))

(defun mouse-event-gesture (event)
  (dd-mouse-event-gesture (platform (event-object event)) event))

(defmethod warp-mouse ((relative-to-canvas canvas) x y)
  (check-arglist (x integer) (y integer))
  (dd-warp-mouse (platform relative-to-canvas) relative-to-canvas x y))


(def-solo-accessor KEYBOARD-FOCUS display 
  :type (or null canvas)
  :driver dd-display-keyboard-focus)

(def-solo-accessor KEYBOARD-FOCUS canvas 
  :type (or null canvas)
  :driver dd-canvas-keyboard-focus)


(def-solo-reader VIRTUAL-KEYBOARD-FOCUS display
  :type (or null canvas)
  :driver dd-display-virtual-keyboard-focus)

(def-solo-reader VIRTUAL-KEYBOARD-FOCUS canvas
  :type (or null canvas)
  :driver dd-canvas-virtual-keyboard-focus)


(defun keyboard-event-char (event)
  (dd-keyboard-event-char (platform (event-object event)) event))

(defun keyboard-event-action (event)
  (dd-keyboard-event-action (platform (event-object event)) event))

(defun keyboard-event-modifiers (event)
  (dd-keyboard-event-modifiers (platform (event-object event)) event))


;;; LISPVIEW IPC[sic] FACILITY - cperdue

;;; To use this facility pick one or more functions that will do the work
;;; when Lisp receives a message.  For each, do (setf (valid-ipc-function-p
;;; fn) t).  (Fn must be a symbol.)
;;;
;;; To send a message, pick a property of LispView's default display's root
;;; window such that the property name begins with "LispView-IPC-input".
;;; Set the value of the property to a string.  The string must contain a
;;; readable Lisp s-expression that is a list.  The CAR of the list must be
;;; one of the functions you have set up as valid, and the CDR must be a
;;; list of arguments to apply the function to.  LispView will dispatch to
;;; that function, passing it those arguments.
;;;
;;; This is really not the way to do IPC for a variety of reasons ranging
;;; from esthetics to security and synchronization issues, functionality
;;; (for example the requestors are not identified) state of the actual
;;; implementation, and probably performance, but it exists.  Use of READ on
;;; the Lisp side is a security hole because of #.  until this code can be
;;; modified to use the proposed ANSI feature to turn off #. while reading.

(defvar *valid-ipc-functions* '(eval))

(defun valid-ipc-function-p (fn)
  (member fn *valid-ipc-functions* :test 'eq))

(defun .set-valid-ipc-function-p (fn value)
  (if value
      (pushnew fn *valid-ipc-functions*)
    (setf *valid-ipc-functions* (delete fn *valid-ipc-functions* :test 'eq))))

(defsetf valid-ipc-function-p .set-valid-ipc-function-p)

(defun valid-ipc-functions ()
  *valid-ipc-functions*)


;;; Handler for LispView IPC events.  Gets the message from the
;;; event, which will be a string, reads an s-expression from it, and
;;; APPLYs the CAR to the CDR while being pretty careful about error
;;; checking. 
;;;
;;; Interesting consequences could result if multiple X clients set
;;; themselves up to receive this kind of events.  I guess each message
;;; contained in a property would be retrieved by an arbitrary interested
;;; client. /csp

(defmethod receive-event (root-canvas interest (event lispview-ipc-event))
  (declare (ignore root-canvas interest))
  (block receive
   (let ((msg
	  (handler-case
	    (read-from-string (lispview-ipc-event-message event))
	    (serious-condition (c)
	      (warn "~&LispView IPC event handler could not read message:~%~A~&" c)
	      (return-from receive)))))
     (if (valid-ipc-function-p (car msg))
	 (handler-case (apply (car msg) (cdr msg))
	   (serious-condition (c)
	     (warn "~&LispView IPC event handler~%~
                   attempt to apply function ~S to list of args ~S failed:~%~A~&"
		   (car msg) (cdr msg) c)))))))

