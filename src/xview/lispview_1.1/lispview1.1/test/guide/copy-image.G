;GIL-2
(
(
	:type                   :base-window
	:name                   window1
	:owner                  nil
	:width                  449
	:height                 331
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
	:width                  449
	:height                 64
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
	:x                      24
	:y                      8
	:constant-width         nil
	:button-type            :normal
	:width                  50
	:height                 42
	:foreground-color       "Medium Blue"
	:label                  "r.icon"
	:label-type             :glyph
	:menu                   nil
	:notify-handler         "(let ((g (solo:graphics-context solo:*default-display*)))(solo:with-graphics-context (g :foreground (solo:foreground canvas1)) (dotimes (i 100) (solo:copy-area (solo:label button1) canvas1 0 0 32 32 i i :gc g))))"
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
	:y                      63
	:width                  449
	:height                 268
	:background-color       ""
	:foreground-color       "Magenta"
	:menu                   nil
	:horizontal-scrollbar   nil
	:scrollable-width       449
	:vertical-scrollbar     nil
	:scrollable-height      268
	:repaint-proc           nil
	:event-handler          nil
	:events                 ()
	:drawing-model          :xview
	:user-data              ()
)
)
