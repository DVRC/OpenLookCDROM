;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)types.lisp	3.6 10/11/91



(in-package :xview :use '(lisp))


;;; The following definitions disappeared in the pre-FCS version of XView:
;;;
;;; colormapseg, cms-map


;;; The following definitions were added for the pre-FCS version of Solo 
;;; XView interface:
;;;
;;; xv-cmsdata, xv-singlecolor


;;;
;;; The "rect" structures from rect.h, rectlist.h
;;;

(def-exported-foreign-struct rect
  (r-left :type short)
  (r-top :type short)
  (r-width :type short)
  (r-height :type short))

(def-exported-foreign-struct rectnode
  (rn-next :type (:pointer rectnode)) 
  (rn-rect :type rect))

(def-exported-foreign-struct rectlist
  (rl-x :type short)
  (rl-y :type short)
  (rl-head :type (:pointer rectnode))
  (rl-tailp :type (:pointer rectnode))
  (rl-bound :type rect))


;;; "callback" is a C function pointer

(def-exported-foreign-synonym-type callback caddr-t) 


;;; Most of the exported xview types are "opaque", i.e. only functional access 
;;; to these objects is supported.

(def-exported-foreign-synonym-type Xv-opaque           caddr-t)   ;; base.h
(def-exported-foreign-synonym-type Xv-pkg              caddr-t) 
(def-exported-foreign-synonym-type Xv-object           xv-opaque) 
(def-exported-foreign-synonym-type Canvas              xv-opaque) ;; canvas.h
(def-exported-foreign-synonym-type Canvas-view         xv-opaque)
(def-exported-foreign-synonym-type Canvas-paint-window xv-opaque)
(def-exported-foreign-synonym-type Xv-Cursor           xv-opaque) ;; cursor.h      
(def-exported-foreign-synonym-type Xv-Drawable         xv-opaque) ;; drawable.h
(def-exported-foreign-synonym-type Frame       	       xv-opaque) ;; frame.h  
(def-exported-foreign-synonym-type Fullscreen          xv-opaque) ;; fullscreen.h  
(def-exported-foreign-synonym-type Icon                xv-opaque) ;; icon.h        
(def-exported-foreign-synonym-type Menu                xv-opaque) ;; openmenu.h    
(def-exported-foreign-synonym-type Menu-item           xv-opaque)                  
(def-exported-foreign-synonym-type Scrollbar           xv-opaque) ;; scrollbar.h   
(def-exported-foreign-synonym-type Xv-Server           xv-opaque) ;; server.h      
(def-exported-foreign-synonym-type Server-image        xv-opaque) ;; svrimage.h    
(def-exported-foreign-synonym-type Termsw              xv-opaque) ;; termsw.h      
(def-exported-foreign-synonym-type Termsw-view         xv-opaque)                  
(def-exported-foreign-synonym-type Tty                 xv-opaque) ;; tty.h         
(def-exported-foreign-synonym-type Tty-view            xv-opaque) ;; tty.h         
(def-exported-foreign-synonym-type Ttysubwindow        caddr-t)   ;; ttysw.h       
(def-exported-foreign-synonym-type Xv-Window           xv-opaque) ;; window.h      
(def-exported-foreign-synonym-type window-type         int)                        


;;; attr.h

(def-exported-foreign-synonym-type Attr-avlist (:pointer xv-opaque))
(def-exported-foreign-synonym-type Attr-attribute unsigned-int)


;;; cms.h 

;;; Warning: the dummy slot is a patch for a Lucid FFI bug.  When the real
;;; bugfix is available the dummy slot must be removed.

(def-exported-foreign-struct xv-cmsdata
  (type :type xv-cmstype)
  (size :type short)
  (index :type short)
  (rgb-count :type short)
  (red :type (:pointer unsigned-char))
  (green :type (:pointer unsigned-char))
  (blue :type (:pointer unsigned-char)))


(def-exported-foreign-struct xv-singlecolor
  (red :type unsigned-char)
  (green :type unsigned-char)
  (blue :type unsigned-char))



;;; font.h 

(def-exported-foreign-struct font-string-dims
  (width :type int)
  (height :type int))

(def-exported-foreign-synonym-type Xv-Font xv-opaque) 


;;;  notify.h

(def-exported-foreign-synonym-type notify-client caddr-t)
(def-exported-foreign-synonym-type notify-event caddr-t)
(def-exported-foreign-synonym-type notify-arg caddr-t)
(def-exported-foreign-synonym-type notify-func caddr-t)


;;; panel.h

(def-exported-foreign-synonym-type Panel                   xv-opaque)
(def-exported-foreign-synonym-type Panel-item              xv-opaque)
(def-exported-foreign-synonym-type Panel-attribute-value   xv-opaque)
(def-exported-foreign-synonym-type Xv-panel                xv-opaque)
(def-exported-foreign-synonym-type Xv-item                 xv-opaque)
(def-exported-foreign-synonym-type Panel-view              xv-opaque)
(def-exported-foreign-synonym-type Xv-panel-message        xv-item)
(def-exported-foreign-synonym-type panel-or-item           xv-opaque)


;;; selection.h

(def-exported-foreign-struct selection
  (sel-type :type int)
  (sel-items :type int)
  (sel-itembytes :type int)
  (sel-pubflags :type int)
  (sel-privdata :type caddr-t))


;;;   The following types exist to support the definition of seln-access, they
;;;   were culled from /usr/include/netinet/in.h 

(def-foreign-struct in-addr-struct-1
  (s-b1 :type u-char)
  (s-b2 :type u-char)
  (s-b3 :type u-char)
  (s-b4 :type u-char))

(def-foreign-struct in-addr-struct-2
  (s-w1 :type u-short) 
  (s-w2 :type u-short))

(def-foreign-struct in-addr-struct-3
  (s-un-b :type in-addr-struct-1 :offset 0)
  (s-un-w :type in-addr-struct-2 :offset 0)
  (s-addr :type u-long :offset 0))

(def-foreign-struct in-addr
  (s-un :type in-addr-struct-3))

(def-foreign-struct sockaddr-in
  (sin-family :type short)
  (sin-port :type u-short)
  (sin-addr :type in-addr)
  (sin-zero :type (:array char (8))))


;;; sel_svc.h

(def-exported-foreign-synonym-type seln-client (:pointer char))
(def-exported-foreign-synonym-type seln-rank :signed-32bit)
(def-exported-foreign-synonym-type seln-state :signed-32bit)
(def-exported-foreign-synonym-type seln-function :signed-32bit)
(def-exported-foreign-synonym-type seln-result :signed-32bit)

(def-exported-foreign-struct seln-file-info
  (rank :type seln-rank) 
  (pathname :type (:pointer char)))

(def-exported-foreign-struct seln-access
  (pid :type int)
  (program :type int)
  (tcp-address :type sockaddr-in)
  (udp-address :type sockaddr-in)
  (client :type (:pointer char)))

(def-exported-foreign-struct seln-holder
  (rank :type seln-rank) 
  (state :type seln-state) 
  (access :type seln-access))

(def-exported-foreign-struct seln-holders-all
  (caret :type seln-holder)
  (primary :type seln-holder)
  (secondary :type seln-holder)
  (shelf :type seln-holder))

(def-exported-foreign-struct seln-function-buffer
  (function :type seln-function)
  (addressee-rank :type seln-rank)
  (caret :type seln-holder)
  (primary :type seln-holder)
  (secondary :type seln-holder)
  (shelf :type seln-holder))

(def-exported-foreign-struct seln-replier-data
  (client-data :type (:pointer char))
  (rank :type seln-rank)
  (context :type (:pointer char))
  (request-pointer :type (:pointer (:pointer char)))
  (response-pointer :type (:pointer (:pointer char))))

(def-exported-foreign-struct seln-requester
  (consume :type caddr-t)
  (context :type (:pointer char)))

(def-exported-foreign-struct seln-request
  (replier :type (:pointer seln-replier-data))
  (requester :type seln-requester)
  (addressee :type (:pointer char))
  (rank :type seln-rank)
  (status :type seln-result)
  (buf-size :type unsigned)
  (data :type (:array char (1892)))) ;; Warning - sun3 specific



;;; textsw.h

(def-exported-foreign-synonym-type Textsw            xv-opaque)
(def-exported-foreign-synonym-type Textsw-view       xv-opaque)
(def-exported-foreign-synonym-type Textsw-opaque     caddr-t)
(def-exported-foreign-synonym-type Textsw-mark       Textsw-opaque)
(def-exported-foreign-synonym-type Textsw-index      long)


;;; timeval from /usr/include/sys/time.h

(def-exported-foreign-struct timeval
  (tv-sec :type long) 
  (tv-usec :type long))


;;; The "event" structure from win_input.h 

#+ignore
(def-exported-foreign-struct event
  (ie-code :type short)
  (ie-flags :type short)
  (ie-shiftmask :type short)
  (ie-locx :type short)
  (ie-locy :type short)
  (ie-time :type timeval)
  (action  :type short)                   ;; keymapped version of ie-code - xview
  (ie-win  :type Xv-object)               ;; window the event is directed to - xview
  (ie-string :type (:pointer :char))      ;;string returned by XLookupString 
  (ie-xevent :type (:pointer X11:XEvent)))


(def-exported-foreign-struct event
  (ie-code :type short)
  (ie-flags :type short)
  (ie-shiftmask :type short)
  (ie-locx :type short)
  (ie-locy :type short)
  (ie-time :type timeval)
  (action  :type short)                   ;; keymapped version of ie-code - xview
  (ie-win  :type Xv-object)               ;; window the event is directed to - xview
  (ie-string :type :signed-32bit)
  (ie-xevent :type :signed-32bit))


;;; Some of the pixrect structures from /usr/include/pixrect/pixrect.h

(def-exported-foreign-struct pr-size
  (x :type int) 
  (y :type int))


(def-exported-foreign-struct pixrect
  (pr-ops :type caddr-t)
  (pr-size :type pr-size)
  (pr-depth :type int)
  (pr-data :type caddr-t))


(def-exported-foreign-struct pr-pos
  (x :type int) 
  (y :type int))


;;; memory pixrect data structure from /usr/include/pixrect/memvar.h

(def-exported-foreign-struct mpr-data
  (md-linebytes :type int)
  (md-image :type (:pointer short))
  (md-offset :type pr-pos)
  (md-primary :type short)
  (md-flags :type short))




;;; BELOW - Lisp types that are related to the XView foreign types

(deftype xview-package ()
  "package keyword for xv-create and xv-find"
  '#.(cons 'member (mapcar #'car *xview-packages*)))


;;; MULTIPLE-VALUED-ATTRIBUTES
;;;
;;; Many of the lisp keywords that represented attributes have been organized
;;; into types and augmented with properties to facilitate mapping from 
;;; Lisp style keyword value argument lists to C attribute value argument
;;; lists.  C attribute value lists aren't always just alternating enum
;;; value pairs terminated by a 0, SunView uses several variations which 
;;; we identify with Lisp types:
;;; 
;;; list-attribute
;;; For example MENU_STRINGS in 
;;;    xv_create(NULL, MENU, MENU_STRINGS, "1", "2", "3", 0, 0);
;;; or WIN_MOUSE_XY in 
;;;    xv_set(window, :WIN_MOUSE_XY, 128, 155, 0);
;;; List attributes are either 0 terminated arbitrary length "lists" 
;;; of values (like MENU_STRINGS) or fixed length "lists" of values (like
;;; WIN_MOUSE_XY).  In lisp these examples would be written: 
;;;    (xv-create null :menu :menu_strings '("1" "2" "3"))
;;;    (xv-set window :win-mouse-xy '(128 155))
;;;
;;; avlist-attribute
;;; For example MENU_ITEM in 
;;;   (xv_create menu, MENU_ITEM, MENU_STRING, "1" MENU_FONT, font, 0, 0)
;;; AVlist attributes are embedded attribute value lists, in Lisp
;;; they are just keyword value lists.  The example would be written:
;;;   (xv-create menu :menu-item (list :menu-string "1" :menu-font font))
;;;

(eval-when (compile load eval)
  (defparameter *fixed-length-list-attributes*
    '((:font-rescale-of . (xv-font (:pointer frame-scale-state)))
      (:menu-action-image . ((:pointer server-image) callback))
      (:menu-action-item . (string callback))
      (:menu-gen-pin-window . (frame string))
      (:menu-gen-proc-image . ((:pointer server-image) callback))
      (:menu-gen-proc-item . (string callback))
      (:menu-gen-pullright-image . ((:pointer server-image) callback))
      (:menu-gen-pullright-item . (string callback))
      (:menu-image-item . ((:pointer server-image) xv-opaque))
      (:menu-insert . (int menu-item))
      (:menu-insert-item . (menu-item menu-item))
      (:menu-pullright-image . ((:pointer server-image) menu))
      (:menu-pullright-item . (string menu))
      (:menu-replace . (int menu-item))
      (:menu-replace-item . (menu-item menu-item))
      (:menu-string-item . (string xv-opaque))
      (:notice-button . (string int))
      (:notice-focus-xy . (int int))
      (:panel-choice-image . (int (:pointer server-image)))
      (:panel-choice-string . (int string))
      (:panel-list-client-data . (int long))
      (:panel-list-font . (int xv-font))
      (:panel-list-select . (int boolean))
      (:panel-list-string . (int string))
      (:panel-list-glyph . (int (:pointer server-image)))
      (:panel-toggle-value . (int int))
      (:xv-init-args . (int (:pointer (:pointer char))))
      (:xv-init-argc-ptr-argv . ((:pointer int) (:pointer (:pointer char))))
      (:xv-key-data . (attribute int))
      (:win-mouse-xy . (int int)))
    "Assoc table of attributes whose value must be a fixed length Lisp list"))

	     
(eval-when (compile load eval)
  (defvar *arbitrary-length-list-attributes*
    '((:cms-named-colors . (string))
      (:menu-images . ((:pointer server-image)))
      (:menu-strings . (string))
      (:notice-message-strings . (string))
      (:panel-choice-images . ((:pointer server-image)))
      (:panel-choice-strings . (string))
      (:panel-list-client-datas . (caddr-t))
      (:panel-list-fonts . (xv-font))
      (:panel-list-glyphs . (int (:pointer server-image)))
      (:panel-list-strings . (string))
      (:seln-request-contents-pieces . (caddr-t))
      (:win-ignore-events . (int))
      (:win-consume-events . (int)))
    "Assoc table of attributes whose value can be an arbitrary length Lisp list"))

(deftype list-attribute ()
  "Attributes whose value must a Lisp list"
  '#.(cons 'member (nconc (mapcar #'car *fixed-length-list-attributes*)
			  (mapcar #'car *arbitrary-length-list-attributes*))))


(dolist (x (append *fixed-length-list-attributes* 
		   *arbitrary-length-list-attributes*))
  (setf (get (car x) 'attribute-type) (cdr x)))


(dolist (x *fixed-length-list-attributes*)
  (setf (get (car x) 'list-attribute-length) (cdr x)))


(deftype avlist-attribute ()
  "Attributes whose value must be a Lisp keyword value list"
  '(member :canvas-paintwindow-attrs
	   :menu-item 
	   :openwin-split
	   :openwin-view-attrs))

(deftype multiple-valued-attribute ()
  `(or list-attribute avlist-attribute))



;;; FLAG-ATTRIBUTE
;;; These C attributes could just as well have been boolean valued, 
;;; although they appear in C attribute-value lists they aren't paired
;;; with a value.  In Lisp flag valued attributes are treated like
;;; booleans, if their value is nil then the attribute will not appear
;;; in the C attribute-value list.

(deftype flag-attribute ()
  "Attribute whose C representation doesn't require a value"
  '(member :menu-descend-first
	   :menu-release
	   :menu-release-image
	   :server-sync-and-process-events
	   :win-input-only))
	   


;;; CALLBACK-ATTRIBUTE
;;; The value of callback attributes like CANVAS_REPAINT_PROC must be 
;;; the address of a C callable function. In lisp callbacks are represented 
;;; by the name (symbol) of a foreign callable function.  At run-time 
;;; the address of the foreign function is computed and passed along to C.

(deftype callback-attribute ()
  "Attributes whose value must be a pointer to a C callable function"
  '(member :canvas-repaint-proc 
	   :canvas-resize-proc 
	   :frame-default-done-proc
	   :frame-done-proc
	   :frame-properties-proc
	   :frame-props-reset-proc
	   :xv-init-help-proc
	   :xv-usage-proc
	   :xv-error-proc
	   :menu-done-proc
	   :menu-gen-proc 
	   :menu-notify-proc 
	   :menu-pin-proc
	   :menu-action-proc
	   :menu-gen-proc
	   :menu-gen-pullright
	   :openwin-split-init-proc
	   :panel-background-proc
	   :panel-event-proc
	   :panel-repaint-proc
	   :panel-notify-proc
	   :scrollbar-compute-scroll-proc
	   :scrollbar-normalize-proc
	   :textsw-notify-proc
	   :win-event-proc
	   :win-notify-event-proc
	   :xv-error-proc))


(deftype string-attribute ()
  "Attributes whose value must be a foreign string"
  '(member :cms-name
           :font-family
	   :font-string-dims
	   :font-style
	   :frame-left-footer
	   :frame-right-footer
	   :menu-title-item
	   :menu-string
	   :notice-button-no
	   :notice-button-yes
	   :panel-label-string
	   :panel-list-text-value
	   :panel-notify-string
	   :textsw-contents
	   :textsw-file
	   :textsw-file-contents
	   :textsw-insert-from-file
	   :win-cms-name
	   :xv-label
	   :xv-name
	   :xv-help-string-filename))


(deftype string-or-int-attribute ()
  "Attributes whose value may be a string or an integer"
  '(member :panel-value))


(deftype attribute-attribute ()
  "Attributes whose value must be an attribute keyword"
  '(member :cms-type
	   :menu-class
	   :menu-type
	   :openwin-split-direction
	   :panel-direction
	   :panel-notify-level
	   :panel-layout
	   :panel-display-level
	   :panel-feedback
	   :panel-paint
	   :seln-req-yield
	   :scrollbar-direction
	   :textsw-insert-makes-visible
	   :textsw-line-break-action))
	   

(deftype boolean-attribute ()
  "Attributes whose C value must be TRUE or FALSE (1 or 0), and non NIL or NIL in Lisp"
  '(member :canvas-auto-expand
	   :canvas-auto-shrink
	   :canvas-fast-mono
	   :canvas-fixed-image
	   :canvas-retained
	   :canvas-x-paint-window
	   :cms-control-cms
	   :cms-default-cms
	   :cms-frame-cms
	   :xv-show
	   :cursor-show-image
	   :frame-busy
	   :frame-inherit-colors
	   :frame-left-footer
	   :frame-show-header
	   :frame-show-footer
	   :frame-show-label
	   :frame-show-resize-corner
	   :frame-closed
	   :frame-no-confirm
	   :frame-cmd-pushpin-in
	   :frame-props-pushpin-in
	   :icon-transparent
	   :icon-transparent-label
	   :menu-col-major
	   :menu-pin
	   :menu-valid-result
	   :menu-feedback
	   :menu-inactive
	   :menu-invert
	   :menu-selected
	   :notice-no-beeping
	   :openwin-adjust-for-horizontal-scrollbar
	   :openwin-adjust-for-vertical-scrollbar	   
	   :openwin-auto-clear
	   :openwin-no-margin
	   :openwin-show-borders
	   :panel-accept-keystroke
	   :panel-choose-one
	   :panel-choose-none
	   :panel-inactive
	   :panel-inverted
	   :panel-show-range
	   :panel-show-value
	   :panel-read-only
	   :panel-slider-end-boxes
	   :panel-value-underlined
	   :panel-list-selected
	   :server-image-save-pixmap
	   :textsw-adjust-is-pending-delete
	   :textsw-again-recording
	   :textsw-auto-indent
	   :textsw-blink-caret
	   :textsw-browsing
	   :textsw-confirm-overwrite
	   :textsw-control-chars-use-font
	   :textsw-disable-cd
	   :textsw-disable-load
	   :testsw-read-only
	   :textsw-store-changes-file
	   :tty-console
	   :tty-page-mode
	   :tty-quit-on-child-death
	   :win-dynamic-color
	   :win-dynamic-visual
	   :win-grab-all-input
	   :win-kbd-focus
	   :win-map
	   :win-no-decorations
	   :win-retained
	   :win-save-under
	   :win-x-paint-window))


(deftype client-data-attribute ()
  '(member :menu-client-data
	   :panel-client-data
	   :panel-list-client-data
	   :textsw-client-data
	   :win-client-data))


(deftype attribute ()
  "Names of the C enumerated types"
  '(member wm-direction 
	   window-layout-op
	   window-visual
	   window-input-event
	   window-attribute
	   error-attr
	   error-layer
	   error-severity
	   tty-attribute
	   textsw-filter-command
	   textsw-menu-cmd
	   textsw-enum
	   textsw-expand-status
	   textsw-status
	   textsw-filter-attribute
	   textsw-action
	   textsw-attribute
	   termsw-attribute
	   termsw-mode
	   server-image-attribute
	   server-attr
	   seln-response
	   seln-state
	   seln-function
	   seln-rank
	   seln-result
	   seln-level
	   seln-attribute
	   scrollbar-setting
	   scroll-motion
	   scrollbar-attribute
	   screen-attr
	   pw-batch-type
	   panel-item-type
	   panel-setting
	   panel-attr
	   openwin-attribute
	   openwin-split-direction
	   menu-generate
	   menu-feedback
	   menu-class
	   menu-attribute
	   notify-value
	   notify-dump-type
	   notice-attribute
	   icon-attribute
	   xv-generic-attr
	   fullscreen-attr
	   frame-rescale-state
	   frame-attribute
	   font-type
	   font-attribute
	   drawable-attr
	   cursor-attribute
	   canvas-paint-attribute
	   canvas-view-attribute
	   canvas-attribute
	   cms-attribute
	   attr-generic
	   attr-pkg
	   attr-base-cardinality
	   attr-base-type
	   attr-list-type
	   attr-list-ptr-type
	   attr-cu-type))

