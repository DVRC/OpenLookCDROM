;GIL-2
(
(
	:type                   :base-window
	:name                   window1
	:owner                  nil
	:width                  400
	:height                 150
	:background-color       ""
	:foreground-color       ""
	:label                  "Drag Events"
	:label-type             :string
	:mapped                 t
	:show-footer            t
	:resizable              t
	:icon-file              ""
	:icon-mask-file         ""
	:event-handler          dragnet
	:events                 (:mouse-drag )
	:user-data              ()
)
(
	:type                   :canvas-pane
	:name                   canvas1
	:owner                  window1
	:help                   ""
	:x                      0
	:y                      93
	:width                  212
	:height                 57
	:background-color       "Cadet Blue"
	:foreground-color       ""
	:menu                   nil
	:horizontal-scrollbar   nil
	:scrollable-width       212
	:vertical-scrollbar     nil
	:scrollable-height      57
	:repaint-proc           nil
	:event-handler          dragnet
	:events                 (:mouse-drag )
	:drawing-model          :xview
	:user-data              ()
)
(
	:type                   :control-area
	:name                   controls1
	:owner                  window1
	:help                   ""
	:x                      212
	:y                      94
	:width                  188
	:height                 56
	:background-color       ""
	:foreground-color       ""
	:show-border            nil
	:menu                   nil
	:event-handler          dragnet
	:events                 (:mouse-drag )
	:user-data              ()
)
)
