;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;@(#)package.lisp	3.34 10/11/91


;;; This file defines the Solo and LispView (nickname LV) packages without creating
;;; symbols in any existing packages.

(LISP:in-package (gensym))

(LCL:defpackage LISPVIEW
  (:use lisp clos xview)
  (:nicknames lv solo)

  #+lucid
  (:IMPORT-FROM foreign-function-interface

   def-foreign-function
   def-foreign-callable
   def-foreign-struct
   def-foreign-synonym-type
   defined-foreign-type-p
   foreign-aref
   typed-foreign-aref
   foreign-string-value
   foreign-pointer-address
   foreign-pointer
   foreign-pointer-type
   foreign-value
   foreign-typep 
   foreign-size-of
   free-foreign-pointer
   make-foreign-pointer
   malloc-foreign-pointer
   copy-foreign-pointer
   stationary-object-p
   with-static-area
   run-program
   malloc-foreign-string
   maybe-malloc-foreign-string
   free-foreign-string-at
   lookup-callback-address
   foreign-pointer-to-array
   foreign-array-to-pointer
   map-foreign-vector
   make-null-foreign-pointer)


  #+lucid 
  (:IMPORT-FROM multiprocessing 

   process
   *current-process*
   make-process		
   process-plist
   process-allow-schedule
   process-wait
   process-whostate
   process-state
   process-alive-p)


  #+lucid
  (:IMPORT-FROM lucid-common-lisp 

   cd                            ;; utility
   pwd 
   shell 
   quit 
   arglist
   xor
   environment-variable 
   with-interrupts-deferred
   def-compiler-macro

   dynamic-extent                ;; declarations
   arglist 
   type-reduce

   ignore-errors                 ;; error handler
   handler-case
   serious-condition
   define-condition

   using-resource                ;; resource - storage managemnt 
   make-resource
   resource-allocate
   resource-deallocate)

  (:EXPORT
   
   ;; GLOBALS
   
   *lispview-version*
   *default-platform*    
   *default-display*
   default-display
   
   ;; REGION
   
   region           
   region-p 
   make-region 
   copy-region 
   region-min-x 
   region-min-y 
   region-max-x 
   region-max-y
   region-left 
   region-right 
   region-bottom 
   region-top
   region-width 
   region-height
   region-equal
   region-contains-xy-p 
   region-contains-region-p 
   region-bounding-region
   regions-intersect-p 
   region-union 
   region-intersection 
   region-difference
   
   ;; PLATFORM
   
   platform
   xview
   
   ;; EVENT-DISPATCH
   
   event-dispatch
   event-dispatch-process
   event-dispatch-queue
   
   ;; DISPLAY 
   status
   host
   server
   screen
   name
   root-canvas
   backing-store-support
   supported-depths
   display-images
   display-colormaps
   display-cursors
   display-fonts
   graphics-context
   output-buffering
   with-output-buffering
   without-output-buffering
   flush-output-buffer
   property-list
   resolution
   default-colormap

   ;; DISPLAY-DEVICE-STATUS (mixin)
   
   display
   device
   status
   realize
   destroy
   xview-id
   x11-id
   
   ;; VISUAL
   
   visual
   color-visual
   static-visual
   colormap-size         ;; backwards compatibility
   pseudo-color-visual
   gray-scale-visual
   direct-color-visual
   true-color-visual
   static-color-visual
   static-gray-visual
   monochrome-visual
   
   ;; CHARACTER-METRICS
   
   char-metrics
   zero-char-metrics
   char-left-bearing
   char-right-bearing
   char-width
   char-ascent
   char-descent
   
   ;; FONT
   
   font
   font-spec
   property-list
   font-ascent
   font-descent
   font-height
   min-char-code
   max-char-code
   char-metrics
   min-char-metrics
   max-char-metrics
   font-search-path
   available-fonts
   string-width
   
   ;; INTEREST
   
   interest
   revoke-interest
   express-interest
   mouse-interest
   keyboard-interest
   damage-interest
   keyboard-focus-interest
   click-interval
   click-travel

   ;; EVENT
   
   event
   event-object
   event-timestamp
   event-interest
   damage-event
   make-damage-event
   damage-event-regions
   keyboard-event
   make-keyboard-event
   keyboard-event-x
   keyboard-event-y 
   keyboard-event-char
   keyboard-event-keysym
   keyboard-event-action
   keyboard-event-string
   keyboard-event-modifiers
   mouse-event
   make-mouse-event
   mouse-event-x
   mouse-event-y 
   mouse-event-gesture
   keyboard-focus-event
   make-keyboard-focus-event
   keyboard-focus-event-focus
   scroll-event
   scroll-event-scrollbar
   scroll-event-motion
   scroll-event-view-start
   *button-name-synonyms*
   *modifier-name-synonyms*
   
   ;; DRAWABLE
   
   drawable
   
   ;; CURSOR
   cursor
   name
   foreground
   background
   cursor-x-hot
   cursor-y-hot
   cursor-image
   cursor-mask
   
   ;; CANVAS
   
   canvas
   parent
   children
   insert
   withdraw
   expose
   bury
   depth
   bounding-region
   mapped
   bit-gravity  
   backing-store  
   interests
   opaque-canvas
   transparent-canvas
   insert
   widthdraw
   expose
   bury
   
   ;; IMAGE
   
   image
   bounding-region
   depth
   read-image
   image-array

   ;; GRAPHICS-CONTEXT
   
   graphics-context
   boole-constant
   operation
   plane-mask 
   foreground
   background 
   line-width 
   line-style 
   cap-style 
   join-style 
   fill-style 
   fill-rule 
   tile 
   stipple 
   ts-x-origin
   ts-y-origin
   font 
   subwindow-mode 
   graphics-exposures 
   clip-x-origin
   clip-y-origin
   clip-mask 
   dash-offset 
   dashes 
   arc-mode
   with-graphics-context
   
   ;; ROOT-CANVAS
   
   root-canvas
   
   ;; WINDOW
   
   window
   border-width
   
   ;; TOP-LEVEL-WINDOW
   
   top-level-window
   owner
   label
   left-footer
   right-footer
   state
   busy
   closed
   foreground-color
   background-color
   base-window
   icon
   confirm-quit
   popup-window
   help-window
   
   ;; PANEL
   
   panel
   
   ;; INPUT
   
   deliver-event
   receive-event
   send-event
   match-event
   mouse-state
   warp-mouse
   keyboard-focus
   keyboard-focus-mode
   virtual-keyboard-focus
   valid-ipc-function-p 
   valid-ipc-functions
   
   ;; OUTPUT
   
   draw-line 
   draw-lines
   draw-arc
   draw-arcs
   draw-rectangle 
   draw-rectangles
   draw-polygon
   draw-string
   draw-char
   copy-area
   clear
   
   ;; COLOR
   
   color
   undefined-color
   name 
   pixel
   red
   blue
   green
   hue
   saturation
   intensity
   red-component       ;; backwards compatibility
   green-component     ;; ""
   blue-component      ;; ""
   find-color
   colormap
   read-only-colormap
   read-write-colormap 
   decomposed-colormap 
   undecomposed-colormap 
   pseudo-colormap 
   gray-scale-colormap
   direct-colormap
   true-colormap
   static-colormap 
   static-gray-colormap
   monochrome-colormap

   colormap-length
   colormap-colors
   allocated-colors
   supported-colormap-classes
   reserved-colormap-colors
   with-pixel-composition
   compose-pixel


   ;; SCROLLBAR
   
   scrollbar
   scrollbar-client
   scrollbar-menu
   scrollbar-splittable
   horizontal-scrollbar
   vertical-scrollbar
   view-min
   view-max
   view-start
   view-length
   scroll
   update-scrollbar
   update-scrollbar-event
   
   ;; VIEWPORT
   
   viewport
   output-region
   view-region
   container-region
   repaint
   vertical-scrollbar
   horizontal-scrollbar
   compute-view-start
   
   ;; SCROLLING-WINDOW
   
   scrolling-window
   viewports
   viewport
   
   ;; ICON
   
   icon
   
   ;; ITEM
   
   item
   item-state
   item-layout
   display
   device
   status
   bounding-region
   mapped
   parent
   foreground
   background
   state
   layout
   notify
   spot-help

   ;; LABEL
   
   label
   label-width
   
   ;; COMMAND
   
   command
   
   ;; MENU
   
   menu
   choices
   choices-nrows
   choices-ncols
   default
   owner
   pushpin
   dismissed
   menu-show
   menu-item
   command-menu-item
   submenu-item
   spacer-menu-item
   state
   mapped
   notice-prompt
   
   ;; SCROLLING-LIST
   
   scrolling-list
   exclusive-scrolling-list
   non-exclusive-scrolling-list
   choices
   value
   choice-width
   choice-height
   nchoices
   nchoices-visible
   selection-required
   
   ;; SETTING
   
   setting
   exclusive-setting
   non-exclusive-setting
   check-box
   abbreviated-exclusive-setting
   choices
   value 
   value-x
   value-y
   selection-required
   update-value
   choice-label-callback

   ;; NUMERIC RANGE
   
   value
   min-value
   max-value
   
   ;; GAUGE
   
   gauge
   vertical-gauge
   horizontal-gauge
   show-value
   show-range
   nticks
   gauge-length
   
   ;; SLIDER
   
   slider
   horizontal-slider
   vertical-slider
   show-range
   show-value
   update-value
   show-end-boxes
   
   ;; BUTTON
   
   button
   command-button
   menu-button
   
   ;; MESSAGE
   
   message
   
   ;; TEXT-FIELD
   
   text-field
   text-field-notify-level
   value
   read-only
   stored-value-length
   displayed-value-length
   value-underlined
   mask-char
   update-value
   
   ;; NUMERIC-FIELD
   
   numeric-field

   ;; VERSION

   def-lispview-patch
   print-lispview-version))


