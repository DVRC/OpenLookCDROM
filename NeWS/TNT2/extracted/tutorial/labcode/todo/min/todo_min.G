;GIL-2
(
(
	:type                   :base-window
	:name                   window1
	:owner                  nil
	:width                  654
	:height                 295
	:background-color       ""
	:foreground-color       ""
	:label                  "To Do"
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
	:type                   :text-pane
	:name                   textpane1
	:owner                  window1
	:help                   ""
	:x                      0
	:y                      0
	:width                  348
	:height                 295
	:background-color       ""
	:foreground-color       ""
	:show-border            t
	:read-only              nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :control-area
	:name                   controls1
	:owner                  window1
	:help                   ""
	:x                      347
	:y                      0
	:width                  307
	:height                 295
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
	:name                   InsertButton
	:owner                  controls1
	:help                   ""
	:x                      228
	:y                      84
	:constant-width         nil
	:button-type            :normal
	:width                  53
	:height                 19
	:foreground-color       ""
	:label                  "Insert"
	:label-type             :string
	:menu                   nil
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :text-field
	:name                   HeaderField
	:owner                  controls1
	:help                   ""
	:x                      12
	:y                      116
	:width                  192
	:height                 32
	:foreground-color       ""
	:text-type              :alphanumeric
	:label                  "Header:"
	:label-type             :string
	:value-x                12
	:value-y                133
	:layout-type            :vertical
	:value-length           24
	:stored-length          80
	:read-only              nil
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   DeleteButton
	:owner                  controls1
	:help                   ""
	:x                      228
	:y                      124
	:constant-width         nil
	:button-type            :normal
	:width                  57
	:height                 19
	:foreground-color       ""
	:label                  "Delete"
	:label-type             :string
	:menu                   nil
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :scrolling-list
	:name                   ToDoList
	:owner                  controls1
	:help                   ""
	:x                      12
	:y                      184
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
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
)
