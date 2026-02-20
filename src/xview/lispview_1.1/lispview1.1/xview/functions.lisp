;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)functions.lisp	3.8 10/11/91



(in-package 'xview :use '(lisp))

;;;
;;; The layout of this file generally follows the layout of Appendix C - "XView
;;; Summary Tables" in the XView manual.  Functions tend to be grouped 
;;; according to the type they are specific to:
;;;
;;; Generic, Common Procedures and Macros, Canvas, Cursor, Menu, Notice, 
;;; Panel, Scrollbar, Selection, Textsw, TTY subwindow, Window, Wmgr, 
;;; Notifier, Attribute, "Low Level" window functions, Icon Loader, Unix
;;;

;;; Generic 

(def-exported-foreign-function (xv_get (:return-type xv-opaque)
				       (:name "_xv_get"))
  (object xv-object)
  (attr xv-generic-attr)
  &optional 
  ((optional-attribute 0) int))


(def-exported-foreign-function (xv_set 
				(:return-type :null)
				(:max-rest-args 768)
				(:name "_xv_set"))
  (object xv-object)
  &rest attr-avlist)


(def-exported-foreign-function (xv_create 
				(:return-type xv-object)
				(:max-rest-args 768)
				(:name "_xv_create"))
  (object xv-object)
  (package xv-pkg)
  &rest attr-avlist)


(def-xview-foreign-function (ff-xv-create 
			     (:return-type xv-object)
			     (:max-rest-args 768)
			     (:name "_xv_create"))
  (object xv-object)
  (package xv-pkg)
  (attr-list attr-avlist))


(def-xview-foreign-function (xv-destroy (:return-type int))
  (object xv-object))


(def-xview-foreign-function (xv-destroy-safe (:return-type int))
  (object xv-object))


(def-xview-foreign-function (ff-xv-find 
			     (:return-type xv-object)
			     (:name "_xv_find"))
  (object xv-object)
  (package xv-pkg)
  (attr-list attr-avlist))

(def-xview-foreign-function (ff-xv-set-client-data1 (:return-type :fixnum)
						    (:name "_xv_set"))
  (object xv-object)
  (attribute int)
  (value :lisp)
  &optional 
  ((zero 0) int))


(def-xview-foreign-function (ff-xv-set-client-data2 (:return-type :fixnum)
						    (:name "_xv_set"))
  (object xv-object)
  (attribute int)
  (index int)
  (value :lisp)
  &optional 
  ((zero 0) int))

(def-xview-foreign-function (ff-xv-get-client-data (:return-type :lisp)
						   (:name "_xv_get"))
  (object xv-object)
  (attribute int)
  &optional ((zero 0) int))

(def-xview-foreign-function (xv-get (:return-type xv-opaque))
  (object xv-object)
  (attr xv-generic-attr)
  &optional 
  ((optional-attribute 0) int))

(def-xview-foreign-function (xv-set 
			     (:return-type :fixnum)
			     (:max-rest-args 768))
  (object xv-object)
  (attr-list attr-avlist))

(def-xview-foreign-function (xv-init (:return-type int))
  (attr-list attr-avlist))


;;; Common Procedures and Macros

(def-xview-foreign-function (xv-col (:return-type int))
  (window xv-window)
  (columns int))

(def-xview-foreign-function (xv-cols (:return-type int))
  (window xv-window)
  (columns int))

(def-xview-foreign-function (xv-row (:return-type int))
  (window xv-window)
  (columns int))

(def-xview-foreign-function (xv-rows (:return-type int))
  (window xv-window)
  (columns int))

(def-xview-foreign-function (xv-send-message (:return-type void))
  (window xv-object)
  (addresse xv-opaque)
  (msg-type (:pointer char))
  (format int)
  (data (:pointer xv-opaque))
  (len int))


;;; Canvas


;;; Cursor

(def-xview-foreign-function (cursor-copy (:return-type xv-cursor))
  (src-cursor xv-cursor))


;;; Menu

(def-xview-foreign-function (menu-return-item (:return-type caddr-t))
  (menu menu)
  (menu-item menu-item))

(def-xview-foreign-function (menu-return-value (:return-type caddr-t))
  (menu menu)
  (menu-item menu-item))

(def-xview-foreign-function (xv-menu-show 
			     (:return-type void)
			     (:name "_menu_show"))
  (menu menu)
  (window xv-window)
  (event (:pointer event))
  &optional
  ((zero 0) int))


