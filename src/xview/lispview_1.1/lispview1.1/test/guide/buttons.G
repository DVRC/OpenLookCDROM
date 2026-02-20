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
	:menu-item-labels       ("Item" )
	:menu-item-label-types  (:string )
	:menu-item-defaults     (nil )
	:menu-item-handlers     (nil )
	:menu-item-menus        (nil )
	:menu-item-colors       ("" )
	:pinnable               t
	:user-data              ()
)
(
	:type                   :base-window
	:name                   window1
	:owner                  nil
	:width                  182
	:height                 210
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
	:owner                  window1
	:help                   ""
	:x                      0
	:y                      0
	:width                  182
	:height                 210
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
	:x                      32
	:y                      20
	:constant-width         nil
	:button-type            :normal
	:width                  58
	:height                 19
	:foreground-color       ""
	:label                  "Button"
	:label-type             :string
	:menu                   nil
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
	:x                      32
	:y                      64
	:constant-width         t
	:button-type            :normal
	:width                  100
	:height                 19
	:foreground-color       ""
	:label                  "Button"
	:label-type             :string
	:menu                   nil
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
	:x                      32
	:y                      116
	:constant-width         t
	:button-type            :normal
	:width                  100
	:height                 19
	:foreground-color       ""
	:label                  "Button"
	:label-type             :string
	:menu                   menu1
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   button4
	:owner                  controls1
	:help                   ""
	:x                      32
	:y                      164
	:constant-width         nil
	:button-type            :normal
	:width                  72
	:height                 19
	:foreground-color       ""
	:label                  "Button"
	:label-type             :string
	:menu                   menu1
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
)
