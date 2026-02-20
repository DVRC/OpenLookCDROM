;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)xview-font.lisp	3.5 10/11/91


(in-package "LISPVIEW")


(eval-when (compile load eval)
   (defvar x11-font-attr-alists nil))

(defmacro def-x11-font-attribute-keyword (keyword alist)
  (let ((type-name (intern (format nil "X11-FONT-~A" keyword)))
	(alist-constant (intern (format nil "X11-FONT-~A-ALIST" keyword))))
    `(progn
       (pushnew (cons ,keyword ',alist) x11-font-attr-alists :test #'eq :key #'car)
       (defconstant ,alist-constant ',alist)
       (deftype ,type-name () '(member ,@(mapcar #'car alist))))))


(def-x11-font-attribute-keyword :weight
  ((:ultra-light . "UltraLight")
   (:extra-light . "ExtraLight")
   (:light . "Light")
   (:semi-light . "SemiLight")
   (:medium . "Medium")
   (:normal . "Normal")
   (:regular . "Regular")
   (:semi-bold . "SemiBold")
   (:bold . "Bold")
   (:extra-bold . "ExtraBold")
   (:ultra-bold . "UltraBold")))


(def-x11-font-attribute-keyword :slant
  ((:roman . "R")
   (:italic . "I")
   (:oblique . "O")
   (:reverse-italic . "RI")
   (:reverse-oblique . "RO")))


(def-x11-font-attribute-keyword :setwidth
  ((:ultracondensed . "UltraCondensed")
   (:Extracondensed . "ExtraCondensed")
   (:condensed . "Condensed")
   (:semicondensed . "SemiCondensed")
   (:medium . "Medium")
   (:semiexpanded . "SemiExpanded")
   (:demiexpanded . "DemiExpanded")
   (:expanded . "Expanded")
   (:extraexpanded . "ExtraExpanded")
   (:ultraexpanded . "UltraExpanded")
   (:extrawide . "ExtraWide")))


(def-x11-font-attribute-keyword :spacing
  ((:monospaced . "M")
   (:proportional . "P")
   (:character-cell . "C")))


(deftype x11-integer-font-attribute ()
  '(member :pixel-size :point-size :resolution-x :resolution-y	:average-width))

(deftype x11-keyword-font-attribute ()
  '(member :weight :slant :setwidth :spacing))

(deftype x11-string-font-attribute ()
  '(member :font-name-registry :foundry :family :style :charset-registry :charset-encoding))

(eval-when (load eval compile)
  (defconstant x11-font-attributes 
    '(:font-name-registry :foundry :family :weight :slant :setwidth 
      :style :pixel-size :point-size :resolution-x :resolution-y 
      :spacing :average-width :charset-registry :charset-encoding)))

(deftype x11-font-attribute () '(member #.x11-font-attributes))


(defun x11-font-name-to-plist (name)
  (if (= 14 (count #\- name))
      (let ((start 0)
	    (end 0)
	    (plist nil))
	(dolist (attr x11-font-attributes plist)
	  (setq end (if (eq attr #.(car (last x11-font-attributes)))
			(length name)
		      (position #\- name :start start)))
	  (when (and end (>= end (1+ start)))
	    (setf (getf plist attr)
		  (typecase attr
		     (x11-integer-font-attribute
		      (let ((n (parse-integer name :start start :end end)))
			(if (eq attr :point-size)
			    (/ n 10.0)
			  n)))
		     (x11-keyword-font-attribute
		      (let ((value (subseq name start end)))
			(or (car (rassoc value (cdr (assoc attr x11-font-attr-alists)) 
					 :test #'string-equal))
			    value)))
		     (t
		      (subseq name start end)))))
	  (when end
	    (setq start (1+ end)))))))
		     


(defun x11-font-plist-to-name (plist)
  (macrolet ((string-value (keyword)
	        `(or (getf plist ,keyword) "*"))
	     (keyword-to-string-value (keyword)
                (let ((type (intern (format nil "X11-FONT-~A" keyword)))
		      (alist (intern (format nil "X11-FONT-~A-ALIST" keyword))))
		  `(let ((value (getf plist ,keyword)))
		     (if value
			 (if (typep value 'string)
			     value
			   (progn
			     (check-type value ,type)
			     (cdr (assoc value ,alist :test #'eq))))
		       "*"))))
	     (int-to-string-value (keyword)
	        `(let ((value (getf plist ,keyword)))
		   (if value
		       (prin1-to-string (if (eq ,keyword :point-size)
					    (truncate (* value 10))
					  value))
		     "*"))))
     (format nil "~A-~A-~A-~A-~A-~A-~A-~A-~A-~A-~A-~A-~A-~A-~A" 
	(string-value :font-name-registry)
	(string-value :foundry)
	(string-value :family)
	(keyword-to-string-value :weight)
	(keyword-to-string-value :slant)
	(keyword-to-string-value :setwidth)
	(string-value :style)
	(int-to-string-value :pixel-size)
	(int-to-string-value :point-size)
	(int-to-string-value :resolution-x)
	(int-to-string-value :resolution-y)
	(keyword-to-string-value :spacing)
	(int-to-string-value :average-width)
	(string-value :charset-registry)
	(string-value :charset-encoding))))




