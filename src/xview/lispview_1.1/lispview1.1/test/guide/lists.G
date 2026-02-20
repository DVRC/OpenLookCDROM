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
	:menu-item-labels       ("list1" "list2" "list3" "list4" "list5" "list6" )
	:menu-item-label-types  (:string :string :string :string :string :string )
	:menu-item-defaults     (nil nil nil nil nil nil )
	:menu-item-handlers     ("(setf (lv:value (list1 lists)) nil)" "(setf (lv:value (list2 lists)) nil)" "(setf (lv:value (list3 lists)) nil)" "(setf (lv:value (list4 lists)) nil)" "(setf (lv:value (list5 lists)) nil)" "(setf (lv:value (list6 lists)) nil)" )
	:menu-item-menus        (nil nil nil nil nil nil )
	:menu-item-colors       ("" "" "" "" "" "" )
	:pinnable               t
	:user-data              ()
)
(
	:type                   :base-window
	:name                   window1
	:owner                  nil
	:width                  386
	:height                 735
	:background-color       ""
	:foreground-color       ""
	:label                  "Scrolling List Test"
	:label-type             :string
	:mapped                 t
	:show-footer            t
	:resizable              nil
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
	:width                  386
	:height                 735
	:background-color       ""
	:foreground-color       ""
	:show-border            nil
	:menu                   nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :scrolling-list
	:name                   list1
	:owner                  controls1
	:help                   ""
	:x                      16
	:y                      20
	:width                  200
	:height                 74
	:foreground-color       ""
	:label                  "Ex-Required(1)"
	:label-type             :string
	:layout-type            :horizontal
	:rows                   3
	:read-only              nil
	:multiple-selections    nil
	:selection-required     t
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
	:x                      33
	:y                      112
	:width                  200
	:height                 74
	:foreground-color       ""
	:label                  "Ex-notreq(2)"
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
(
	:type                   :scrolling-list
	:name                   list3
	:owner                  controls1
	:help                   ""
	:x                      16
	:y                      200
	:width                  200
	:height                 74
	:foreground-color       ""
	:label                  "Ne-required(3)"
	:label-type             :string
	:layout-type            :horizontal
	:rows                   3
	:read-only              nil
	:multiple-selections    t
	:selection-required     t
	:menu                   nil
	:notify-handler         hello_dolly
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :scrolling-list
	:name                   list4
	:owner                  controls1
	:help                   ""
	:x                      30
	:y                      292
	:width                  200
	:height                 74
	:foreground-color       ""
	:label                  "Ne-notreq(4)"
	:label-type             :string
	:layout-type            :horizontal
	:rows                   3
	:read-only              nil
	:multiple-selections    t
	:selection-required     nil
	:menu                   nil
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :scrolling-list
	:name                   list-image
	:owner                  controls1
	:help                   ""
	:x                      56
	:y                      384
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
	:name                   list5
	:owner                  controls1
	:help                   ""
	:x                      23
	:y                      472
	:width                  200
	:height                 91
	:foreground-color       ""
	:label                  "read-only exclusive required label above"
	:label-type             :string
	:layout-type            :vertical
	:rows                   3
	:read-only              t
	:multiple-selections    nil
	:selection-required     t
	:menu                   nil
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :scrolling-list
	:name                   list6
	:owner                  controls1
	:help                   ""
	:x                      12
	:y                      584
	:width                  200
	:height                 91
	:foreground-color       ""
	:label                  "read-only non-exclusive NOT required label above"
	:label-type             :string
	:layout-type            :vertical
	:rows                   3
	:read-only              t
	:multiple-selections    t
	:selection-required     nil
	:menu                   nil
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   button1
	:owner                  controls1
	:help                   ""
	:x                      131
	:y                      708
	:constant-width         nil
	:button-type            :normal
	:width                  65
	:height                 19
	:foreground-color       ""
	:label                  "Reset"
	:label-type             :string
	:menu                   menu1
	:notify-handler         nil
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
(
	:type                   :button
	:name                   button2
	:owner                  controls1
	:help                   ""
	:x                      203
	:y                      708
	:constant-width         nil
	:button-type            :normal
	:width                  57
	:height                 19
	:foreground-color       ""
	:label                  "Set All"
	:label-type             :string
	:menu                   nil
	:notify-handler         "(mapcar #'(lambda(l)
	(setf (lv:choices (funcall l lists)) '(\"a\" \"b\")))
				'(list1 list2 list3 list4 list5 list6)
				)"
	:event-handler          nil
	:events                 ()
	:user-data              ()
)
)
