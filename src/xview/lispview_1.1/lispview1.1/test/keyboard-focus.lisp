;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)keyboard-focus.lisp	1.2 10/17/91

(in-package "LISPVIEW-TEST")


#|
This test demonstrates how an application can work with an ICCCM
compliant window manager to manage the keyboard focus within the
windows it owns.  The application is a base-window with two children.
When the mouse enters a child window the application resets the
keyboard-focus of the base-window to be the child.  When the user sets
the keyboard focus to be the base-window, e.g. by clicking on the
title bar with the window manager in "click to type" mode, the child
window with the keyboard-focus gets a keyboard-focus event.  The
application inverts the child window with the focus.


When we created the base-window we initialized its :keyboard-focus-mode
to :passive (the default is NIL - means that the window will never
accept the keyboard focus).  This is the right value for most basic keyboard
applications, it means that the application will never setf the displays
keyboard-focus but the application does plan to handle keyboard events.
An application that has several top-level windows may want to transfer
the keyboard focus between them - once one of the windows is notified 
that it has the keyboard focus to begin with.  In this case the 
value of :keyboard-focus-mode should be :locally-active.  It might be
instructive to modify the example: create two window complexes instead
of just one and when some magic keystroke is received setf the displays
keyboard focus to the other base-window.  For example if the two base-windows
were called w01 and w02 (good names eh?) you could make pressing "1"
(setf (keyboard-focus (display w01)) w01).

Only the base-window is created with a keyboard interest.  All applications
that handle keyboard events should do this and use (setf keyboard-focus)
to identify the window that will actually receive keyboard events when the
user has designated the top-level window as the keyboard-focus window.
Note: this is less intuitive then just putting keyboard interests on all
windows that expect to handle keyboard events - but the LispView internals
are much simpler and for many applications it's much less demanding of the 
X11 server.

Obscura:

- The ICCCM manual is a good source if you want the nitty gritty details
for the semantics of the different keyboard-focus modes.  It's not pretty.

- XView uses a completely brain dead keyboard focus policy within panels;
it sets the displays keyboard-focus whenever the mouse enters a panel item
that accepts keyboard input.  This doesn't hurt LispView applications although
one can't transfer the keyboard-focus from a window to a panel item 
programmatically (or the panel).  We may try to add this feature in the future.

|#


