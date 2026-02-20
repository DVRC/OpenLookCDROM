;GIL-2
(
(
	:type                   :base-window
	:name                   window1
	:owner                  nil
	:width                  124
	:height                 66
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
	:type                   :popup-window
	:name                   popup1
	:owner                  window1
	:width                  400
	:height                 150
	:background-color       ""
	:foreground-color       ""
	:label                  "Done Handler"
	:label-type             :string
	:mapped                 t
	:show-footer            nil
	:resizable              t
	:pinned                 t
	:done-handler           foobar
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
)
