;GIL-2
(
(
	:type                   :menu
	:name                   glv-load-menu
	:help                   ""
	:columns                1
	:label                  ""
	:label-type             :string
	:menu-type              :command
	:menu-handler           nil
	:menu-title             ""
	:menu-item-labels       ("only app" "ui only" "app & ui " "stub & ui" )
	:menu-item-label-types  (:string :string :string :string )
	:menu-item-defaults     (nil nil nil t )
	:menu-item-handlers     ("(load-lisp-files glv '(\"app\"))" "(load-lisp-files glv '(\"app.ui\"))" "(load-lisp-files glv '(\"app.ui\" \"app\"))" "(load-lisp-files glv '(\"app.ui\" \"app.stub\"))" )
	:menu-item-menus        (nil nil nil nil )
	:menu-item-colors       ("" "" "" "" )
	:pinnable               nil
	:user-data              ()
)
(
	:type                   :base-window
	:name                   glv-window
	:owner                  nil
	:width                  514
	:height                 100
	:background-color       ""
	:foreground-color       ""
	:label                  "GLV  Devguide to LispView Conversion"
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
						 :data *glv-mask-data*)
		       :label (list (make-instance 'lv:image
						 :data *glv-data*) 
						 "GLV"))))
)
(
	:type                   :control-area
	:name                   glv-panel
	:owner                  glv-window
	:help                   ""
	:x                      0
	:y                      0
	:width                  514
	:height                 100
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
	:name                   glv-display-props
	:owner                  glv-panel
	:help                   ""
	:x                      12
	:y                      9
	:constant-width         nil
	:button-type            :normal
	:width                  61
	:height                 19
	:foreground-color       ""
	:label                  "Props..."
	:label-type             :string
	:menu                   nil
	:notify-handler         "(display-props glv)"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   glv-convert
	:owner                  glv-panel
	:help                   ""
	:x                      90
	:y                      9
	:constant-width         nil
	:button-type            :normal
	:width                  66
	:height                 19
	:foreground-color       ""
	:label                  "Convert"
	:label-type             :string
	:menu                   nil
	:notify-handler         "(convert-to-lisp glv-directory glv-filename glv-window)"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   glv-load
	:owner                  glv-panel
	:help                   ""
	:x                      162
	:y                      9
	:constant-width         nil
	:button-type            :normal
	:width                  60
	:height                 19
	:foreground-color       ""
	:label                  "Load"
	:label-type             :string
	:menu                   glv-load-menu
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   glv-evaluate
	:owner                  glv-panel
	:help                   ""
	:x                      243
	:y                      9
	:constant-width         nil
	:button-type            :normal
	:width                  46
	:height                 19
	:foreground-color       ""
	:label                  "Eval:"
	:label-type             :string
	:menu                   nil
	:notify-handler         "(eval-text-line glv-eval-field glv-window)"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :text-field
	:name                   glv-eval-field
	:owner                  glv-panel
	:help                   ""
	:x                      289
	:y                      11
	:width                  217
	:height                 15
	:foreground-color       ""
	:text-type              :alphanumeric
	:label                  ""
	:label-type             :string
	:value-x                298
	:value-y                11
	:layout-type            :horizontal
	:value-length           26
	:stored-length          80
	:read-only              nil
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :text-field
	:name                   glv-directory
	:owner                  glv-panel
	:help                   ""
	:x                      55
	:y                      46
	:width                  451
	:height                 15
	:foreground-color       ""
	:text-type              :alphanumeric
	:label                  "Directory:"
	:label-type             :string
	:value-x                130
	:value-y                46
	:layout-type            :horizontal
	:value-length           47
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
	:name                   glv-filename
	:owner                  glv-panel
	:help                   ""
	:x                      13
	:y                      71
	:width                  493
	:height                 15
	:foreground-color       ""
	:text-type              :alphanumeric
	:label                  "Interface Name:"
	:label-type             :string
	:value-x                130
	:value-y                71
	:layout-type            :horizontal
	:value-length           47
	:stored-length          80
	:read-only              nil
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :popup-window
	:name                   glv-popup
	:owner                  glv-window
	:width                  290
	:height                 147
	:background-color       ""
	:foreground-color       ""
	:label                  "GLV: Properties"
	:label-type             :string
	:mapped                 nil
	:show-footer            nil
	:resizable              nil
	:pinned                 nil
	:done-handler           nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :control-area
	:name                   glv-popup-panel
	:owner                  glv-popup
	:help                   ""
	:x                      0
	:y                      0
	:width                  290
	:height                 147
	:background-color       ""
	:foreground-color       ""
	:show-border            nil
	:menu                   nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :setting
	:name                   glv-defclass-format
	:owner                  glv-popup-panel
	:help                   ""
	:x                      16
	:y                      32
	:width                  241
	:height                 23
	:value-x                139
	:value-y                32
	:layout-type            :horizontal
	:foreground-color       ""
	:setting-type           :exclusive
	:rows                   1
	:columns                0
	:label                  "Defclass Format:"
	:label-type             :string
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:choices                ("Slots" "Accessors" )
	:choice-label-types     (:string :string )
	:choice-colors          ("" "" )
	:user-data              ()
)
(
	:type                   :setting
	:name                   glv-output-format
	:owner                  glv-popup-panel
	:help                   ""
	:x                      28
	:y                      67
	:width                  223
	:height                 23
	:value-x                139
	:value-y                67
	:layout-type            :horizontal
	:foreground-color       ""
	:setting-type           :exclusive
	:rows                   1
	:columns                0
	:label                  "Output Format:"
	:label-type             :string
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:choices                ("pprint" "glv-pp" )
	:choice-label-types     (:string :string )
	:choice-colors          ("" "" )
	:user-data              ()
)
(
	:type                   :button
	:name                   glv-apply
	:owner                  glv-popup-panel
	:help                   ""
	:x                      90
	:y                      107
	:constant-width         nil
	:button-type            :normal
	:width                  53
	:height                 19
	:foreground-color       ""
	:label                  "Apply"
	:label-type             :string
	:menu                   nil
	:notify-handler         "(apply-props glv)"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   glv-reset
	:owner                  glv-popup-panel
	:help                   ""
	:x                      153
	:y                      107
	:constant-width         nil
	:button-type            :normal
	:width                  51
	:height                 19
	:foreground-color       ""
	:label                  "Reset"
	:label-type             :string
	:menu                   nil
	:notify-handler         "(reset-props glv)"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
)
