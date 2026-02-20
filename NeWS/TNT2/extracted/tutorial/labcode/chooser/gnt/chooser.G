;GIL-2
(
(
	:type                   :base-window
	:name                   window1
	:owner                  nil
	:width                  558
	:height                 159
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
	:width                  364
	:height                 159
	:background-color       ""
	:foreground-color       ""
	:show-border            nil
	:menu                   nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :slider
	:name                   Hue_slider
	:owner                  controls1
	:help                   ""
	:x                      72
	:y                      20
	:width                  237
	:height                 15
	:value-x                111
	:value-y                20
	:slider-width           100
	:foreground-color       ""
	:label                  "Hue:"
	:label-type             :string
	:layout-type            :horizontal
	:orientation            :horizontal
	:show-endboxes          nil
	:show-range             t
	:show-value             t
	:min-value              0
	:max-value              1
	:ticks                  0
	:notify-handler         ps_Hue_slider_handler
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :slider
	:name                   Saturation_slider
	:owner                  controls1
	:help                   ""
	:x                      28
	:y                      60
	:width                  281
	:height                 15
	:value-x                111
	:value-y                60
	:slider-width           100
	:foreground-color       ""
	:label                  "Saturation:"
	:label-type             :string
	:layout-type            :horizontal
	:orientation            :horizontal
	:show-endboxes          nil
	:show-range             t
	:show-value             t
	:min-value              0
	:max-value              1
	:ticks                  0
	:notify-handler         ps_Saturation_slider_handler
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :slider
	:name                   Brightness_slider
	:owner                  controls1
	:help                   ""
	:x                      24
	:y                      100
	:width                  285
	:height                 15
	:value-x                111
	:value-y                100
	:slider-width           100
	:foreground-color       ""
	:label                  "Brightness:"
	:label-type             :string
	:layout-type            :horizontal
	:orientation            :horizontal
	:show-endboxes          nil
	:show-range             t
	:show-value             t
	:min-value              0
	:max-value              1
	:ticks                  0
	:notify-handler         ps_Brightness_slider_handler
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :canvas-pane
	:name                   canvas1
	:owner                  window1
	:help                   ""
	:x                      361
	:y                      0
	:width                  197
	:height                 159
	:background-color       ""
	:foreground-color       ""
	:menu                   nil
	:horizontal-scrollbar   nil
	:scrollable-width       197
	:vertical-scrollbar     nil
	:scrollable-height      159
	:repaint-proc           nil
	:event-handler          nil
	:events                 ()
	:drawing-model          :xview
	:user-data              ()
)
)
