;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;; Default for the output-region and view-region are "just big enough"

(let* ((bw (make-instance 'base-window))
       (br (bounding-region bw)))
  (make-instance 'viewport
    :parent bw
    :vertical-scrollbar (make-instance 'vertical-scrollbar)
    :border-width 1
    :container-region (make-region :width (region-width br) :height (region-height br))))



;;; Typical use of output-region

(let* ((bw (make-instance 'base-window))
       (br (bounding-region bw)))
  (make-instance 'viewport
    :parent bw
    :vertical-scrollbar (make-instance 'vertical-scrollbar)
    :horizontal-scrollbar (make-instance 'horizontal-scrollbar)
    :border-width 1
    :container-region (make-region :width (region-width br) :height (region-height br))
    :output-region (make-region :width 800 :height 800)))



;;; Default for unspecified output-region dimensions are "just big enough"

(let* ((bw (make-instance 'base-window))
       (br (bounding-region bw)))
  (make-instance 'viewport
    :parent bw
    :vertical-scrollbar (make-instance 'vertical-scrollbar)
    :border-width 1
    :container-region (make-region :width (region-width br) :height (region-height br))
    :output-region (list :height 1000)))


