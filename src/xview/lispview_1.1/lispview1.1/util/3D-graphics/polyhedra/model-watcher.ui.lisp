;;; This file produced by GLV
;;; do not edit by hand unless you are satisfied
;;; with the layout of these objects,
;;; instead, use Devguide to edit /auto/net/newbirth/export/home/gtg/conal/gaf/polyhedra/model-watcher.G

(in-package "USER") 

(defclass model-watcher
          nil
          ((watcher-window :accessor watcher-window)
            (controls :accessor controls)
            (scale-slider :accessor scale-slider)
            (rotate-slider :accessor rotate-slider)
            (rotation-axes :accessor rotation-axes)
            (rotation-count :accessor rotation-count)
            (rotate-button :accessor rotate-button)
            (axistheta :accessor axistheta)
            (axisphi :accessor axisphi)
            (controls1 :accessor controls1)
            (truncate-button :accessor truncate-button)
            (platonic-button :accessor platonic-button)
            (platonic-setting :accessor platonic-setting)
            (dual-button :accessor dual-button)))


(defmethod initialize-instance
           :after
           ((model-watcher model-watcher) &rest args)
           (with-slots
             (watcher-window controls
                             scale-slider
                             rotate-slider
                             rotation-axes
                             rotation-count
                             rotate-button
                             axistheta
                             axisphi
                             controls1
                             truncate-button
                             platonic-button
                             platonic-setting
                             dual-button)
             model-watcher
             (setf watcher-window
                   (make-instance 'model:watcher-window
                                  :mapped
                                  nil
                                  :closed
                                  nil
                                  :show-resize-corners
                                  t
                                  :left-footer
                                  " "
                                  :right-footer
                                  " "
                                  :width
                                  332
                                  :height
                                  589
                                  :label
                                  "Model Watcher")
                   controls
                   (make-instance 'lispview:panel
                                  :left
                                  0
                                  :top
                                  306
                                  :width
                                  332
                                  :height
                                  218
                                  :parent
                                  watcher-window
                                  :background
                                  (lispview:find-color :name
                                                       :thistle))
                   scale-slider
                   (make-instance 'slider-100-init
                                  :min-value
                                  0
                                  :max-value
                                  300
                                  :gauge-length
                                  100
                                  :show-end-boxes
                                  t
                                  :show-range
                                  t
                                  :show-value
                                  t
                                  :nticks
                                  6
                                  :left
                                  16
                                  :top
                                  12
                                  :width
                                  311
                                  :height
                                  20
                                  :layout
                                  :horizontal
                                  :label
                                  "Scale (%):  "
                                  :parent
                                  controls
                                  :update-value
                                  #'(lambda (value) (do-scale model-watcher)))
                   rotate-slider
                   (make-instance 'lispview:horizontal-slider
                                  :min-value
                                  1
                                  :max-value
                                  25
                                  :gauge-length
                                  100
                                  :show-end-boxes
                                  nil
                                  :show-range
                                  t
                                  :show-value
                                  t
                                  :nticks
                                  25
                                  :left
                                  16
                                  :top
                                  40
                                  :width
                                  286
                                  :height
                                  20
                                  :layout
                                  :horizontal
                                  :label
                                  "Rotate (%):"
                                  :parent
                                  controls)
                   rotation-axes
                   (make-instance 'lispview:non-exclusive-setting
                                  :choices-nrows
                                  1
                                  :choices
                                  (list "X" "Y" "Z")
                                  :left
                                  20
                                  :top
                                  80
                                  :width
                                  96
                                  :height
                                  40
                                  :layout
                                  :vertical
                                  :label
                                  "Rotation axes:"
                                  :parent
                                  controls)
                   rotation-count
                   (make-instance 'lispview:numeric-field
                                  :displayed-value-length
                                  3
                                  :stored-value-length
                                  3
                                  :min-value
                                  1
                                  :max-value
                                  999
                                  :left
                                  152
                                  :top
                                  88
                                  :width
                                  77
                                  :height
                                  32
                                  :layout
                                  :vertical
                                  :label
                                  "Rotations:  "
                                  :parent
                                  controls)
                   rotate-button
                   (make-instance 'lispview:command-button
                                  :command
                                  #'(lambda nil (do-rotate model-watcher))
                                  :left
                                  264
                                  :top
                                  96
                                  :width
                                  54
                                  :height
                                  19
                                  :label
                                  "rotate"
                                  :parent
                                  controls)
                   axistheta
                   (make-instance 'lispview:horizontal-slider
                                  :min-value
                                  0
                                  :max-value
                                  360
                                  :gauge-length
                                  100
                                  :show-end-boxes
                                  nil
                                  :show-range
                                  t
                                  :show-value
                                  t
                                  :nticks
                                  12
                                  :left
                                  24
                                  :top
                                  148
                                  :width
                                  293
                                  :height
                                  20
                                  :layout
                                  :horizontal
                                  :label
                                  "axis theta:"
                                  :parent
                                  controls)
                   axisphi
                   (make-instance 'lispview:horizontal-slider
                                  :min-value
                                  0
                                  :max-value
                                  180
                                  :gauge-length
                                  100
                                  :show-end-boxes
                                  nil
                                  :show-range
                                  t
                                  :show-value
                                  t
                                  :nticks
                                  6
                                  :left
                                  24
                                  :top
                                  176
                                  :width
                                  281
                                  :height
                                  20
                                  :layout
                                  :horizontal
                                  :label
                                  "axis phi:"
                                  :parent
                                  controls)
                   controls1
                   (make-instance 'lispview:panel
                                  :left
                                  0
                                  :top
                                  525
                                  :width
                                  332
                                  :height
                                  64
                                  :parent
                                  watcher-window
                                  :background
                                  (lispview:find-color :name
                                                       :mediumturquoise))
                   truncate-button
                   (make-instance 'lispview:command-button
                                  :command
                                  #'(lambda nil (do-truncation model-watcher))
                                  :left
                                  248
                                  :top
                                  8
                                  :width
                                  72
                                  :height
                                  19
                                  :label
                                  "Truncate"
                                  :parent
                                  controls1)
                   platonic-button
                   (make-instance 'lispview:command-button
                                  :command
                                  #'(lambda nil (do-platonic model-watcher))
                                  :left
                                  164
                                  :top
                                  12
                                  :width
                                  67
                                  :height
                                  19
                                  :label
                                  "Platonic"
                                  :parent
                                  controls1)
                   platonic-setting
                   (make-instance 'lispview:abbreviated-exclusive-setting
                                  :choices-nrows
                                  1
                                  :choices
                                  (list "Tetrahedron"
                                        "Hexahedron"
                                        "Octahedron"
                                        "Dodecahedron"
                                        "Icosahedron")
                                  :left
                                  8
                                  :top
                                  20
                                  :width
                                  123
                                  :height
                                  40
                                  :layout
                                  :vertical
                                  :label
                                  "Platonic choice:"
                                  :parent
                                  controls1)
                   dual-button
                   (make-instance 'lispview:command-button
                                  :command
                                  #'(lambda nil (do-dual model-watcher))
                                  :left
                                  244
                                  :top
                                  40
                                  :width
                                  80
                                  :height
                                  19
                                  :label
                                  "Form dual"
                                  :parent
                                  controls1))
             (setf (lispview:mapped watcher-window)
                   t)))