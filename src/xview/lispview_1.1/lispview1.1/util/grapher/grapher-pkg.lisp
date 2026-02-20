;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;;  File: grapher-pkg.lisp
;;;;
;;;;  Author: Philip McBride
;;;;
;;;;  This file contains the defpackage form for the lispview grapher.
;;;;
;;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;;	See LEGAL_NOTICE file for terms of the license.
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package :grapher :nicknames '(:gr))
(in-package 'user)

(defpackage :grapher
  (:nicknames :gr)
  (:use :lispview)
  (:use :clos)
  (:use :lcl :lisp)
  (:shadow lispview:display lispview:label lispview:children lispview:depth 
	   lispview:name lispview:canvas lispview:layout lispview:label-width
	   lispview:font-height)
  (:import-from :clos validate-superclass class-prototype 
		class-default-initargs)
  ;; classes
  (:export graph-object node string-node image-node plain-str-node
	   italic-str-node bold-str-node grapher-gc node-gc image-node-gc
	   string-node-gc plain-str-gc bold-str-gc italic-str-gc arc-gc 
	   italicbold-str-gc arc-gc solid-arc-gc bold-arc-gc
	   dashed-arc-gc geometry straight-line-geo arc relation
	   children children-arc relation-meta ftc-relation-meta
	   ltc-relation-meta btc-relation-meta transitive-closure
	   full-t-c lazy-t-c background-t-c ftc-relation-meta
	   ltc-relation-meta btc-relation-meta abstract-graph graph
	   subgraph graph-layout left-right-layout bottom-top-layout 
	   right-left-layout top-bottom-layout horizontal-layout
	   vertical-layout side-layout centered-layout
	   centered-horizontal-layout centered-vertical-layout
	   standard-lr-graph standard-rl-graph standard-tb-graph
	   standard-bt-graph graph-base-window graph-viewport
	   dummy-mouse-interest select-mouse-interest menu-mouse-interest
	   move-mouse-interest graph-tool grapher-library-tool
	   graph-window-mixin graph-base-window-mixin)
  ;; class accessors
  (:export object label userfield region selected layout-p display-p
	   toarcs fromarcs x y depth-set breadth-set root buffers base
	   width height depth border depth-limit expand-continuation
	   collapse diplicates is-duplicated-by fromnode tonode from-x
	   from-y to-x to-y roots nonroots allnodes rootnodes
	   nonrootnodes leafnodes arcs arcregions noderegions nodelabels
	   relations expand-depth sweeping moving graph-menu
	   node-menu panel-menu buffer root-depth graph-width graph-height
	   view-height view-width output-height output-width 
	   ancestor-spacing sibling-spacing top-graph-class 
	   bottom-graph-class top-graph bottom-graph left-graph-class
	   right-graph-class left-graph right-graph name selections
	   canvas bw graph-buffer menu-node tool viewers current-viewer
	   current-buffer graph-damage centered-graph-view ancestor-graph-view
	   descendant-graph-view checkcycles cycle-duplication gcount 
	   gancestors cross-link back-link label-width label-height g-c)
  ;; supporting methods
  (:export display layout relayout get-range-objects make-node make-subgraphs
	   make-graph-menus make-graph-window region-to-node region-to-arc
	   associated-graph highlight unhighlight nodeselect sweep move
	   move-node move-adjacent find-node add-buffer grapher-init
	   ancestors descendants node-siblings node-subtree node-supertree
	   collapse-node expand remove-buffer run-expand-continuation
	   run-expand-subgraph graph-roots graph-leaves add-descendant 
	   remove-descendant link-nodes add-arc add-node remove-node 
	   make-depth-label unmake-depth-label change-label make-arc 
	   object-equal push-graph-window text center-graph-window
	   select-mouse-event menu-mouse-event move-mouse-event next-buffer
	   previous-buffer cleanup-destroyed-base make-new-graph-tool
	   destroy-graph-tool change-depth-level push-buffer remove-arc
	   back-link? unlink-nodes add-ancestors update-ancestors
	   ungroup make-buffer node-inclusion arc-inclusion display-label
	   get-depth-label get-graph-depth-label display-arc display-back-arc
	   display-border make-new-tool-window setup-interests update-gr-output
	   object-to-edit object-to-inspect scroll-to-node)
  ;; vars
  (:export *grapher-boldfont* *grapher-normalfont* *grapher-italicboldfont*
	   *grapher-italicfont* *image-node-gc* *plain-str-gc* *bold-str-gc*
	   *italic-str-gc* *italicbold-str-gc* *solid-arc-gc* *bold-arc-gc*
	   *doublebold-arc-gc* *dashed-arc-gc* *bolddashed-arc-gc*
	   *graph-tool* *grapher-icon-image* *damage-interest* 
	   *select-mouse-interest* *menu-mouse-interest* *dummy-mouse-interest*
	   *move-mouse-interest*))

;; package used for graph tools functions
(defpackage :grapher-tool
  (:nicknames :gt)
  (:use :grapher)
  (:use :lispview)
  (:use :clos)
  (:use :lcl :lisp)
  (:shadow lispview:label lispview:children lispview:depth 
	   lispview:name lispview:layout lispview:label-width
	   lispview:font-height) ; lispview:display  lispview:canvas
  (:shadowing-import-from :grapher display canvas)
  (:shadow gr::get-current-buffer gr::current-graph gr::get-selections
	   gr::graph-relayout-fn gr::graph-redisplay-fn gr::get-node-fn
	   gr::node-select-fn gr::node-select-a-fn gr::node-select-s-fn
	   gr::node-select-d-fn gr::select-all-fn gr::node-relayout-fn
	   gr::node-collapse-fn gr::node-collapse-a-fn
	   gr::node-collapse-s-fn gr::node-collapse-se-fn gr::node-depth-fn
	   gr::graph-depth-fn gr::aerial-scroll-fn gr::inspect-fn
	   gr::edit-fn gr::node-expand-all-fn gr::graph-expand-all-fn
	   gr::node-expand-n-fn gr::noop-fn gr::previous-buffer-fn 
	   gr::next-buffer-fn gr::upward-branch gr::downward-branch
	   gr::both-branch gr::node-expand-fn)
  ;; tool interface classes and methods
  (:export grapher-tool-base-window grapher-tool-tool grapher-tool-scrolling-window
	   grapher-tool-scrolling-window-viewport make-new-grapher-tool
	   make-grapher-tool-scrolling-window make-grapher-tool-window
	   cleanup-destroyed-base-from-tool)
  ;; tool menu methods
  (:export get-current-buffer current-graph get-selections graph-relayout-fn
	   graph-redisplay-fn get-node-fn node-select-fn node-select-a-fn
	   node-select-s-fn node-select-d-fn select-all-fn node-relayout-fn
	   node-collapse-fn node-collapse-a-fn node-collapse-s-fn
	   node-collapse-se-fn node-depth-fn graph-depth-fn aerial-scroll-fn
	   inspect-fn edit-fn node-expand-all-fn node-expand-n-fn noop-fn
	   previous-buffer-fn next-buffer-fn upward-branch downward-branch
	   both-branch node-expand-fn graph-expand-all-fn))
