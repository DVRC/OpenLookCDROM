;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.
;;; Shared Solo definitions

;;;@(#)defs.lisp	3.45 10/11/91


(in-package "LISPVIEW")


(proclaim '(special *default-platform*     ;; defined in platforms.lisp
		    *default-display*))


(deftype positive-fixnum ()
  '(and fixnum (integer 0 *)))

(deftype coercible-to-string ()
  '(or string symbol string-char))

(deftype boolean () t)


(defmacro check-arglist (&rest args)
  (if args
      `(progn
	 ,@(mapcar #'(lambda (arg)
		       `(check-type ,(car arg) ,(cadr arg)))
		   args))))



(deftype region-dimension () 'fixnum)

(deftype region-initarg () '(or null region-dimension))

(defun region-spec-p (x)
  (and (listp x) (evenp (length x))))

(deftype region-spec () '(satisfies region-spec-p))

(defstruct (REGION (:print-function print-region)
		   (:constructor %make-region)
		   (:copier %copy-region))
  (min-x 0 :type region-dimension)
  (min-y 0 :type region-dimension)
  (max-x 0 :type region-dimension)
  (max-y 0 :type region-dimension))

(defstruct (NOTIFICATION-REGION 
	    (:include region)
	    (:constructor make-notification-region (min-x min-y max-x max-y))))


(defclass WINDOW-SYSTEM ()
  ((name :reader window-system-name :initarg :name)))


(defclass XVIEW (window-system)
  ()
  (:default-initargs :name "XView"))


(defun search-path-p (x)
  (and (listp x)
       (every #'(lambda (p) (typep p '(or pathname string))) x)))

(deftype search-path ()
  '(satisfies search-path-p))


(defclass property-list ()
  ((property-list
     :type list
     :initform nil 
     :initarg :property-list
     :accessor property-list)))


(defclass lock ()
  ((lock :accessor lock :initform nil)))

(defclass display (lock property-list)
  ((platform 
     :type window-system 
     :reader platform 
     :initarg :platform)
   (root-canvas
     :type root-canvas
     :reader root-canvas)
   (backing-store-support
     :type t
     :reader backing-store-support)
   (supported-depths
     :type list
     :reader supported-depths)
   (images
     :type list
     :reader display-images
     :initform nil)
   (cursors
     :type list
     :reader display-cursors
     :initform nil)
   (fonts 
     :type list 
     :reader display-fonts
     :initform nil)
   (colormaps
     :type list 
     :reader display-colormaps
     :initform nil)
   (menus
     :type list
     :reader display-menus
     :initform nil)
   (font-search-path
     :type list
     :reader display-font-search-path
     :initarg :font-search-path)
   (graphics-context 
     :type graphics-context 
     :accessor graphics-context)
   (output-buffering
     :reader output-buffering
     :initarg :output-buffering)
   (status 
     :reader status
     :initarg :status)
   (device 
     :accessor device))
  (:default-initargs
    :status :realized
    :platform *default-platform*
    :server-number 0
    :screen-number 0
    :output-buffering nil))

(defvar *realized-displays* nil)
(defvar *default-display* nil)

(defun make-default-display ()
  (format t ";;; Creating a display for ~A ... ~%" 
         (window-system-name *default-platform*))
  (prog1
      (setq *default-display* (make-instance 'display))
   (format t ";;; ... Created an ~A display on host ~S, screen ~D, server ~D.~%"
	   (window-system-name *default-platform*)
	   (host *default-display*)
	   (screen *default-display*)
	   (server *default-display*))))

(defmacro default-display ()
  `(or *default-display* (make-default-display)))


(defvar *output-buffering* nil)


(defclass display-device-status (lock)
  ((display 
    :type display 
    :initarg :display 
    :reader display)
   (device 
    :initarg :device 
    :accessor device)
   (status 
    :type solo-allocation-status
    :initarg :status
    :reader status))
  (:default-initargs
    :display (default-display)
    :status :realized))

(deftype solo-allocation-status ()
  `(member :initialized :realized :destroyed))

(defun realize (object)
  (when (eq (status object) :initialized)
    (setf (status object) :realized)))

(defun destroy (object)
  (unless (eq (status object) :destroyed)
    (setf (status object) :destroyed)))


(defclass visual (display-device-status) ())

(defclass color-visual () ())
(defclass static-visual () ())

(defclass pseudo-color-visual (visual color-visual) ())
(defclass direct-color-visual (visual color-visual) ())
(defclass true-color-visual   (visual color-visual static-visual) ())
(defclass static-color-visual (visual color-visual static-visual) ())
(defclass gray-scale-visual   (visual) ())
(defclass static-gray-visual  (visual static-visual) ())
(defclass monochrome-visual   (visual static-visual) ())


(deftype color-component () '(float 0.0 1.0))

(defclass color (display-device-status)
  ((red        :type color-component :initarg :r :initarg :red)
   (green      :type color-component :initarg :g :initarg :green)
   (blue       :type color-component :initarg :b :initarg :blue)
   (hue        :type color-component :initarg :h :initarg :hue)
   (saturation :type color-component :initarg :s :initarg :saturation)
   (intensity  :type color-component :initarg :i :initarg :intensity)
   (name  :type coercible-to-string :initarg :name :reader name)
   (pixel :type integer :initarg :pixel :reader pixel)
   (colormap :type colormap :initarg :colormap :reader colormap)))

(defmacro check-color-components (&rest components)
  `(progn
     ,@(mapcar #'(lambda (x)
		   `(check-type ,x color-component "in the range 0.0, 1.0"))
	       components)))

(defclass undefined-color (color) ()
  (:default-initargs
   :pixel 0
   :name "Undefined"
   :red 0.0
   :green 0.0
   :blue 0.0))


(defun color-triplet-p (triplet)
  (and (typep triplet 'sequence) 
       (= (length triplet) 3)
       (every #'(lambda (n) (typep n 'color-component)) triplet)))

(deftype color-spec ()
  '(or coercible-to-string (satisfies color-triplet-p)))


(defconstant colormap-load-rgb '#(T T T))

(defclass colormap (display-device-status)
  ((undefined-color :type undefined-color))
  (:default-initargs
   :load colormap-load-rgb
   :skip t))

(defclass read-only-colormap () ())
(defclass read-write-colormap () ())
(defclass decomposed-colormap () ())
(defclass undecomposed-colormap () ())

(defclass pseudo-colormap 
  (colormap read-write-colormap undecomposed-colormap) ())

(defclass gray-scale-colormap
  (colormap read-write-colormap undecomposed-colormap) ())

(defclass direct-colormap
  (colormap read-write-colormap decomposed-colormap) ())

(defclass true-colormap
  (colormap read-only-colormap decomposed-colormap) ())

(defclass static-colormap 
  (colormap read-only-colormap undecomposed-colormap) ())

(defclass static-gray-colormap
  (colormap read-only-colormap undecomposed-colormap) ())

(defclass monochrome-colormap
  (colormap read-only-colormap undecomposed-colormap) ())


(defun colormap-skip-sequence-p (x) 
  (or (eq x t)
      (and (typep x 'sequence) (every #'numberp x))))

(deftype colormap-skip-sequence ()
  '(satisfies colormap-skip-sequence-p))



(defclass char-metrics ()
  ((left-bearing 
    :type fixnum 
    :reader char-left-bearing
    :initarg :left-bearing)
   (right-bearing 
    :type fixnum
    :reader char-right-bearing
    :initarg :right-bearing)
   (width 
    :type fixnum
    :reader char-width
    :initarg :width)
   (ascent 
    :type fixnum
    :reader char-ascent
    :initarg :ascent)
   (descent 
    :type fixnum
    :reader char-descent
    :initarg :descent)))


(defclass zero-char-metrics (char-metrics)
  ()
  (:default-initargs
   :left-bearing 0
   :right-bearing 0
   :width 0
   :ascent 0
   :descent 0))



(macrolet
 ((def-font-type (parameter args type-spec)
    (let ((type-name (intern (format nil "FONT-~A" parameter)))
	  (keyword (intern (string parameter) (find-package :keyword))))
      `(progn
	 (eval-when (compile load eval) 
	   (setf (get ,keyword 'font-parameter-type) ',type-name))
	 (deftype ,type-name ,args
	   ,type-spec)))))
	 
  (def-font-type foundry () 'coercible-to-string)
  (def-font-type family () 'coercible-to-string)
  (def-font-type weight () 'coercible-to-string)

  (def-font-type slant ()
    '(member :roman :italic :oblique :reverse-italic :reverse-oblique))

  (def-font-type setwidth () 'coercible-to-string)

  (def-font-type pixel-size () 'positive-fixnum)
  
  (def-font-type point-size () '(and number (or (satisfies zerop) (satisfies plusp))))

  (def-font-type resolution-x () 'positive-fixnum)
  (def-font-type resolution-y () 'positive-fixnum)

  (def-font-type spacing ()
    '(member :monospaced :proportional :character-cell))

  (def-font-type average-width () 'positive-fixnum)

  (def-font-type charset-registry () 'coercible-to-string)
  (def-font-type charset-encoding () 'coercible-to-string))


(defclass font (display-device-status)
  ((specification
    :type list
    :accessor font-spec
    :initarg :spec)))


(defclass interest () ())

(defconstant mouse-actions
  '(:move :enter :exit (or :enter :exit) (or :exit :enter)))

(proclaim '(inline mouse-action-p))

(defun mouse-action-p (x)
  (member x mouse-actions :test #'equal))

(deftype mouse-action () '(satisfies mouse-action-p))

(eval-when (load eval compile)
  (defconstant button-names 
    (let ((names nil))
      (dotimes (n 10 (nreverse names))
	(push (intern (format nil "BUTTON~D" n) (find-package :keyword)) names)))))

(defvar *button-name-synonyms*
  `((:left . :button0)
    (:middle . :button1)
    (:right . :button2)
    (:any-button . (or ,@button-names))))

(proclaim '(inline button-name-p))

(defun button-name-p (name)
  (or (assoc name *button-name-synonyms* :test #'eq)
      (member name button-names :test #'eq)))

(deftype button-name () '(satisfies button-name-p))

(defconstant button-actions
  '(:up :down :click1 :click2 :click3 :click4 (or :up :down) (or :down :up)))

(proclaim '(inline button-action-p))

(defun button-action-p (action)
  (member action button-actions :test #'equal))

(deftype button-action () '(satisfies button-action-p))

(defconstant modifier-names 
  '(:shift :control :meta :super :hyper :left :middle :right :others))

(defvar *modifier-name-synonyms*
  '((:left . :button0)
    (:middle . :button1)
    (:right . :button2)
    (:any-modifier . (:others (or :up :down)))))

(defun modifier-name-p (name)
  (or (and (keywordp name) 
	   (or (assoc name *modifier-name-synonyms* :test #'eq)
	       (member name modifier-names :test #'eq)))
      (and (consp name) 
	   (and (let ((id (nth 0 name)))
		  (or (keywordp (cdr (assoc id *modifier-name-synonyms* :test #'eq)))
		      (member id modifier-names :test #'eq)))
		(member (nth 1 name) button-actions :test #'equal)))))

(deftype modifier () '(satisfies modifier-name-p))

(deftype keyboard-focus-mode ()
  '(member nil :passive :locally-active :globally-active))
 
(deftype keyboard-key-type ()
  '(member :ascii :modifier :cursor :function :keypad :misc-function :programmable-function :any))

(defun keyboard-event-spec-p (x)
  (let ((key-types (car x))
	(action (cadr x)))
    (and 
     (if (consp key-types)
	 (every #'(lambda (kt) (typep kt 'keyboard-key-type)) key-types)
       (typep key-types 'keyboard-key-type))
     (member action '(:up :down (or :up :down) (or :down :up)) :test #'equal))))


(defclass mouse-interest (interest)
  ((parsed-event-spec :type list)))

(defclass keyboard-interest (interest) 
  ((event-spec :type list :initarg :event-spec))
  (:default-initargs
   :event-spec '(:ascii :down)))

(defclass damage-interest (interest) ())

(defclass keyboard-focus-interest (interest) ())

(defclass visibility-change-interest (interest) ())


(defvar *keyboard-focus-lock* nil)

(defmacro with-keyboard-focus-lock (&body body)
  `(MP:with-process-lock (*keyboard-focus-lock*) ,@body))


(defclass queue ()
  ((buffer :initform (make-array 512) :type simple-vector)
   (in :initform 0 :type fixnum)
   (out :initform 0 :type fixnum)))

(defmacro process-event-queue (p)
  `(getf (process-plist ,p) 'event-queue))



(defstruct event 
  object
  timestamp
  interest
  raw-event)

(defstruct (bounding-region-notification-event (:include event)) region)
(defstruct (parent-notification-event (:include event)) parent)
(defstruct (stacking-order-notification-event (:include event)) above)
(defstruct (status-notification-event (:include event)) status)
(defstruct (closed-notification-event (:include event)) closed)
(defstruct (mapped-notification-event (:include event)) mapped)

(defstruct (visibility-change-event (:include event)) visibility)

(defstruct (keyboard-focus-event (:include event)) focus virtual)

(defstruct (damage-event (:include event)) regions)

(defstruct (keyboard-event (:include event)) x y type string keysym state)

(defstruct (scroll-event (:include event)) scrollbar motion view-start)

(defstruct (lispview-ipc-event (:include event)) message)


;;; %gesture captures the action that triggered the mouse event the state of 
;;; the keyboard modifier keys, the mouse buttons not involved in the action, 
;;; and the action that triggered the event.  This information is respresented
;;; in a platform specific way - it's only decoded when the application asks
;;; for it with the mouse-event-gesture accessor.

(defstruct (mouse-event (:include event))
  (x 0 :type fixnum)
  (y 0 :type fixnum)
  %gesture)

(defstruct (mouse-moved-event (:include mouse-event)))

(defstruct (mouse-button-event (:include mouse-event)))

(defstruct (mouse-crossing-event (:include mouse-event)))



(defclass cursor (display-device-status) ())


(defclass drawable () ())


(defclass tree-node () ())

(defclass parent () 
  ((parent :initform nil :reader parent)))

(defclass children ()
  ((children :type list :initform nil)))

(defmethod children ((x children)) (copy-list (slot-value x 'children)))

(defclass interests ()
  ((interests :type list :initform nil)))


(deftype insert-relation () '(member :before :after :at))


(defclass event-dispatch ()
  ((event-dispatch-process
     :initarg :event-dispatch-process 
     :reader event-dispatch-process)
   (event-dispatch-queue 
     :accessor event-dispatch-queue)))

(deftype event-dispatch-process ()
  '(and process (satisfies process-alive-p)))


(defclass bounding-region () ())


(defclass canvas (event-dispatch 
		  display-device-status 
		  tree-node
		  parent 
		  children
		  interests
		  bounding-region)
   ()
   (:default-initargs 
    :mapped t
    :cursor nil))



(deftype backing-store ()
  '(member t nil :when-mapped))

(defconstant bit-gravity-keywords
  '(:northwest :north :northeast :west :center :east 
    :southwest :south :southeast :static :forget))
  
(deftype bit-gravity ()
  `(or null (member ,@bit-gravity-keywords)))
	   
(defclass opaque-canvas (drawable canvas) ()
  (:default-initargs
   :backing-store nil
   :bit-gravity :forget
   :foreground nil
   :background nil))

(defclass transparent-canvas (canvas) ())


(defun pixel-map-p (v)
  (or (null v) (and (typep v 'vector) (every #'integerp v))))

(deftype pixel-map () '(satisfies pixel-map-p))

(defclass image (drawable display-device-status bounding-region property-list)
  ()
  (:default-initargs
   :depth 1))

(defun bitmap-p (x)
  (and (typep x 'image) (= (depth x) 1)))

(deftype bitmap ()
  '(satisfies bitmap-p))


(defconstant boole-constants 
  '(boole-clr boole-and boole-andc2 boole-1
    boole-andc1 boole-2 boole-xor boole-ior
    boole-nor boole-eqv boole-c2 boole-orc2
    boole-c1 boole-orc1 boole-nand boole-set))

(deftype boole-constant ()
  '(member #.boole-clr #.boole-and #.boole-andc2 #.boole-1
	   #.boole-andc1 #.boole-2 #.boole-xor #.boole-ior
	   #.boole-nor #.boole-eqv #.boole-c2 #.boole-orc2
	   #.boole-c1 #.boole-orc1 #.boole-nand #.boole-set))


(deftype line-style ()
  '(member :dash :double-dash :solid))

(deftype cap-style ()
  '(member :butt :not-last :projecting :round))

(deftype join-style ()
  '(member :bevel :miter :round))

(deftype fill-style ()
  '(member :opaque-stippled :solid :stippled :tiled))

(deftype fill-rule ()
  '(member :even-odd :winding))

(deftype subwindow-mode ()
  '(member :clip-by-children :include-inferiors))

(deftype on-off ()
  '(member :on :off))

(deftype clip-mask ()
  '(or image region list))

(deftype arc-mode ()
  '(member :chord :pie-slice))

(defun dashes-list-p (x)
  (and (listp x) (every #'(lambda (d) (typep d '(integer 1 *))) x)))

(deftype dashes-list ()
  `(satisfies dashes-list-p))

(defconstant graphics-context-slot-names  
  '(operation 
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
    arc-mode))


(defclass GRAPHICS-CONTEXT (display-device-status) ()
  (:default-initargs
     :operation boole-1
     :plane-mask #xFF
     :line-width 0
     :line-style :solid
     :cap-style :butt
     :join-style :miter
     :fill-style  :solid
     :fill-rule :even-odd
     :ts-x-origin 0
     :ts-y-origin 0
     :clip-mask nil
     :clip-x-origin 0
     :clip-y-origin 0
     :dash-offset 0
     :dashes nil
     :arc-mode :pie-slice
     :graphics-exposures :on
     :subwindow-mode :clip-by-children))



(defclass root-canvas (opaque-canvas)
  ()
  (:default-initargs
   :parent nil
   :mapped t))


(defclass window (opaque-canvas) ()
  (:default-initargs
   :border-width 0))


(defclass panel (window) ())


(deftype top-level-window-state () '(member :open :closed))

(defclass top-level-window (window) ()
  (:default-initargs
   :label ""
   :left-footer nil
   :right-footer nil
   :state :open
   :busy nil
   :show-resize-corners t))


(defclass base-window (top-level-window) ()
  (:default-initargs
   :confirm-quit nil))


(defclass popup-window (top-level-window) ()
  (:default-initargs
   :show-resize-corners nil
   :pushpin :in))


(defclass icon (display-device-status) ())

(defun icon-label-p (label)
  (or (typep label '(or null string image))
      (and (consp label)
	   (every #'(lambda (x) (typep x '(or string image))) label))))

(deftype icon-label ()
  '(satisfies icon-label-p))


(defclass item (display-device-status 
		tree-node
		parent
		bounding-region)
  ()
  (:default-initargs
   :mapped t
   :state :active
   :layout :horizontal))

(deftype item-state () '(member :active :inactive))

(deftype item-layout ()  '(member :vertical :horizontal))



(defclass label ()
  ((label
    :type t 
    :initarg :label 
    :reader label)))

(deftype item-label () '(or null string image))


(defclass message (item label) ())


(defclass command ()
  ((command 
    :initarg :command
    :accessor command)))


(defclass update-value ()
  ((update-value
    :initarg :update-value
    :reader update-value
    :type function))
  (:default-initargs
   :update-value nil))

(defstruct (update-value-event (:include event)) value op)

(defun default-scrolling-list-validate-choice-callback (sl row choice)
  (declare (ignore sl row))
  choice)

(defclass choice-label-callback ()
  ((choice-label 
      :type function
      :initarg :choice-label-callback
      :initform #'label
      :accessor choice-label-callback)))


(defclass scrolling-list (item label update-value choice-label-callback)
  ((validate-choice-callback
    :initarg :validate-choice-callback
    :accessor validate-choice-callback))
  (:default-initargs
   :choices nil
   :read-only nil
   :validate-choice-callback #'default-scrolling-list-validate-choice-callback))


(defclass exclusive-scrolling-list (scrolling-list) 
  ()
  (:default-initargs
   :selection-required nil))

(defclass non-exclusive-scrolling-list (scrolling-list) ())
   

(defclass setting (item label update-value choice-label-callback)
  ()
  (:default-initargs
   :choices nil))

(defclass exclusive-setting (setting)
  ()
  (:default-initargs
   :default 0
   :selection-required t))

(defclass abbreviated-exclusive-setting (exclusive-setting)
  ())

(defclass toggle () 
  ()
  (:default-initargs 
   :default nil))

(defclass non-exclusive-setting (toggle setting) ())

(defclass check-box (toggle setting) ())


(defstruct (button-pressed-event (:include mouse-event)))

(deftype button-state () '(member :active :inactive :busy))

(defclass button (item label) ())

(defclass command-button (button command) ())

(defclass menu-button (button) ())


(deftype text-field-notify-level ()
  '(member :none :non-printable :specified :all))

(defclass text-field (item label update-value)
  ()
  (:default-initargs
   :layout :horizontal
   :value nil
   :read-only nil
   :value-underlined t
   :stored-value-length nil
   :displayed-value-length nil
   :notify-level :specified
   :notify-chars (list #\newline #\tab #\return)
   :mask-char nil))


(defclass numeric-range ()
  ()
  (:default-initargs
   :min-value 0
   :max-value 100))
   

(defclass numeric-field (numeric-range text-field)
  ()
  (:default-initargs
   :underline nil))


(defclass gauge (numeric-range item label) ())

(defclass vertical-gauge (gauge) ())

(defclass horizontal-gauge (gauge) ())


(defclass slider (gauge update-value) ())

(defclass vertical-slider (slider) ())

(defclass horizontal-slider (slider) ())


(defun menu-spec-choice-p (x)
  (and (consp x)
       (typep (nth 0 x) '(or string image))
       (typep (nth 1 x) '(or (member :menu) function))))

(deftype menu-spec-choice ()
  '(satisfies menu-spec-choice-p))

(deftype menu-label () '(or null string image))

(deftype menu-layout () '(member :vertical :horizontal :row-major :col-major))

(defclass menu (event-dispatch display-device-status label)
  ()
  (:default-initargs
   :label nil
   :choices nil
   :pushpin nil
   :items nil
   :choices-nrows nil
   :choices-ncols nil
   :layout :vertical))

(proclaim '(inline menu-item-list-p))

(defun menu-item-list-p (choices)
  (or (null choices)
      (and (consp choices) (typep (car choices) 'menu-item))))

(defun menu-choices-p (choices)
  (cond
   ((null choices))
   ((menu-item-list-p choices)
    (every #'(lambda (choice) (typep choice 'menu-item)) choices))
   (t
    (functionp choices))))

(defstruct (menu-dismissed-event (:include event)))

(deftype menu-item-state () '(member :active :inactive :busy))

(defclass menu-item (display-device-status label)
  ()
  (:default-initargs
   :mapped t
   :state :active))

(defstruct (menu-item-selected-event (:include event)) item)

(defclass command-menu-item (menu-item command) ())

(defclass submenu-item (menu-item)
  ((menu 
    :type menu 
    :initarg :menu 
    :reader menu)))

(defclass spacer-menu-item (menu-item) ())


(defstruct (update-scrollbar-event (:include event))
  view-min
  view-max
  view-start
  view-length)


(defclass scrollbar (event-dispatch 
		     display-device-status 
		     tree-node
		     parent
		     bounding-region)
  ((client
    :type t
    :initarg :client
    :reader scrollbar-client))
  (:default-initargs
   :parent nil
   :client nil
   :menu nil
   :splittable nil))

(defclass horizontal-scrollbar (scrollbar) ())

(defclass vertical-scrollbar (scrollbar) ())

(defclass viewport (window) ()
  (:default-initargs
   :vertical-scrollbar nil
   :horizontal-scrollbar nil))

(defclass scrolling-window (window)
  ((viewports
    :type list
    :initarg :viewports))
  (:default-initargs
   :viewport-class 'viewport))



;;; Define a simple Solo accessor.  The reader just applies DD-name to 
;;; ((platform x) x), the writer checks the type of its
;;; first argument before calling (setf DD-name).  For example:
;;;      (def-solo-accessor label base-window :type string)
;;; generates the following code:
;;;
;;; (progn
;;;   (defmethod label ((x base-window))
;;;     (the string (dd-label (platform x) x)))
;;;   (defmethod (setf label) (value (x base-window))
;;;     (check-type value string)
;;;     (setf (dd-label (platform x) x) (the string value))))

(defun solo-driver (name driver)
  (or driver (intern (format nil "DD-~A" (string-upcase name)))))

(defmacro def-solo-reader (name class &key (type t) driver)
  (let ((driver (solo-driver name driver)))
    `(defmethod ,name ((x ,class))
       (the ,type (,driver (platform x) x)))))
				
(defmacro def-solo-writer (name class &key type driver)
  (let ((driver (solo-driver name driver)))
    `(defmethod (setf ,name) (value (x ,class))
       ,@(if type
	     `((check-type value ,type)))
       (setf (,driver (platform x) x) 
	     (the ,(or type T) value)))))
  
(defmacro def-solo-accessor (name class &key (type T) driver)
  `(progn
     (def-solo-reader ,name ,class :type ,type :driver ,driver)
     (def-solo-writer ,name ,class :type ,type :driver ,driver)))

