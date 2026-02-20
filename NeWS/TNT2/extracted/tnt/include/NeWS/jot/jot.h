/*
 *	@(#)jot.h 1.12 91/02/20 Copyright 1990-91 Sun Microsystems
 *
 * This file is a product of Sun Microsystems, Inc. and is provided for
 * unrestricted use provided that this legend is included on all tape
 * media and as a part of the software program in whole or part.  Users
 * may copy or modify this file without charge, but are not authorized to
 * license or distribute it to anyone else except as part of a product
 * or program developed by the user.
 * 
 * THIS FILE IS PROVIDED AS IS WITH NO WARRANTIES OF ANY KIND INCLUDING THE
 * WARRANTIES OF DESIGN, MERCHANTIBILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE, OR ARISING FROM A COURSE OF DEALING, USAGE OR TRADE PRACTICE.
 * 
 * This file is provided with no support and without any obligation on the
 * part of Sun Microsystems, Inc. to assist in its use, correction,
 * modification or enhancement.
 * 
 * SUN MICROSYSTEMS, INC. SHALL HAVE NO LIABILITY WITH RESPECT TO THE
 * INFRINGEMENT OF COPYRIGHTS, TRADE SECRETS OR ANY PATENTS BY THIS FILE
 * OR ANY PART THEREOF.
 * 
 * In no event will Sun Microsystems, Inc. be liable for any lost revenue
 * or profits or other special, indirect and consequential damages, even
 * if Sun has been advised of the possibility of such damages.
 * 
 * Sun Microsystems, Inc.
 * 2550 Garcia Avenue
 * Mountain View, California  94043
 */

#if !defined (JOT_H)
#define JOT_H

#ifndef FILE
#  include <stdio.h>
#endif

#include <NeWS/c_varieties.h>
#include <NeWS/wire/wire.h>

/* JOT error numbers */

#define Jot_ERRORSTART	90	/* make this larger than max system errno */

#define Jot_EMEMORY	(Jot_ERRORSTART + 1)
#define Jot_ERANGECHECK	(Jot_ERRORSTART + 2)
#define Jot_ETEXT	(Jot_ERRORSTART + 3)
#define Jot_ECONSTRAIN	(Jot_ERRORSTART + 4)
#define Jot_ESYNTAX	(Jot_ERRORSTART + 5)
#define Jot_EFONT	(Jot_ERRORSTART + 6)
#define Jot_ESELECTION	(Jot_ERRORSTART + 7)

extern int  Jot_Errno;


typedef struct JotSpan		JotSpan;
typedef struct JotText		JotText;
typedef struct JotView		JotView;
typedef struct bytestring	Bytestring;
typedef struct JotBoundingBox	JotBoundingBox;
typedef struct font		JotFont;


EXTERN_FUNCTION( void	Jot_Initialize,		(wire_Wire wire) );

#endif	/* JOT_H */