;;; Notice

(def-xview-foreign-function (xv-notice-prompt 
			     (:return-type :fixnum)
			     (:name "_notice_prompt")
			     (:max-rest-args 768))
  (client-frame frame)
  (event (:pointer event))
  (attr-list attr-avlist))


;;; Panel


(def-xview-foreign-function (panel-advance-caret (:return-type xv-opaque))
  (panel panel))

(def-xview-foreign-function (panel-backup-caret (:return-type xv-opaque))
  (panel panel))

(def-xview-foreign-function (panel-default-handle-event (:return-type int))
  (object panel-or-item)
  (event (:pointer event)))

(def-xview-foreign-function (panel-paint (:return-type void))
  (client-object panel)
  (flag panel-setting))

(def-xview-foreign-function (panel-text-notify (:return-type panel-setting))
  (item panel-item)
  (event (:pointer event)))


;;; Scrollbar

(def-xview-foreign-function (scrollbar-default-compute-scroll-proc (:return-type void))
  (scrollbar scrollbar)
  (pos int)
  (available-cable int)
  (motion int)   ;; was scroll-motion 
  (offset (:pointer unsigned-long))
  (object-length (:pointer unsigned-long)))

(def-xview-foreign-function (scrollbar-paint (:return-type void))
  (scrollbar scrollbar))


;;; Selection

#|

(def-xview-foreign-function (selection-acquire (:return-type Seln-rank))
  (server xv-server)
  (client Seln-client)
  (asked Seln-rank))

(def-xview-foreign-function (selection-ask (:return-type (:pointer seln-request)))
  (server xv-server)
  (holder (:pointer Seln-holder))
  (attr-list attr-avlist))

(def-xview-foreign-function (selection-clear-functions (:return-type void))
  )

(def-xview-foreign-function (selection-create (:return-type Seln-client))
  (server xv-server)
  (function-proc callback)
  (reply-proc callback)
  (client-data xv-opaque))

;;; previously selection-destroy
(def-xview-foreign-function (seln-destroy (:return-type void))
  (server xv-server)
  (client Seln-client))

(def-xview-foreign-function (selection-done (:return-type Seln-result))
  (server xv-server)
  (client Seln-client)
  (rank Seln-rank))

(def-xview-foreign-function (selection-figure-response (:return-type Seln-response))
  (server xv-server)
  (buffer (:pointer seln-function-buffer))
  (holder (:pointer (:pointer Seln-holder))))

(def-xview-foreign-function (selection-hold-file (:return-type Seln-result))
  (server xv-server)
  (rank Seln-rank)
  (path (:pointer char)))

#+ignore
(def-foreign-struct-function (selection-inform (:return-type Seln-function-buffer))
  (server xv-server)
  (client Seln-client)
  (which Seln-function)
  (down int))

#+ignore
(def-foreign-struct-function (selection-inquire (:return-type Seln-holder))
  (server xv-server)
  (rank Seln-rank))

#+ignore
(def-foreign-struct-function (selection-inquire-all (:return-type Seln-holders-all)))

(def-xview-foreign-function (selection-init-request (:return-type void))
  (server xv-server)
  (buffer (:pointer seln-request))
  (holder (:pointer Seln-holder))
  (attributes (:pointer char)))

(def-xview-foreign-function (selection-query (:return-type seln-result))
  (server xv-server)
  (holder (:pointer Seln-holder))
  (reader callback)
  (context (:pointer char))
  (attr-list attr-avlist))

(def-xview-foreign-function (selection-report-event (:return-type void))
  (server xv-server)
  (client Seln-client)
  (event (:pointer event)))

(def-xview-foreign-function (selection-request (:return-type Seln-result))
  (server xv-server)
  (holder (:pointer Seln-holder))
  (buffer (:pointer seln-request)))

(def-xview-foreign-function (selection-yield-all (:return-type void)))

|#


;;; Textsw

(def-xview-foreign-function (textsw-add-mark (:return-type textsw-mark))
  (textsw textsw)
  (position textsw-index)
  (flags unsigned))

(def-xview-foreign-function (textsw-append-file-name (:return-type int))
  (textsw textsw)
  (name (:pointer char)))

(def-xview-foreign-function (textsw-delete (:return-type textsw-index))
  (textsw textsw)
  (first textsw-index)
  (last-plus-one textsw-index))

