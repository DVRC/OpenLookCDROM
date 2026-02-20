/*
 *	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
 *	Sun design patents pending in the U.S. and foreign countries.
 *	See LEGAL_NOTICE file for terms of the license.
 */

/* To compile this file:
 * setenv OPENWINHOME /usr/local/openwin/
 * setenv LD_LIBRARY_PATH "$OPENWINHOME/lib:/usr/lib"
 * sun3: cc -I$OPENWINHOME/include -I./include/sun3 build-xview-defs.c -o build-xview-defs
 * sun4: cc -I$OPENWINHOME/include -I./include/sun4 build-xview-defs.c -o build-xview-defs
*/

#include <stdio.h>
#include <xview/xview.h>
#include <xview/seln.h>
#include <xview/canvas.h>
#include <xview/frame.h>
#include <xview/cursor.h>
#include <xview/font.h>
#include <xview/fullscreen.h>
#include <xview/notice.h>
#include <xview/openwin.h>
#include <xview/panel.h>
#include <xview/scrollbar.h>
#include <xview/svrimage.h>
#include <xview/termsw.h>
#include <xview/textsw.h>
#include <xview/tty.h>
#include <xview/win_enum.h>
#include <xview/wmgr.h>
#include <xview/cms.h>
#include <xview/icon.h>                                        
#include <xview/icon_load.h>                                        
#include <xview_private/ntfy.h>
#include <xview_private/ndet.h>


