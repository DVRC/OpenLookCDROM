;GIL-2
(
(
	:type                   :base-window
	:name                   window1
	:owner                  nil
	:width                  330
	:height                 51
	:background-color       ""
	:foreground-color       ""
	:label                  "Enter/Exit"
	:label-type             :string
	:mapped                 t
	:show-footer            nil
	:resizable              nil
	:icon-file              ""
	:icon-mask-file         ""
	:event-handler          enter-exit
	:events                 (:mouse-enter :mouse-exit )
	:user-data              ()
)
(
	:type                   :base-window
	:name                   window2
	:owner                  nil
	:width                  332
	:height                 52
	:background-color       ""
	:foreground-color       ""
	:label                  "Mouse Button Events"
	:label-type             :string
	:mapped                 t
	:show-footer            nil
	:resizable              nil
	:icon-file              ""
	:icon-mask-file         ""
	:event-handler          "(format t \"Button Event\")"
	:events                 (:mouse )
	:user-data              ()
)
(
	:type                   :base-window
	:name                   window3
	:owner                  nil
	:width                  328
	:height                 48
	:background-color       ""
	:foreground-color       ""
	:label                  "Drag Events"
	:label-type             :string
	:mapped                 t
	:show-footer            nil
	:resizable              nil
	:icon-file              ""
	:icon-mask-file         ""
	:event-handler          "(print 'drag)"
	:events                 (:mouse-drag )
	:user-data              ()
)
(
	:type                   :base-window
	:name                   window4
	:owner                  nil
	:width                  322
	:height                 52
	:background-color       ""
	:foreground-color       ""
	:label                  "Move Events"
	:label-type             :string
	:mapped                 t
	:show-footer            nil
	:resizable              nil
	:icon-file              ""
	:icon-mask-file         ""
	:event-handler          nil
	:events                 (:mouse-move )
	:user-data              ()
)
)
