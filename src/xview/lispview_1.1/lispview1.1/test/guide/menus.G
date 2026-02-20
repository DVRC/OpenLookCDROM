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
	:menu-item-labels       ("Vanilla" "Chocolate" "Strawberry" )
	:menu-item-label-types  (:string :string :string )
	:menu-item-defaults     (nil t nil )
	:menu-item-handlers     (nil nil nil )
	:menu-item-menus        (nil nil nil )
	:menu-item-colors       ("" "" "" )
	:pinnable               nil
	:user-data              ()
)
(
	:type                   :menu
	:name                   menu2
	:help                   ""
	:columns                1
	:label                  ""
	:label-type             :string
	:menu-type              :command
	:menu-handler           nil
	:menu-title             ""
	:menu-item-labels       ("first" "sub menu" )
	:menu-item-label-types  (:string :string )
	:menu-item-defaults     (nil nil )
	:menu-item-handlers     (nil nil )
	:menu-item-menus        (nil menu5 )
	:menu-item-colors       ("" "" )
	:pinnable               nil
	:user-data              ()
)
(
	:type                   :menu
	:name                   menu3
	:help                   ""
	:columns                1
	:label                  ""
	:label-type             :string
	:menu-type              :command
	:menu-handler           nil
	:menu-title             ""
	:menu-item-labels       ("r.icon" "48.icon" )
	:menu-item-label-types  (:glyph :glyph )
	:menu-item-defaults     (nil nil )
	:menu-item-handlers     (nil nil )
	:menu-item-menus        (nil nil )
	:menu-item-colors       ("" "" )
	:pinnable               t
	:user-data              ()
)
(
	:type                   :menu
	:name                   menu4
	:help                   ""
	:columns                1
	:label                  ""
	:label-type             :string
	:menu-type              :command
	:menu-handler           nil
	:menu-title             ""
	:menu-item-labels       ("This" "is" "A Popup" )
	:menu-item-label-types  (:string :string :string )
	:menu-item-defaults     (nil nil nil )
	:menu-item-handlers     (nil nil nil )
	:menu-item-menus        (nil nil nil )
	:menu-item-colors       ("" "" "" )
	:pinnable               t
	:user-data              ()
)
(
	:type                   :menu
	:name                   menu5
	:help                   ""
	:columns                1
	:label                  ""
	:label-type             :string
	:menu-type              :command
	:menu-handler           nil
	:menu-title             ""
	:menu-item-labels       ("finally" "this" )
	:menu-item-label-types  (:string :string )
	:menu-item-defaults     (nil nil )
	:menu-item-handlers     (nil "(print 'you-got-this)" )
	:menu-item-menus        (nil nil )
	:menu-item-colors       ("" "" )
	:pinnable               t
	:user-data              ()
)
(
	:type                   :base-window
	:name                   window1
	:owner                  nil
	:width                  243
	:height                 253
	:background-color       ""
	:foreground-color       ""
	:label                  "Menus"
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
	:type                   :control-area
	:name                   controls1
	:owner                  window1
	:help                   ""
	:x                      0
	:y                      0
	:width                  243
	:height                 72
	:background-color       ""
	:foreground-color       ""
	:show-border            nil
	:menu                   nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   button1
	:owner                  controls1
	:help                   ""
	:x                      16
	:y                      16
	:constant-width         nil
	:button-type            :normal
	:width                  63
	:height                 19
	:foreground-color       ""
	:label                  "Plain"
	:label-type             :string
	:menu                   menu1
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   button2
	:owner                  controls1
	:help                   ""
	:x                      88
	:y                      16
	:constant-width         nil
	:button-type            :normal
	:width                  55
	:height                 19
	:foreground-color       ""
	:label                  "Sub"
	:label-type             :string
	:menu                   menu2
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   button3
	:owner                  controls1
	:help                   ""
	:x                      160
	:y                      16
	:constant-width         nil
	:button-type            :normal
	:width                  69
	:height                 19
	:foreground-color       ""
	:label                  "Image"
	:label-type             :string
	:menu                   menu3
	:notify-handler         nil
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
	:y                      72
	:width                  243
	:height                 181
	:background-color       ""
	:foreground-color       ""
	:menu                   menu4
	:horizontal-scrollbar   nil
	:scrollable-width       243
	:vertical-scrollbar     nil
	:scrollable-height      181
	:repaint-proc           nil
	:event-handler          nil
	:events                 ()
	:drawing-model          :xview
	:user-data              ()
)
)
