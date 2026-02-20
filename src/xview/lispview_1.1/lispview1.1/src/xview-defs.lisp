;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)xview-defs.lisp	3.40 10/11/91


(in-package "LISPVIEW")


(defvar xview-null-event 
  (make-foreign-pointer :address 0 :type '(:pointer XV:event)))



;;; Note: many of the xview-object "subclasses" defined below shadow xview 
;;; boolean attributes with structure slots.  This is done so that the value
;;; of non nil attributes isn't lost.  For example the busy slot in an
;;; xview-top-level-window corresponds to the XView :frame-busy attribute
;;; whose value must be 0 or 1 (TRUE or FALSE).  A lisp application can put any 
;;; lisp object in a top-level-windows busy "slot".


;;; id - XView object integer "handle" 
;;; xid - X server integer resource id
;;; dsp - foreign pointer to Xlib display 
;;; xvd - xview-display structure (see below), not set in an xview-display 
;;; initargs - temporary home for the make-instance initargs

(defun print-xview-object (xvo stream depth)
  (declare (ignore depth))
  (format stream "#<~A id ~A xid ~A ~X>"
	  (type-of xvo)
	  (or (xview-object-id xvo) "-")
	  (or (xview-object-xid xvo) "-")
	  (SYS:%pointer stream)))

(defstruct (XVIEW-OBJECT (:print-function print-xview-object))
  id
  xid
  dsp
  xvd
  initargs)


;;; name - X "display" string, e.g. "cumulus:0.0"
;;; initargs - temporary home for the make-instance initargs
;;; id - integer id of the XView server
;;; xid - X11 resource id for the display
;;; dsp - foreign pointer to Xlib display 
;;; xvd - nil
;;; screen - integer id of the XView screen
;;; scr - foreign pointer to Xlib screen
;;; root - XView id of the root window for screen
;;; rdb - X11 resource database
;;; nil-parent-frame - canvas' with nil parent are actually parented to this unmapped FRAME_BASE
;;; nil-parent-panel - same for panel items

(defun print-xview-display (xvd stream depth)
  (declare (ignore depth))
  (format stream "#<XView Display ~S, ID ~A, XID ~A ~X>"
	  (or (xview-display-name xvd) "")
	  (or (xview-object-id xvd) "-")
	  (or (xview-object-xid xvd) "-")
	  (SYS:%pointer stream)))


(defstruct (XVIEW-DISPLAY (:include xview-object)
			  (:print-function print-xview-display))
  name  
  screen
  scr
  root
  keyboard-focus
  rdb
  %nil-parent-frame
  %nil-parent-panel)

(defun xview-display-nil-parent-frame (xvd)
  (or (xview-display-%nil-parent-frame xvd)
      (setf (xview-display-%nil-parent-frame xvd)
	    (XV:xv-create (xview-display-root xvd) :frame-base :win-map nil))))

(defun xview-display-nil-parent-panel (xvd)
  (or (xview-display-%nil-parent-panel xvd)
      (setf (xview-display-%nil-parent-panel xvd)
	    (XV:xv-create (xview-display-nil-parent-frame xvd) :panel))))


;;; All of the GC slots are cached here - X11 doesn't officially cache anything.

(defstruct (X11-GC (:include xview-object))
  drawable
  function 
  plane-mask 
  foreground
  background 
  line-width 
  line-style 
  cap-style 
  join-style 
  fill-style 
  fill-rule 
  tile 
  stipple 
  ts-x-origin
  ts-y-origin
  font 
  subwindow-mode 
  graphics-exposures 
  clip-x-origin
  clip-y-origin
  clip-mask 
  dash-offset 
  dashes 
  arc-mode)


;;; X11-INTEREST
;;;
;;; object - the interest object this X11 input-mask corresponds to 
;;; input-mask - X11 input mask 

(defstruct (x11-interest (:print-function print-x11-interest))
  object
  (input-mask 0)
  types)

(defstruct (x11-mouse-interest (:include x11-interest)
			       (:print-function print-x11-mouse-interest))
  (state-mask 0)
  (state-match 0)
  (button 0)
  (nclicks 0))

  
;;; keysym-ranges - list of dotted pairs (min . max), matching keysyms must fall within
;;; one of the specified ranges.

(defstruct (x11-keyboard-interest (:include x11-interest)
				  (:print-function print-x11-keyboard-interest))
  (keysym-ranges nil))

(defstruct (x11-damage-interest (:include x11-interest)
				(:print-function print-x11-damage-interest)))



;;; initargs - temporary home for the make-instance initargs
;;; interest-table - X11 event type indexed vector, each element is a list of x11-interests
;;; input-mask - Solo X11 input-mask (fixnum)
;;; initial-input-mask - XViews internal input mask
;;; all other slots - cached Solo values

(defstruct (XVIEW-CANVAS (:include xview-object))
  mapped
  cursor
  (interest-table (make-array X11:LastEvent))
  from-focus
  to-focus)


(defstruct (XVIEW-TRANSPARENT-CANVAS (:include xview-canvas)))

(defstruct (XVIEW-OPAQUE-CANVAS (:include xview-canvas))
  depth
  foreground
  background
  backing-store
  save-under
  bit-gravity
  colormap)


(defstruct (XVIEW-WINDOW (:include xview-opaque-canvas))
  border-width)


;;; reparent - XID of new parent if this window has been reparented
;;; configuration - current XConfigureEvent for this window
;;; destroyed-xvo - copy of this struct made when DESTROY_CHECKING succeeds
;;; destroyed-p - T if the XView version of this window is gone.

(defstruct (XVIEW-TOP-LEVEL-WINDOW (:include xview-window))
  busy
  closed
  icon
  confirm-quit
  owner
  keyboard-focus-mode
  reparent
  configuration
  destroyed-xvo
  destroyed-p)


;;; depth - pixel depth
;;; data - 2D array of initial pixel values, nil after image has been realized
;;; visual - for XCreateImage call
;;; colors - colormap colors 

(defstruct (XVIEW-IMAGE (:include xview-object))
  depth
  data
  visual
  colors)


(defmacro xview-drawable-depth (xvo)
  (let ((xvo-var (gensym)))
    `(let ((,xvo-var ,xvo))
       (if (typep ,xvo-var 'xview-image)
	   (xview-image-depth ,xvo-var)
	 (xview-opaque-canvas-depth ,xvo-var)))))


;;; name - nil or the name of an X11 cursor.  
;;; foreground, background - color specifications
;;; x-hot, y-hot - integers or null
;;; image, mask - images or null.

(defstruct (XVIEW-CURSOR (:include xview-object))
  name 
  (foreground :black)
  (background :white)
  x-hot
  y-hot
  image
  mask)


;;; label-string - string or null
;;; label-image - image or null
;;; clip-mask - image or null for ICON_MASK_IMAGE 
;;; foreground - color or null
;;; backround - color or :transparent or null

(defstruct (XVIEW-ICON (:include xview-object))
  label-string
  label-image
  clip-mask
  foreground
  background)


;;; index - index into the cms
;;; xcolor - foreign pointer to an XColor struct

(defstruct XVIEW-COLOR 
  (index 0 :type fixnum)
  xcolor)



;;; When we run out of colors in a colormap we allocate "proxy" colors, i.e. we 
;;; substitute the closest already allocated color to the color requested by the 
;;; application.

(defstruct (XVIEW-PROXY-COLOR 
	    (:include xview-color)
	    (:constructor %make-xview-proxy-color))
  proxy)

(defun make-xview-proxy-color (color)
  (let ((xvo (device color)))
    (%make-xview-proxy-color
       :index (xview-color-index xvo)
       :xcolor (copy-foreign-pointer (xview-color-xcolor xvo))
       :proxy color)))
  


;;; This color was allocated by the toolkit (or by the window system) - it's 
;;; place in the colormap shouldn't be reused.

(defstruct (xview-toolkit-color (:include xview-color)))


;;; Rather than checking colors to see if they've been destroyed before using
;;; them we just set the device slot of colors that have been destroyed (or
;;; couldn't be allocated) to no-such-xview-color.  Applications that blithely
;;; use destroyed colors will look strange but they will not blow up.

(defvar no-such-xview-color
  (make-xview-color 
    :index 0
    :xcolor (copy-foreign-pointer 
	     (X11:make-xcolor :pixel 0 :red 0 :blue 0 :green 0 :flags 0) :static t)))



;;; Allocation is a vector with the same number of entries as the colormap,
;;; NIL entries are unallocated, allocated entries contain a color instance.
;;;
;;; Last-allocation is the index of the last color allocated.  When allocating
;;; a new color we search from last-allocation to the end of the allocation 
;;; vector and then from the beginning to last-allocation for an empty (NIL)
;;; entry.   
;;; 
;;; Reserved-colors is a vector of of "reserved" color instances
;;; Pixel-to-index is an inverted XView CMS_INDEX_TABLE.

(defstruct (XVIEW-COLORMAP (:include xview-object))
  visual
  allocation
  (last-allocation 0)
  reserved-colors
  pixel-to-index)


;;; This colormap is being managed by the toolkit - it's X11 resources 
;;; shouldn't be  destroyed.

(defstruct (xview-toolkit-colormap (:include xview-colormap)))

(defconstant x11-do-rgb
  (logior X11:DoRed X11:DoGreen X11:DoBlue))


;;; xstruct - foreign pointer to a X11 XFontStruct 

(defstruct (XVIEW-FONT (:include xview-object))
  xstruct
  char-metrics
  min-char-metrics
  max-char-metrics
  property-list)

  

;;; mapped - stores the Lisp value (usually t or nil) that corresponds to :xv-show
;;; foreground - color object (or index)
;;; background - same

(defstruct (XVIEW-ITEM (:include xview-object))
  mapped
  foreground
  background)


;;; show-value,range - stores the Lisp values (usually t or nil) that 
;;;    correspond to :panel-show-value and :panel-show-range

(defstruct (XVIEW-GAUGE (:include xview-item))
  show-value
  show-range)

(defstruct (XVIEW-SLIDER (:include xview-gauge))
  show-end-boxes)

;;; choices - list of choice objects (often strings, images, or printable objects)
;;; default - a choice or list of choices
;;; selection-required - Lisp value (usually t or nil) that corresponds to :panel-choose-one

(defstruct (XVIEW-SETTING (:include xview-item))
  default
  selection-required
  choices)


;;; underline-value - Lisp value (usually t or nil) that corresponds to :panel-value-underlined
;;; read-only - Lisp value (usually t or nil) that corresponds to :panel-read-only
;;; mask-char - XView "features" support for setting but not getting this attribute, bugtraq RFE #1030467

(defstruct (XVIEW-TEXT-FIELD (:include xview-item))
  value-underlined
  read-only
  mask-char)


;;; choices - list of choice objects (often strings, images, or printable objects)
;;; selection-requied - Lisp value (usually t or nil) that corresponds to :panel-choose-none
;;; read-only - Lisp value (usually t or nil) that corresponds to :panel-read-only

(defstruct (XVIEW-SCROLLING-LIST (:include xview-item))
  choices
  selection-required
  read-only)


;;; choices - sequence of Solo menu-items
;;; default - integer item position, submenu-item, or a command-menu-item
;;; owner - cached locally to fix bugtraq bugid #1032089
;;; pushpin - Lisp value (usually t or nil) that corresponds to :menu-gen-pin-window
;;; dismissed - Lisp function to call when menu is dismissed or NIL.
;;;
;;; We initialize default to 0 here to reflect the OPEN LOOK default for default.

(defstruct (XVIEW-MENU (:include xview-item))
  choices
  (default 0)
  owner
  pushpin
  dismissed)

(defstruct (XVIEW-MENU-ITEM (:include xview-item)))


(defstruct (XVIEW-SCROLLBAR (:include xview-canvas)))


;;; XView "scrollbar_request" events don't contain the elevator motion that caused
;;; the event.  We squirrel away the motion keyword (:page-forward, :page-backward, etc)
;;; and the new view-start inside the XView compute_scroll_proc, the scrollbar_request
;;; event handler uses the globals to create a Solo scroll event.

(defvar xview-scrollbar-motion nil)
(defvar xview-scrollbar-view-start nil)


;;; The xview-viewport-object actually represents the XView paint window, i.e. 
;;; the large drawing window that is a child of the XView view window.  Viewport 
;;; resize and stacking order operations modify the container window.  The container
;;; window is the parent for the view window and the (optional) scrollbars, and the 
;;; view-window is the parent for the (usually relatively large) paint window.  If
;;; the viewport has a border the view window is the one that actually gets it.
;;;
;;; id, xid - XView "paint" windows XView id.
;;; xvw - XView "view" windows XView id.
;;; xcw - XView "container" windows XView id.

(defstruct (XVIEW-VIEWPORT (:include xview-window))
  xvw
  xcw
  view-region
  output-region
  vertical-scrollbar
  horizontal-scrollbar)

(defmacro xview-viewport-scrollbars (xvo)
  (let ((xvo-var (gensym)))
    `(let ((,xvo-var ,xvo))
       (values (xview-viewport-vertical-scrollbar ,xvo-var)
	       (xview-viewport-horizontal-scrollbar ,xvo-var)))))


(defmacro xview-container-id (xvo)
  (let ((xvo-var (gensym)))
    `(let ((,xvo-var ,xvo))
       (typecase ,xvo-var
	(xview-scrollbar
	 (let ((id (xview-object-id ,xvo-var)))
	   (if id (xv_get id WIN_PARENT))))
	(xview-viewport
	 (if (xview-object-id ,xvo-var) (xview-viewport-xcw ,xvo-var)))
	(t
	 (xview-object-id ,xvo-var))))))


(defstruct (xview-scrolling-window (:include xview-window)))



(defmacro xview-maybe-XFlush (xvd &optional dsp)
  (if (and xvd dsp)
      `(unless (member ,xvd *output-buffering* :test #'eq)
	 (X11:XFlush ,dsp))
    (let ((xvd-var (gensym)))
      `(let ((,xvd-var ,xvd))
	 (unless (member ,xvd-var *output-buffering* :test #'eq)
	   (X11:XFlush (xview-display-dsp ,xvd-var)))))))


;;; We leave the xview-objects xvd (xview-display) slot intact so that
;;; if the window loses the keyboard focus when it's destroyed we can still
;;; figure out which displays keyboard-focus needs to be updated.

(defmacro null-xview-object (xvo)
  (let ((xvo-var (gensym)))
    `(let ((,xvo-var ,xvo))
       (when (typep ,xvo-var 'xview-object)
	 (setf (xview-object-id  ,xvo-var) nil
	       (xview-object-xid ,xvo-var) nil
	       (xview-object-dsp ,xvo-var) nil))
       (when (typep ,xvo-var 'xview-viewport)
	 (setf (xview-viewport-xvw ,xvo-var) nil
	       (xview-viewport-xcw ,xvo-var) nil)))))


;;; The mapping from integer XView ids and X11 "resource" id's to LispView 
;;; objects is maintained in two hash tables: xview-object-table and 
;;; x11-object-table.  Conversion from XView id to LispView canvas, panel, 
;;; or menu item is required for most XView window or panel callback functions.
;;; Conversion from X11 id to LispView object isn't used at the moment.
;;;
;;; When a top-level window is destroyed we scan the both hash tables and
;;; remove entries that correspond to already destroyed LispView objects.

(defvar xview-object-table (make-hash-table))

(defvar x11-object-table (make-hash-table))

(defun def-xview-object (object xvo)
  (let ((id (xview-object-id xvo))
	(xid (xview-object-xid xvo)))
    (when id
      (setf (gethash id xview-object-table) object))
    (when xid
      (setf (gethash xid x11-object-table) object))))


(defmethod undef-xview-object (object xvo)
  (let ((id (xview-object-id xvo))
	(xid (xview-object-xid xvo)))
    (null-xview-object xvo)
    (when (and id (eq object (xview-id-to-object id)))
      (remhash id xview-object-table))
    (when (and xid (eq object (x11-id-to-object xid)))
      (remhash xid x11-object-table))))


(defmethod undef-xview-object (object (xvo xview-top-level-window))
  (when (xview-top-level-window-destroyed-p xvo)
    (call-next-method object (xview-top-level-window-destroyed-xvo xvo))))


(defun xview-id-to-object (id) 
  (XV:with-xview-lock 
   (gethash id xview-object-table)))

(defun x11-id-to-object (xid) 
  (XV:with-xview-lock 
   (gethash xid x11-object-table)))


(defun destroy-xview-object (object &optional (xvo (device object)) 
				              (id (xview-object-id xvo))
					      (xvd (xview-object-xvd xvo)))
  (XV:with-xview-lock 
    (undef-xview-object object xvo)
    (when id
      (XV:xv-destroy-safe id)
      (xview-maybe-XFlush xvd))))


;;; XView sets up all windows that are interested in the keyboard in "click
;;; to type" mode.   This means that mousing left changes the servers idea
;;; of the keyboard focus, with XSetInputFocus.  LispView has it's own 
;;; keyboard-focus management system and fortuntately we can defeat XViews
;;; with an undocumented XView window function.

(defmacro defeat-xview-click-to-type (id)
  `(XV:win-set-no-focus ,id XV:True))
      

;;; We defeat the passive grab established by window_grab_select_button in 
;;; libxvin/window/window_set.c.  According to the comment above this routine
;;; the grab exists (if the window is interested in the keyboard) because:
;;;
;;;    This eliminates the race condition of clicking in a new window and typing
;;;    characters before the focus actually changes 
;;;
;;; This is true unfortunately - and it's true because XView doesn't implement 
;;; a sensible keyboard focus management system.  XView justs pushes the servers
;;; focus around with XSetInputFocus.  Since LispView defeats the XView
;;; (fascist) focus policy for everything except text-fields we can safely 
;;; remove the grab.
;;;
;;; If the grab is left in place then a left mouse down event that occurs
;;; in a LispView window while the Lisp notifier process is stopped can 
;;; make the entire window system appear to hang.  This is because the 
;;; notifier has to run to release the passive grab that is activated
;;; by the server.  The notifier may fail to run because Lisp scheduling or 
;;; interrupts are inhibited, becuase the XView lock XV::*xview-lock* is being
;;; held by another process, becuase the notifier process is in the debugger,
;;; or because the notifier process is dead.  

(defmacro defeat-xview-passive-grab (dsp xid)
  `(X11:XUngrabButton ,dsp X11:Button1 X11:AnyModifier ,xid))



;;; XVIEW Attribute/Value lists.  
;;;
;;; The definitions below support managing XView Attr_avlist foreign vectors.  This
;;; approach to creating/modifying XView attributes is neccessary when the total number of 
;;; arguments to XV:xv-create or XV:xv-set is larger than XV:attr-standard-size
;;; (currently that's 250).  This is because XView converts the arguments for these 
;;; functions into short vectors internally; for more information see chapter 21
;;; of the XView book - "XView Internals".
;;; 
;;; The attribute/value vectors or "lists" are created incrementally by using 
;;; the function push-xview-attrs to add attributes and values to an xview-attr-list 
;;; structure, xview-attr-list structs must be allocated and deallocated from
;;; the the xview-attr-list-resource.  For example, given a panel, an XView scrolling 
;;; list could be created like this:
#|
(using-resource (al xview-attr-list-resource panel :panel-list)
  (push-xview-attrs al (XV:keyword-enum :panel-list-display-rows) 5)
  (let ((row 0))
    (dolist (f *features*)
      (push-xview-attrs al (XV:keyword-enum :panel-list-string) 
			   row 
			   (malloc-foreign-string (string f)))
      (incf row))
    (flush-xview-attr-list al)
    (xview-attr-list-id al)))
|#
;;; In this case calling flush-xview-attr-list forces XV:xv-create to be applied
;;; to the owner and package we specified with the arguments to LCL:using-resource,
;;; and to the all of the attributes added to the list with push-xview-attrs.  
;;;
;;; Please refer to the code and comments below for more information.


(def-foreign-synonym-type 
  xview-attr-list 
  (:array :signed-32bit (#.XV:attr-standard-size)))


;;; owner - xview-object struct
;;; package - XView package keyword
;;; id - integer XView object id or nil
;;; attrs - Foreign pointer to XView attribute value list  array
;;; index - first available element in fp
;;; reclaim - foreign pointers that can be freed after attrs has been XV:xv-set

(defstruct xview-attr-list
  owner
  package
  id 
  (attrs (make-foreign-pointer :type '(:pointer xview-attr-list) :static t))
  attrs-addr
  (index 0)
  (reclaim (make-array (list XV:attr-standard-size) :fill-pointer 0)))


(defvar xview-attr-list-resource 
  (macrolet 
   ((al-owner-xvo (owner)
      `(typecase ,owner
         (display-device-status (device ,owner))
	 (xview-object ,owner)
	 (integer (make-xview-object :id ,owner)))))

    (make-resource "xview-attr-list structs"
      :initialization-function 
	 #'(lambda (al owner package &optional id)
	     (setf (xview-attr-list-owner al) (al-owner-xvo owner)
		   (xview-attr-list-package al) package
		   (xview-attr-list-id al) id
		   (xview-attr-list-index al) 0
		   (fill-pointer (xview-attr-list-reclaim al)) 0)
	     al)
      :constructor 
	 #'(lambda (owner package &optional id)
	     (let ((al (make-xview-attr-list :owner (al-owner-xvo owner)
					     :package package
					     :id id)))
	       (setf (xview-attr-list-attrs-addr al)
		     (foreign-pointer-address (xview-attr-list-attrs al)))
	       al))
      :cleanup-function
	'flush-xview-attr-list)))


(macrolet
 ((attrs-ref (attrs index)
     `(typed-foreign-aref 'xview-attr-list ,attrs ,index)))

 ;;; Apply XV:xv-create or XV:xv-set to the specified attribute/value list using the XView
 ;;; :attr-list attribute.  Afterward we FFI:free-foreign-pointer each element of
 ;;; the xview-attr-list-reclaim vector.
 ;;; 
 ;;; Before calling XView we verify that the owner hasn't been destroyed - but we do not 
 ;;; verify that the XView object represented by  xview-attr-list-id still exists.  This routine 
 ;;; should only be used in a situation (usually dd-realize-something) when we know the status 
 ;;; of the  object being created/modified will not change.

 (defun FLUSH-XVIEW-ATTR-LIST (al) 
   (declare (type-reduce number fixnum)
	    (optimize (speed 3) (space 0) (safety 1)))

   (let ((id (xview-attr-list-id al))
	 (addr (xview-attr-list-attrs-addr al))
	 (reclaim (xview-attr-list-reclaim al))
	 (index (xview-attr-list-index al))
	 (owner (xview-attr-list-owner al)))
     (XV:with-xview-lock 
       (when (and (> index 0) (xview-object-id owner))
	 (setf (attrs-ref (xview-attr-list-attrs al) index) 0)
	 (if id
	     (XV:xv-set id :attr-list addr)
	   (setf (xview-attr-list-id al)
		 (XV:xv-create (xview-object-id owner)
			       (xview-attr-list-package al)
			       :attr-list addr)))

	 (setf (xview-attr-list-index al) 0)
	 (dotimes (i (fill-pointer reclaim) (setf (fill-pointer reclaim) 0))
	   (free-foreign-pointer (aref reclaim i)))))))


 ;;; If there isn't enough room for all of the XView args in the xview-attr-list then
 ;;; flush it (see above); add the specified attribute/values to the list.  Args should
 ;;; be a list of integers and foreign-pointers.  The foreign-pointers will be reclaimed,
 ;;; with FFI:free-foreign-pointer, after the list has been used.  Foreign-pointers
 ;;; are converted to addresses before being stored in the XView attribute value vector.

 (defun PUSH-XVIEW-ATTRS (al &rest args)
   (declare (dynamic-extent args)
	    (type-reduce number fixnum)
	    (optimize (speed 3) (space 0) (safety 1)))

   (when (<= (- XV:attr-standard-size (+ 1 (xview-attr-list-index al) (length args))) 0)
     (flush-xview-attr-list al))

   (let ((index (xview-attr-list-index al))
	 (attrs (xview-attr-list-attrs al)))
     (dolist (arg args)
       (setf (attrs-ref attrs index)
	     (if (typep arg 'foreign-pointer)
		 (progn
		   (vector-push arg (xview-attr-list-reclaim al))
		   (foreign-pointer-address arg))
	       arg))
       (incf index))

     (setf (xview-attr-list-index al) index))))



;;; These macros modify the value of a single XView string attribute.  We've used a 
;;; macro called set-xview-... instead of a setf method so that the XView attribute keyword 
;;; doesn't get bound to a temporary which would prevent the call to xv-set from getting 
;;; completely expanded until run-time.
;;;
;;; These macros should only be called from within XV:with-xview-lock.

(defmacro get-xview-string-attribute (id attribute)
  `(let ((addr (XV:xv-get ,id ,attribute)))
     (if (/= 0 addr)
	 (foreign-string-value
	  (make-foreign-pointer :type '(:pointer :character) 
				    :address addr)))))

(defmacro set-xview-string-attribute (id attribute value)
  `(let ((fp (malloc-foreign-string ,value)))
     (prog1
	 (XV:xv-set ,id ,attribute fp)
       (free-foreign-pointer fp))))



;;; These macros modify the value of a single XView attribute.  We rely on the
;;; XView interface to do the propert string and boolean conversions when an
;;; attribute is set.  When the value of attribute is retrieved (with XV:xv-get)
;;; we do the string or boolean conversion here.  
;;; 
;;; The xview-to-solo and solo-to-xview conversions should be expressions that contain
;;; one instance of the symbols XVIEW-VALUE and SOLO-VALUE respectively.  The macro 
;;; replaces these symbols by a form that computes the value by getting or setting
;;; an XView attribute.


(defmacro get-xview-attribute (id attribute type xview-to-solo)
  (let ((expr (if (eq type 'string)
		  `(get-xview-string-attribute ,id ,attribute)
		(let ((expr `(XV:xv-get ,id ,attribute)))
		  (if (eq type 'boolean)
		      `(/= ,expr 0)
		    expr)))))
    (if xview-to-solo
	(subst expr 'xview-value xview-to-solo)
      expr)))


(defmacro set-xview-attribute (id attribute value type solo-to-xview)
  `(let (,@(if solo-to-xview
	       `((value ,(subst `(the ,type ,value)  'solo-value solo-to-xview)))))
     (XV:with-xview-lock
       ,(if (eq type 'string)
	    `(set-xview-string-attribute ,id ,attribute ,value)
	  `(XV:xv-set ,id ,attribute ,value)))))



;;; These macros define xview reader and writer driver methods that get or set a single
;;; XView attribute.  If the XView object has not been realized then the reader and
;;; writer just update the objects initargs, if the object has been realized then 
;;; the xview object is accessed instead.

(defmacro def-xview-initarg-writer (driver attribute initarg &key (type t) solo-to-xview)
  `(defmethod (setf ,driver) (value (p XView) x)
     (XV:with-xview-lock 
       (let* ((xvo (device x))
	      (id (xview-object-id xvo)))
	 (if id
	     (progn
	       (set-xview-attribute id ,attribute value ,type ,solo-to-xview)
	       (xview-maybe-XFlush (xview-object-xvd xvo))
	       (the ,type value))
	   (setf (getf (xview-item-initargs xvo) ,initarg) (the ,type value)))))))


(defmacro def-xview-initarg-reader (driver attribute initarg &key (type t) xview-to-solo)
  `(defmethod ,driver ((p XView) x)
     (XV:with-xview-lock 
       (let* ((xvo (device x))
	      (id (xview-object-id xvo)))
	 (the ,type 
	      (if id
		  (get-xview-attribute id ,attribute ,type ,xview-to-solo)
		(getf (xview-item-initargs xvo) ,initarg)))))))


(defmacro def-xview-initarg-accessor (driver attribute initarg 
					     &key (type t) xview-to-solo solo-to-xview)
  `(progn
     (def-xview-initarg-reader ,driver ,attribute ,initarg 
       :type ,type :xview-to-solo ,xview-to-solo)
     (def-xview-initarg-writer ,driver ,attribute ,initarg 
       :type ,type :solo-to-xview ,solo-to-xview)))


;;; These macros are similar to the initarg-accessor macros defined above except
;;; that the Lisp attribute values are always cached in an xview-object slot.
;;; To read a slot defined this way we just look it up in the xview-object
;;; with the supplied accessor.  To write a slot we set the specified XView attribute 
;;; (with XV:xv-set) AND write the xview object slot with the accessor.

(defmacro def-xview-object-writer (driver attribute accessor &key (type t) solo-to-xview)
  `(defmethod (setf ,driver) (value (p XView) x)
     (XV:with-xview-lock 
       (let* ((xvo (device x))
	      (id (xview-object-id xvo)))
	 (when id
	   (progn
	     (set-xview-attribute id ,attribute value ,type ,solo-to-xview)
	     (xview-maybe-XFlush (xview-object-xvd xvo))))
	 ,@(if accessor
	       `((setf (,accessor xvo) (the ,type value)))
	     `(the ,type value))))))


(defmacro def-xview-object-accessor (driver attribute accessor &key (type t) solo-to-xview)
  `(progn 
     (defmethod ,driver ((p XView) x)
       (,accessor (device x)))
     (def-xview-object-writer ,driver ,attribute ,accessor 
       :type ,type :solo-to-xview ,solo-to-xview)))


;;; The functions below will gradually replace the def-xview-mumble functions above.

(defun xv-set-attr (value xvo id attr type)
  (XV:with-xview-lock 
    (when id
      (cond
       ((subtypep type 'number)
	(xv_set id attr (truncate value) XV_NULL))
       ((subtypep type 'string)
	(let ((fp (malloc-foreign-string value)))
	  (xv_set id attr fp XV_NULL)
	  (free-foreign-pointer fp)))
       ((subtypep type '(or image font menu))
	(let ((value-id (xview-object-id (device value))))
	  (when id
	    (xv_set id attr value-id XV_NULL))))
	((subtypep type 'color)
	 (let ((index (xview-color-index (device value))))
	   (when index
	     (xv_set id attr index XV_NULL))))
	((eq type 'boolean)
	 (xv_set id attr (if value TRUE FALSE) XV_NULL)))

    (xview-maybe-XFlush (xview-object-xvd xvo))))
  value)


(defun set-xview-attr (value obj attr &optional (type (type-of value)) (convert #'identity))
  (XV:with-xview-lock 
    (let* ((xvo (device obj))
	   (id (xview-object-id xvo)))
	(when id
	  (xv-set-attr (funcall convert value) xvo id attr type))))
  value)


(defun set-xview-initarg-attr (value obj attr initarg &optional (type (type-of value)) (convert #'identity))
  (XV:with-xview-lock 
    (let* ((xvo (device obj))
	   (id (xview-object-id xvo)))
      (if id
	  (xv-set-attr (funcall convert value) xvo id attr type)
	(setf (getf (xview-object-initargs xvo) initarg) value))))
  value)


(defun get-xview-initarg-attr (obj attr initarg &optional (type 'integer) (convert #'identity))
  (XV:with-xview-lock 
    (let* ((xvo (device obj))
	   (id (xview-object-id xvo)))
	(if id
	    (funcall convert
	     (let ((value (if (consp attr) 
			      (apply #'xv_get id attr)
			    (xv_get id attr))))
	       (ecase type
		(integer value)
		(boolean (if (/= value FALSE) t nil))
		(string
		 (when (/= 0 value)
		   (foreign-string-value
		    (make-foreign-pointer :type '(:pointer :character) 
					  :address value)))))))
	  (getf (xview-object-initargs xvo) initarg)))))



;;; X11 Constants

(defconstant x11-event-types
  '(X11:KeyPress
    X11:KeyRelease
    X11:ButtonPress
    X11:ButtonRelease
    X11:MotionNotify
    X11:EnterNotify
    X11:LeaveNotify
    X11:FocusIn
    X11:FocusOut
    X11:KeymapNotify
    X11:Expose
    X11:GraphicsExpose
    X11:NoExpose
    X11:VisibilityNotify
    X11:CreateNotify
    X11:DestroyNotify
    X11:UnmapNotify
    X11:MapNotify
    X11:MapRequest
    X11:ReparentNotify
    X11:ConfigureNotify
    X11:ConfigureRequest
    X11:GravityNotify
    X11:ResizeRequest
    X11:CirculateNotify
    X11:CirculateRequest
    X11:PropertyNotify
    X11:SelectionClear
    X11:SelectionRequest
    X11:SelectionNotify
    X11:ColormapNotify
    X11:ClientMessage
    X11:MappingNotify))


(defconstant x11-modifiers
  '(X11:Button1Mask 
    X11:Button2Mask 
    X11:Button3Mask 
    X11:Button4Mask 
    X11:Button5Mask
    X11:ShiftMask 
    X11:LockMask 
    X11:ControlMask 
    X11:Mod1Mask 
    X11:Mod2Mask 
    X11:Mod3Mask 
    X11:Mod4Mask 
    X11:Mod5Mask))

(defconstant x11-modifier-bits 
  (apply #'logior (mapcar #'symbol-value x11-modifiers)))


