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
	:menu-title             "A Menu"
	:menu-item-labels       ("Sub Menu" "Press Me" )
	:menu-item-label-types  (:string :string )
	:menu-item-defaults     (nil t )
	:menu-item-handlers     (nil "(progn (lv:clear canvas1)(lv:draw-string canvas1 9 30 \"You made a selection\"))" )
	:menu-item-menus        (menu2 nil )
	:menu-item-colors       ("" "" )
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
	:menu-item-labels       ("pear" "peach" "plum" )
	:menu-item-label-types  (:string :string :string )
	:menu-item-defaults     (nil nil nil )
	:menu-item-handlers     (nil nil nil )
	:menu-item-menus        (nil nil nil )
	:menu-item-colors       ("" "" "" )
	:pinnable               t
	:user-data              ()
)
(
	:type                   :base-window
	:name                   bw
	:owner                  nil
	:width                  705
	:height                 318
	:background-color       ""
	:foreground-color       ""
	:label                  "All Items"
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
	:owner                  bw
	:help                   ""
	:x                      0
	:y                      0
	:width                  705
	:height                 284
	:background-color       ""
	:foreground-color       ""
	:show-border            nil
	:menu                   nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :gauge
	:name                   gauge1
	:owner                  controls1
	:help                   ""
	:x                      18
	:y                      11
	:width                  46
	:height                 133
	:value-x                18
	:value-y                28
	:slider-width           100
	:foreground-color       "Medium Blue"
	:label                  "Gauge:"
	:label-type             :string
	:layout-type            :vertical
	:orientation            :vertical
	:show-range             nil
	:min-value              0
	:max-value              100
	:ticks                  4
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   menu-button
	:owner                  controls1
	:help                   ""
	:x                      98
	:y                      11
	:constant-width         nil
	:button-type            :normal
	:width                  114
	:height                 19
	:foreground-color       ""
	:label                  "Menu-Button"
	:label-type             :string
	:menu                   menu1
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   print-settings
	:owner                  controls1
	:help                   ""
	:x                      226
	:y                      11
	:constant-width         nil
	:button-type            :normal
	:width                  101
	:height                 19
	:foreground-color       ""
	:label                  "Print Settings"
	:label-type             :string
	:menu                   nil
	:notify-handler         "(progn (lv:clear canvas1)(lv:draw-string canvas1 9 30 (format nil \"~TSTACK: ~A~TEXCLUSIVE: ~A~TNON EXCLUSIVE: ~A~TCHECK BOX: ~A\" (lv:value stack )(lv:value eset)(lv:value nes)(lv:value box))))"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :setting
	:name                   eset
	:owner                  controls1
	:help                   ""
	:x                      340
	:y                      11
	:width                  220
	:height                 23
	:value-x                435
	:value-y                11
	:layout-type            :horizontal
	:foreground-color       "Khaki"
	:setting-type           :exclusive
	:rows                   1
	:columns                0
	:label                  "Excl-Setting:"
	:label-type             :string
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:choices                ("one" "two" "three" )
	:choice-label-types     (:string :string :string )
	:choice-colors          ("" "" "" )
	:user-data              ()
)
(
	:type                   :setting
	:name                   nes
	:owner                  controls1
	:help                   ""
	:x                      586
	:y                      11
	:width                  96
	:height                 98
	:value-x                586
	:value-y                28
	:layout-type            :vertical
	:foreground-color       "Steel Blue"
	:setting-type           :nonexclusive
	:rows                   0
	:columns                1
	:label                  "NonExclusive:"
	:label-type             :string
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:choices                ("one" "two" "three" )
	:choice-label-types     (:string :string :string )
	:choice-colors          ("" "" "" )
	:user-data              ()
)
(
	:type                   :slider
	:name                   sl
	:owner                  controls1
	:help                   ""
	:x                      76
	:y                      51
	:width                  214
	:height                 32
	:value-x                76
	:value-y                68
	:slider-width           100
	:foreground-color       "Medium Blue"
	:label                  "Slider:"
	:label-type             :string
	:layout-type            :vertical
	:orientation            :horizontal
	:show-endboxes          nil
	:show-range             t
	:show-value             t
	:min-value              0
	:max-value              100
	:ticks                  0
	:notify-handler         "(setf (lv:left-footer bw) (format nil \"Slider: ~A\" value))"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :text-field
	:name                   tf1
	:owner                  controls1
	:help                   ""
	:x                      339
	:y                      51
	:width                  74
	:height                 32
	:foreground-color       "Indian Red"
	:text-type              :alphanumeric
	:label                  "Text Field: "
	:label-type             :string
	:value-x                339
	:value-y                68
	:layout-type            :vertical
	:value-length           8
	:stored-length          80
	:read-only              nil
	:notify-handler         "(setf (lv:right-footer bw) value)"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :message
	:name                   message1
	:owner                  controls1
	:help                   ""
	:x                      452
	:y                      51
	:width                  61
	:height                 13
	:foreground-color       "Orchid"
	:label                  "Message"
	:label-type             :string
	:label-bold             t
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :text-field
	:name                   tf2
	:owner                  controls1
	:help                   ""
	:x                      73
	:y                      98
	:width                  103
	:height                 32
	:foreground-color       "Indian Red"
	:text-type              :numeric
	:label                  "Numeric Field: "
	:label-type             :string
	:value-x                73
	:value-y                115
	:layout-type            :vertical
	:value-length           8
	:stored-length          80
	:max-value              100
	:min-value              0
	:read-only              nil
	:notify-handler         "(setf (lv:value gauge1) value)"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :setting
	:name                   stack
	:owner                  controls1
	:help                   ""
	:x                      221
	:y                      98
	:width                  68
	:height                 40
	:value-x                221
	:value-y                115
	:layout-type            :vertical
	:foreground-color       "Khaki"
	:setting-type           :stack
	:rows                   0
	:columns                1
	:label                  "Stack:"
	:label-type             :string
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:choices                ("one" "two" "three" )
	:choice-label-types     (:string :string :string )
	:choice-colors          ("" "" "" )
	:user-data              ()
)
(
	:type                   :setting
	:name                   box
	:owner                  controls1
	:help                   ""
	:x                      314
	:y                      98
	:width                  227
	:height                 23
	:value-x                395
	:value-y                98
	:layout-type            :horizontal
	:foreground-color       "Steel Blue"
	:setting-type           :check
	:rows                   1
	:columns                0
	:label                  "Check Box:"
	:label-type             :string
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:choices                ("first" "second" )
	:choice-label-types     (:string :string )
	:choice-colors          ("" "" )
	:user-data              ()
)
(
	:type                   :scrolling-list
	:name                   list1
	:owner                  controls1
	:help                   ""
	:x                      28
	:y                      152
	:width                  200
	:height                 110
	:foreground-color       ""
	:label                  ""
	:label-type             :string
	:layout-type            :horizontal
	:rows                   5
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
	:type                   :button
	:name                   print-values1
	:owner                  controls1
	:help                   ""
	:x                      262
	:y                      152
	:constant-width         nil
	:button-type            :normal
	:width                  92
	:height                 19
	:foreground-color       ""
	:label                  "Print Values"
	:label-type             :string
	:menu                   nil
	:notify-handler         "(progn (lv:clear canvas1)(lv:draw-string canvas1 9 30 (format nil \"Exclusive Scrolling List: ~A\" (lv:value list1))))"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :scrolling-list
	:name                   list2
	:owner                  controls1
	:help                   ""
	:x                      368
	:y                      152
	:width                  200
	:height                 110
	:foreground-color       ""
	:label                  ""
	:label-type             :string
	:layout-type            :horizontal
	:rows                   5
	:read-only              nil
	:multiple-selections    t
	:selection-required     nil
	:menu                   nil
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   print-values2
	:owner                  controls1
	:help                   ""
	:x                      602
	:y                      152
	:constant-width         nil
	:button-type            :normal
	:width                  92
	:height                 19
	:foreground-color       ""
	:label                  "Print Values"
	:label-type             :string
	:menu                   nil
	:notify-handler         "(progn (lv:clear canvas1)(lv:draw-string canvas1 9 30 (format nil \"Non Exclusive Scrolling List: ~A\" (lv:value list2))))"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   set-list1
	:owner                  controls1
	:help                   ""
	:x                      262
	:y                      178
	:constant-width         nil
	:button-type            :normal
	:width                  37
	:height                 19
	:foreground-color       ""
	:label                  "Set"
	:label-type             :string
	:menu                   nil
	:notify-handler         "(setf (lv:choices list1) '(\"a\"  \"b\" \"c\"))"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   set-list2
	:owner                  controls1
	:help                   ""
	:x                      602
	:y                      178
	:constant-width         nil
	:button-type            :normal
	:width                  37
	:height                 19
	:foreground-color       ""
	:label                  "Set"
	:label-type             :string
	:menu                   nil
	:notify-handler         "(setf (lv:choices list2) '(\"one\" \"two\" \"three\"))"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   reset-list1
	:owner                  controls1
	:help                   ""
	:x                      262
	:y                      204
	:constant-width         nil
	:button-type            :normal
	:width                  51
	:height                 19
	:foreground-color       ""
	:label                  "Reset"
	:label-type             :string
	:menu                   nil
	:notify-handler         "(setf (lv:value list1) nil)"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   reset-list2
	:owner                  controls1
	:help                   ""
	:x                      602
	:y                      204
	:constant-width         nil
	:button-type            :normal
	:width                  51
	:height                 19
	:foreground-color       ""
	:label                  "Reset"
	:label-type             :string
	:menu                   nil
	:notify-handler         "(setf (lv:value list2) nil)"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :canvas-pane
	:name                   canvas1
	:owner                  bw
	:help                   ""
	:x                      0
	:y                      278
	:width                  705
	:height                 40
	:background-color       ""
	:foreground-color       ""
	:menu                   nil
	:horizontal-scrollbar   nil
	:scrollable-width       705
	:vertical-scrollbar     nil
	:scrollable-height      40
	:repaint-proc           nil
	:event-handler          nil
	:events                 ()
	:drawing-model          :xview
	:user-data              ()
)
)
