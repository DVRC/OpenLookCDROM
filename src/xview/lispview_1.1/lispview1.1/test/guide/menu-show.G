;GIL-2
(
(
	:type                   :menu
	:name                   panel-menu
	:help                   ""
	:columns                1
	:label                  ""
	:label-type             :string
	:menu-type              :command
	:menu-handler           nil
	:menu-title             ""
	:menu-item-labels       ("panel" "Item" )
	:menu-item-label-types  (:string :string )
	:menu-item-defaults     (nil nil )
	:menu-item-handlers     (nil nil )
	:menu-item-menus        (nil nil )
	:menu-item-colors       ("" "" )
	:pinnable               t
	:user-data              ()
)
(
	:type                   :menu
	:name                   canvas-menu
	:help                   ""
	:columns                1
	:label                  ""
	:label-type             :string
	:menu-type              :command
	:menu-handler           nil
	:menu-title             ""
	:menu-item-labels       ("canvas" "Item" )
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
	:width                  200
	:height                 128
	:background-color       ""
	:foreground-color       ""
	:label                  "Menu Show Test"
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
	:owner                  window1
	:help                   ""
	:x                      0
	:y                      0
	:width                  200
	:height                 60
	:background-color       ""
	:foreground-color       ""
	:show-border            nil
	:menu                   panel-menu
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
	:y                      57
	:width                  200
	:height                 71
	:background-color       ""
	:foreground-color       ""
	:menu                   canvas-menu
	:horizontal-scrollbar   nil
	:scrollable-width       200
	:vertical-scrollbar     nil
	:scrollable-height      71
	:repaint-proc           nil
	:event-handler          nil
	:events                 ()
	:drawing-model          :xview
	:user-data              ()
)
)
