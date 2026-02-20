;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)xview-display.lisp	3.10 10/11/91


(in-package "LISPVIEW")


;;; X11 Error Handling.
;;;
;;; The default X11 error handler prints a terse message and exits Lisp.  This is 
;;; inappropriate for Lisp so we install our own error handler that signals
;;; a warning on the notifier process.  

(let 
  ((x11-request-names
   '#("error" "CreateWindow" "ChangeWindowAttributes" "GetWindowAttributes"
      "DestroyWindow" "DestroySubwindows" "ChangeSaveSet" "ReparentWindow"
      "MapWindow" "MapSubwindows" "UnmapWindow" "UnmapSubwindows"
      "ConfigureWindow" "CirculateWindow" "GetGeometry" "QueryTree"
      "InternAtom" "GetAtomName" "ChangeProperty" "DeleteProperty"
      "GetProperty" "ListProperties" "SetSelectionOwner" "GetSelectionOwner"
      "ConvertSelection" "SendEvent" "GrabPointer" "UngrabPointer"
      "GrabButton" "UngrabButton" "ChangeActivePointerGrab" "GrabKeyboard"
      "UngrabKeyboard" "GrabKey" "UngrabKey" "AllowEvents"
      "GrabServer" "UngrabServer" "QueryPointer" "GetMotionEvents"
      "TranslateCoords" "WarpPointer" "SetInputFocus" "GetInputFocus"
      "QueryKeymap" "OpenFont" "CloseFont" "QueryFont"
      "QueryTextExtents" "ListFonts" "ListFontsWithInfo" "SetFontPath"
      "GetFontPath" "CreatePixmap" "FreePixmap" "CreateGC"
      "ChangeGC" "CopyGC" "SetDashes" "SetClipRectangles"
      "FreeGC" "ClearToBackground" "CopyArea" "CopyPlane"
      "PolyPoint" "PolyLine" "PolySegment" "PolyRectangle"
      "PolyArc" "FillPoly" "PolyFillRectangle" "PolyFillArc"
      "PutImage" "GetImage" "PolyText8" "PolyText16"
      "ImageText8" "ImageText16" "CreateColormap" "FreeColormap"
      "CopyColormapAndFree" "InstallColormap" "UninstallColormap" "ListInstalledColormaps"
      "AllocColor" "AllocNamedColor" "AllocColorCells" "AllocColorPlanes"
      "FreeColors" "StoreColors" "StoreNamedColor" "QueryColors"
      "LookupColor" "CreateCursor" "CreateGlyphCursor" "FreeCursor"
      "RecolorCursor" "QueryBestSize" "QueryExtension" "ListExtensions"
      "SetKeyboardMapping" "GetKeyboardMapping" "ChangeKeyboardControl" "GetKeyboardControl"
      "Bell" "ChangePointerControl" "GetPointerControl" "SetScreenSaver"
      "GetScreenSaver" "ChangeHosts" "ListHosts" "ChangeAccessControl"
      "ChangeCloseDownMode" "KillClient" "RotateProperties" "ForceScreenSaver"
      "SetPointerMapping" "GetPointerMapping" "SetModifierMapping" "GetModifierMapping")))

  (defun x11-request-name (code)
    (if (< code (length x11-request-names))
	(aref x11-request-names code)
      (format nil "unrecognized request ~S" code))))


;;; To paper over XView bug 1041607 we squelch BadMatch warnings that occur
;;; in response to SetInputFocus requests.

