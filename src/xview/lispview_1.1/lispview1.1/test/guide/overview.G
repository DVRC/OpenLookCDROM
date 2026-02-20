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
	:pinnable               nil
	:user-data              ()
)
(
	:type                   :base-window
	:name                   window1
	:owner                  nil
	:width                  543
	:height                 392
	:background-color       ""
	:foreground-color       ""
	:label                  "Editor Tool"
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
	:width                  543
	:height                 28
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
	:name                   button3
	:owner                  controls1
	:help                   ""
	:x                      4
	:y                      4
	:constant-width         nil
	:button-type            :normal
	:width                  54
	:height                 19
	:foreground-color       ""
	:label                  "FIle"
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
	:x                      64
	:y                      4
	:constant-width         nil
	:button-type            :normal
	:width                  62
	:height                 19
	:foreground-color       ""
	:label                  "View"
	:label-type             :string
	:menu                   menu1
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   button5
	:owner                  controls1
	:help                   ""
	:x                      132
	:y                      4
	:constant-width         nil
	:button-type            :normal
	:width                  56
	:height                 19
	:foreground-color       ""
	:label                  "Edit"
	:label-type             :string
	:menu                   menu1
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   button6
	:owner                  controls1
	:help                   ""
	:x                      208
	:y                      4
	:constant-width         nil
	:button-type            :normal
	:width                  61
	:height                 19
	:foreground-color       ""
	:label                  "Props..."
	:label-type             :string
	:menu                   nil
	:notify-handler         "(setf (lv:mapped popup1) t)"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :popup-window
	:name                   popup1
	:owner                  window1
	:width                  495
	:height                 320
	:background-color       ""
	:foreground-color       ""
	:label                  "Editor:  Properties"
	:label-type             :string
	:mapped                 t
	:show-footer            nil
	:resizable              nil
	:pinned                 nil
	:done-handler           nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :control-area
	:name                   controls2
	:owner                  popup1
	:help                   ""
	:x                      0
	:y                      0
	:width                  495
	:height                 320
	:background-color       ""
	:foreground-color       ""
	:show-border            nil
	:menu                   nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :scrolling-list
	:name                   list1
	:owner                  controls2
	:help                   ""
	:x                      62
	:y                      12
	:width                  200
	:height                 74
	:foreground-color       ""
	:label                  "Style Name:"
	:label-type             :string
	:layout-type            :horizontal
	:rows                   3
	:read-only              nil
	:multiple-selections    nil
	:selection-required     nil
	:menu                   nil
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :setting
	:name                   setting2
	:owner                  controls2
	:help                   ""
	:x                      111
	:y                      92
	:width                  137
	:height                 23
	:value-x                152
	:value-y                92
	:layout-type            :horizontal
	:foreground-color       ""
	:setting-type           :stack
	:rows                   1
	:columns                0
	:label                  "Font:"
	:label-type             :string
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:choices                ("Helvetica" "Italic" "Underline" )
	:choice-label-types     (:string :string :string )
	:choice-colors          ("" "" "" )
	:user-data              ()
)
(
	:type                   :setting
	:name                   setting3
	:owner                  controls2
	:help                   ""
	:x                      74
	:y                      116
	:width                  170
	:height                 23
	:value-x                152
	:value-y                116
	:layout-type            :horizontal
	:foreground-color       ""
	:setting-type           :stack
	:rows                   1
	:columns                0
	:label                  "Body Text:"
	:label-type             :string
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:choices                ("12  point" "Clos" "Lisp" )
	:choice-label-types     (:string :string :string )
	:choice-colors          ("" "" "" )
	:user-data              ()
)
(
	:type                   :setting
	:name                   setting1
	:owner                  controls2
	:help                   ""
	:x                      60
	:y                      142
	:width                  192
	:height                 23
	:value-x                152
	:value-y                142
	:layout-type            :horizontal
	:foreground-color       ""
	:setting-type           :exclusive
	:rows                   1
	:columns                0
	:label                  "Determined:"
	:label-type             :string
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:choices                ("Automatically" )
	:choice-label-types     (:string )
	:choice-colors          ("" )
	:user-data              ()
)
(
	:type                   :setting
	:name                   setting5
	:owner                  controls2
	:help                   ""
	:x                      277
	:y                      142
	:width                  186
	:height                 23
	:value-x                348
	:value-y                142
	:layout-type            :horizontal
	:foreground-color       ""
	:setting-type           :exclusive
	:rows                   1
	:columns                0
	:label                  "Based on"
	:label-type             :string
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:choices                ("Indents" "Codes" )
	:choice-label-types     (:string :string )
	:choice-colors          ("" "" )
	:user-data              ()
)
(
	:type                   :message
	:name                   message4
	:owner                  controls2
	:help                   ""
	:x                      151
	:y                      177
	:width                  100
	:height                 13
	:foreground-color       ""
	:label                  "Body Size Plus"
	:label-type             :string
	:label-bold             t
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :setting
	:name                   setting4
	:owner                  controls2
	:help                   ""
	:x                      277
	:y                      177
	:width                  38
	:height                 98
	:value-x                277
	:value-y                194
	:layout-type            :vertical
	:foreground-color       ""
	:setting-type           :check
	:rows                   0
	:columns                1
	:label                  "Bold:"
	:label-type             :string
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:choices                (" " " " " " )
	:choice-label-types     (:string :string :string )
	:choice-colors          ("" "" "" )
	:user-data              ()
)
(
	:type                   :setting
	:name                   setting6
	:owner                  controls2
	:help                   ""
	:x                      325
	:y                      177
	:width                  39
	:height                 98
	:value-x                325
	:value-y                194
	:layout-type            :vertical
	:foreground-color       ""
	:setting-type           :check
	:rows                   0
	:columns                1
	:label                  "Italic:"
	:label-type             :string
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:choices                (" " " " " " )
	:choice-label-types     (:string :string :string )
	:choice-colors          ("" "" "" )
	:user-data              ()
)
(
	:type                   :text-field
	:name                   textfield1
	:owner                  controls2
	:help                   ""
	:x                      71
	:y                      200
	:width                  154
	:height                 15
	:foreground-color       ""
	:text-type              :numeric
	:label                  "Level One:"
	:label-type             :string
	:value-x                152
	:value-y                200
	:layout-type            :horizontal
	:value-length           4
	:stored-length          80
	:max-value              100
	:min-value              0
	:read-only              nil
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :message
	:name                   message1
	:owner                  controls2
	:help                   ""
	:x                      229
	:y                      200
	:width                  38
	:height                 13
	:foreground-color       ""
	:label                  "points"
	:label-type             :string
	:label-bold             nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :text-field
	:name                   textfield2
	:owner                  controls2
	:help                   ""
	:x                      112
	:y                      228
	:width                  113
	:height                 15
	:foreground-color       ""
	:text-type              :numeric
	:label                  "Two:"
	:label-type             :string
	:value-x                152
	:value-y                228
	:layout-type            :horizontal
	:value-length           4
	:stored-length          80
	:max-value              100
	:min-value              0
	:read-only              nil
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :message
	:name                   message2
	:owner                  controls2
	:help                   ""
	:x                      229
	:y                      228
	:width                  38
	:height                 13
	:foreground-color       ""
	:label                  "points"
	:label-type             :string
	:label-bold             nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :text-field
	:name                   textfield3
	:owner                  controls2
	:help                   ""
	:x                      100
	:y                      256
	:width                  125
	:height                 15
	:foreground-color       ""
	:text-type              :numeric
	:label                  "Three:"
	:label-type             :string
	:value-x                152
	:value-y                256
	:layout-type            :horizontal
	:value-length           4
	:stored-length          80
	:max-value              100
	:min-value              0
	:read-only              nil
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :message
	:name                   message3
	:owner                  controls2
	:help                   ""
	:x                      229
	:y                      256
	:width                  38
	:height                 13
	:foreground-color       ""
	:label                  "points"
	:label-type             :string
	:label-bold             nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   button1
	:owner                  controls2
	:help                   ""
	:x                      184
	:y                      288
	:constant-width         nil
	:button-type            :normal
	:width                  53
	:height                 19
	:foreground-color       ""
	:label                  "Apply"
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
	:owner                  controls2
	:help                   ""
	:x                      252
	:y                      288
	:constant-width         nil
	:button-type            :normal
	:width                  65
	:height                 19
	:foreground-color       ""
	:label                  "Reset"
	:label-type             :string
	:menu                   menu1
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
)
