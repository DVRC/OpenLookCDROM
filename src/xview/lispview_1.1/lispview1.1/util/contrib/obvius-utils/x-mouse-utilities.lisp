;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  File: x-mouse-utilities.lisp
;;;  Author: Eero Simoncelli
;;;  Description:  Mouse documentation.  Generic dragging mechanism.
;;;  Creation Date: 11/90
;;;  ----------------------------------------------------------------
;;;    Object-Based Vision and Image Understanding System (OBVIUS),
;;;      Copyright 1988, Vision Science Group,  Media Laboratory,  
;;;              Massachusetts Institute of Technology.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package 'obvius)

(export '(make-drag-interests))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Mechanism for providing dynamic display of mouse documentation
;;;; (as with Lisp Machines).

;;;; NOTE: Requires lispview patches in x-bucky.lisp (definition of
;;;; match-event-spec) Also, user must provide a display-mouse-documentation
;;;; function.

;;; Mouse interests that inherit from this class will have mouse documentation!
(defclass documented-mouse-interest (lispview:mouse-interest)
  ((doc-string :initform "Undocumented" :initarg :doc-string :accessor doc-string)))

(defun compute-mouse-documentation (pane event)
  (multiple-value-bind (x y modifiers) (lispview::mouse-state (lispview::display pane))
    (let* ((l-interest (lispview::match-event-spec pane `(,modifiers (:left :down))))
	   (l-doc (if (typep l-interest 'documented-mouse-interest)
		      (doc-string l-interest)
		      "Unbound"))
	   (m-interest (lispview::match-event-spec pane `(,modifiers (:middle :down))))
	   (m-doc (if (typep m-interest 'documented-mouse-interest)
		      (doc-string m-interest)
		      "Unbound"))
	   (r-interest (lispview::match-event-spec pane `(,modifiers (:right :down))))
	   (r-doc (if (typep r-interest 'documented-mouse-interest)
		      (doc-string r-interest)
		      "Unbound")))
      (values l-doc m-doc r-doc))))

;;; Mouse interests which respond to changes in the modifier keys or
;;; entry/exit of the mouse to/from the window by displaying mouse
;;; documentation.
(defclass bucky-change-interest (lispview:keyboard-interest) ()
	  (:default-initargs :event-spec `((:modifier) (or :down :up))))
(defclass mouse-entry-interest (lispview:mouse-interest) ()
	  (:default-initargs :event-spec '(((:others (or :up :down))) :enter)))
(defclass mouse-exit-interest (lispview:mouse-interest) ()
	  (:default-initargs :event-spec '(((:others (or :up :down))) :exit)))

(defmethod lispview:receive-event
    ((pane lispview:window) (interest bucky-change-interest) event)
  (multiple-value-bind (l-doc m-doc r-doc)
      (compute-mouse-documentation pane event)
    (display-mouse-documentation pane l-doc m-doc r-doc)))

(defmethod lispview:receive-event
    ((pane lispview:window) (interest mouse-entry-interest) event)
  (multiple-value-bind (l-doc m-doc r-doc)
      (compute-mouse-documentation pane event)
    (display-mouse-documentation pane l-doc m-doc r-doc)))

(defmethod lispview:receive-event
    ((pane lispview:window) (interest mouse-exit-interest) event)
  (display-mouse-documentation pane "" "" ""))

;;; Default mouse doc display just prints to standard-output.
(defun display-mouse-documentation (win left-doc middle-doc right-doc)
  (format t "MOUSE: ~60,1,4<~A~;~A~;~A~>~%" left-doc middle-doc right-doc))

#| Example usage:

(defclass left-interest (obvius::documented-mouse-interest) ()
  (:default-initargs :doc-string "left doc" :event-spec '(() (:left :down))))
(defclass middle-interest (obvius::documented-mouse-interest) ()
  (:default-initargs :doc-string "middle doc" :event-spec '(() (:middle :down))))
(defclass right-interest (obvius::documented-mouse-interest) ()
  (:default-initargs :doc-string "right doc" :event-spec '(() (:right :down))))

(defmethod receive-event ((pane lv:base-window) (interest left-interest) event)
  (format t "received a left mouse click~%"))
(defmethod receive-event ((pane lv:base-window) (interest middle-interest) event)
  (format t "received a middle mouse click~%"))
(defmethod receive-event ((pane lv:base-window) (interest right-interest) event)
  (format t "received a right mouse click~%"))

;;; Make a "self-documenting" window
(let* ((ints (list (make-instance 'left-interest)
		   (make-instance 'middle-interest)
		   (make-instance 'right-interest)
		   (make-instance 'obvius::mouse-entry-interest)
		   (make-instance 'obvius::mouse-exit-interest)
		   (make-instance 'obvius::bucky-change-interest)))
       (win (make-instance 'lispview:base-window :width 360 :height 200
			   :label "Documented Mouse Example"
			   :interests ints :mapped t :keyboard-focus-mode :passive
			   :background (lv:find-color :name :black)))
       (panel (make-instance 'lispview:panel :parent win :height 35))
       (msg (make-instance 'lispview:message :parent panel))
       (format-string "~60,1,4<~A~;~A~;~A~>"))
  (setq *doc-window* win)
  (defun obvius::display-mouse-documentation (w left-doc middle-doc right-doc)
    (let ((doc-string (format nil format-string left-doc middle-doc right-doc)))
      (setf (lv:label msg) doc-string))))

(setf (lv:status *doc-window*) :destroyed)
|#

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Generic mouse-dragging mechanism, intended for interactive
;;; dragging requests.  The idea is to abstract out the "interest"
;;; mechanism.  The user provides three functions: the first is called
;;; when the mouse button goes down, the second when the mouse moves
;;; (i.e. is dragged) and the third when the button is released.  The
;;; functions will be called with the following args:

;;;    begin-function: (window x y . function-args)
;;;    drag-function:  (window begin-x begin-y last-x last-y x y . function-args)
;;;    end-function: (window begin-x begin-y last-x last-y x y . function-args)

;;; State information (in addition to mouse positions) can be captured
;;; using lexical closures, or can be passed in function-args.  NOTE:
;;; The last-x and last-y args will be nil on the first call to the
;;; drag-function!  If :permanent-p is nil (the default), the
;;; interests will be automatically removed from the interest list of
;;; the window when the dragging operation is complete (i.e. a
;;; one-time-only drag).  Examples of :buttons arg -- :left '(or :left
;;; :right).  Examples of :modifiers arg -- :shift '(and :shift
;;; :control) '(or :shift :meta).  NOTE: modifiers are used to start
;;; and move, but they are ignored at the end (i.e. the dragging
;;; ALWAYS ends when the mouse button is released, regardless of the
;;; state of the bucky keys).

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; *** To be done: This code should be rewritten to allow the user to
;;; use receive-event instead of having the user pass functions.  In
;;; general, dragging is defined by three interests: a start-interest,
;;; a move-interest and an end-interest.  They serve the following
;;; roles: 1) Start-interest: Change cursor, save original cursor,
;;; store starting mouse position in move-interest, run user code,
;;; activate move and end interests, remove self from pane if not
;;; permanent.  2) Move-interest: If activated: call user code (if
;;; error, call end-interest receive-event).  Save last mouse
;;; position.  3) End-interest: If activated: call user code
;;; (unwind-protected), reset cursor, deactivate move-interest and
;;; stop-interest.  If not permanent, remove move-interest and
;;; end-interest.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; This function returns two interests which should be put onto the
;;; interest list of a LispView window.  An end-drag-interest must
;;; also be pushed onto the interest list: I tried to do it
;;; automagically, but it doesn't work (by the time the interest is
;;; realized and installed, the up-mouse event has already happened).
;;; Note that a single end-drag-interest handles all up-mouse
;;; (drag-termination) events.
(defun make-drag-interests (begin-function
			    drag-function
			    end-function
			    &key
			    other-args
			    drag-cursor
			    permanent-p
			    (doc-string "undocumented")
			    (buttons :left)
			    (modifiers nil))
  (unless buttons (error "Must provide a button name or list of button names."))
  (unless (listp modifiers) (error "Modifiers arg must be a list of modifiers (or nil)."))
  (let* ((drag-spec (list (append (cond ((eq (car modifiers) 'or) (list modifiers))
					((eq (car modifiers) 'and) (cdr modifiers))
					(t modifiers))
				  (cond ((not (listp buttons)) (list buttons))
					((eq (car buttons) 'or) (list buttons))
					((eq (car buttons) 'and) (cdr buttons))
					(t buttons)))
			  :move))
	 (move-interest (make-instance 'move-drag-interest
				       :the-function drag-function
				       :function-args other-args
				       :event-spec drag-spec))
	 (begin-interest (make-instance 'begin-drag-interest
					:doc-string doc-string
					:begin-function begin-function
					:end-function end-function
					:function-args other-args
					:drag-cursor drag-cursor
					:move-interest move-interest
					:permanent-p permanent-p
					:event-spec `(,modifiers (,buttons :down)))))
    (list begin-interest move-interest)))

;;; The ignore-me slot is used to "turn off" the interests at
;;; appropriate times.  The move and end interests are turned off
;;; until a begin interest event is received.  hey are turned off by
;;; the end interest.  A begin interest turns itself off.
(defclass begin-drag-interest (documented-mouse-interest)
  ((begin-function :initarg :begin-function :accessor begin-function)
   (end-function :initarg :end-function :accessor end-function)
   (function-args :initform nil :initarg :function-args :accessor function-args)
   (ignore-me :initform nil :initarg :ignore-me :accessor ignore-me)
   (original-cursor :initarg :original-cursor :accessor original-cursor)
   (drag-cursor :initarg :drag-cursor :accessor drag-cursor)
   (move-interest :initarg :move-interest :accessor move-interest)
   (permanent-p :initform nil :initarg :permanent-p :accessor permanent-p)))

(defmethod initialize-instance ((int begin-drag-interest) &rest initargs)
  (with-slots (drag-cursor) int
    (call-next-method)
    (when (and drag-cursor (not (typep drag-cursor 'lispview:cursor)))
      (setf drag-cursor (make-instance 'lispview:cursor :name drag-cursor)))))

(defclass move-drag-interest (lispview:mouse-interest)
  ((the-function :initarg :the-function :accessor the-function)
   (function-args :initform nil :initarg :function-args :accessor function-args)
   (ignore-me :initform t :initarg :ignore-me :accessor ignore-me)
   (begin-x-position :initform nil :initarg :begin-x-position :accessor begin-x-position)
   (begin-y-position :initform nil :initarg :begin-y-position :accessor begin-y-position)
   (last-x-position :initform nil :initarg :last-x-position :accessor last-x-position)
   (last-y-position :initform nil :initarg :last-y-position :accessor last-y-position)))

(defclass end-drag-interest (lispview:mouse-interest)
  ((begin-interest :initarg :begin-interest :accessor begin-interest :initform nil))
  (:default-initargs
      :event-spec `(((:others (or :up :down))) ((or :button0 :button1 :button2) :up))))

(defmethod lispview:receive-event
    ((window lispview:window) (interest begin-drag-interest) event)
  (with-slots (begin-function function-args ignore-me original-cursor
			      drag-cursor move-interest permanent-p) interest
    (unless ignore-me
      (let ((event-x (lispview:mouse-event-x event))
	    (event-y (lispview:mouse-event-y event))
	    (end-interest (find-if #'(lambda (x) (typep x 'end-drag-interest))
				   (lispview:interests window))))
	(unless end-interest
	  (error "Window ~A does not have an end-drag-interest."))
	(setf original-cursor (lispview:cursor window))
	(when drag-cursor
	  (when (not (typep drag-cursor 'lispview:cursor))
	    (setf drag-cursor (make-instance 'lispview:cursor :name drag-cursor)))
	  (setf (lispview:cursor window) drag-cursor))
	(setf (begin-x-position move-interest) event-x)
	(setf (begin-y-position move-interest) event-y)
	(setf (last-x-position move-interest) nil) ;make sure these are nil
	(setf (last-y-position move-interest) nil)
	(apply begin-function window event-x event-y function-args)
	;; Set up end interest and move interest
	(setf (slot-value end-interest 'begin-interest) interest)
	(setf (ignore-me move-interest) nil)
	;; Remove begin-interest if permanent-p is nil
	(unless permanent-p
	  (setf (ignore-me interest) t)
	  (setf (lispview:interests window)
		(delete interest (lispview:interests window))))
	t))))

(defmethod lispview:receive-event 
    ((window lispview:window) (interest move-drag-interest) event)
  (with-slots (ignore-me the-function function-args begin-x-position
			 begin-y-position last-x-position last-y-position) interest
    (unless ignore-me
      (let ((event-x (lispview:mouse-event-x event))
	    (event-y (lispview:mouse-event-y event)))
	(apply the-function window begin-x-position begin-y-position
	       last-x-position last-y-position event-x event-y function-args)
	(setf last-x-position event-x)
	(setf last-y-position event-y)
	t))))

(defmethod lispview:receive-event
    ((window lispview:window) (interest end-drag-interest) event)
  (with-slots (begin-interest) interest
    (when (typep begin-interest 'begin-drag-interest)
      (with-slots (end-function move-interest function-args original-cursor
				permanent-p) begin-interest
	(unwind-protect
	   (apply end-function window
		  (begin-x-position move-interest) (begin-y-position move-interest)
		  (last-x-position move-interest) (last-y-position move-interest)
		  (lispview:mouse-event-x event) (lispview:mouse-event-y event)
		  function-args)
	  (setf (lispview:cursor window) original-cursor)
	  (setf (ignore-me move-interest) t) ;turn off move and end interests!
	  (setf begin-interest nil)
	  (unless permanent-p	   ;remove from interest list if permanent-p is nil
	    (setf (lispview:interests window)
		  (delete interest (lispview:interests window)))
	    (setf (lispview:interests window)
		  (delete move-interest (lispview:interests window))))
	t)))))

#| Rubber band line example:

(setq *w* (make-instance 'lv:base-window
			   :width 400
			   :height 300
			   :foreground (lv:find-color :name :white)))

(let* ((win *w*)
       (clr (lv:find-color :name :black))
       (drag-clr (lv:find-color :pixel 0))	;get pixel with zero index
       (op boole-eqv)
       (begin-function #'(lambda (window x y)
			   (format t ";;; Begin dragging....~%")))
       (drag-function #'(lambda (window xs ys x0 y0 x1 y1)
			  (when (and x0 y0)
			    (lv:draw-line window xs ys x0 y0
					  :operation op :foreground drag-clr))
			  (lv:draw-line window xs ys x1 y1
					:operation op :foreground drag-clr)))
       (end-function #'(lambda (window xs ys x0 y0 x1 y1)
			 (when (and x0 y0)
			   (lv:draw-line window xs ys x0 y0
					 :operation op :foreground drag-clr))
			 (format t ";;; Finished dragging.~%")
			 (lv:draw-line window xs ys x1 y1
				       :foreground clr)))
       (end-interest (or (find-if #'(lambda (x) (typep x 'obvius::end-drag-interest))
				  (lv:interests win))
			 (make-instance 'obvius::end-drag-interest))))
  (pushnew end-interest (lv:interests win))
  (setf (lv:interests win)
	(append (make-drag-interests begin-function drag-function end-function
				     :doc-string "Rubber-band-line"
				     :drag-cursor :XC-crosshair
				     :permanent-p t
				     :buttons :left
				     :modifiers '(:control :shift))
		(lv:interests win))))

;;; Removing permanent interests:
(setf (lv:interests *w*)
      (delete-if #'(lambda (i) (or (typep i 'obvius::begin-drag-interest)
				   (typep i 'obvius::move-drag-interest)
				   (typep i 'obvius::end-drag-interest)))
		 (lv:interests *w*)))

(setf (lv:status *w*) :destroyed)
|#


