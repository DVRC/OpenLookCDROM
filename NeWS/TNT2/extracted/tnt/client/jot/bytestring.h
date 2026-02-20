/*
 *	@(#)bytestring.h 1.9 91/02/20 Copyright 1990-91 Sun Microsystems
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

#ifndef _BYTESTRING_INCLUDED_
#define _BYTESTRING_INCLUDED_

#include <NeWS/c_varieties.h>
#include <NeWS/jot/jot.h>
#include <NeWS/jot/jot_private.h>

/* A string of bytes.  It supports insertion, deletion and reference */
struct bytestring {
    u_char	*bytes;		/* the beginning of the buffer */
    int         bufsize;	/* the number of bytes in the buffer */
    int         size;		/* the number of bytes in the string
				   (bufsize-size is the number of spare
				   bytes) */
    int         firstsize;	/* The number of bytes in the first part.  The
				   buffer is split into two parts, firstsize
				   bytes at the beginning of the buffer,
				   size-firstsize at the end, with
				   bufsize-size spare in the middle */
    u_char	*secondpart;	/* == bytes+bufsize-size, to speed up
				   references in the second part */
};


EXTERN_FUNCTION( void		 Bytestring_BytesInserted,	(Bytestring *b, int pos, int nbytes) );
EXTERN_FUNCTION( int		 Bytestring_Delete,	(Bytestring *b, int pos, int n) );
EXTERN_FUNCTION( void		 Bytestring_Finalize,	(Bytestring *b) );
EXTERN_FUNCTION( void		 Bytestring_Free,	(Bytestring *b) );
EXTERN_FUNCTION( void		 Bytestring_Free,	(Bytestring *b) );
EXTERN_FUNCTION( void		 Bytestring_Initialize,	(Bytestring *b, int size) );
EXTERN_FUNCTION( int		 Bytestring_Insert,	(Bytestring *b, int pos, char* str, int n) );
EXTERN_FUNCTION( int		 Bytestring_InsertChar,	(Bytestring *b, int pos, char c) );
EXTERN_FUNCTION( void		 Bytestring_MoveGap,	(Bytestring *b, int pos) );
EXTERN_FUNCTION( Bytestring	*Bytestring_New,	(int size) );
EXTERN_FUNCTION( boolean	 Bytestring_RoomFor,	(Bytestring *b, int n) );
EXTERN_FUNCTION( int		 Bytestring_Scan,	(Bytestring *b, int pos, int dir, int c, int limit) );

/* Get byte n from bytestring b */
#define Bytestring_CharAt(b, n) \
	(*(n + ((n) < (b)->firstsize ? (b)->bytes : (b)->secondpart)))

#define Bytestring_Length(b)	    ((b)->size)

#endif
