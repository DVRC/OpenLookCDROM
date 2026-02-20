;;; -*- Mode: Lisp; Package: XGL -*-
;;;
;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.
;;;
;;; Created:       Wed May 29 11:33:33 1991 by Conal Elliott
;;; Last Modified: Wed May 29 12:29:42 1991 by Conal Elliott
;;;
;;; XGL support that I just hacked in.
;;;
;;; Sccs Id %W% %G%
;;;

(in-package :XGL)

(export '())

#|
(def-exported-foreign-synonym-type xgl-object (:pointer :character))
|#


(def-exported-foreign-struct xgli-om-class-inst    
   (ops :type caddr-t)
   (inst-data :type caddr-t)
   (class :type caddr-t)
   (super :type caddr-t))

(def-exported-foreign-struct xgli-om-object
   (obj-id :type unsigned-int)
   (inst :type xgli-om-class-inst))

(def-exported-foreign-synonym-type _xgli-om-object xgli-om-object) 

(def-exported-foreign-synonym-type xgl-object (:pointer xgli-om-object)) 
