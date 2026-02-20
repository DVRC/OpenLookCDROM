;GIL-2
(
(
	:type                   :menu
	:name                   menu1
	:help                   ""
	:columns                1
	:label                  ""
	:label-type             :string
	:menu-type              :command
	:menu-handler           nil
	:menu-title             ""
	:menu-item-labels       ("one" "Item" )
	:menu-item-label-types  (:string :string )
	:menu-item-defaults     (nil nil )
	:menu-item-handlers     (nil nil )
	:menu-item-menus        (nil nil )
	:menu-item-colors       ("" "" )
	:pinnable               t
	:user-data              ()
)
(
	:type                   :base-window
	:name                   window1
	:owner                  nil
	:width                  228
	:height                 127
	:background-color       ""
	:foreground-color       ""
	:label                  "Has menu and repaint"
	:label-type             :string
	:mapped                 t
	:show-footer            nil
	:resizable              t
	:icon-file              ""
	:icon-mask-file         ""
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :canvas-pane
	:name                   canvas1
	:owner                  window1
	:help                   ""
	:x                      0
	:y                      0
	:width                  228
	:height                 127
	:background-color       ""
	:foreground-color       ""
	:menu                   menu1
	:horizontal-scrollbar   t
	:scrollable-width       228
	:vertical-scrollbar     nil
	:scrollable-height      127
	:repaint-proc           repaint-win
	:event-handler          nil
	:events                 ()
	:drawing-model          :xview
	:user-data              ()
)
(
	:type                   :base-window
	:name                   window2
	:owner                  nil
	:width                  257
	:height                 135
	:background-color       ""
	:foreground-color       ""
	:label                  "Base Window"
	:label-type             :string
	:mapped                 t
	:show-footer            nil
	:resizable              t
	:icon-file              ""
	:icon-mask-file         ""
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :canvas-pane
	:name                   canvas2
	:owner                  window2
	:help                   ""
	:x                      0
	:y                      0
	:width                  257
	:height                 135
	:background-color       ""
	:foreground-color       ""
	:menu                   nil
	:horizontal-scrollbar   t
	:scrollable-width       257
	:vertical-scrollbar     t
	:scrollable-height      135
	:repaint-proc           nil
	:event-handler          nil
	:events                 ()
	:drawing-model          :xview
	:user-data              ()
)
(
	:type                   :base-window
	:name                   window3
	:owner                  nil
	:width                  132
	:height                 165
	:background-color       ""
	:foreground-color       ""
	:label                  "Base Window"
	:label-type             :string
	:mapped                 t
	:show-footer            nil
	:resizable              t
	:icon-file              ""
	:icon-mask-file         ""
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :canvas-pane
	:name                   canvas3
	:owner                  window3
	:help                   ""
	:x                      0
	:y                      0
	:width                  132
	:height                 165
	:background-color       ""
	:foreground-color       ""
	:menu                   nil
	:horizontal-scrollbar   nil
	:scrollable-width       132
	:vertical-scrollbar     t
	:scrollable-height      165
	:repaint-proc           nil
	:event-handler          nil
	:events                 ()
	:drawing-model          :xview
	:user-data              ()
)
(
	:type                   :base-window
	:name                   window4
	:owner                  nil
	:width                  400
	:height                 150
	:background-color       ""
	:foreground-color       ""
	:label                  "Base Window"
	:label-type             :string
	:mapped                 t
	:show-footer            t
	:resizable              t
	:icon-file              ""
	:icon-mask-file         ""
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :control-area
	:name                   controls1
	:owner                  window4
	:help                   ""
	:x                      0
	:y                      0
	:width                  400
	:height                 48
	:background-color       ""
	:foreground-color       ""
	:show-border            nil
	:menu                   nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :canvas-pane
	:name                   canvas4
	:owner                  window4
	:help                   ""
	:x                      0
	:y                      48
	:width                  400
	:height                 102
	:background-color       ""
	:foreground-color       ""
	:menu                   nil
	:horizontal-scrollbar   t
	:scrollable-width       400
	:vertical-scrollbar     t
	:scrollable-height      102
	:repaint-proc           nil
	:event-handler          nil
	:events                 ()
	:drawing-model          :xview
	:user-data              ()
)
)
