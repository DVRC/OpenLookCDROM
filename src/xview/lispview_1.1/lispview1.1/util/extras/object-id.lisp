;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;;%W% %G%


(in-package "LISPVIEW")

(export '(x11-id xview-id))

;;; Return the XView object id (that's the integer returned by xv_create) or the 
;;; X11 resource id for most XView objects.  For a LispView display xview-id
;;; returns an XView Server and x11-id returns a foreign-pointer to an Xlib
;;; Display struct.  There are some objects that don't have an x11-id, e.g. 
;;; all panel items, like buttons and menus.


(flet 
 ((no-x11-id-error (x)
    (error "~S doesn't have an X11 ID" x)))

 (defmethod x11-id ((x display-device-status))
   (or (dd-x11-id (platform x) (device x))
       (no-x11-id-error x)))

 (defmethod x11-id ((x display))
   (or (dd-x11-id (platform x) (device x))
       (no-x11-id-error x)))

 (defmethod x11-id (x)
   (no-x11-id-error x)))


(flet
 ((no-xview-id-error (x)
    (error "~S doesn't have an XView ID" x)))

 (defmethod xview-id ((x display))
   (or (dd-xview-id (platform x) (device x))
       (no-xview-id-error x)))

 (defmethod xview-id ((x display-device-status))
   (or (dd-xview-id (platform x) (device x))
       (no-xview-id-error x)))

 (defmethod xview-id (x)
   (no-xview-id-error x)))



(defmethod dd-xview-id ((p Xview) (x xview-object))
  (xview-object-id x))

(defmethod dd-x11-id ((p XView) (x xview-object))
 (xview-object-xid x))


(defmethod dd-xview-id ((p Xview) (x xview-display))
  (XV:xv-get (xview-display-screen x) :screen-server))

(defmethod dd-x11-id ((p XView) (x xview-display))
 (xview-display-dsp x))



