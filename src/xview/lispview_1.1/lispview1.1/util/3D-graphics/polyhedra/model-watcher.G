;GIL-2
(
(
	:type                   :base-window
	:name                   watcher-window
	:owner                  nil
	:width                  332
	:height                 589
	:background-color       ""
	:foreground-color       ""
	:label                  "Model Watcher"
	:label-type             :string
	:mapped                 t
	:show-footer            t
	:resizable              t
	:icon-file              ""
	:icon-mask-file         ""
	:event-handler          nil
	:events                 ()
	:user-data              (:class model:watcher-window)
)
(
	:type                   :control-area
	:name                   controls
	:owner                  watcher-window
	:help                   ""
	:x                      0
	:y                      306
	:width                  332
	:height                 218
	:background-color       "Thistle"
	:foreground-color       ""
	:show-border            nil
	:menu                   nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :slider
	:name                   scale-slider
	:owner                  controls
	:help                   ""
	:x                      16
	:y                      12
	:width                  311
	:height                 20
	:value-x                97
	:value-y                12
	:slider-width           100
	:foreground-color       ""
	:label                  "Scale (%):  "
	:label-type             :string
	:layout-type            :horizontal
	:orientation            :horizontal
	:show-endboxes          t
	:show-range             t
	:show-value             t
	:min-value              0
	:max-value              300
	:ticks                  6
	:notify-handler         "(do-scale model-watcher)"
	:event-handler          nil
	:events                 ()
	:user-data              (:class slider-100-init)
)
(
	:type                   :slider
	:name                   rotate-slider
	:owner                  controls
	:help                   ""
	:x                      16
	:y                      40
	:width                  286
	:height                 20
	:value-x                96
	:value-y                40
	:slider-width           100
	:foreground-color       ""
	:label                  "Rotate (%):"
	:label-type             :string
	:layout-type            :horizontal
	:orientation            :horizontal
	:show-endboxes          nil
	:show-range             t
	:show-value             t
	:min-value              1
	:max-value              25
	:ticks                  25
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :setting
	:name                   rotation-axes
	:owner                  controls
	:help                   ""
	:x                      20
	:y                      80
	:width                  96
	:height                 40
	:value-x                20
	:value-y                97
	:layout-type            :vertical
	:foreground-color       ""
	:setting-type           :nonexclusive
	:rows                   1
	:columns                0
	:label                  "Rotation axes:"
	:label-type             :string
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:choices                ("X" "Y" "Z" )
	:choice-label-types     (:string :string :string )
	:choice-colors          ("" "" "" )
	:user-data              ()
)
(
	:type                   :text-field
	:name                   rotation-count
	:owner                  controls
	:help                   ""
	:x                      152
	:y                      88
	:width                  77
	:height                 32
	:foreground-color       ""
	:text-type              :numeric
	:label                  "Rotations:  "
	:label-type             :string
	:value-x                152
	:value-y                105
	:layout-type            :vertical
	:value-length           3
	:stored-length          3
	:max-value              999
	:min-value              1
	:read-only              nil
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   rotate-button
	:owner                  controls
	:help                   ""
	:x                      264
	:y                      96
	:constant-width         nil
	:button-type            :normal
	:width                  54
	:height                 19
	:foreground-color       ""
	:label                  "rotate"
	:label-type             :string
	:menu                   nil
	:notify-handler         "(do-rotate model-watcher)"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :slider
	:name                   axistheta
	:owner                  controls
	:help                   ""
	:x                      24
	:y                      148
	:width                  293
	:height                 20
	:value-x                103
	:value-y                148
	:slider-width           100
	:foreground-color       ""
	:label                  "axis theta:"
	:label-type             :string
	:layout-type            :horizontal
	:orientation            :horizontal
	:show-endboxes          nil
	:show-range             t
	:show-value             t
	:min-value              0
	:max-value              360
	:ticks                  12
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :slider
	:name                   axisphi
	:owner                  controls
	:help                   ""
	:x                      24
	:y                      176
	:width                  281
	:height                 20
	:value-x                91
	:value-y                176
	:slider-width           100
	:foreground-color       ""
	:label                  "axis phi:"
	:label-type             :string
	:layout-type            :horizontal
	:orientation            :horizontal
	:show-endboxes          nil
	:show-range             t
	:show-value             t
	:min-value              0
	:max-value              180
	:ticks                  6
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :control-area
	:name                   controls1
	:owner                  watcher-window
	:help                   ""
	:x                      0
	:y                      525
	:width                  332
	:height                 64
	:background-color       "Medium Turquoise"
	:foreground-color       ""
	:show-border            nil
	:menu                   nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   truncate-button
	:owner                  controls1
	:help                   ""
	:x                      248
	:y                      8
	:constant-width         nil
	:button-type            :normal
	:width                  72
	:height                 19
	:foreground-color       ""
	:label                  "Truncate"
	:label-type             :string
	:menu                   nil
	:notify-handler         "(do-truncation model-watcher)"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   platonic-button
	:owner                  controls1
	:help                   ""
	:x                      164
	:y                      12
	:constant-width         nil
	:button-type            :normal
	:width                  67
	:height                 19
	:foreground-color       ""
	:label                  "Platonic"
	:label-type             :string
	:menu                   nil
	:notify-handler         "(do-platonic model-watcher)"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :setting
	:name                   platonic-setting
	:owner                  controls1
	:help                   ""
	:x                      8
	:y                      20
	:width                  123
	:height                 40
	:value-x                8
	:value-y                37
	:layout-type            :vertical
	:foreground-color       ""
	:setting-type           :stack
	:rows                   1
	:columns                0
	:label                  "Platonic choice:"
	:label-type             :string
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:choices                ("Tetrahedron" "Hexahedron" "Octahedron" "Dodecahedron" "Icosahedron" )
	:choice-label-types     (:string :string :string :string :string )
	:choice-colors          ("" "" "" "" "" )
	:user-data              ()
)
(
	:type                   :button
	:name                   dual-button
	:owner                  controls1
	:help                   ""
	:x                      244
	:y                      40
	:constant-width         nil
	:button-type            :normal
	:width                  80
	:height                 19
	:foreground-color       ""
	:label                  "Form dual"
	:label-type             :string
	:menu                   nil
	:notify-handler         "(do-dual model-watcher)"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
)