main (argc, argv)
 int argc;
 char **argv;
{
  printf("XV_VISUAL_CLASS %d\n", XV_VISUAL_CLASS);

  /*
  printf("ICON_TRANSPARENT %d\n", ICON_TRANSPARENT);
  printf("ICON_MASK_IMAGE %d\n", ICON_MASK_IMAGE);
  printf("ICON_TRANSPARENT_LABEL %d\n", ICON_TRANSPARENT_LABEL);
  */

  /*
  printf("MENU_PARENT %d\n", MENU_PARENT);
  */

  /* 
  printf("PANEL_CHOICE_NROWS %d\n", PANEL_CHOICE_NROWS);
  printf("PANEL_CHOICE_NCOLS %d\n", PANEL_CHOICE_NCOLS);
  */

  /*
   printf("(def-xview-constant null %d \"NULL\")\n", NULL);
   printf("(def-xview-constant true %d \"TRUE\")\n", TRUE);
   printf("(def-xview-constant false %d \"FALSE\")\n", FALSE);
   printf("(def-xview-constant attr-standard-size %d \"ATTR_STANDARD_SIZE\")\n", ATTR_STANDARD_SIZE);
   printf("(def-xview-constant action-null-event %d \"ACTION_NULL_EVENT\")\n", ACTION_NULL_EVENT);
   printf("(def-xview-constant action-erase-char-backward %d \"ACTION_ERASE_CHAR_BACKWARD\")\n", ACTION_ERASE_CHAR_BACKWARD);
   printf("(def-xview-constant action-erase-char-forward %d \"ACTION_ERASE_CHAR_FORWARD\")\n", ACTION_ERASE_CHAR_FORWARD);
   printf("(def-xview-constant action-erase-word-backward %d \"ACTION_ERASE_WORD_BACKWARD\")\n", ACTION_ERASE_WORD_BACKWARD);
   printf("(def-xview-constant action-erase-word-forward %d \"ACTION_ERASE_WORD_FORWARD\")\n", ACTION_ERASE_WORD_FORWARD);
   printf("(def-xview-constant action-erase-line-backward %d \"ACTION_ERASE_LINE_BACKWARD\")\n", ACTION_ERASE_LINE_BACKWARD);
   printf("(def-xview-constant action-erase-line-end %d \"ACTION_ERASE_LINE_END\")\n", ACTION_ERASE_LINE_END);
   printf("(def-xview-constant action-go-char-backward %d \"ACTION_GO_CHAR_BACKWARD\")\n", ACTION_GO_CHAR_BACKWARD);
   printf("(def-xview-constant action-go-char-forward %d \"ACTION_GO_CHAR_FORWARD\")\n", ACTION_GO_CHAR_FORWARD);
   printf("(def-xview-constant action-go-word-backward %d \"ACTION_GO_WORD_BACKWARD\")\n", ACTION_GO_WORD_BACKWARD);
   printf("(def-xview-constant action-go-word-forward %d \"ACTION_GO_WORD_FORWARD\")\n", ACTION_GO_WORD_FORWARD);
   printf("(def-xview-constant action-go-word-end %d \"ACTION_GO_WORD_END\")\n", ACTION_GO_WORD_END);
   printf("(def-xview-constant action-go-line-backward %d \"ACTION_GO_LINE_BACKWARD\")\n", ACTION_GO_LINE_BACKWARD);
   printf("(def-xview-constant action-go-line-forward %d \"ACTION_GO_LINE_FORWARD\")\n", ACTION_GO_LINE_FORWARD);
   printf("(def-xview-constant action-go-line-end %d \"ACTION_GO_LINE_END\")\n", ACTION_GO_LINE_END);
   printf("(def-xview-constant action-go-line-start %d \"ACTION_GO_LINE_START\")\n", ACTION_GO_LINE_START);
   printf("(def-xview-constant action-go-column-backward %d \"ACTION_GO_COLUMN_BACKWARD\")\n", ACTION_GO_COLUMN_BACKWARD);
   printf("(def-xview-constant action-go-column-forward %d \"ACTION_GO_COLUMN_FORWARD\")\n", ACTION_GO_COLUMN_FORWARD);
   printf("(def-xview-constant action-go-document-start %d \"ACTION_GO_DOCUMENT_START\")\n", ACTION_GO_DOCUMENT_START);
   printf("(def-xview-constant action-go-document-end %d \"ACTION_GO_DOCUMENT_END\")\n", ACTION_GO_DOCUMENT_END);
   printf("(def-xview-constant action-stop %d \"ACTION_STOP\")\n", ACTION_STOP);
   printf("(def-xview-constant action-again %d \"ACTION_AGAIN\")\n", ACTION_AGAIN);
   printf("(def-xview-constant action-props %d \"ACTION_PROPS\")\n", ACTION_PROPS);
   printf("(def-xview-constant action-undo %d \"ACTION_UNDO\")\n", ACTION_UNDO);
   printf("(def-xview-constant action-redo %d \"ACTION_REDO\")\n", ACTION_REDO);
   printf("(def-xview-constant action-front %d \"ACTION_FRONT\")\n", ACTION_FRONT);
   printf("(def-xview-constant action-back %d \"ACTION_BACK\")\n", ACTION_BACK);
   printf("(def-xview-constant action-copy %d \"ACTION_COPY\")\n", ACTION_COPY);
   printf("(def-xview-constant action-open %d \"ACTION_OPEN\")\n", ACTION_OPEN);
   printf("(def-xview-constant action-close %d \"ACTION_CLOSE\")\n", ACTION_CLOSE);
   printf("(def-xview-constant action-paste %d \"ACTION_PASTE\")\n", ACTION_PASTE);
   printf("(def-xview-constant action-find-backward %d \"ACTION_FIND_BACKWARD\")\n", ACTION_FIND_BACKWARD);
   printf("(def-xview-constant action-find-forward %d \"ACTION_FIND_FORWARD\")\n", ACTION_FIND_FORWARD);
   printf("(def-xview-constant action-replace %d \"ACTION_REPLACE\")\n", ACTION_REPLACE);
   printf("(def-xview-constant action-cut %d \"ACTION_CUT\")\n", ACTION_CUT);
   printf("(def-xview-constant action-select-field-backward %d \"ACTION_SELECT_FIELD_BACKWARD\")\n", ACTION_SELECT_FIELD_BACKWARD);
   printf("(def-xview-constant action-select-field-forward %d \"ACTION_SELECT_FIELD_FORWARD\")\n", ACTION_SELECT_FIELD_FORWARD);
   printf("(def-xview-constant action-copy-then-paste %d \"ACTION_COPY_THEN_PASTE\")\n", ACTION_COPY_THEN_PASTE);
   printf("(def-xview-constant action-store %d \"ACTION_STORE\")\n", ACTION_STORE);
   printf("(def-xview-constant action-load %d \"ACTION_LOAD\")\n", ACTION_LOAD);
   printf("(def-xview-constant action-include-file %d \"ACTION_INCLUDE_FILE\")\n", ACTION_INCLUDE_FILE);
   printf("(def-xview-constant action-get-filename %d \"ACTION_GET_FILENAME\")\n", ACTION_GET_FILENAME);
   printf("(def-xview-constant action-set-directory %d \"ACTION_SET_DIRECTORY\")\n", ACTION_SET_DIRECTORY);
   printf("(def-xview-constant action-do-it %d \"ACTION_DO_IT\")\n", ACTION_DO_IT);
   printf("(def-xview-constant action-help %d \"ACTION_HELP\")\n", ACTION_HELP);
   printf("(def-xview-constant action-insert %d \"ACTION_INSERT\")\n", ACTION_INSERT);
   printf("(def-xview-constant action-invoke %d \"ACTION_INVOKE\")\n", ACTION_INVOKE);
   printf("(def-xview-constant action-expand %d \"ACTION_EXPAND\")\n", ACTION_EXPAND);
   printf("(def-xview-constant action-match-delimiter %d \"ACTION_MATCH_DELIMITER\")\n", ACTION_MATCH_DELIMITER);
   printf("(def-xview-constant action-caps-lock %d \"ACTION_CAPS_LOCK\")\n", ACTION_CAPS_LOCK);
   printf("(def-xview-constant action-quote %d \"ACTION_QUOTE\")\n", ACTION_QUOTE);
   printf("(def-xview-constant action-empty %d \"ACTION_EMPTY\")\n", ACTION_EMPTY);
   printf("(def-xview-constant action-select %d \"ACTION_SELECT\")\n", ACTION_SELECT);
   printf("(def-xview-constant action-adjust %d \"ACTION_ADJUST\")\n", ACTION_ADJUST);
   printf("(def-xview-constant action-menu %d \"ACTION_MENU\")\n", ACTION_MENU);
   printf("(def-xview-constant action-drag-move %d \"ACTION_DRAG_MOVE\")\n", ACTION_DRAG_MOVE);
   printf("(def-xview-constant action-drag-copy %d \"ACTION_DRAG_COPY\")\n", ACTION_DRAG_COPY);
   printf("(def-xview-constant action-drag-load %d \"ACTION_DRAG_LOAD\")\n", ACTION_DRAG_LOAD);
   printf("(def-xview-constant action-split-horizontal %d \"ACTION_SPLIT_HORIZONTAL\")\n", ACTION_SPLIT_HORIZONTAL);
   printf("(def-xview-constant action-split-vertical %d \"ACTION_SPLIT_VERTICAL\")\n", ACTION_SPLIT_VERTICAL);
   printf("(def-xview-constant action-split-init %d \"ACTION_SPLIT_INIT\")\n", ACTION_SPLIT_INIT);
   printf("(def-xview-constant action-split-destroy %d \"ACTION_SPLIT_DESTROY\")\n", ACTION_SPLIT_DESTROY);
   printf("(def-xview-constant action-rescale %d \"ACTION_RESCALE\")\n", ACTION_RESCALE);
   printf("(def-xview-constant action-pinin %d \"ACTION_PININ\")\n", ACTION_PININ);
   printf("(def-xview-constant action-pinout %d \"ACTION_PINOUT\")\n", ACTION_PINOUT);
   printf("(def-xview-constant action-dismiss %d \"ACTION_DISMISS\")\n", ACTION_DISMISS);
   printf("(def-xview-constant action-take-focus %d \"ACTION_TAKE_FOCUS\")\n", ACTION_TAKE_FOCUS);
   printf("(def-xview-constant loc-move %d \"LOC_MOVE\")\n", LOC_MOVE);
   printf("(def-xview-constant loc-winenter %d \"LOC_WINENTER\")\n", LOC_WINENTER);
   printf("(def-xview-constant loc-winexit %d \"LOC_WINEXIT\")\n", LOC_WINEXIT);
   printf("(def-xview-constant loc-movewhilebutdown %d \"LOC_MOVEWHILEBUTDOWN\")\n", LOC_MOVEWHILEBUTDOWN);
   printf("(def-xview-constant loc-drag %d \"LOC_DRAG\")\n", LOC_DRAG);
   printf("(def-xview-constant win-repaint %d \"WIN_REPAINT\")\n", WIN_REPAINT);
   printf("(def-xview-constant win-resize %d \"WIN_RESIZE\")\n", WIN_RESIZE);
   printf("(def-xview-constant win-map-notify %d \"WIN_MAP_NOTIFY\")\n", WIN_MAP_NOTIFY);
   printf("(def-xview-constant win-unmap-notify %d \"WIN_UNMAP_NOTIFY\")\n", WIN_UNMAP_NOTIFY);
   printf("(def-xview-constant kbd-use %d \"KBD_USE\")\n", KBD_USE);
   printf("(def-xview-constant kbd-done %d \"KBD_DONE\")\n", KBD_DONE);
   printf("(def-xview-constant win-client-message %d \"WIN_CLIENT_MESSAGE\")\n", WIN_CLIENT_MESSAGE);
   printf("(def-xview-constant win-unused-11 %d \"WIN_UNUSED_11\")\n", WIN_UNUSED_11);
   printf("(def-xview-constant win-stop %d \"WIN_STOP\")\n", WIN_STOP);
   printf("(def-xview-constant key-codes %d \"KEY_CODES\")\n", KEY_CODES);
   printf("(def-xview-constant ms-left %d \"MS_LEFT\")\n", MS_LEFT);
   printf("(def-xview-constant ms-middle %d \"MS_MIDDLE\")\n", MS_MIDDLE);
   printf("(def-xview-constant ms-right %d \"MS_RIGHT\")\n", MS_RIGHT);
   printf("(def-xview-constant shift-capslock %d \"SHIFT_CAPSLOCK\")\n", SHIFT_CAPSLOCK);
   printf("(def-xview-constant shift-lock %d \"SHIFT_LOCK\")\n", SHIFT_LOCK);
   printf("(def-xview-constant shift-left %d \"SHIFT_LEFT\")\n", SHIFT_LEFT);
   printf("(def-xview-constant shift-right %d \"SHIFT_RIGHT\")\n", SHIFT_RIGHT);
   printf("(def-xview-constant shift-leftctrl %d \"SHIFT_LEFTCTRL\")\n", SHIFT_LEFTCTRL);
   printf("(def-xview-constant shift-ctrl %d \"SHIFT_CTRL\")\n", SHIFT_CTRL);
   printf("(def-xview-constant shift-rightctrl %d \"SHIFT_RIGHTCTRL\")\n", SHIFT_RIGHTCTRL);
   printf("(def-xview-constant shift-meta %d \"SHIFT_META\")\n", SHIFT_META);
   printf("(def-xview-constant shift-top %d \"SHIFT_TOP\")\n", SHIFT_TOP);
   printf("(def-xview-constant shift-cmd %d \"SHIFT_CMD\")\n", SHIFT_CMD);
   printf("(def-xview-constant notice-yes %d \"NOTICE_YES\")\n", NOTICE_YES);
   printf("(def-xview-constant notice-no %d \"NOTICE_NO\")\n", NOTICE_NO);
   printf("(def-xview-constant notice-failed %d \"NOTICE_FAILED\")\n", NOTICE_FAILED);
   printf("(def-xview-constant notice-triggered %d \"NOTICE_TRIGGERED\")\n", NOTICE_TRIGGERED);
   printf("(def-xview-constant cms-status-default %d \"CMS_STATUS_DEFAULT\")\n", CMS_STATUS_DEFAULT);
   printf("(def-xview-constant cms-status-control %d \"CMS_STATUS_CONTROL\")\n", CMS_STATUS_CONTROL);
   printf("(def-xview-constant cms-status-frame %d \"CMS_STATUS_FRAME\")\n", CMS_STATUS_FRAME);
   printf("(def-xview-constant cms-control-colors %d \"CMS_CONTROL_COLORS\")\n", CMS_CONTROL_COLORS);
   printf("(def-xview-constant xv-default-cms-size %d \"XV_DEFAULT_CMS_SIZE\")\n", XV_DEFAULT_CMS_SIZE);
   printf("(def-xview-constant xv-static-cms %d \"XV_STATIC_CMS\")\n", XV_STATIC_CMS);
   printf("(def-xview-constant xv-dynamic-cms %d \"XV_DYNAMIC_CMS\")\n", XV_DYNAMIC_CMS);
   printf("(def-xview-constant ie-negevent %d \"IE_NEGEVENT\")\n", IE_NEGEVENT);
   printf("(def-xview-constant shiftmask %d \"SHIFTMASK\")\n", SHIFTMASK);
   printf("(def-xview-constant ctrlmask %d \"CTRLMASK\")\n", CTRLMASK);
   printf("(def-xview-constant meta-shift-mask %d \"META_SHIFT_MASK\")\n", META_SHIFT_MASK);
   printf("(def-xview-constant ms-left-mask %d \"MS_LEFT_MASK\")\n", MS_LEFT_MASK);
   printf("(def-xview-constant ms-middle-mask %d \"MS_MIDDLE_MASK\")\n", MS_MIDDLE_MASK);
   printf("(def-xview-constant ms-right-mask %d \"MS_RIGHT_MASK\")\n", MS_RIGHT_MASK);
   printf("(def-xview-constant ms-button-mask %d \"MS_BUTTON_MASK\")\n", MS_BUTTON_MASK);
   printf("(def-xview-constant but-first %d \"BUT_FIRST\")\n", BUT_FIRST);
   printf("(def-xview-constant but-last %d \"BUT_LAST\")\n", BUT_LAST);
   printf("(def-xview-constant ascii-first %d \"ASCII_FIRST\")\n", ASCII_FIRST);
   printf("(def-xview-constant ascii-last %d \"ASCII_LAST\")\n", ASCII_LAST);
   printf("(def-xview-constant meta-first %d \"META_FIRST\")\n", META_FIRST);
   printf("(def-xview-constant meta-last %d \"META_LAST\")\n", META_LAST);
   printf("(def-xview-constant key-leftfirst %d \"KEY_LEFTFIRST\")\n", KEY_LEFTFIRST);
   printf("(def-xview-constant key-leftlast %d \"KEY_LEFTLAST\")\n", KEY_LEFTLAST);
   printf("(def-xview-constant key-rightfirst %d \"KEY_RIGHTFIRST\")\n", KEY_RIGHTFIRST);
   printf("(def-xview-constant key-rightlast %d \"KEY_RIGHTLAST\")\n", KEY_RIGHTLAST);
   printf("(def-xview-constant key-topfirst %d \"KEY_TOPFIRST\")\n", KEY_TOPFIRST);
   printf("(def-xview-constant key-toplast %d \"KEY_TOPLAST\")\n", KEY_TOPLAST);
   printf("(def-xview-constant key-bottomleft %d \"KEY_BOTTOMLEFT\")\n", KEY_BOTTOMLEFT);
   printf("(def-xview-constant key-bottomright %d \"KEY_BOTTOMRIGHT\")\n", KEY_BOTTOMRIGHT);
   printf("(def-xview-constant win-null-value %d \"WIN_NULL_VALUE\")\n", WIN_NULL_VALUE);
   printf("(def-xview-constant win-no-events %d \"WIN_NO_EVENTS\")\n", WIN_NO_EVENTS);
   printf("(def-xview-constant win-up-events %d \"WIN_UP_EVENTS\")\n", WIN_UP_EVENTS);
   printf("(def-xview-constant win-ascii-events %d \"WIN_ASCII_EVENTS\")\n", WIN_ASCII_EVENTS);
   printf("(def-xview-constant win-up-ascii-events %d \"WIN_UP_ASCII_EVENTS\")\n", WIN_UP_ASCII_EVENTS);
   printf("(def-xview-constant win-mouse-buttons %d \"WIN_MOUSE_BUTTONS\")\n", WIN_MOUSE_BUTTONS);
   printf("(def-xview-constant win-in-transit-events %d \"WIN_IN_TRANSIT_EVENTS\")\n", WIN_IN_TRANSIT_EVENTS);
   printf("(def-xview-constant win-left-keys %d \"WIN_LEFT_KEYS\")\n", WIN_LEFT_KEYS);
   printf("(def-xview-constant win-top-keys %d \"WIN_TOP_KEYS\")\n", WIN_TOP_KEYS);
   printf("(def-xview-constant win-right-keys %d \"WIN_RIGHT_KEYS\")\n", WIN_RIGHT_KEYS);
   printf("(def-xview-constant win-meta-events %d \"WIN_META_EVENTS\")\n", WIN_META_EVENTS);
   printf("(def-xview-constant win-up-meta-events %d \"WIN_UP_META_EVENTS\")\n", WIN_UP_META_EVENTS);
   printf("(def-xview-constant win-sunview-function-keys %d \"WIN_SUNVIEW_FUNCTION_KEYS\")\n", WIN_SUNVIEW_FUNCTION_KEYS);
   printf("(def-xview-constant win-edit-keys %d \"WIN_EDIT_KEYS\")\n", WIN_EDIT_KEYS);
   printf("(def-xview-constant win-motion-keys %d \"WIN_MOTION_KEYS\")\n", WIN_MOTION_KEYS);
   printf("(def-xview-constant win-text-keys %d \"WIN_TEXT_KEYS\")\n", WIN_TEXT_KEYS);
   printf("(def-xview-constant xv-ok %d \"XV_OK\")\n", XV_OK);
   printf("(def-xview-constant xv-error %d \"XV_ERROR\")\n", XV_ERROR);
   printf("(def-xview-constant scrollbar-request %d \"SCROLLBAR_REQUEST\")\n", SCROLLBAR_REQUEST);
   printf("(def-xview-constant il-errormsg-size %d \"IL_ERRORMSG_SIZE\")\n", IL_ERRORMSG_SIZE);
   printf("(def-xview-constant ndet-stop %d \"NDET_STOP\")\n", NDET_STOP);
   printf("(def-xview-constant ndet-fd-change %d \"NDET_FD_CHANGE\")\n", NDET_FD_CHANGE);
   printf("(def-xview-constant ndet-signal-change %d \"NDET_SIGNAL_CHANGE\")\n", NDET_SIGNAL_CHANGE);
   printf("(def-xview-constant ndet-real-change %d \"NDET_REAL_CHANGE\")\n", NDET_REAL_CHANGE);
   printf("(def-xview-constant ndet-virtual-change %d \"NDET_VIRTUAL_CHANGE\")\n", NDET_VIRTUAL_CHANGE);
   printf("(def-xview-constant ndet-wait3-change %d \"NDET_WAIT3_CHANGE\")\n", NDET_WAIT3_CHANGE);
   printf("(def-xview-constant ndet-dispatch %d \"NDET_DISPATCH\")\n", NDET_DISPATCH);
   printf("(def-xview-constant ndet-real-poll %d \"NDET_REAL_POLL\")\n", NDET_REAL_POLL);
   printf("(def-xview-constant ndet-virtual-poll %d \"NDET_VIRTUAL_POLL\")\n", NDET_VIRTUAL_POLL);
   printf("(def-xview-constant ndet-interrupt %d \"NDET_INTERRUPT\")\n", NDET_INTERRUPT);
   printf("(def-xview-constant ndet-started %d \"NDET_STARTED\")\n", NDET_STARTED);
   printf("(def-xview-constant ndet-exit-soon %d \"NDET_EXIT_SOON\")\n", NDET_EXIT_SOON);
   printf("(def-xview-constant ndet-stop-on-sig %d \"NDET_STOP_ON_SIG\")\n", NDET_STOP_ON_SIG);
   printf("(def-xview-constant ndet-vetoed %d \"NDET_VETOED\")\n", NDET_VETOED);
   printf("(def-xview-constant ndet-itimer-enq %d \"NDET_ITIMER_ENQ\")\n", NDET_ITIMER_ENQ);
   printf("(def-xview-constant ndet-no-delay %d \"NDET_NO_DELAY\")\n", NDET_NO_DELAY);
   printf("(def-xview-constant ndet-destroy-change %d \"NDET_DESTROY_CHANGE\")\n", NDET_DESTROY_CHANGE);
   printf("(def-xview-constant ndet-poll %d \"NDET_POLL\")\n", NDET_POLL);
   printf("(def-xview-constant ndet-condition-change %d \"NDET_CONDITION_CHANGE\")\n", NDET_CONDITION_CHANGE);
  */
}