(let* ((event
	 (make-foreign-pointer
	   :type '(:pointer X11:XErrorEvent)
	   :address 0))
       (display
	 (make-foreign-pointer
	   :type '(:pointer X11:Display)
	   :address 0))
       (error-buffer-length 1024)
       (error-buffer
	(let ((fp (make-foreign-pointer 
		    :type `(:pointer (:array :character (,error-buffer-length)))
		    :static t)))
	  (setf (foreign-pointer-type fp) '(:pointer :character))
	  fp)))

  (defun HANDLE-X11-ERROR (display-addr error-event-addr)
    (setf (foreign-pointer-address display) display-addr
	  (foreign-pointer-address event) error-event-addr)

    (let ((serial (X11:XErrorEvent-serial event))
	  (error-code (X11:XErrorEvent-error-code event))
	  (request-code (X11:XErrorEvent-request-code event))	
	  (minor-code (X11:XErrorEvent-minor-code event))
	  (xid (X11:XErrorEvent-resourceid event)))
      (unless (and (= request-code 42) (= error-code X11:BadMatch))
	(X11:XGetErrorText display error-code error-buffer error-buffer-length)
	(warn "X11 error: ~S in request ~S (error code ~D), request major code ~D, minor code ~D~%~
			  Resource id ~D, serial number of last event processed: ~S" 
	       (foreign-string-value error-buffer)
	       (x11-request-name request-code)
	       error-code
	       request-code
	       minor-code
	       xid
	       serial)))))

(XV:defcallback x11-error-handler (display-addr error-event-addr)
  (XV:with-xview-lock 
    (handle-x11-error display-addr error-event-addr)))


(defun xview-make-root-canvas (display xvd dsp root)
  (let* ((xvo 
	  (make-xview-window
	    :id root
	    :xid (XV:xv-get root :xv-xid)
	    :xvd xvd
	    :dsp dsp
	    :cursor t
	    :depth (XV:xv-get root :win-depth)
	    :bit-gravity nil
	    :border-width 0))
	 (process (make-event-dispatch-process))
 	 (root-canvas
	  (make-instance 'root-canvas
	    :status :realized
	    :display display
	    :device xvo
	    :bounding-region (xview-win-bounding-region root)
	    :event-dispatch-process process))
	 (colormap 
	  (make-xview-default-colormap root-canvas)))

    (def-xview-object root-canvas xvo)

     (setf (event-dispatch-queue root-canvas) (process-event-queue process)
	   (xview-opaque-canvas-colormap xvo) colormap)

     (XV:xv-set root :win-consume-x-event-mask X11:PropertyChangeMask
		     :win-notify-event-proc 'handle-xview-event)

     root-canvas))

    
(defun xview-make-supported-depths (display scr)
  (let* ((ndepths (X11:screen-ndepths scr))
	 (depths (foreign-pointer-to-array (X11:screen-depths scr) ndepths))
	 (alist nil))
    (dotimes (i ndepths)
      (let* ((depth (foreign-aref depths i))
	     (nvisuals (X11:depth-nvisuals depth))
	     (x11-visuals (if (> nvisuals 0) 
			      (foreign-pointer-to-array (X11:depth-visuals depth) nvisuals)))
	     (visuals nil))
	(dotimes (j nvisuals)
	  (let* ((x11-visual (foreign-aref x11-visuals j))
		 (x11-visual-class (X11:visual-class x11-visual))
		 (colormap-length (X11:visual-map-entries x11-visual)))
	    (push (make-instance (if (and (= x11-visual-class X11:StaticGray)
					  (= colormap-length 2))
				     'monochrome-visual
				   (cdr (assoc x11-visual-class
					  '((#.X11:PseudoColor . pseudo-color-visual)
					    (#.X11:GrayScale . gray-scale-visual)
					    (#.X11:DirectColor . direct-color-visual)
					    (#.X11:TrueColor . true-color-visual)
					    (#.X11:StaticColor . static-color-visual)
					    (#.X11:StaticGray . static-gray-visual))
					  :test #'=)))
			:display display
			:device x11-visual)
		  visuals)))
	(push (cons (X11:depth-depth depth) (nreverse visuals)) alist)))
    (unless (assoc 1 alist :test #'=)
      (push (cons 1 nil) alist))

    alist))


;;; Multiple-value returns host, server, screen-number.  
;;; 
;;; According to the Scheifler, Gettys, Newman book on Unix machines
;;; a display name is "a string in the following format: 
;;; hostname:number.screen_number" and a double colon is allowed to 
;;; indicate a DECnet connection.  It seems that most X servers will
;;; allow one to ommit the screen number.  

(defun x11-parse-display-name (name)
  (let ((colon0 (position #\: name))
	(colon1 (position #\: name :from-end t))
	(period (position #\. name :from-end t)))
    (values 
       (if colon0
	   (subseq name 0 colon0)
	 (error "X11 display name must be host:server_number.screen_number"))
       (let ((start (1+ (or colon1 colon0))))
	 (if (>= start (length name))
	     0
	   (parse-integer name :start start :junk-allowed t)))
       (if (and period (< (1+ period) (length name)))
	   (parse-integer name :start (1+ period))
	 0))))


;;; Multiple value return XView ids for server, screen, root-window,
;;; a pointer to the X11 display structure, and a pointer to the X11
;;; screen structure.

(defun xview-open-display (name)
  (multiple-value-bind (host server screen-number)
      (x11-parse-display-name name)
    (declare (ignore host server))
    (XV:with-xview-lock 
      (let ((server  (XV:xv-create nil :server :xv-name name)))
	(when (= 0 server)
	  (error "Couldn't open a connection to X11 display ~S" name))
	(let* ((screen (XV:xv-get server :server-nth-screen screen-number))
	       (root (XV:xv-get screen :xv-root))
	       (dsp (make-foreign-pointer
		     :address (XV:xv-get server :xv-display)
		     :type '(:pointer X11:display)))
	       (scr (let ((screens (X11:display-screens dsp)))
		      (setf (foreign-pointer-type screens)
			    `(:pointer (:array x11:screen (,(X11:display-nscreens dsp)))))
		      (foreign-aref screens screen-number))))
	  (values server screen root dsp scr))))))



