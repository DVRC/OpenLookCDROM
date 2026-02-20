;GIL-2
(
(
	:type                   :base-window
	:name                   window1
	:owner                  nil
	:width                  479
	:height                 185
	:background-color       ""
	:foreground-color       ""
	:label                  "Base Window"
	:label-type             :string
	:mapped                 t
	:show-footer            t
	:resizable              t
	:icon-file              ""
	:icon-mask-file         ""
	:event-handler          hey-dude
	:events                 (:mouse )
	:user-data              ()
)
(
	:type                   :control-area
	:name                   controls1
	:owner                  window1
	:help                   ""
	:x                      0
	:y                      0
	:width                  479
	:height                 185
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
	:name                   message1
	:owner                  controls1
	:help                   ""
	:x                      60
	:y                      16
	:width                  51
	:height                 13
	:foreground-color       ""
	:label                  "Message"
	:label-type             :string
	:label-bold             nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :text-field
	:name                   textfield3
	:owner                  controls1
	:help                   ""
	:x                      248
	:y                      16
	:width                  143
	:height                 15
	:foreground-color       ""
	:text-type              :alphanumeric
	:label                  "read-only:"
	:label-type             :string
	:value-x                327
	:value-y                16
	:layout-type            :horizontal
	:value-length           8
	:stored-length          80
	:read-only              t
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :text-field
	:name                   textfield4
	:owner                  controls1
	:help                   ""
	:x                      248
	:y                      48
	:width                  178
	:height                 15
	:foreground-color       ""
	:text-type              :numeric
	:label                  "read-only:"
	:label-type             :string
	:value-x                327
	:value-y                48
	:layout-type            :horizontal
	:value-length           8
	:stored-length          80
	:max-value              100
	:min-value              0
	:read-only              t
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :message
	:name                   message2
	:owner                  controls1
	:help                   ""
	:x                      56
	:y                      60
	:width                  60
	:height                 13
	:foreground-color       ""
	:label                  "Message"
	:label-type             :string
	:label-bold             t
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :text-field
	:name                   textfield1
	:owner                  controls1
	:help                   ""
	:x                      60
	:y                      96
	:width                  148
	:height                 15
	:foreground-color       ""
	:text-type              :alphanumeric
	:label                  "read-write:"
	:label-type             :string
	:value-x                144
	:value-y                96
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
	:name                   textfield5
	:owner                  controls1
	:help                   ""
	:x                      252
	:y                      96
	:width                  99
	:height                 15
	:foreground-color       ""
	:text-type              :alphanumeric
	:label                  "length4:"
	:label-type             :string
	:value-x                315
	:value-y                96
	:layout-type            :horizontal
	:value-length           4
	:stored-length          80
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
	:x                      60
	:y                      128
	:width                  183
	:height                 15
	:foreground-color       ""
	:text-type              :numeric
	:label                  "read-write:"
	:label-type             :string
	:value-x                144
	:value-y                128
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
	:name                   textfield6
	:owner                  controls1
	:help                   ""
	:x                      288
	:y                      132
	:width                  44
	:height                 32
	:foreground-color       ""
	:text-type              :alphanumeric
	:label                  "above:"
	:label-type             :string
	:value-x                288
	:value-y                149
	:layout-type            :vertical
	:value-length           4
	:stored-length          80
	:read-only              nil
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
)
