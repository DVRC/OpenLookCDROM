;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.

;;; XGL utilities.  Load after xgl-functions.

;;;%W% %G%

(in-package "XGL")


(def-xgl-function (XGLUT-DBUF-INIT
		   (:return-type void) 
		   (:name "_xglut_dbuf_init"))
    "Initialize double buffering."
  (dbuf-information (:pointer xglut-dbuf-info)))

(def-xgl-function (XGLUT-DBUF-ON
		   (:return-type void) 
		   (:name "_xglut_dbuf_on"))
    "Enable double buffering."
  (dbuf-information (:pointer xglut-dbuf-info)))

(def-xgl-function (XGLUT-DBUF-SWITCH-BUFFER
		   (:return-type void) 
		   (:name "_xglut_dbuf_switch_buffer"))
    "Swap buffers."
  (dbuf-information (:pointer xglut-dbuf-info)))
