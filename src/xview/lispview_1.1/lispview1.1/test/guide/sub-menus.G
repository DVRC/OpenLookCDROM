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
	:menu-item-labels       ("one" "sub" "three" )
	:menu-item-label-types  (:string :string :string )
	:menu-item-defaults     (nil nil nil )
	:menu-item-handlers     (print-one nil nil )
	:menu-item-menus        (nil menu2 nil )
	:menu-item-colors       ("" "" "" )
	:pinnable               t
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
	:menu-item-labels       ("second" "sub" )
	:menu-item-label-types  (:string :string )
	:menu-item-defaults     (nil nil )
	:menu-item-handlers     (nil nil )
	:menu-item-menus        (nil submenu )
	:menu-item-colors       ("" "" )
	:pinnable               t
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
	:menu-item-labels       ("hello" "sub" )
	:menu-item-label-types  (:string :string )
	:menu-item-defaults     (nil nil )
	:menu-item-handlers     (nil nil )
	:menu-item-menus        (nil menu3 )
	:menu-item-colors       ("" "" )
	:pinnable               t
	:user-data              ()
)
(
	:type                   :menu
	:name                   submenu
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
	:menu-item-handlers     ("(print 'hello)" )
	:menu-item-menus        (nil )
	:menu-item-colors       ("" )
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
	:label                  "Base Window"
	:label-type             :string
	:mapped                 t
	:show-footer            nil
	:resizable              nil
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
	:height                 128
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
	:x                      48
	:y                      32
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
