;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)globals.lisp	3.9 10/11/91



(in-package :XVIEW :use '(lisp))


(eval-when (load eval compile)
  (defvar *xview-globals*
    '((*ndet-flags* . "_ndet_flags")                ;; Foreign pointer for the notifiers ndet_flags global (see xview_private/ndet.h).
      (*lisp-sigio-flag* . "_lisp_sigio_flag"))))   ;; Set each time a SIGIO occurs - see lisp_setup_sigio_handler in macros.c

;;; Define and export (but don't bind) *xview-globals*

(macrolet    
 ((defvar-xview-globals ()
    `(progn ,@(mapcar #'(lambda (x) 
			  `(progn 
			     (defvar ,(car x)) 
			     (export ',(car x))))
		      *xview-globals*))))
 (defvar-xview-globals))
       






;;; XView "Packages"
;;;
;;; The 2nd argument for xv-create and xv-fund must be a pointer to a special 
;;; C structure. The C version of the XView interface hides this 
;;; with a #define, e.g.:
;;;
;;;    extern Xv_pkg xv_canvas_pkg;
;;;    #define CANVAS &xv_canvas_pkg
;;;
;;; We store the address of the global package variable on the property list of the 
;;; keyword that represents the C #define.  The functions xv-create
;;; and xv-find look up this property at run time so you can
;;; say (xv-create NULL :panel) or (let ((type :frame)) (xv-create NULL type)).
;;;

(export '(*xview-packages*))

(defvar *xview-packages*
  '((:canvas . "_xv_canvas_pkg")                      ;; canvas.h 
    (:canvas-view . "_xv_canvas_view_pkg")
    (:canvas-pixwin . "_xv_canvas_pw_pkg")
    (:cms . "_xv_cms_pkg")                            ;; cms.h
    (:cursor . "_xv_cursor_pkg")                      ;; cursor.h
    (:font . "_xv_font_pkg")                          ;; font.h
    (:frame-base . "_xv_frame_base_pkg")              ;; frame.h
    (:frame-cmd . "_xv_frame_cmd_pkg")                
    (:frame-props . "_xv_frame_cmd_pkg")                
    (:frame-help . "_xv_frame_help_pkg")              
    (:frame-class . "_xv_frame_class_pkg")
    (:fullscreen . "_xv_fullscreen_pkg")              ;; fullscreen.h
    (:icon .  "_xv_icon_pkg")                         ;; icon.h
    (:menu . "_xv_command_menu_pkg")                  ;; menu.h
    (:menu-command-menu . "_xv_command_menu_pkg")     ;; menu.h
    (:menu-choice-menu . "_xv_choice_menu_pkg")
    (:menu-toggle-menu . "_xv_toggle_menu_pkg")
    (:menuitem . "_xv_menu_item_pkg")
    (:openwin . "_xv_openwin_pkg")                    ;; openwin.h
    (:panel . "_xv_panel_pkg")                        ;; panel.h
    (:panel-button . "_xv_panel_button_pkg")    
    (:panel-choice . "_xv_panel_choice_pkg")    
    (:panel-gauge . "_xv_panel_gauge_pkg")             
    (:panel-item . "_xv_panel_item_pkg")    
    (:panel-list . "_xv_panel_list_pkg")    
    (:panel-message . "_xv_panel_message_pkg")    
    (:panel-slider . "_xv_panel_slider_pkg")
    (:panel-text . "_xv_panel_text_pkg")
    (:panel-numeric-text . "_xv_panel_num_text_pkg")
    (:panel-view . "_xv_panel_view_pkg")
    (:screen . "_xv_screen_pkg")                       ;; screen.h
    (:scrollbar . "_xv_scrollbar_pkg")                 ;; scrollbar.h
    (:server . "_xv_server_pkg")                       ;; server.h
    (:server-image . "_xv_server_image_pkg")           ;; svrimage.h
    (:termsw . "_xv_termsw_pkg")                       ;; termsw.h
    (:termsw-view . "_xv_termsw_view_pkg")                 
    (:textsw . "_xv_textsw_pkg")                       ;; textsw.h
    (:textsw-view . "_xv_textsw_view_pkg")                 
    (:tty . "_xv_tty_pkg")                             ;; tty.h
    (:tty-view . "_xv_tty_view_pkg")                 
    (:window . "_xv_window_pkg")))
  
   
;;; To update the values of the XView constants defined with def-xview-constant
;;; remove the #+ignore that hides the second definition of def-xview-constant
;;; and load this file.  The resulting C printf statements should inserted
;;; into the body of main in build-xview-defs.c.  When compiled and executed the 
;;; output of build-xview-defs.c should be used to replace the def-xview-constant
;;; forms below.

(defmacro def-xview-constant (symbol value name)
  (declare (ignore name))
  `(def-exported-constant ,symbol ,value))


;;; Print a C printf statement that, when compiled and exectuted, will print
;;; a def-xview-constant form.  For example
;;;
;;;   printf("(def-xview-constant null %d \"NULL\")", NULL);
;;;

#+ignore
(defmacro def-xview-constant (symbol value name)
  (declare (ignore value))
  (format t "   printf(\"(def-xview-constant ~A %d \\\"~A\\\")\\n\", ~A);~%" 
	  (string-downcase (string symbol))
	  name 
	  name))


(def-xview-constant XV_NULL 0 "NULL")
;; (def-xview-constant null 0 "NULL")
(def-xview-constant true 1 "TRUE")
(def-xview-constant false 0 "FALSE")
(def-xview-constant attr-standard-size 250 "ATTR_STANDARD_SIZE")
(def-xview-constant action-null-event 31744 "ACTION_NULL_EVENT")
(def-xview-constant action-erase-char-backward 31745 "ACTION_ERASE_CHAR_BACKWARD")
(def-xview-constant action-erase-char-forward 31746 "ACTION_ERASE_CHAR_FORWARD")
(def-xview-constant action-erase-word-backward 31747 "ACTION_ERASE_WORD_BACKWARD")
(def-xview-constant action-erase-word-forward 31748 "ACTION_ERASE_WORD_FORWARD")
(def-xview-constant action-erase-line-backward 31749 "ACTION_ERASE_LINE_BACKWARD")
(def-xview-constant action-erase-line-end 31750 "ACTION_ERASE_LINE_END")
(def-xview-constant action-go-char-backward 31752 "ACTION_GO_CHAR_BACKWARD")
(def-xview-constant action-go-char-forward 31753 "ACTION_GO_CHAR_FORWARD")
(def-xview-constant action-go-word-backward 31754 "ACTION_GO_WORD_BACKWARD")
(def-xview-constant action-go-word-forward 31755 "ACTION_GO_WORD_FORWARD")
(def-xview-constant action-go-word-end 31756 "ACTION_GO_WORD_END")
(def-xview-constant action-go-line-backward 31757 "ACTION_GO_LINE_BACKWARD")
(def-xview-constant action-go-line-forward 31758 "ACTION_GO_LINE_FORWARD")
(def-xview-constant action-go-line-end 31759 "ACTION_GO_LINE_END")
(def-xview-constant action-go-line-start 31760 "ACTION_GO_LINE_START")
(def-xview-constant action-go-column-backward 31761 "ACTION_GO_COLUMN_BACKWARD")
(def-xview-constant action-go-column-forward 31762 "ACTION_GO_COLUMN_FORWARD")
(def-xview-constant action-go-document-start 31763 "ACTION_GO_DOCUMENT_START")
(def-xview-constant action-go-document-end 31764 "ACTION_GO_DOCUMENT_END")
(def-xview-constant action-stop 31767 "ACTION_STOP")
(def-xview-constant action-again 31768 "ACTION_AGAIN")
(def-xview-constant action-props 31769 "ACTION_PROPS")
(def-xview-constant action-undo 31770 "ACTION_UNDO")
(def-xview-constant action-redo 31771 "ACTION_REDO")
(def-xview-constant action-front 31772 "ACTION_FRONT")
(def-xview-constant action-back 31773 "ACTION_BACK")
(def-xview-constant action-copy 31774 "ACTION_COPY")
(def-xview-constant action-open 31775 "ACTION_OPEN")
(def-xview-constant action-close 31776 "ACTION_CLOSE")
(def-xview-constant action-paste 31777 "ACTION_PASTE")
(def-xview-constant action-find-backward 31778 "ACTION_FIND_BACKWARD")
(def-xview-constant action-find-forward 31779 "ACTION_FIND_FORWARD")
(def-xview-constant action-replace 31780 "ACTION_REPLACE")
(def-xview-constant action-cut 31781 "ACTION_CUT")
(def-xview-constant action-select-field-backward 31782 "ACTION_SELECT_FIELD_BACKWARD")
(def-xview-constant action-select-field-forward 31783 "ACTION_SELECT_FIELD_FORWARD")
(def-xview-constant action-copy-then-paste 31784 "ACTION_COPY_THEN_PASTE")
(def-xview-constant action-store 31785 "ACTION_STORE")
(def-xview-constant action-load 31786 "ACTION_LOAD")
(def-xview-constant action-include-file 31787 "ACTION_INCLUDE_FILE")
(def-xview-constant action-get-filename 31788 "ACTION_GET_FILENAME")
(def-xview-constant action-set-directory 31789 "ACTION_SET_DIRECTORY")
(def-xview-constant action-do-it 31790 "ACTION_DO_IT")
(def-xview-constant action-help 31791 "ACTION_HELP")
(def-xview-constant action-insert 31792 "ACTION_INSERT")
(def-xview-constant action-invoke 31793 "ACTION_INVOKE")
(def-xview-constant action-expand 31794 "ACTION_EXPAND")
(def-xview-constant action-match-delimiter 31795 "ACTION_MATCH_DELIMITER")
(def-xview-constant action-caps-lock 31796 "ACTION_CAPS_LOCK")
(def-xview-constant action-quote 31797 "ACTION_QUOTE")
(def-xview-constant action-empty 31798 "ACTION_EMPTY")
(def-xview-constant action-select 31799 "ACTION_SELECT")
(def-xview-constant action-adjust 31800 "ACTION_ADJUST")
(def-xview-constant action-menu 31801 "ACTION_MENU")
(def-xview-constant action-drag-move 31802 "ACTION_DRAG_MOVE")
(def-xview-constant action-drag-copy 31803 "ACTION_DRAG_COPY")
(def-xview-constant action-drag-load 31804 "ACTION_DRAG_LOAD")
(def-xview-constant action-split-horizontal 31805 "ACTION_SPLIT_HORIZONTAL")
(def-xview-constant action-split-vertical 31806 "ACTION_SPLIT_VERTICAL")
(def-xview-constant action-split-init 31807 "ACTION_SPLIT_INIT")
(def-xview-constant action-split-destroy 31808 "ACTION_SPLIT_DESTROY")
(def-xview-constant action-rescale 31809 "ACTION_RESCALE")
(def-xview-constant action-pinin 31810 "ACTION_PININ")
(def-xview-constant action-pinout 31811 "ACTION_PINOUT")
(def-xview-constant action-dismiss 31812 "ACTION_DISMISS")
(def-xview-constant action-take-focus 31815 "ACTION_TAKE_FOCUS")
(def-xview-constant loc-move 32512 "LOC_MOVE")
(def-xview-constant loc-winenter 32513 "LOC_WINENTER")
(def-xview-constant loc-winexit 32514 "LOC_WINEXIT")
(def-xview-constant loc-movewhilebutdown 32515 "LOC_MOVEWHILEBUTDOWN")
(def-xview-constant loc-drag 32515 "LOC_DRAG")
(def-xview-constant win-repaint 32516 "WIN_REPAINT")
(def-xview-constant win-resize 32517 "WIN_RESIZE")
(def-xview-constant win-map-notify 32518 "WIN_MAP_NOTIFY")
(def-xview-constant win-unmap-notify 32519 "WIN_UNMAP_NOTIFY")
(def-xview-constant kbd-use 32520 "KBD_USE")
(def-xview-constant kbd-done 32521 "KBD_DONE")
(def-xview-constant win-client-message 32522 "WIN_CLIENT_MESSAGE")
(def-xview-constant win-unused-11 32542 "WIN_UNUSED_11")
(def-xview-constant win-stop 32573 "WIN_STOP")
(def-xview-constant key-codes 127 "KEY_CODES")
(def-xview-constant ms-left 32563 "MS_LEFT")
(def-xview-constant ms-middle 32564 "MS_MIDDLE")
(def-xview-constant ms-right 32565 "MS_RIGHT")
(def-xview-constant shift-capslock 32547 "SHIFT_CAPSLOCK")
(def-xview-constant shift-lock 32548 "SHIFT_LOCK")
(def-xview-constant shift-left 32549 "SHIFT_LEFT")
(def-xview-constant shift-right 32550 "SHIFT_RIGHT")
(def-xview-constant shift-leftctrl 32551 "SHIFT_LEFTCTRL")
(def-xview-constant shift-ctrl 32551 "SHIFT_CTRL")
(def-xview-constant shift-rightctrl 32552 "SHIFT_RIGHTCTRL")
(def-xview-constant shift-meta 32553 "SHIFT_META")
(def-xview-constant shift-top 32554 "SHIFT_TOP")
(def-xview-constant shift-cmd 32555 "SHIFT_CMD")
(def-xview-constant notice-yes 1 "NOTICE_YES")
(def-xview-constant notice-no 0 "NOTICE_NO")
(def-xview-constant notice-failed -1 "NOTICE_FAILED")
(def-xview-constant notice-triggered -2 "NOTICE_TRIGGERED")
(def-xview-constant cms-status-default 0 "CMS_STATUS_DEFAULT")
(def-xview-constant cms-status-control 1 "CMS_STATUS_CONTROL")
(def-xview-constant cms-status-frame 2 "CMS_STATUS_FRAME")
(def-xview-constant cms-control-colors 4 "CMS_CONTROL_COLORS")
(def-xview-constant xv-default-cms-size 2 "XV_DEFAULT_CMS_SIZE")
(def-xview-constant xv-static-cms 1 "XV_STATIC_CMS")
(def-xview-constant xv-dynamic-cms 2 "XV_DYNAMIC_CMS")
(def-xview-constant ie-negevent 1 "IE_NEGEVENT")
(def-xview-constant shiftmask 14 "SHIFTMASK")
(def-xview-constant ctrlmask 48 "CTRLMASK")
(def-xview-constant meta-shift-mask 64 "META_SHIFT_MASK")
(def-xview-constant ms-left-mask 128 "MS_LEFT_MASK")
(def-xview-constant ms-middle-mask 256 "MS_MIDDLE_MASK")
(def-xview-constant ms-right-mask 512 "MS_RIGHT_MASK")
(def-xview-constant ms-button-mask 896 "MS_BUTTON_MASK")
(def-xview-constant but-first 32563 "BUT_FIRST")
(def-xview-constant but-last 32572 "BUT_LAST")
(def-xview-constant ascii-first 0 "ASCII_FIRST")
(def-xview-constant ascii-last 127 "ASCII_LAST")
(def-xview-constant meta-first 0 "META_FIRST")
(def-xview-constant meta-last 255 "META_LAST")
(def-xview-constant key-leftfirst 32573 "KEY_LEFTFIRST")
(def-xview-constant key-leftlast 32588 "KEY_LEFTLAST")
(def-xview-constant key-rightfirst 32589 "KEY_RIGHTFIRST")
(def-xview-constant key-rightlast 32604 "KEY_RIGHTLAST")
(def-xview-constant key-topfirst 32605 "KEY_TOPFIRST")
(def-xview-constant key-toplast 32620 "KEY_TOPLAST")
(def-xview-constant key-bottomleft 32621 "KEY_BOTTOMLEFT")
(def-xview-constant key-bottomright 32622 "KEY_BOTTOMRIGHT")
(def-xview-constant win-null-value 0 "WIN_NULL_VALUE")
(def-xview-constant win-no-events 1 "WIN_NO_EVENTS")
(def-xview-constant win-up-events 2 "WIN_UP_EVENTS")
(def-xview-constant win-ascii-events 3 "WIN_ASCII_EVENTS")
(def-xview-constant win-up-ascii-events 4 "WIN_UP_ASCII_EVENTS")
(def-xview-constant win-mouse-buttons 5 "WIN_MOUSE_BUTTONS")
(def-xview-constant win-in-transit-events 6 "WIN_IN_TRANSIT_EVENTS")
(def-xview-constant win-left-keys 7 "WIN_LEFT_KEYS")
(def-xview-constant win-top-keys 8 "WIN_TOP_KEYS")
(def-xview-constant win-right-keys 9 "WIN_RIGHT_KEYS")
(def-xview-constant win-meta-events 10 "WIN_META_EVENTS")
(def-xview-constant win-up-meta-events 11 "WIN_UP_META_EVENTS")
(def-xview-constant win-sunview-function-keys 12 "WIN_SUNVIEW_FUNCTION_KEYS")
(def-xview-constant win-edit-keys 13 "WIN_EDIT_KEYS")
(def-xview-constant win-motion-keys 14 "WIN_MOTION_KEYS")
(def-xview-constant win-text-keys 15 "WIN_TEXT_KEYS")
(def-xview-constant xv-ok 0 "XV_OK")
(def-xview-constant xv-error 1 "XV_ERROR")
(def-xview-constant scrollbar-request 32256 "SCROLLBAR_REQUEST")
(def-xview-constant il-errormsg-size 256 "IL_ERRORMSG_SIZE")
(def-xview-constant ndet-stop 1 "NDET_STOP")
(def-xview-constant ndet-fd-change 2 "NDET_FD_CHANGE")
(def-xview-constant ndet-signal-change 4 "NDET_SIGNAL_CHANGE")
(def-xview-constant ndet-real-change 8 "NDET_REAL_CHANGE")
(def-xview-constant ndet-virtual-change 16 "NDET_VIRTUAL_CHANGE")
(def-xview-constant ndet-wait3-change 32 "NDET_WAIT3_CHANGE")
(def-xview-constant ndet-dispatch 64 "NDET_DISPATCH")
(def-xview-constant ndet-real-poll 128 "NDET_REAL_POLL")
(def-xview-constant ndet-virtual-poll 256 "NDET_VIRTUAL_POLL")
(def-xview-constant ndet-interrupt 512 "NDET_INTERRUPT")
(def-xview-constant ndet-started 1024 "NDET_STARTED")
(def-xview-constant ndet-exit-soon 2048 "NDET_EXIT_SOON")
(def-xview-constant ndet-stop-on-sig 4096 "NDET_STOP_ON_SIG")
(def-xview-constant ndet-vetoed 8192 "NDET_VETOED")
(def-xview-constant ndet-itimer-enq 16384 "NDET_ITIMER_ENQ")
(def-xview-constant ndet-no-delay 32768 "NDET_NO_DELAY")
(def-xview-constant ndet-destroy-change 65536 "NDET_DESTROY_CHANGE")
(def-xview-constant ndet-poll 384 "NDET_POLL")
(def-xview-constant ndet-condition-change 65598 "NDET_CONDITION_CHANGE")
(def-xview-constant olc-basic-ptr 0 "OLC_BASIC_PTR")
(def-xview-constant olc-basic-mask-ptr	1 "OLC_BASIC_MASK_PTR")
(def-xview-constant olc-move-ptr 2 "OLC_MOVE_PTR")
(def-xview-constant olc-move-mask-ptr 3 "OLC_MOVE_MASK_PTR")
(def-xview-constant olc-copy-ptr 4 "OLC_COPY_PTR")
(def-xview-constant olc-copy-mask-ptr 5 "OLC_COPY_MASK_PTR")
(def-xview-constant olc-busy-ptr 6 "OLC_BUSY_PTR")
(def-xview-constant olc-busy-mask-ptr 7 "OLC_BUSY_MASK_PTR")
(def-xview-constant olc-stop-ptr 8  "OLC_STOP_PTR")
(def-xview-constant olc-stop-mask-ptr 9 "OLC_STOP_MASK_PTR")
(def-xview-constant olc-panning-ptr 10 "OLC_PANNING_PTR")
(def-xview-constant olc-navigation-level-ptr 12 "OLC_NAVIGATION_LEVEL_PTR")
(def-xview-constant win-property-notify 32536 "WIN_PROPERTY_NOTIFY")
(def-xview-constant textsw-infinity #x77777777 "TEXTSW_INFINITY")
(def-xview-constant textsw-cannot-set #x80000000 "TEXTSW_CANNOT_SET")
(def-xview-constant textsw-notify-destroy-view 1 "TEXTSW_NOTIFY_DESTROY_VIEW")
(def-xview-constant textsw-notify-edit-delete 2 "TEXTSW_NOTIFY_EDIT_DELETE")
(def-xview-constant textsw-notify-edit-insert 4 "TEXTSW_NOTIFY_EDIT_INSERT")
(def-xview-constant textsw-notify-paint 8 "TEXTSW_NOTIFY_PAINT")
(def-xview-constant textsw-notify-repaint 16 "TEXTSW_NOTIFY_REPAINT")
(def-xview-constant textsw-notify-scroll 32 "TEXTSW_NOTIFY_SCROLL")
(def-xview-constant textsw-notify-split-view 64 "TEXTSW_NOTIFY_SPLIT_VIEW")
(def-xview-constant textsw-notify-standard 128 "TEXTSW_NOTIFY_STANDARD")
(def-xview-constant textsw-notify-edit 6 "TEXTSW_NOTIFY_EDIT")

