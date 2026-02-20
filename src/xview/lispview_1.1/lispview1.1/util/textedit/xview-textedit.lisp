;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)xview-textedit.lisp	1.6 10/21/91


(in-package "LISPVIEW")


(def-foreign-function (xv-get-textsw-contents 
		       (:name "_xv_get")
		       (:return-type XV:xv-opaque))
  (object XV:xv-object)
  (attr XV:xv-generic-attr)
  (pos XV:textsw-index)
  (buf (:pointer :character))
  (buf-len :signed-32bit))


(defstruct (XVIEW-TEXTEDIT-WINDOW (:include xview-window))
  filename)


(defmethod dd-initialize-canvas ((p XView) (w textedit-window) &rest initargs)
  (declare (dynamic-extent initargs))
  (xview-initialize-canvas w #'make-xview-textedit-window initargs))


;;; The macro below generates the function xview-realize-textsw which 
;;; handles converting the myriad textsw initargs (there are 30) from 
;;; LispView initarg keywords to XView attribute keywords.   The result
;;; isn't very complicated (just big) - evaluate the entire macrolet 
;;; expression and then describe 'xview-realize-textsw to see.

(macrolet
 ((def-realize-xview-textsw (special-initargs)
    (let* ((literal-initargs
	    (mapcar #'(lambda (entry)
			(intern (string (textedit-accessor-initarg entry))))
		    literal-xview-textedit-accessors))

	   (initargs
	    (append literal-initargs special-initargs))

	   (key-arglist
	    (mapcar #'(lambda (initarg)
			(list initarg nil (intern (format nil "~A-P" initarg))))
		    initargs))

	   (xview-attr-initforms
	    (mapcar #'(lambda (initarg entry)
			(let ((initarg-p 
			       (intern (format nil "~A-P" initarg)))
			      (xview-attr 
			       (xview-textedit-attribute entry))
			      (type
			       (xview-textedit-attribute-type entry)))
			  `(if ,initarg-p
			       ,(cond
				 ((subtypep type 'display-device-status)
				  `(let ((id (xview-object-id (device ,initarg))))
				     (if id (list ,xview-attr id))))
				 ((or (eq type 'boolean) (subtypep type 'integer))
				  `(list ,xview-attr ,initarg))))))
		    literal-initargs
		    literal-xview-textedit-accessors)))

      `(defun realize-xview-textsw (ew xvo al &key ,@key-arglist &allow-other-keys)
	 (apply #'realize-xview-canvas ew xvo al (nconc ,@xview-attr-initforms))
	 (when contents-p 
	   (setf (textedit-contents ew) contents))
	 (when insertion-point-p
	   (setf (textedit-insertion-point ew) insertion-point))
	 (when line-break-action-p 
	   (setf (textedit-line-break-action ew) line-break-action))
	 (when insert-makes-visible-p
	   (setf (textedit-insert-makes-visible ew) insert-makes-visible))))))

 (def-realize-xview-textsw (contents insertion-point)))


(defmethod dd-realize-canvas ((p xview) (w textedit-window))
  (XV:with-xview-lock 
    (let* ((xvo (device w))
	   (initargs 
	    (prog1
		(xview-object-initargs xvo)
	      (setf (xview-object-initargs xvo) nil))))

      (using-resource (al xview-attr-list-resource (xview-canvas-owner w) :textsw)
	(apply-xview-opaque-canvas-inits w xvo al initargs)
	(apply #'init-xview-window w xvo al initargs)
	(apply #'realize-xview-textsw w xvo al initargs)))))

	    
(defun xview-textsw-index (location)
  (case location 
    (:first 0) 
    (:last XV:textsw-infinity) 
    (t location)))


(def-xview-initarg-accessor DD-TEXTEDIT-INSERTION-POINT
  :textsw-insertion-point 
  :insertion-point
  :type textedit-location
  :solo-to-xview (xview-textsw-index SOLO-VALUE))


(def-xview-initarg-reader DD-TEXTEDIT-MODIFIED-P
  :textsw-modified
  :not-used
  :type boolean)


(def-xview-initarg-reader DD-TEXTEDIT-CONTENTS-LENGTH
  :textsw-length
  :no-initarg
  :type fixnum)


(defun xview-handle-textsw-status (status format-string &rest args)
  (let* ((value 
	  (prog1 
	      (foreign-value status)
	    (free-foreign-pointer status)))
	 (error-message
	  (XV:enum-case value
	    (:textsw-status-okay nil)
	    (:textsw-status-bad-attr "internal LispView error [bad XView attribute]")
	    (:textsw-status-bad-attr-value "internal LispView error [bad XView attribute value]")
	    (:textsw-status-cannot-allocate "not enough memory available [malloc/calloc failed]")
	    (:textsw-status-cannot-open-input "can't open/access file")
	    (:textsw-status-cannot-insert-from-file "internal XView error [insert failed]")
	    (:textsw-status-out-of-memory "out of memory")
	    (:textsw-status-other-error "internal XView error"))))
    (when error-message
      (apply #'error 
	     (format nil "~A - ~~A" format-string) 
	     (append args (list error-message))))))


(defmethod (setf dd-textedit-contents) (value (p XView) ew)
  (XV:with-xview-lock 
    (let* ((xvo (device ew))
	   (id (xview-object-id xvo)))
      (if id
	  (let ((status (malloc-foreign-pointer :type '(:pointer XV:Textsw-status))))
	    (if (typep value 'string)
		(progn
		  (XV:xv-set id :textsw-status status
			        :textsw-contents value
				:textsw-first 0)
		  (xview-handle-textsw-status status 
		     "Unable to insert string ~24S~A" value (if (> (length value) 24) "..." "")))
	      (progn
		(XV:xv-set id 
		  :textsw-status status
		  :textsw-file (setf (xview-textedit-window-filename xvo) (namestring value))
		  :textsw-first 0)
		(xview-handle-textsw-status status "Unable to load file ~S" value))))
	(setf (getf (xview-canvas-initargs xvo) :contents) value))))
  value)



(defmethod dd-textedit-contents ((p XView) ew start end)
  (XV:with-xview-lock 
    (let* ((xvo (device ew))
	   (id (xview-object-id xvo)))
      (when id  
	(let* ((start (if start (xview-textsw-index start) 0))
	       (end (if end 
			(xview-textsw-index end) 
		      (XV:xv-get id :textsw-length)))
	       (length (- end start))
	       (buffer (malloc-foreign-pointer
			 :type `(:pointer (:array :character (,length))))))
	  (xv-get-textsw-contents id 
				  #.(XV:keyword-enum :textsw-contents)
				  start 
				  (foreign-array-to-pointer buffer) 
				  length)
	  (prog1
	      (foreign-string-value buffer)
	    (free-foreign-pointer buffer)))))))



(defmethod dd-textedit-insert ((p XView) ew value)
  (XV:with-xview-lock 
    (let* ((xvo (device ew))
	   (id (xview-object-id xvo)))
      (when id  
	(typecase value
	  (string
	   (let* ((fp (malloc-foreign-string value))
		  (length (length value))
		  (n (XV:textsw-insert id fp length)))
	     (free-foreign-pointer fp)
	     (unless (= n length)
	       (error "String insert in ~S failed: ~S of ~S chars inserted" n length))))

	  (pathname
	   (let* ((status (malloc-foreign-pointer :type '(:pointer XV:Textsw-status)))
		  (fp (malloc-foreign-string (namestring value))))
	     (XV:xv-set id :textsw-status status
			   :textsw-insert-from-file fp)
	     (free-foreign-pointer fp)
	     (xview-handle-textsw-status status "Unable to load file ~S" value))))))))
		 

(defmethod dd-textedit-delete ((p XView) ew start end update-clipboard)
  (XV:with-xview-lock 
    (let* ((xvo (device ew))
	   (id (xview-object-id xvo)))
      (when id  
	(let* ((first (xview-textsw-index start))
	       (last-plus-one (xview-textsw-index end))
	       (err
		(if update-clipboard
		    (XV:textsw-delete id first last-plus-one)
		  (XV:textsw-erase id first last-plus-one))))
	  (when (= 0 err)
	    (error "Delete operation failed: ~S to ~S" start end)))))))
  

;;; BUG - Fails if viewing the end of the file.

(defmethod dd-textedit-visible-text-offset ((p XView) ew unit)
  (XV:with-xview-lock 
    (let* ((xvo (device ew))
	   (id (xview-object-id xvo)))
      (if id  
	  (let ((top (malloc-foreign-pointer :type '(:pointer :signed-32bit)))
		(bottom (malloc-foreign-pointer :type '(:pointer :signed-32bit))))
	    (XV:textsw-file-lines-visible id top bottom)
	    (multiple-value-prog1
		(let ((top (foreign-value top))
		      (bottom (foreign-value bottom))) 
		  (if (eq unit :line)
		      (values top bottom)
		    (values (XV:textsw-index-for-file-line id top)
			    (1- (XV:textsw-index-for-file-line id (1+ bottom))))))
	      (free-foreign-pointer top)
	      (free-foreign-pointer bottom)))
	(values 0 0)))))


;;; BUG - Fails if value is :last.

(defmethod (setf dd-textedit-visible-text-offset) (value (p XView) ew unit)
  (XV:with-xview-lock 
    (let* ((xvo (device ew))
	   (id (xview-object-id xvo)))
      (if id  
	  (let* ((index (xview-textsw-index value))
		 (offset (if (eq unit :char)
			     index
			   (XV:textsw-index-for-file-line id index))))
	    (XV:xv-set id :textsw-first offset)))))
  value)



(defmethod dd-textedit-filename ((p XView) ew)
  (XV:with-xview-lock 
    (let* ((xvo (device ew))
	   (id (xview-object-id xvo)))
      (if id  
	  (let* ((fp (malloc-foreign-string (make-string 1024 :initial-element #\null)))
		 (err (XV:textsw-append-file-name id fp)))
	    (prog1
		(when (= 0 err)
		  (setf (xview-textedit-window-filename xvo) (foreign-string-value fp)))
	      (free-foreign-pointer fp)))
	(let ((initargs (xview-canvas-initargs xvo)))
	  (or (xview-textedit-window-filename xvo)
	      (let ((contents (getf initargs :contents)))
		(if (pathnamep contents) contents))))))))
	    
  
(defmethod (setf dd-textedit-filename) (value (p XView) ew)
  (setf (xview-textedit-window-filename (device ew)) value))


;;; If a filename was specified then use it.  If the textsw has a filename,
;;; i.e. if textedit-filename returns non nil, then either the user has 
;;; loaded a file interactively or the contents of the textsw have 
;;; been set to a file programatically.  In this case we save the textsw
;;; without specifying a filename, with XV:textsw-save.  Finally: if a filename
;;; was set for this textedit-window, e.g. with (setf textedit-filename), 
;;; then use that.

(defmethod dd-textedit-save ((p XView) ew filename notice-x notice-y)
  (XV:with-xview-lock 
    (let* ((xvo (device ew))
	   (id (xview-object-id xvo))
	   (err nil))
      (when id
	(let ((filename (or filename
			    (textedit-filename ew)
			    (xview-textedit-window-filename xvo))))
	  (when filename
	    (let ((fp (malloc-foreign-string (namestring (pathname filename)))))
	      (setf err (XV:textsw-store-file id fp (or notice-x 0) (or notice-y 0)))
	      (free-foreign-pointer fp)))
	  (if (zerop err) 
	      filename
	    (warn "File save failed: ~S, ~S" ew filename)))))))


(defmethod dd-textedit-reset ((p XView) ew notice-x notice-y)
  (XV:with-xview-lock 
    (let* ((xvo (device ew))
	   (id (xview-object-id xvo)))
      (when id
	(XV:textsw-reset id (or notice-x 0) (or notice-y 0)))))
  nil)


(defmethod dd-textedit-font ((p XView) ew)
  (XV:with-xview-lock 
    (let* ((xvo (device ew))
	   (id (xview-object-id xvo)))
      (if id
	  (xview-id-to-font (XV:xv-get id :xv-font) (display ew))
	(getf (xview-canvas-initargs xvo) :font)))))

	      
(defmethod (setf dd-textedit-font) (font (p XView) ew)
  (XV:with-xview-lock 
    (let* ((xvo (device ew))
	   (ew-id (xview-object-id xvo))
	   (font-id (xview-object-id (device font))))
      (if ew-id
	  (when font-id 
	    (XV:xv-set ew-id :xv-font font-id))
	(setf (getf (xview-canvas-initargs xvo) :font) font)))))

	      
						     
(def-xview-initarg-accessor DD-TEXTEDIT-INSERT-MAKES-VISIBLE
  :textsw-insert-makes-visible
  :insert-makes-visible
  :type textedit-insert-makes-visible
  :solo-to-xview 
     (case SOLO-VALUE 
       (:always :textsw-always)
       (:if-auto-scroll :textsw-if-auto-scroll))
  :xview-to-solo 
     (XV:enum-case XVIEW-VALUE
       (:textsw-always :always)
       (:textsw-if-auto-scroll :if-auto-scroll)))



(macrolet 
 ((def-menu-accessor (driver attribute initarg)
    `(def-xview-initarg-accessor ,driver
       ,attribute
       ,initarg
       :type menu
       :solo-to-xview (xview-object-id (device SOLO-VALUE))
       :xview-to-solo (error "not implemented"))))

 (def-menu-accessor DD-TEXTEDIT-SUBMENU-EDIT :textsw-submenu-edit :submenu-edit)
 (def-menu-accessor DD-TEXTEDIT-SUBMENU-FILE :textsw-submenu-file :submenu-file)
 (def-menu-accessor DD-TEXTEDIT-SUBMENU-FIND :textsw-submenu-find :submenu-find)
 (def-menu-accessor DD-TEXTEDIT-SUBMENU-VIEW :textsw-submenu-view :submenu-view))



;;; BUG - This fails, XView bug #1047539

(def-xview-initarg-accessor DD-TEXTEDIT-LINE-BREAK-ACTION
  :textsw-line-break-action
  :line-break-action
  :type textedit-line-break-action
  :solo-to-xview 
     (case SOLO-VALUE 
       (:clip :textsw-clip)
       (:wrap-at-char :textsw-wrap-at-char)
       (:wrap-at-word :textsw-wrap-at-word))
  :xview-to-solo 
     (XV:enum-case XVIEW-VALUE
       (:textsw-clip :clip)
       (:textsw-wrap-at-char :wrap-at-char)
       (:textsw-wrap-at-word :wrap-at-word)))



(defmethod dd-textedit-find-string ((p Xview) ew string start end from-end)
  (XV:with-xview-lock 
    (let* ((xvo (device ew))
	   (id (xview-object-id xvo)))
      (when id
	(let ((first (malloc-foreign-pointer :type '(:pointer XV:textsw-index)))
	      (last-plus-one (malloc-foreign-pointer :type '(:pointer XV:textsw-index)))
	      (buf (malloc-foreign-string  string))
	      (flags (if from-end 1 0))
	      (length (length string)))
	  (setf (foreign-value first) (xview-textsw-index start)
		(foreign-value last-plus-one) (xview-textsw-index end))
	  (prog1
	      (when (/= -1 (XV:textsw-find-bytes id first last-plus-one buf length flags))
		(if from-end 
		    (1- (foreign-value last-plus-one))
		  (foreign-value first)))
	    (free-foreign-pointer first)
	    (free-foreign-pointer last-plus-one)
	    (free-foreign-pointer buf)))))))
	      

;;; The macros below define the following driver methods:
;;;
;;;   dd-textedit-left-margin
;;;   dd-textedit-right-margin
;;;   dd-textedit-bottom-margin
;;;   dd-textedit-top-margin
;;;   dd-textedit-again-recording 
;;;   dd-textedit-auto-indent
;;;   dd-textedit-auto-scroll-by 
;;;   dd-textedit-blink-caret
;;;   dd-textedit-browsing 
;;;   dd-textedit-checkpoint-frequency
;;;   dd-textedit-confirm-overwrite 
;;;   dd-textedit-control-chars-use-font
;;;   dd-textedit-disable-cd 
;;;   dd-textedit-disable-load
;;;   dd-textedit-history-limit 
;;;   dd-textedit-ignore-limit
;;;   dd-textedit-lower-context 
;;;   dd-textedit-memory-maximum
;;;   dd-textedit-multi-click-space 
;;;   dd-textedit-multi-click-timeout
;;;   dd-textedit-store-changes-file 
;;;   dd-textedit-upper-context
;;;   dd-textedit-read-only
;;; 
;;; Each of these gets/sets the integer or boolean XView textsw attribute whose
;;; name is the same modulo the dd-textedit prefix.  For example the accessor called
;;; dd-textedit-auto-indent manages the XView textsw attribute textsw-auto-indent.

(macrolet
 ((def-literal-accessor (entry)
    `(def-xview-initarg-accessor ,(intern (format nil "DD-~A" (car entry)))
       ,(xview-textedit-attribute entry)
       ,(textedit-accessor-initarg entry)
       :type ,(xview-textedit-attribute-type entry)))

  (def-literal-accessors ()
    `(progn
       ,@(mapcan #'(lambda (entry)
		     (let ((type (xview-textedit-attribute-type entry)))
		       (when (or (eq type 'boolean)
				 (subtypep type 'integer))
			 `((def-literal-accessor ,entry)))))
		 literal-xview-textedit-accessors))))

 (def-literal-accessors))


#|

(defconstant textsw-notify-all 
  (logior XV:textsw-notify-destroy-view
	  XV:textsw-notify-edit-delete
	  XV:textsw-notify-edit-insert
	  XV:textsw-notify-paint
	  XV:textsw-notify-repaint
	  XV:textsw-notify-scroll
	  XV:textsw-notify-split-view
	  XV:textsw-notify-standard))

(defconstant xview-textsw-action-translations
  (list
   (cons (XV:keyword-enum :textsw-action-caps-lock)          :caps-lock)
   (cons (XV:KEYWORD-ENUM :textsw-action-changed-directory)  :changed-directory)
   (cons (XV:keyword-enum :textsw-action-edited-file)        :edited-file)
   (cons (xv:keyword-enum :textsw-action-edited-memory)      :edited-memory)
   (cons (xv:keyword-enum :textsw-action-file-is-readonly)   :file-is-readonly)
   (cons (xv:keyword-enum :textsw-action-loaded-file)        :loaded-file)
   (cons (xv:keyword-enum :textsw-action-tool-close)         :tool-close)
   (cons (xv:keyword-enum :textsw-action-tool-destroy)       :tool-destroy)
   (cons (xv:keyword-enum :textsw-action-tool-mgr)           :tool-mgr)
   (cons (xv:keyword-enum :textsw-action-tool-quit)          :tool-quit)
   (cons (xv:keyword-enum :textsw-action-using-memory)       :using-memory)
   (cons (xv:keyword-enum :textsw-action-destroy-view)       :destroy-view)
   (cons (xv:keyword-enum :textsw-action-painted)            :painted)
   (cons (xv:keyword-enum :textsw-action-replaced)           :replaced)
   (cons (xv:keyword-enum :textsw-action-saving-file)        :saving-file)
   (cons (xv:keyword-enum :textsw-action-scrolled)           :scrolled)
   (cons (xv:keyword-enum :textsw-action-split-view)         :split-view)
   (cons (xv:keyword-enum :textsw-action-storing-file)       :storing-file)
   (cons (xv:keyword-enum :textsw-action-write-failed)       :write-failed)))


(defvar xview-error-avlist-type 
  '(:pointer (:array :signed-32bit (#.XV:attr-standard-size))))


(defun handle-xview-textsw-notify-avlist (textedit-window avlist-addr)
  (let ((avlist-fp (FFI:make-foreign-pointer :address avlist-addr
					     :type '(:pointer xview-attr-list)))
	(n 0))
    (macrolet
     ((avlist-ref (index)
	`(typed-foreign-aref 'xview-attr-list avlist-fp ,index)))

     (loop
      (let ((action 
	     (assoc (avlist-ref n) xview-textsw-action-translations :test #'=)))
	(if (null action)
	    (return)
	  (let* ((action (cdr action))
		 (value
		  (case action
		    ((:changed-directory
		      :edited-file
		      :file-is-readonly
		      :loaded-file
		      :storing-file)
		     (prog1
			 (foreign-string-value (avlist-ref (1+ n)))
		       (incf n 2)))

		    ((:caps-lock)
		     (prog1
			 (/= 0 (avlist-ref (1+ n)))
		       (incf n 2)))

		    ((:edited-memory
		      :tool-close
		      :using-memory
		      :destroy-view
		      :saving-file
		      :write-failed)
		     (incf n) nil)

		    (:painted
		     (let ((fp (make-foreign-pointer :address (avlist-ref (1+ n))
						     :type '(:pointer XV:rect))))
		       (prog1
			   (make-region :left (XV:rect-r-left fp)
					:top  (XV:rect-r-top fp)
					:width (XV:rect-r-width fp)
					:height (XV:rect-r-height fp))
			 (incf n 2))))
		       
		    ((:tool-destroy
		      :tool-mgr
		      :tool-quit
		      :split-view)
		     (prog1
			 (avlist-ref (1+ n))
		       (incf n 2)))

		    (:replaced
		      (incf n 6) nil)

		    (:scrolled
		      (incf n 3) nil))))

	    (print (list action value)))))))))
	  


(XV:defcallback textsw-notify-proc (textsw avlist-addr)
  (let ((textedit-window 
	 (XV:xv-client-data (XV:xv-get textsw :win-parent) :win-client-data)))
    (when (typep textedit-window 'textedit-window)
      (handle-xview-textsw-notify-avlist textedit-window avlist-addr)))
  (textsw-default-notify textsw avlist-addr))
    

|#