;;; The "<host>:<server>.<screen>" name of the display  may be specified directly, 
;;; as an initialization argument to make-instance 'display.  If a name is 
;;; not specified but the a value for :host is then the name of the display will 
;;; be "<host>:<server>.<screen>" with server and screen defaulting to zero.
;;; If :host is not specified then the Unix "DISPLAY" environment 
;;; variable is used.  If the DISPLAY envrionment variable is not bound
;;; then "unix:0.0" is used.
;;;
;;; The make-instance initargs are stored in the :initargs slots of the xview-display
;;; until the display is realized - at that point this slots is set to nil.

(defmethod dd-initialize-display ((p XView) display
				  &rest args
				  &key 
				    host
				    (screen 0)
				    (server 0)
				    name
				  &allow-other-keys)
  (setf (device display)
	(make-xview-display 
	 :name (or name
		   (if host
		       (format nil "~A:~D.~D" host screen server))
		   (environment-variable "DISPLAY")
		   "unix:0.0")
	 :initargs (copy-list args)))
  (setf (slot-value display 'status) :initialized))


;;; Note: XView keeps track of the number of frames on a particular server
;;; with a reference count.  When the reference count goes from 0 to n and
;;; then back to 0 XView assumes that the application is about to terminate
;;; and sets itself up acoordingly (as of 8/22/89 see libxvol/frame/fm_destroy.c
;;; in the XView sources). This is considered a "feature".  To prevent this 
;;; from happening during a Lisp session we make the servers FRAME_COUNT off by 
;;; one just after it's created.

(defmethod dd-realize-display ((p XView) display)
  (let ((xvd (device display)))
    (multiple-value-bind (server screen root dsp scr)
	(xview-open-display (xview-display-name xvd))
      (XV:xv-set server :server-sync-and-process-events t)
      (X11:XFlush dsp)
      (start-xview-notifier dsp)
      (XV:with-xview-lock 
	(XV:xv-set server :xv-key-data '(:frame-count 1)) ;; force ref count to be off by one
	(setf (slot-value display 'property-list)
	      (list 
	       :X-protocol-major-version (X11:display-proto-major-version dsp)
	       :X-protocol-minor-version (X11:display-proto-minor-version dsp)
	       :X-server-vendor (foreign-string-value (X11:display-vendor dsp))
	       :X-vendor-release (X11:display-release dsp)
	       :X-connection-number (X11:XConnectionNumber dsp))))
      (X11:XSetErrorHandler (lookup-callback-address 'x11-error-handler))

      (setf (xview-display-id xvd) server
	    (xview-display-xid xvd) (X11:display-resource-id dsp)
	    (xview-display-dsp xvd) dsp
	    (xview-display-scr xvd) scr
	    (xview-display-screen xvd) screen
	    (xview-display-root xvd) root
	    (xview-display-rdb xvd) (load-initial-resources display)
	    (xview-display-initargs xvd) nil)

      (with-slots (supported-depths root-canvas graphics-context) display
	(setf supported-depths (xview-make-supported-depths display scr)
	      root-canvas (xview-make-root-canvas display xvd dsp root)
	      graphics-context (make-instance 'graphics-context :display display))))))



;;; The display host, screen, and server slots are extracted from the 
;;; displays name (string) rather than storing them.  

(macrolet 
 ((def-reader (slot-name)
    `(defmethod ,(intern (format nil "DD-DISPLAY-~A" slot-name)) ((p XView) display)
       (let ((name (xview-display-name (device display))))
	 (multiple-value-bind (host server screen)
	     (x11-parse-display-name name)
	   (declare (ignore ,@(remove slot-name '(host screen server))))
	   ,slot-name)))))
 (def-reader host)
 (def-reader screen)
 (def-reader server))
	   
(defmethod dd-display-name ((p XView) display)
  (xview-display-name (device display)))


(defmethod dd-flush-output-buffer ((p XView) display)
  (XV:with-xview-lock 
   (X11:XFlush (xview-display-dsp (device display)))))
  


    
;;; Will need to set servers FRAME_COUNT to zero after all frames have been
;;; destroyed.

(defmethod dd-destroy-display ((ws XView) display)
  (declare (ignore display)))