(defvar x11-nfont-paths 
  (make-foreign-pointer :type '(:pointer :signed-32bit) :static t))

(defmethod dd-font-search-path ((p XView) display)
  (XV:with-xview-lock 
    (let ((x11-paths (X11:XGetFontPath (xview-display-dsp (device display)) x11-nfont-paths))
	  (npaths (foreign-value x11-nfont-paths))
	  (paths nil))
      (setf (foreign-pointer-type x11-paths) 
	    `(:pointer (:array (:pointer :character) (,npaths))))
      (prog1
	  (dotimes (i npaths (nreverse paths))
	    (push (foreign-string-value (foreign-aref x11-paths i)) paths))
	(setf (foreign-pointer-type x11-paths) '(:pointer (:pointer :character)))
	(X11:XFreeFontPath x11-paths)))))


(defmethod (setf dd-font-search-path) (value (p XView) display)
  (let* ((npaths (length value))
	 (x11-paths (make-foreign-pointer 
		     :type `(:pointer (:array (:pointer :character) (,npaths))))))
    (let ((i 0))
      (dolist (path value)
	(setf (foreign-aref x11-paths i) (malloc-foreign-string path))
	(incf i)))
    (XV:with-xview-lock  
      (X11:XSetFontPath (xview-display-dsp (device display)) x11-paths npaths))
    (dotimes (i npaths)
      (free-foreign-pointer (foreign-aref x11-paths i)))
    (free-foreign-pointer x11-paths))
  value)


(defmethod dd-available-fonts ((p XView) display 
				&rest args
				&key 
				  name
				  (max-matches 1000)
				&allow-other-keys)
  (let* ((return-count (malloc-foreign-pointer :type '(:pointer :signed-32bit)))
	 (data (XV:with-xview-lock
		  (let ((name (malloc-foreign-string 
			        (or name (x11-font-plist-to-name args)))))
		    (prog1
			(X11:XListFonts (xview-display-dsp (device display))
					name
					max-matches
					return-count)
		      (free-foreign-pointer name)))))
	 (size (prog1 
		   (foreign-value return-count) 
		 (free-foreign-pointer return-count))))
    (when (> size 0)
      (setf (foreign-pointer-type data) 
	    `(:pointer (:array (:pointer :character) (,size))))
      (prog1
	  (let ((fonts nil))
	    (dotimes (i size fonts)
	      (push (x11-font-name-to-plist (foreign-string-value (foreign-aref data i)))
		    fonts)))
	(setf (foreign-pointer-type data) 
	      '(:pointer (:pointer :character)))
	(XV:with-xview-lock (X11:XFreeFontNames data))))))



(defun xview-get-font-info (id)
  (make-foreign-pointer 
    :type '(:pointer X11:XFontStruct)
    :address (XV:xv-get id :font-info)))


(defun xview-load-query-font (font name args)
  (let* ((name (malloc-foreign-string (or name (x11-font-plist-to-name args))))
	 (xvd (device (display font)))
	 (id (XV:with-xview-lock 
	       (XV:xv-create (xview-display-root xvd) :font :font-name name))))
    (unwind-protect
	(if (= 0 id)
	    (error "Can't find a font that matches ~S using name ~A" 
		   args 
		   (foreign-string-value name))
	  (XV:with-xview-lock 
	    (make-xview-font 
	      :xvd xvd 
	      :id id 
	      :xid (XV:xv-get id :xv-xid)
	      :dsp (xview-display-dsp xvd)
	      :xstruct (xview-get-font-info id))))
      (free-foreign-pointer name))))


(defmethod dd-initialize-font ((p XView) font &rest args)
  (declare (ignore args))
  (setf (slot-value font 'status) :initialized))


;;; Each font property is a keyword with a (CL) property under
;;; the indicator 'X-atom that is the value of the X atom for this
;;; property.  The names of the font property keywords are the same as the X
;;; atom minus the "XA-" prefix.

(defvar *x11-font-properties* 
  (let ((package (find-package :keyword)))
    (mapcar #'(lambda (atom)
		(let ((prop (intern (subseq (string atom) 3) package)))
		  (setf (get prop 'X-atom) (symbol-value atom))
		  prop))
	    '(X11:XA-min-space
	      X11:XA-norm-space
	      X11:XA-max-space
	      X11:XA-end-space
	      X11:XA-superscript-x
	      X11:XA-superscript-y
	      X11:XA-underline-position
	      X11:XA-underline-thickness
	      X11:XA-strikeout-ascent	      
	      X11:XA-strikeout-descent	      
	      X11:XA-italic-angle
	      X11:XA-x-height
	      X11:XA-quad-width
	      X11:XA-cap-height
	      X11:XA-weight
	      X11:XA-point-size
	      X11:XA-resolution))))

(defun x11-font-properties (xfont &optional (props *x11-font-properties*))
  (let ((value (malloc-foreign-pointer :type '(:pointer :signed-32bit))))
    (prog1
	(mapcan #'(lambda (prop)
		    (let ((atom (get prop 'X-atom)))
		      (if (and atom (/= 0 (X11:XGetFontProperty xfont atom value)))
			  (list prop (foreign-value value)))))
		props)
      (free-foreign-pointer value))))



(defun initialize-xview-font (xvo char-metrics-class)
  (let ((x11-font (xview-font-xstruct xvo)))
    (flet 
     ((cs-cm (cs &optional (nil-if-zero nil))
       (let ((cm (make-instance char-metrics-class
		   :left-bearing (X11:XCharStruct-lbearing cs)
		   :right-bearing (X11:XCharStruct-rbearing cs)
		   :width (X11:XCharStruct-width cs)
		   :ascent (X11:XCharStruct-ascent cs)
		   :descent (X11:XCharStruct-descent cs))))
	 (if (and nil-if-zero
		  (= 0 (char-left-bearing cm))
		  (= 0 (char-right-bearing cm))
		  (= 0 (char-width cm))
		  (= 0 (char-ascent cm))
		  (= 0 (char-descent cm)))
	     nil
	   cm))))

     (setf (xview-font-min-char-metrics xvo) (cs-cm (X11:XFontStruct-min-bounds x11-font))
	   (xview-font-max-char-metrics xvo) (cs-cm (X11:XFontStruct-max-bounds x11-font))
	   (xview-font-property-list xvo) (x11-font-properties x11-font))

     (let* ((min-code (X11:XFontStruct-min-char-or-byte2 x11-font))
	    (n-char-structs (1+ (- (X11:XFontStruct-max-char-or-byte2 x11-font) min-code)))
	    (cmv (setf (xview-font-char-metrics xvo) (make-array n-char-structs)))
	    (per-char (X11:XFontStruct-per-char x11-font)))
       (if (= 0 (foreign-pointer-address per-char))
	   (let ((cm (xview-font-min-char-metrics xvo)))
	     (dotimes (i n-char-structs)
	       (setf (svref cmv i) cm)))
	 (progn
	   (setf (foreign-pointer-type per-char) 
		 `(:pointer (:array X11:XCharStruct (,n-char-structs))))
	   (dotimes (i n-char-structs)
	     (setf (svref cmv i) (cs-cm (foreign-aref per-char i) :nil-if-zero)))))))))