(def-xview-foreign-function (textsw-edit (:return-type textsw-index))
  (textsw textsw)
  (unit unsigned)
  (count unsigned)
  (direction unsigned))

(def-xview-foreign-function (textsw-erase (:return-type textsw-index))
  (textsw textsw)
  (first textsw-index)
  (last-plus-one textsw-index))

(def-xview-foreign-function (textsw-file-lines-visible (:return-type void))
  (textsw textsw)
  (top (:pointer int))
  (bottom (:pointer int)))

(def-xview-foreign-function (textsw-find-bytes (:return-type textsw-index))
  (textsw textsw)
  (first (:pointer textsw-index))
  (last-plus-one (:pointer textsw-index))
  (buf (:pointer char))
  (buf-len unsigned)
  (flags unsigned))

(def-xview-foreign-function (textsw-find-mark (:return-type textsw-index))
  (textsw textsw)
  (mark textsw-mark))

(def-xview-foreign-function (textsw-first (:return-type textsw))
  (textsw textsw))

(def-xview-foreign-function (textsw-index-for-file-line (:return-type textsw-index))
  (textsw textsw)
  (line int))

(def-xview-foreign-function (textsw-insert (:return-type textsw-index))
  (textsw textsw)
  (buf (:pointer char))
  (buf-len int))

(def-xview-foreign-function (textsw-match-bytes (:return-type int))
  (textsw textsw)
  (first (:pointer textsw-index))
  (last-plus-one (:pointer textsw-index))
  (start-sym (:pointer char))
  (end-sym (:pointer char))
  (start-sym-len int)
  (end-sym-len int)
  (field-flag unsigned))

(def-xview-foreign-function (textsw-next (:return-type textsw))
  (textsw textsw))

(def-xview-foreign-function (textsw-normalize-view (:return-type void))
  (textsw textsw)
  (position textsw-index))

;; added ..and_set_selection
(def-xview-foreign-function (textsw-possibly-normalize-and-set-selection (:return-type void))
  (textsw textsw)
  (position textsw-index))

(def-xview-foreign-function (textsw-remove-mark (:return-type void))
  (textsw textsw)
  (mark textsw-mark))

(def-xview-foreign-function (textsw-replace-bytes (:return-type int))
  (textsw textsw)
  (first textsw-index)
  (last-plus-one textsw-index)
  (buf (:pointer char))
  (buf-len int))

(def-xview-foreign-function (textsw-reset (:return-type void))
  (textsw textsw)
  (x int)
  (y int))

(def-xview-foreign-function (textsw-save (:return-type unsigned))
  (textsw textsw)
  (x int)
  (y int))

(def-xview-foreign-function (textsw-screen-line-count (:return-type int))
  (textsw textsw))

(def-xview-foreign-function (textsw-scroll-lines (:return-type void))
  (textsw textsw)
  (count int))

(def-xview-foreign-function (textsw-set-selection (:return-type void))
  (textsw textsw)
  (first textsw-index)
  (last-plus-one textsw-index)
  (type unsigned))

(def-xview-foreign-function (textsw-store-file (:return-type unsigned))
  (textsw textsw)
  (filename (:pointer char))
  (x int)
  (y int))

(def-xview-foreign-function (textsw-default-notify (:return-type :null))
  (textsw textsw)
  (avlist-addr int))


;;; TTY subwindow

(def-xview-foreign-function (ttysw-input (:return-type int))
  (tty tty)
  (buf (:pointer char))
  (len int))

(def-xview-foreign-function (ttysw-output (:return-type int))
  (tty tty)
  (buf (:pointer char))
  (len int))


;;; Window

(def-xview-foreign-function (window-done (:return-type int))
  (window xv-window))

(def-xview-foreign-function (xv-main-loop (:return-type void))
  (base-frame frame))

(def-xview-foreign-function (xv-block-loop (:return-type xv-opaque))
  (subframe frame))

(def-xview-foreign-function (xv-block-return (:return-type void))
  (value xv-opaque))

(def-xview-foreign-function (window-read-event (:return-type int))
  (window xv-window)
  (event (:pointer event)))

;;; not in xview doc
#+ignore 
(def-xview-foreign-function (window-bell (:return-type void))
  (window xv-window))


;;; Wmgr

(def-xview-foreign-function (wmgr-bottom (:return-type void))
  (frame frame))

