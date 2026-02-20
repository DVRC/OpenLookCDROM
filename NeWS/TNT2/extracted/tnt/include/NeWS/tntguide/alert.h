/*
 * @(#)alert.h 1.6 91/02/21 Copyright 1990-91 Sun Microsystems
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

#if !defined (ALERT_H)
#define ALERT_H

#include <NeWS/c_varieties.h>

int
GuideNotice(/* char *prompt, char *secline, char *leftlabel, char *rightlabel */);

EXTERN_FUNCTION( int loadPostScript,	(char *path) );
    
extern 	int	FindGuide (/* void */);
extern	int QuitConfirmed (/* void */);
extern	unsigned char *getwindowcolor(/* void */);

#define ERROR_CLIENT	2
#define ERROR_SERVER	3


#include "alertcps.h"

#endif	/* ALERT_H */