(defun make-passive-keyboard-focus-windows ()
  (let* ((echo-keyboard (make-instance 'keyboard-interest))
	 (update-highlight (make-instance 'keyboard-focus-interest))
	 (update-focus (make-instance 'mouse-interest :event-spec '(() :enter)))
	 (w0 (make-instance 'base-window 
	       :label "Follow The Mouse Focus Pocus"
	       :width 400 :height 200
	       :keyboard-focus-mode :passive
	       :interests (list echo-keyboard)
	       :show-resize-corners nil
	       :mapped nil))
	 (w1 (make-instance 'window 
	       :parent w0
	       :interests (list update-focus update-highlight)
       	       :border-width 1 :left 2 :top 2 :width 396 :height 96))
	 (w2 (make-instance 'window 
	       :parent w0
	       :interests (list update-focus update-highlight)
	       :border-width 1 :left 2 :top 102 :width 396 :height 96)))

    (defmethod receive-event (w (i (eql update-highlight)) event)
      (let* ((br (bounding-region w))
	     (dx (- (region-width br) 2))
	     (dy (- (region-height br) 2)))
	(case (keyboard-focus-event-focus event)
	  (:in 
	   (draw-rectangle w 0 0 dx dy :line-width 3 :foreground (foreground w)))
	  (:out 
	   (draw-rectangle w 0 0 dx dy :line-width 3 :foreground (background w)))
	  (:take
	   (error "Didn't expect a :take keyboard focus event with :locally-active keyboard-focus-mode")))))

    (defmethod receive-event (w (i (eql update-focus)) event)
      (declare (ignore event))
      (setf (keyboard-focus w0) w))

    (defmethod receive-event (w (i (eql echo-keyboard)) event)
      (with-output-buffering (display w)
	 (draw-rectangle w 5 5 35 35 :fill-p t :foreground (background w))
	 (draw-char w 15 15 (keyboard-event-char event))))

    (setf (mapped w0) t)
    (list w0 w1 w2)))
	


(def-test test-passive-keyboard-focus ()
  (
   :type :test
   :interactive t
  )

  (let ((windows (make-passive-keyboard-focus-windows)))
    (format t ";;; Passive Keyboard Focus Test:~{~<~%;;;   ~1:; ~A~>~^~}~%"
	    '("Moving the mouse between the bordered panes should highlight the pane"
	      "with the keyboard focus.  Pressing the keyboard should echo the"
	      "character in the highlighted window"))
    (unwind-protect
	(unless (yes-or-no-p "Is the keyboard focus tracking the mouse correctly")
	  (error "test-passive-keyboard-focus failed"))
      (map nil #'destroy windows))))
		 
    


(defun make-locally-active-keyboard-focus-windows ()
  (flet 
   ((make-top-level-window (label)
      (make-instance 'base-window 
	:label label
	:width 400 :height 200
	:keyboard-focus-mode :locally-active
	:interests (list (make-instance 'keyboard-interest))
	:show-resize-corners nil
	:mapped nil)))

   (let ((w1 (make-top-level-window "Window 1"))
	 (w2 (make-top-level-window "Window 2"))
	 (w3 (make-top-level-window "Window 3")))
     (flet
      ((make-children (parent)
	 (let* ((update-highlight (make-instance 'keyboard-focus-interest))
		(update-focus (make-instance 'mouse-interest :event-spec '(() :enter)))
		(echo-keyboard (car (interests parent))))
	   (make-instance 'window 
	     :parent parent
	     :interests (list update-focus update-highlight)
	     :border-width 1 :left 2 :top 2 :width 396 :height 96)

	   (make-instance 'window 
	     :parent parent
	     :interests (list update-focus update-highlight)
	     :border-width 1 :left 2 :top 102 :width 396 :height 96)

	   (defmethod receive-event (w (i (eql update-highlight)) event)
	     (let* ((br (bounding-region w))
		    (dx (- (region-width br) 2))
		    (dy (- (region-height br) 2)))
	       (case (keyboard-focus-event-focus event)
		 (:in 
		  (draw-rectangle w 0 0 dx dy :line-width 3 :foreground (foreground w)))
		 (:out 
		  (draw-rectangle w 0 0 dx dy :line-width 3 :foreground (background w)))
		 (:take
		  (error "Didn't expect a :take keyboard focus event with :locally-active keyboard-focus-mode")))))

	   (defmethod receive-event (w (i (eql update-focus)) event)
	     (declare (ignore event))
	     (setf (keyboard-focus parent) w))

	   (defmethod receive-event (w (i (eql echo-keyboard)) event)
	     (let ((c (keyboard-event-char event)))
	       (if (member c '(#\1 #\2 #\3) :test #'eql)
		   (let ((focus (cdr (assoc c (list (cons #\1 w1) 
						    (cons #\2 w2) 
						    (cons #\3 w3)) :test #'eql))))
		     (setf (keyboard-focus (display w)) focus))
		 (with-output-buffering (display w)
		   (draw-rectangle w 5 5 35 35 :fill-p t :foreground (background w))
		   (draw-char w 15 15 c))))))))

      (make-children w1)
      (make-children w2)      
      (make-children w3))

     (setf (mapped w1) t
	   (mapped w2) t
	   (mapped w3) t)
     (list w1 w2 w3))))


(def-test test-locally-active-keyboard-focus ()
  (
   :type :test
   :interactive t
  )

  (let ((windows (make-locally-active-keyboard-focus-windows)))
    (format t ";;; Locally Active Keyboard Focus Test:~{~<~%;;;   ~1:; ~A~>~^~}~%"
	    '("Moving the mouse between the bordered panes should highlight the pane with the"
              "keyboard focus.  Pressing the keyboard should echo the current character in the"
              "highlighted pane.  Pressing 1,2 or 3 should transfer the focus"
	      "to the pane in the base-window with the corresponding label."))
    (unwind-protect
	(unless (yes-or-no-p "Is the keyboard focus tracking the mouse correctly")
	  (error "test-locally-active-keyboard-focus failed"))
      (map nil #'destroy windows))))
		 