(def-xview-foreign-function (wmgr-changelevel  (:return-type void))
  (window xv-window)
  (parent int)
  (top int))

(def-xview-foreign-function (wmgr-close (:return-type void))
  (frame frame))

(def-xview-foreign-function (wmgr-completechangerect  (:return-type void))
  (window xv-window)
  (rectnew (:pointer rect))
  (rectoriginal (:pointer rect))
  (parentprleft int)
  (parentprtop int))

(def-xview-foreign-function (wmgr-open  (:return-type void))
  (frame frame))

(def-xview-foreign-function (wmgr-refreshwindow  (:return-type void))
  (window xv-window))

(def-xview-foreign-function (wmgr-top  (:return-type void))
  (frame frame))


;;; Notifier 

(def-xview-foreign-function (notify-default-wait3 (:return-type notify-value))
  (client notify-client)
  (pid int)
  (status (:pointer wait))
  (rusage (:pointer rusage)))


;;; Note: :return-type is :fixnum instead of notify-error (see attributes.lisp)
;;; to prevent the FFI from consing a return value.

(def-xview-foreign-function (notify-dispatch (:return-type :fixnum)))


(def-xview-foreign-function (notify-do-dispatch (:return-type notify-error)))

(def-xview-foreign-function (notify-interpose-destroy-func (:return-type notify-error))
  (client notify-client)
  (destroy-func notify-func))

(def-xview-foreign-function (notify-interpose-event-func (:return-type notify-error))
  (client notify-client)
  (event-func notify-func)
  (event-type notify-event-type))

(def-xview-foreign-function (notify-itimer-value (:return-type notify-error))
  (client notify-client)
  (which int)
  (value (:pointer itimerval)))

(def-xview-foreign-function (notify-next-destroy-func (:return-type notify-value))
  (nclient notify-client)
  (status destroy-status))

(def-xview-foreign-function (notify-next-event-func (:return-type notify-value))
  (client notify-client)
  (event notify-event)
  (arg notify-arg)
  (when notify-event-type))

(def-xview-foreign-function (notify-no-dispatch (:return-type notify-error)))

(def-xview-foreign-function (notify-perror (:return-type void))              
  (s (:pointer char)))

(def-xview-foreign-function (notify-set-destroy-func (:return-type notify-func))
  (client notify-client)
  (destroy-func notify-func))

(def-xview-foreign-function (notify-set-exception-func (:return-type notify-func))
  (nclient notify-client)
  (func notify-func)
  (fd int))

(def-xview-foreign-function (notify-set-input-func (:return-type notify-func))
  (nclient notify-client)
  (func notify-func)
  (fd int))

(def-xview-foreign-function (notify-set-itimer-func (:return-type notify-func))
  (nclient notify-client)
  (func notify-func)
  (which int)
  (value (:pointer itimerval))
  (ovalue (:pointer itimerval)))

(def-xview-foreign-function (notify-set-signal-func (:return-type notify-func))
  (nclient notify-client)
  (func notify-func)
  (sig int)
  (when notify-signal-mode))

(def-xview-foreign-function (notify-start (:return-type notify-error)))

(def-xview-foreign-function (notify-stop (:return-type notify-error)))

(def-xview-foreign-function (notify-set-output-func (:return-type notify-func))
  (client notify-client)
  (func notify-func)
  (fd int))

(def-xview-foreign-function (notify-set-wait3-func (:return-type notify-func))
  (client notify-client)
  (func notify-func)
  (fd int))

(def-xview-foreign-function (notify-veto-destroy (:return-type notify-error)) 
  (client notify-client))


;;; Attribute

(def-xview-foreign-function (attr-create-list 
			     (:return-type int)
			     (:max-rest-args 100))
  (attr-list attr-avlist))


;;; "Low Level" window functions

(def-xview-foreign-function (win-get-damage (:return-type (:pointer rectlist))) 
  (window xv-window))

(def-xview-foreign-function (win-set-no-focus (:return-type :null))
  (window Xv-object)
  (state int))


;;; Icon Loader

(def-xview-foreign-function (icon-load-mpr (:return-type (:pointer pixrect)))
  (from-file (:pointer char))
  (error-message (:pointer char)))



;;; SIGIO utility

(def-xview-foreign-function (lisp-setup-sigio-handler (:return-type :fixnum))
  (client notify-client)
  (fd int))



