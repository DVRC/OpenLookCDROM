;;; -*- Mode: Lisp; Package: GENERIC -*-
;;;
;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.
;;;
;;; Random general purpose stuff.
;;;
;;; Author: Conal Elliott.  Last Modified Mon Nov  5 16:05:39 1990
;;;
;;; Sccs Id %W% %G%
;;;

(in-package :GENERIC)

(export '(floatifyf))
(export '(def-cached-slot *tracing-cached-slots*))
(export '(mapp mapp-concat mapp-setify mapp-union
          concatt convert-seq concatenate-seq-seq seq-rotate-right
          seq-translate))
(export '(count-to))

#|
;;;; FFI stuff.
(export '(null-pointer-to copy-to-foreign-array map-foreign-vector))

(defun null-pointer-to (elt-type)
  "Make a foreign pointer to an ELT-TYPE."
  (make-foreign-pointer :type `(:pointer ,elt-type)
                        :address 0))
(defun array-pointer-to-pointer (elt-type arr-ptr)
  "Coerce a foreign pointer of type (:pointer (:array ELT-TYPE ...)) to one of
type (:pointer ELT-TYPE)."
    (make-foreign-pointer :type `(:pointer ,elt-type)
                          :address (foreign-pointer-address arr-ptr)))

(defun map-foreign-vector (foreign-elt-type fun seq)
  "Construct a pointer to the first element of a foreign array with elements
FOREIGN-ELT-TYPE by mapping the one-argument function FUN over the sequence SEQ
whose elements have type (:pointer FOREIGN-ELT-TYPE).  To handle multi-argument
functions, just use map to create one sequence, and then map-foreign-vector
with #'identity."
  (array-pointer-to-pointer foreign-elt-type
   (let ((fptr (make-foreign-pointer
                :type `(:pointer (:array ,foreign-elt-type
                                  (,(length seq)))))))
     (dotimes (i (length seq))
       (setf (foreign-aref fptr i) (funcall fun (elt seq i))))
     fptr)))

|#

(defmacro floatifyf (&rest places)
  "For each PLACE, if PLACE is non-nil, coerce it to a float.  Does not take
care not to re-evaluate PLACE."
  `(progn
    ,@(mapcar #'(lambda (place)
                  `(when ,place (setf ,place (coerce ,place 'float))))
       places)))

;;;; Cached slots

(defvar *tracing-cached-slots* nil
  "Whether there is a message generated when a cached slot is computed.  Helps
with debugging.")

(defmacro def-cached-slot (slot-name arg-spec &rest body)
  "Tell how to compute (slot-value <object> 'SLOT-NAME) if unbound, when
<object> fits the ARG-SPEC.  The result is stashed into the slot as well as
returned, so that it will get computed at most once."
  (let ((class-name-var (gensym))
        (slot-name-var (gensym)))
    `(defmethod slot-unbound (,class-name-var ,arg-spec
                              (,slot-name-var (eql ',slot-name)))
      (declare (ignore ,class-name-var))
      (when *tracing-cached-slots*
        (format t "~&Computing slot ~a of ~s~%"
                ',slot-name ,(first arg-spec)))
      (setf (slot-value ,(first arg-spec) ',slot-name) (progn ,@body)))))


;;;; Sequence stuff.  Mainly this lets us experiment with choices of list
;;;; vs vector.  (Short lists often win over short vectors even for fixed-size
;;;; applications.)

;;;; This implementation just chooses *preferred-sequence-type* all the time,
;;;; but another candidate is to imitate the type of a sequence argument.

#| Now used from ergo-types.lisp
(export 'sequence-of)
(deftype sequence-of (elt-type)
  "Sequence with members of type ELT-TYPE.  Really just sequence, but this lets
us have nice documentation, and later we could put in checking."
  (declare (ignore elt-type))
  `sequence)

|#

;;; Perhaps there should also be (preferring-sequence-type TYPE . BODY).
(defparameter *preferred-sequence-type* 'vector
  "The generally preferred type for sequences which don't obviously need to be
lists or vectors.")

(defun sequence (&rest args)
  "Construct a sequence out of ARGS, deciding which sequence type to use."
  (if (eq *preferred-sequence-type* 'list)
      args
      (apply *preferred-sequence-type* args)))

;;; Probably a lot of these functions should be macros to avoid consing up the
;;; rest args at runtime and using apply.
(defun mapp (fun &rest seqs)
  "Map FUN over the SEQS, deciding which sequence type to use as result."
  (apply #'map *preferred-sequence-type* fun seqs))

(defun mapp-concat (fun &rest seqs)
  "Like mapcan, but with general sequences and non-destructive.  Mapp's FUN
over the SEQS, and concatenates the results."
  (concatenate-seq-seq (apply #'mapp fun seqs)))

(defun mapp-setify (fun &rest seqs)
  "Mapp's FUN over the SEQS and removes the duplicates."
  ;; Since mapp constructs a new sequence, there is no harm using the
  ;; destructive "delete-duplicates" instead of "remove-duplicates"
  (delete-duplicates (apply #'mapp fun seqs)))

(defun mapp-union (fun &rest seqs)
  "Like mapp-concat, but removes duplicates between (not within) the resulting
sequences.  If the returned sequences are disjoint then the result will be
duplicate-free.  If not, then no promises?"
  ;; Actually this simple implementation always gives duplicate-free results.
  ;; However, another implementation could optimize for lists and apply union.
  (delete-duplicates (apply #'mapp-concat fun seqs)))

(defun concatt (&rest seqs)
  "Like concatenate, but chooses the result type."
  (apply #'concatenate *preferred-sequence-type* seqs))

(defun convert-seq (old-seq &optional (new-seq-type *preferred-sequence-type*))
  "Construct a sequence from a sequence.  Returns the given sequence if it is
already of the right type.  The result sequence type is chosen automatically or
as given by the optional argument."
  (if (typep old-seq new-seq-type)
      old-seq
      (map new-seq-type #'identity old-seq)))

(defun concatenate-seq-seq (seq-seq)
  "Concatenate the given sequence of sequences."
  ;; If we have a list to work with or want one as a result, just concat.
  (if (or (typep seq-seq 'list)
          (eq *preferred-sequence-type* 'list))
      (apply #'concatenate *preferred-sequence-type*
             (convert-seq seq-seq 'list))
      ;; Otherwise, make a new vector big enough to hold all of the elements,
      (let ((out-vector (make-sequence
                         'vector
                         ;; Compute sum of lengths.  Note: we could use
                         ;; the reduce-map optimization.
                         (reduce #'+ (mapp #'length seq-seq)
                                 :initial-value 0))))
        ;; ... and fill it in.  Accumulate the offset into the new vector while
        ;; copying the old sequences into it.  (This reduce computes the
        ;; length, but we don't need it in the end.)
        (reduce #'(lambda (length-so-far next-seq)
                    (replace out-vector next-seq :start1 length-so-far)
                    (+ length-so-far (length next-seq)))
                seq-seq
                :initial-value 0)
        out-vector)))

(defun seq-rotate-right (seq)
  "From a sequence [a,b,...,z], generate [b,...,z,a]."
  (if (= (length seq) 0)
      seq
      (etypecase seq
        ;; If a list just post-cons
        (list
         (append (rest seq) (list (first seq))))
        ;; If a vector, make a new one.  Then fill in b,...,z and then a.
        (vector
         (let ((new-vector (make-sequence 'vector (length seq))))
           (replace new-vector seq :start2 1)
           ;; Uses aref instead of svref in case of fill pointers, etc.
           (setf (aref new-vector (1- (length seq)))
                 (aref seq 0))
           new-vector)))))

(defun seq-translate (item keys data &rest rest)
  "Translate ITEM via the sequences KEYS and DATA, i.e., return the element of
DATA in the position corresponding to ITEM in KEYS.  Similar to (cdr (assoc
ITEM (pairlis KEYS DATA))), except that (a) it doesn't build the alist, (b)
KEYS and DATA are general sequences, not just lists, and (c) it yields an error
if the item is not in keys.  Takes the same keyword arguments as does assoc
 (e.g., :key and :test), but also those of find and position (:from-end,
:start, :end)."
  ;; This should also probably be a macro.
  (elt data (apply #'position item keys rest)))


;;;; Functions for generating sequences of consecutive natural numbers.  Often
;;;; allows for elegant mapping operations.

(defvar *master-count-vector*
  ;; The master array from which count-to subsequence results are taken.
  (make-array 0 :fill-pointer t :adjustable t))

(defun ensure-master-count-big-enough (n)
  ;; Make *master-count-vector* be at least 0...n-1
  (let ((curr-length (length *master-count-vector*)))
    (when (> n curr-length)
      ;; (format t "~&bumping master vector for ~s~%" n)
      (dotimes (i (- n curr-length))
        (vector-push-extend (+ curr-length i) *master-count-vector*)))))

;;; It might also probably be a good idea to cache the results of count-to.

(defun count-to (n &key (start 0))
  "Construct a sequence up to n-1.  Starts from 0 or as specified by the
keyword argument :start."
  (if (eq *preferred-sequence-type* 'list)
      ;; Uses tail-recursive accumulator aux function.
      (labels ((count-to-acc (n tail-so-far)
                 (if (<= n start)
                     tail-so-far
                     (count-to-acc (1- n) (cons (1- n) tail-so-far)))))
        (count-to-acc n ()))
      (progn
        (ensure-master-count-big-enough n)
        (make-array (- n start)
                    :displaced-to *master-count-vector*
                    :displaced-index-offset start))))

