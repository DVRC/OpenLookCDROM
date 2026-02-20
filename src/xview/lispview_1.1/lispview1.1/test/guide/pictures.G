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
	:menu-item-labels       ("16.icon" "32.icon" "48.icon" "64.icon" )
	:menu-item-label-types  (:glyph :glyph :glyph :glyph )
	:menu-item-defaults     (nil nil nil nil )
	:menu-item-handlers     (nil nil nil nil )
	:menu-item-menus        (nil nil nil nil )
	:menu-item-colors       ("" "" "" "" )
	:pinnable               nil
	:user-data              ()
)
(
	:type                   :base-window
	:name                   window1
	:owner                  nil
	:width                  894
	:height                 656
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
	:type                   :control-area
	:name                   controls1
	:owner                  window1
	:help                   ""
	:x                      0
	:y                      0
	:width                  894
	:height                 656
	:background-color       ""
	:foreground-color       ""
	:show-border            nil
	:menu                   nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :message
	:name                   message3
	:owner                  controls1
	:help                   ""
	:x                      36
	:y                      16
	:width                  531
	:height                 13
	:foreground-color       ""
	:label                  "message, button, menu-button, setting, slider, gauge, text, numeric, scroll list"
	:label-type             :string
	:label-bold             t
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :message
	:name                   message2
	:owner                  controls1
	:help                   ""
	:x                      40
	:y                      52
	:width                  32
	:height                 32
	:foreground-color       ""
	:label                  "r.icon"
	:label-type             :glyph
	:label-bold             t
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   button2
	:owner                  controls1
	:help                   ""
	:x                      168
	:y                      56
	:constant-width         nil
	:button-type            :normal
	:width                  74
	:height                 74
	:foreground-color       ""
	:label                  "64.icon"
	:label-type             :glyph
	:menu                   nil
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :setting
	:name                   setting5
	:owner                  controls1
	:help                   ""
	:x                      440
	:y                      56
	:width                  418
	:height                 74
	:value-x                554
	:value-y                56
	:layout-type            :horizontal
	:foreground-color       ""
	:setting-type           :check
	:rows                   1
	:columns                0
	:label                  "Image choices: "
	:label-type             :string
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:choices                ("16.icon" "32.icon" "48.icon" "64.icon" )
	:choice-label-types     (:glyph :glyph :glyph :glyph )
	:choice-colors          ("" "" "" "" )
	:user-data              ()
)
(
	:type                   :button
	:name                   button1
	:owner                  controls1
	:help                   ""
	:x                      300
	:y                      68
	:constant-width         nil
	:button-type            :normal
	:width                  56
	:height                 42
	:foreground-color       ""
	:label                  "r.icon"
	:label-type             :glyph
	:menu                   menu1
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :setting
	:name                   setting6
	:owner                  controls1
	:help                   ""
	:x                      668
	:y                      144
	:width                  211
	:height                 74
	:value-x                782
	:value-y                144
	:layout-type            :horizontal
	:foreground-color       ""
	:setting-type           :stack
	:rows                   1
	:columns                0
	:label                  "Image choices: "
	:label-type             :string
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:choices                ("16.icon" "32.icon" "48.icon" "64.icon" )
	:choice-label-types     (:glyph :glyph :glyph :glyph )
	:choice-colors          ("" "" "" "" )
	:user-data              ()
)
(
	:type                   :setting
	:name                   setting3
	:owner                  controls1
	:help                   ""
	:x                      340
	:y                      148
	:width                  313
	:height                 74
	:value-x                454
	:value-y                148
	:layout-type            :horizontal
	:foreground-color       ""
	:setting-type           :exclusive
	:rows                   1
	:columns                0
	:label                  "Image choices: "
	:label-type             :string
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:choices                ("16.icon" "32.icon" "48.icon" "64.icon" )
	:choice-label-types     (:glyph :glyph :glyph :glyph )
	:choice-colors          ("" "" "" "" )
	:user-data              ()
)
(
	:type                   :setting
	:name                   setting1
	:owner                  controls1
	:help                   ""
	:x                      244
	:y                      152
	:width                  35
	:height                 59
	:value-x                244
	:value-y                220
	:layout-type            :vertical
	:foreground-color       ""
	:setting-type           :exclusive
	:rows                   1
	:columns                0
	:label                  "r.icon"
	:label-type             :glyph
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:choices                ("foo" )
	:choice-label-types     (:string )
	:choice-colors          ("" )
	:user-data              ()
)
(
	:type                   :setting
	:name                   setting2
	:owner                  controls1
	:help                   ""
	:x                      40
	:y                      160
	:width                  133
	:height                 32
	:value-x                112
	:value-y                160
	:layout-type            :horizontal
	:foreground-color       ""
	:setting-type           :exclusive
	:rows                   1
	:columns                0
	:label                  "r.icon"
	:label-type             :glyph
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:choices                ("green" "blue" )
	:choice-label-types     (:string :string )
	:choice-colors          ("" "" )
	:user-data              ()
)
(
	:type                   :gauge
	:name                   gauge2
	:owner                  controls1
	:help                   ""
	:x                      716
	:y                      224
	:width                  35
	:height                 152
	:value-x                716
	:value-y                292
	:slider-width           100
	:foreground-color       ""
	:label                  "r.icon"
	:label-type             :glyph
	:layout-type            :vertical
	:orientation            :vertical
	:show-range             t
	:min-value              0
	:max-value              100
	:ticks                  0
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :slider
	:name                   slider3
	:owner                  controls1
	:help                   ""
	:x                      32
	:y                      264
	:width                  186
	:height                 32
	:value-x                32
	:value-y                332
	:slider-width           50
	:foreground-color       ""
	:label                  "r.icon"
	:label-type             :glyph
	:layout-type            :vertical
	:orientation            :horizontal
	:show-endboxes          nil
	:show-range             t
	:show-value             t
	:min-value              0
	:max-value              100
	:ticks                  0
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :slider
	:name                   slider1
	:owner                  controls1
	:help                   ""
	:x                      236
	:y                      264
	:width                  186
	:height                 32
	:value-x                308
	:value-y                264
	:slider-width           50
	:foreground-color       ""
	:label                  "r.icon"
	:label-type             :glyph
	:layout-type            :horizontal
	:orientation            :horizontal
	:show-endboxes          nil
	:show-range             t
	:show-value             t
	:min-value              0
	:max-value              100
	:ticks                  0
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :gauge
	:name                   gauge1
	:owner                  controls1
	:help                   ""
	:x                      536
	:y                      276
	:width                  75
	:height                 116
	:value-x                608
	:value-y                276
	:slider-width           100
	:foreground-color       ""
	:label                  "r.icon"
	:label-type             :glyph
	:layout-type            :horizontal
	:orientation            :vertical
	:show-range             t
	:min-value              0
	:max-value              100
	:ticks                  0
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :text-field
	:name                   textfield4
	:owner                  controls1
	:help                   ""
	:x                      328
	:y                      328
	:width                  139
	:height                 32
	:foreground-color       ""
	:text-type              :numeric
	:label                  "r.icon"
	:label-type             :glyph
	:value-x                400
	:value-y                328
	:layout-type            :horizontal
	:value-length           8
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
	:type                   :text-field
	:name                   textfield2
	:owner                  controls1
	:help                   ""
	:x                      220
	:y                      376
	:width                  64
	:height                 51
	:foreground-color       ""
	:text-type              :alphanumeric
	:label                  "r.icon"
	:label-type             :glyph
	:value-x                220
	:value-y                444
	:layout-type            :vertical
	:value-length           8
	:stored-length          80
	:read-only              nil
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :text-field
	:name                   textfield1
	:owner                  controls1
	:help                   ""
	:x                      51
	:y                      400
	:width                  104
	:height                 32
	:foreground-color       ""
	:text-type              :alphanumeric
	:label                  "r.icon"
	:label-type             :glyph
	:value-x                123
	:value-y                400
	:layout-type            :horizontal
	:value-length           8
	:stored-length          80
	:read-only              nil
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :text-field
	:name                   textfield3
	:owner                  controls1
	:help                   ""
	:x                      392
	:y                      416
	:width                  99
	:height                 51
	:foreground-color       ""
	:text-type              :numeric
	:label                  "r.icon"
	:label-type             :glyph
	:value-x                392
	:value-y                484
	:layout-type            :vertical
	:value-length           8
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
	:type                   :scrolling-list
	:name                   list1
	:owner                  controls1
	:help                   ""
	:x                      51
	:y                      472
	:width                  200
	:height                 74
	:foreground-color       ""
	:label                  "r.icon"
	:label-type             :glyph
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
	:type                   :scrolling-list
	:name                   list2
	:owner                  controls1
	:help                   ""
	:x                      560
	:y                      484
	:width                  200
	:height                 110
	:foreground-color       ""
	:label                  "r.icon"
	:label-type             :glyph
	:layout-type            :vertical
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
	:name                   setting4
	:owner                  controls1
	:help                   ""
	:x                      32
	:y                      564
	:width                  346
	:height                 74
	:value-x                146
	:value-y                564
	:layout-type            :horizontal
	:foreground-color       ""
	:setting-type           :nonexclusive
	:rows                   1
	:columns                0
	:label                  "Image choices: "
	:label-type             :string
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:choices                ("16.icon" "32.icon" "48.icon" "64.icon" )
	:choice-label-types     (:glyph :glyph :glyph :glyph )
	:choice-colors          ("" "" "" "" )
	:user-data              ()
)
)
