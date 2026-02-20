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
	:menu-item-labels       ("foo" "bar" "baz" )
	:menu-item-label-types  (:string :string :string )
	:menu-item-defaults     (nil nil nil )
	:menu-item-handlers     (foo "(print 'bar)" "#'(lambda()(print 'baz))" )
	:menu-item-menus        (nil nil nil )
	:menu-item-colors       ("" "" "" )
	:pinnable               nil
	:user-data              ()
)
(
	:type                   :base-window
	:name                   window1
	:owner                  nil
	:width                  290
	:height                 350
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
	:width                  290
	:height                 350
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
	:y                      4
	:constant-width         nil
	:button-type            :normal
	:width                  63
	:height                 19
	:foreground-color       ""
	:label                  "Default"
	:label-type             :string
	:menu                   nil
	:notify-handler         default
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :setting
	:name                   setting1
	:owner                  controls1
	:help                   ""
	:x                      103
	:y                      7
	:width                  174
	:height                 23
	:value-x                163
	:value-y                7
	:layout-type            :horizontal
	:foreground-color       ""
	:setting-type           :exclusive
	:rows                   1
	:columns                0
	:label                  "Setting:"
	:label-type             :string
	:notify-handler         abe
	:event-handler          nil
	:events                 ()
	:choices                ("Choice" "Choice" )
	:choice-label-types     (:string :string )
	:choice-colors          ("" "" )
	:user-data              ()
)
(
	:type                   :button
	:name                   button2
	:owner                  controls1
	:help                   ""
	:x                      16
	:y                      28
	:constant-width         nil
	:button-type            :normal
	:width                  48
	:height                 19
	:foreground-color       ""
	:label                  "Print"
	:label-type             :string
	:menu                   nil
	:notify-handler         "(print 'hello)"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :setting
	:name                   setting2
	:owner                  controls1
	:help                   ""
	:x                      103
	:y                      39
	:width                  174
	:height                 23
	:value-x                163
	:value-y                39
	:layout-type            :horizontal
	:foreground-color       ""
	:setting-type           :exclusive
	:rows                   1
	:columns                0
	:label                  "Setting:"
	:label-type             :string
	:notify-handler         "(print value)"
	:event-handler          nil
	:events                 ()
	:choices                ("Choice" "Choice" )
	:choice-label-types     (:string :string )
	:choice-colors          ("" "" )
	:user-data              ()
)
(
	:type                   :button
	:name                   button4
	:owner                  controls1
	:help                   ""
	:x                      16
	:y                      52
	:constant-width         nil
	:button-type            :normal
	:width                  66
	:height                 19
	:foreground-color       ""
	:label                  "Lambda"
	:label-type             :string
	:menu                   nil
	:notify-handler         "#'(lambda()(print 'lambda))"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :setting
	:name                   setting3
	:owner                  controls1
	:help                   ""
	:x                      103
	:y                      71
	:width                  174
	:height                 23
	:value-x                163
	:value-y                71
	:layout-type            :horizontal
	:foreground-color       ""
	:setting-type           :exclusive
	:rows                   1
	:columns                0
	:label                  "Setting:"
	:label-type             :string
	:notify-handler         "#'(lambda(v)(print v))"
	:event-handler          nil
	:events                 ()
	:choices                ("Choice" "Choice" )
	:choice-label-types     (:string :string )
	:choice-colors          ("" "" )
	:user-data              ()
)
(
	:type                   :button
	:name                   button3
	:owner                  controls1
	:help                   ""
	:x                      16
	:y                      76
	:constant-width         nil
	:button-type            :normal
	:width                  72
	:height                 19
	:foreground-color       ""
	:label                  "Button"
	:label-type             :string
	:menu                   menu1
	:notify-handler         "#'(lambda()(print 'func))"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :scrolling-list
	:name                   list1
	:owner                  controls1
	:help                   ""
	:x                      24
	:y                      104
	:width                  200
	:height                 74
	:foreground-color       ""
	:label                  ""
	:label-type             :string
	:layout-type            :horizontal
	:rows                   3
	:read-only              nil
	:multiple-selections    nil
	:selection-required     nil
	:menu                   nil
	:notify-handler         zxc
	:event-handler          nil
	:events                 ()
	:user-data              (:default-initargs (:choices '("A" "B")))
)
(
	:type                   :scrolling-list
	:name                   list2
	:owner                  controls1
	:help                   ""
	:x                      24
	:y                      188
	:width                  200
	:height                 74
	:foreground-color       ""
	:label                  ""
	:label-type             :string
	:layout-type            :horizontal
	:rows                   3
	:read-only              nil
	:multiple-selections    nil
	:selection-required     nil
	:menu                   nil
	:notify-handler         "(print (list value operation))"
	:event-handler          nil
	:events                 ()
	:user-data              (:default-initargs (:choices '("A" "B")))
)
(
	:type                   :scrolling-list
	:name                   list3
	:owner                  controls1
	:help                   ""
	:x                      24
	:y                      268
	:width                  200
	:height                 74
	:foreground-color       ""
	:label                  ""
	:label-type             :string
	:layout-type            :horizontal
	:rows                   3
	:read-only              nil
	:multiple-selections    nil
	:selection-required     nil
	:menu                   nil
	:notify-handler         "#'(lambda(v o)(print (list v o)))"
	:event-handler          nil
	:events                 ()
	:user-data              (:default-initargs (:choices '("A" "B")))
)
)
