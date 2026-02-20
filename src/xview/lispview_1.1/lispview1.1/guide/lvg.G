;GIL-2
(
(
	:type                   :menu
	:name                   view-menu
	:help                   ""
	:columns                1
	:label                  ""
	:label-type             :string
	:menu-type              :command
	:menu-handler           nil
	:menu-title             ""
	:menu-item-labels       ("Update List" "Associated Window" )
	:menu-item-label-types  (:string :string )
	:menu-item-defaults     (t nil )
	:menu-item-handlers     ("(lvg-update-list lvg-window-list lvg)" "(lvg-identify-window lvg-window-list lvg)" )
	:menu-item-menus        (nil nil )
	:menu-item-colors       ("" "" )
	:pinnable               nil
	:user-data              ()
)
(
	:type                   :base-window
	:name                   lvg-window
	:owner                  nil
	:width                  516
	:height                 240
	:background-color       ""
	:foreground-color       ""
	:label                  "LVG  LispView to Devguide Conversion"
	:label-type             :string
	:mapped                 t
	:show-footer            t
	:resizable              t
	:icon-file              ""
	:icon-mask-file         ""
	:event-handler          nil
	:events                 ()
	:user-data              (:default-initargs (:icon 
	(make-instance 'lv:icon
		       :clip-mask (make-instance 'lv:image
						 :data *lvg-mask-data*)
		       :label (list (make-instance 'lv:image
						 :data *lvg-data*) 
						 "LVG"))))
)
(
	:type                   :control-area
	:name                   lvg-panel
	:owner                  lvg-window
	:help                   ""
	:x                      0
	:y                      0
	:width                  516
	:height                 240
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
	:name                   lvg-view
	:owner                  lvg-panel
	:help                   ""
	:x                      13
	:y                      6
	:constant-width         nil
	:button-type            :normal
	:width                  62
	:height                 19
	:foreground-color       ""
	:label                  "View"
	:label-type             :string
	:menu                   view-menu
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   lvg-convert
	:owner                  lvg-panel
	:help                   ""
	:x                      90
	:y                      6
	:constant-width         nil
	:button-type            :normal
	:width                  66
	:height                 19
	:foreground-color       ""
	:label                  "Convert"
	:label-type             :string
	:menu                   nil
	:notify-handler         "(lvg-convert-to-gil lvg-window-list lvg)"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :text-field
	:name                   lvg-directory
	:owner                  lvg-panel
	:help                   ""
	:x                      56
	:y                      38
	:width                  443
	:height                 15
	:foreground-color       ""
	:text-type              :alphanumeric
	:label                  "Directory:"
	:label-type             :string
	:value-x                131
	:value-y                38
	:layout-type            :horizontal
	:value-length           46
	:stored-length          80
	:read-only              nil
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              (:default-initargs (:value 
					(namestring (lcl::pwd))))
)
(
	:type                   :text-field
	:name                   lvg-filename
	:owner                  lvg-panel
	:help                   ""
	:x                      14
	:y                      62
	:width                  485
	:height                 15
	:foreground-color       ""
	:text-type              :alphanumeric
	:label                  "Interface Name:"
	:label-type             :string
	:value-x                131
	:value-y                62
	:layout-type            :horizontal
	:value-length           46
	:stored-length          80
	:read-only              nil
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :scrolling-list
	:name                   lvg-window-list
	:owner                  lvg-panel
	:help                   ""
	:x                      13
	:y                      93
	:width                  470
	:height                 145
	:foreground-color       ""
	:label                  "Top Level Windows:"
	:label-type             :string
	:layout-type            :vertical
	:rows                   6
	:read-only              t
	:multiple-selections    t
	:selection-required     nil
	:menu                   nil
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              (:default-initargs (:choices 
						(lvg-make-choices)))
)
)