(defmethod dd-realize-font ((p XView) font)
  (unless (slot-boundp font 'device)
    (let* ((spec (font-spec font))
	   (xvo (xview-load-query-font font (getf spec :name) spec)))
      (initialize-xview-font xvo (or (getf spec :char-metrics-class) 'char-metrics))
      (setf (device font) xvo))))



(defun xview-id-to-font (id display &key (font-class 'font) spec)
  (or (dolist (f (display-fonts display))
	(when (and (eq (type-of f) font-class)
		   (= id (xview-object-id (device f))))
	  (return f)))

      (XV:with-xview-lock 
       (let* ((xvd (device display))
	      (xvo (make-xview-font 
		    :xvd xvd 
		    :id id 
		    :xid (XV:xv-get id :xv-xid)
		    :dsp (xview-display-dsp xvd)
		    :xstruct (xview-get-font-info id))))
	 (initialize-xview-font xvo 'char-metrics)
	 (make-instance font-class
	   :spec spec
	   :display display
	   :status :realized
	   :device xvo)))))


(defmethod dd-destroy-font ((p XView) font)
  (XV:with-xview-lock 
   (XV:xv-destroy-safe (xview-font-id (device font)))))



;;; Define the XView font accessors that just look up a value in the 
;;; X11 XFontStruct.

(macrolet 
 ((def-reader (name x11-font-slot)
    `(defmethod ,name ((p XView) font)
       (declare (optimize (safety 1) (speed 3) (compilation-speed 0)))
       (let ((x11-font (xview-font-xstruct (device font))))
	 (if x11-font
	     (,x11-font-slot x11-font)
	   0)))))

 (def-reader DD-FONT-ASCENT X11:XFontStruct-ascent)
 (def-reader DD-FONT-DESCENT X11:XFontStruct-descent)
 (def-reader DD-FONT-MIN-CHAR-CODE X11:XFontStruct-min-char-or-byte2)
 (def-reader DD-FONT-MAX-CHAR-CODE X11:XFontStruct-max-char-or-byte2))


(let ((zero-char-metrics (make-instance 'zero-char-metrics)))
  (defmethod dd-font-char-metrics ((p XView) font code)
    (let* ((v (xview-font-char-metrics (device font)))
	   (cm (if (and v (>= code 0) (< code (length v))) (svref v code))))
      (if cm
	  (values (svref v code) t)
	(values zero-char-metrics nil)))))


(defmethod dd-font-min-char-metrics ((p XView) font)
  (values (xview-font-min-char-metrics (device font)) t))

(defmethod dd-font-max-char-metrics ((p XView) font)
  (values (xview-font-max-char-metrics (device font)) t))

(defmethod dd-font-property-list ((p XView) font)
  (xview-font-property-list (device font)))


(defmethod dd-string-width ((p XView) font string start end)
  (unless start (setq start 0))
  (let* ((length (if (or end (/= 0 start))
		     (- end start)
		   (length string)))
	 (s (malloc-foreign-string
	       (if end
		   (make-array length :element-type 'string-char
				      :displaced-to string
				      :displaced-index-offset start)
		 string))))
	(prog1
	    (XV:with-xview-lock
	     (X11:XTextWidth (xview-font-xstruct (device font)) s length))
	  (free-foreign-pointer s))))

