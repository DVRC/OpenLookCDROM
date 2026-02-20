;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)font.lisp	3.6 10/11/91


(in-package "LISPVIEW")


(defun check-font-spec (spec)
  (do ((spec-cdr spec (cddr spec-cdr)))
      ((null spec-cdr) nil)
    (let* ((parameter (car spec-cdr))
	   (value (cadr spec-cdr))
	   (type (if (symbolp parameter)
		     (get parameter 'font-parameter-type)
		   (error "indicator ~S should be a symbol" parameter))))
      (cond 
       (type
	(unless (typep value type)
	  (error "the value of ~S, ~S, must be a ~A" parameter value type)))
       ((eq parameter :name)
	(check-type value string))
       ((eq parameter :spec)
	(unless (and (listp spec) (evenp (length spec)))
	  (error "the value of :spec, ~S,  isn't a property list"))
	(check-font-spec value))))))


(defmethod initialize-instance :around ((f font) &key status &allow-other-keys)
  (prog1
      (call-next-method)
    (when (eq status :realized)
      (setf (status f) :realized))))


(defmethod initialize-instance :after ((f font) &rest args)
  (unless (slot-boundp f 'specification)
    (setf (font-spec f) (copy-list args)))
  (apply #'dd-initialize-font (platform f) f args))


(defmethod (setf status) ((value (eql :realized)) (f font))
  (unless (eq (status f) :realized)
    (check-font-spec (font-spec f))
    (dd-realize-font (platform f) f)
    (push f (slot-value (display f) 'fonts)))
  (setf (slot-value f 'status) :realized))


(defmethod (setf status) ((value (eql :destroyed)) (f font))
  (when (eq (status f) :realized)
    (dd-destroy-font (platform f) f))
  (let ((d (display f)))
    (setf (slot-value d 'fonts) (delete f (slot-value d 'fonts))
	  (slot-value f 'status) :destroyed)))



(def-solo-reader FONT-ASCENT font
  :type fixnum
  :driver dd-font-ascent)


(def-solo-reader FONT-DESCENT font
  :type fixnum
  :driver dd-font-descent)


(defun font-height (font) (+ (font-ascent font) (font-descent font)))


(def-solo-reader MIN-CHAR-CODE font
  :type fixnum
  :driver dd-font-min-char-code)


(def-solo-reader MAX-CHAR-CODE font
  :type fixnum
  :driver dd-font-max-char-code)


(def-solo-reader MIN-CHAR-METRICS font
  :driver dd-font-min-char-metrics)


(def-solo-reader MAX-CHAR-METRICS font
  :driver dd-font-max-char-metrics)


(def-solo-reader PROPERTY-LIST font
  :type list
  :driver dd-font-property-list)


(def-solo-accessor FONT-SEARCH-PATH display
  :type list
  :driver dd-font-search-path)


(defmethod CHAR-METRICS ((f font) code)
  (check-type code (integer 0 (#.char-code-limit)))
  (dd-font-char-metrics (platform f) f code))



(defun available-fonts (&rest args 
			&key 
			  max-matches
			  (display (default-display)) 
			&allow-other-keys)
  (declare (arglist (&key 
		       :display
		       :name 
		       :font-name-registry
		       :foundry
		       :family
		       :weight
		       :slant
		       :setwidth
		       :style
		       :pixel-size
		       :point-size
		       :resolution-x
		       :resolution-y
		       :spacing
		       :average-width
		       :charset-registry
		       :charset-encoding
		       :spec
		       :max-matches
		     &allow-other-keys)))
  (check-type max-matches (or null positive-fixnum))
  (check-font-spec args)
  (realize display)
  (apply #'dd-available-fonts (platform display) display args))



;;; The driver should signal an error if start and end are not within the 
;;; bounds of the string.  The driver does this so we can avoid computing
;;; (length string) twice.

(defmethod string-width ((font font) string &optional start end)
  (check-arglist (string string)
		 (start (or null (integer 0 *)))
		 (end (or null (integer 0 *))))
  (dd-string-width (platform font) font string start end))

