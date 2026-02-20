/*
 *	@(#)bytestring.c 1.8 91/02/20 Copyright 1990-91 Sun Microsystems
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

/* routines for supporting bytestrings */

#include <stdio.h>
#include "jot.h"
#include "jot_private.h"
#include "assert.h"
#include "bytestring.h"

/* Create a bytestring and initialize its length to size.  Returns 0 if
   there is no memory.  If Initialize fails to allocate the memory, we
   return successful anyway, and a later insert operation will fail
   instead. */

Bytestring *
Bytestring_New(size)
int size;
{
    register Bytestring	*b;

    b = (Bytestring *) jot_alloc(sizeof(Bytestring));
    if (b != 0)
	Bytestring_Initialize(b, size);

    return b;
}

void
Bytestring_Initialize(b, size)
register Bytestring *b;
int		    size;
{
    bzero((char *) b, sizeof *b);
    if (size > 0) {
	if (size < 16)
	    size = 16;
	size = (size + sizeof (char *) - 1) & ~(sizeof(char *) - 1);
	b->bytes = (u_char *) jot_alloc(size);
	if (b->bytes == 0)
	    return;
	b->bufsize = size;
    }
    b->secondpart = b->bytes + b->bufsize - b->size;
}

void
Bytestring_Free(b)
register Bytestring *b;
{
    Bytestring_Finalize(b);
    jot_free((char *) b);
}

void
Bytestring_Finalize(b)
register Bytestring *b;
{
    if (b->bytes != 0)
	jot_free(b->bytes);
}

/* Move the gap to byte position n; ie. make the first part be n bytes long */
void
Bytestring_MoveGap(b, n)
register Bytestring *b;
register int	    n;
{
    if (b->firstsize == n)
	return;
    if (b->firstsize < n)
	bcopy(b->bytes + b->bufsize - b->size + b->firstsize,
	      b->bytes + b->firstsize,
	      n - b->firstsize);
    else
	bcopy(b->bytes + n,
	      b->bytes + b->bufsize - b->size + n,
	      b->firstsize - n);
    b->firstsize = n;
    assert(b->secondpart = b->bytes + b->bufsize - b->size);
}

/* Make sure there is enough room for N bytes at POS in bytestring B. */

boolean
Bytestring_RoomFor(b, n)
register Bytestring *b;
register int	    n;
{
    if (b->bufsize - b->size < n) {	/* not enough room in buffer */
	register int	newsize = (b->size + n) * 3 >> 1;

	newsize &= ~(sizeof(char *) - 1);   /* kludge or what!? */
	b->bytes = (u_char *) jot_realloc(b->bytes, newsize);
	if (b->bytes == 0)
	    return FALSE;
	bcopy(b->bytes + b->bufsize - b->size + b->firstsize,
	      b->bytes + newsize - b->size + b->firstsize,
	      b->size - b->firstsize);
	b->bufsize = newsize;
	b->secondpart = b->bytes + b->bufsize - b->size;
    }
    return TRUE;
}

/* This is a way to say N bytes have been inserted at POS.  That is,
   somebody has made the gap big enough, just placed some characters
   into the bytestring, and now wants the bytestring to acknowledge
   the fact that it now has these extra characters.  This is used for
   reading files:  You first make the gap as big as the file, then
   you read the characters directly into the buffer gap, and then you
   call this routine to get the internal points adjusted. */
void
Bytestring_BytesInserted(b, pos, n)
register Bytestring *b;
register int	    pos, n;
{
    if (b->firstsize != pos) {
	fprintf(stderr, "It's an error to call BytesInserted when the gap isn't correctly aligned!\n");
	return;
    }
    b->firstsize += n;
    b->size += n;
    b->secondpart = b->bytes + b->bufsize - b->size;
}

/* insert n bytes from s into bytestring b starting at byte pos */
int
Bytestring_Insert(b, pos, s, n)
register Bytestring *b;
int		    pos, n;
char		    *s;
{
    if (n < 0 || pos < 0 || pos > b->size)
	return_error(-1, Jot_ERANGECHECK);
    Bytestring_MoveGap(b, pos);
    if (!Bytestring_RoomFor(b, n))
	return_error(-1, Jot_Errno);
    bcopy(s, b->bytes + pos, n);
    Bytestring_BytesInserted(b, pos, n);

    return n;
}

int
Bytestring_InsertChar(b, pos, c)
Bytestring  *b;
int	    pos;
char	    c;
{
    return Bytestring_Insert(b, pos, &c, 1);
}

void
Bytestring_Copy(src, src_pos, dest, dest_pos, length)
register Bytestring *src, *dest;
register int	    src_pos, dest_pos, length;
{
    while (--length >= 0) {
	Bytestring_InsertChar(dest, dest_pos++,
			      Bytestring_CharAt(src, src_pos));
	src_pos += 1;
    }
}


/* Delete n bytes from bytestring b starting at byte pos.  Copes with
   negative values of n and regions that go outside the buffer. */
int
Bytestring_Delete(b, pos, n)
register Bytestring *b;
int		    pos, n;
{
    if (n < 0)
	pos += n, n = -n;
    if (pos < 0 || pos + n > b->size)
	return_error(-1, Jot_ERANGECHECK);
    if (pos + n == b->firstsize)
	b->firstsize -= n;
    else
	Bytestring_MoveGap(b, pos);
    b->size -= n;
    b->secondpart = b->bytes + b->bufsize - b->size;

    return n;
}

#define min(a, b)   (((a) < (b)) ? (a) : (b))
#define max(a, b)   (((a) > (b)) ? (a) : (b))

/* Scan the bytestring for character C starting from POS, heading in
   DIR, not exceeding LIMIT. */

int
Bytestring_Scan(b, pos, dir, c, limit)
register Bytestring *b;
register int	    c;
int		    pos, dir, limit;
{
    register u_char   *cp;
    register int    n;
    u_char	    *starting_point;

    if (dir > 0) {
	starting_point = cp = &Bytestring_CharAt(b, pos);
	n = min(limit, b->firstsize) - pos;
	while (--n >= 0)
	    if (*cp++ == c)
		return pos + (cp - starting_point) - 1;

	if (pos < b->firstsize)
	    pos = b->firstsize;

	starting_point = cp = &Bytestring_CharAt(b, pos);
	n = limit - b->firstsize;
	while (--n >= 0)
	    if (*cp++ == c)
		return pos + (cp - starting_point) - 1;
    } else {
	starting_point = cp = &Bytestring_CharAt(b, pos);
	n = pos - max(limit, b->firstsize);
	while (--n >= 0)
	    if (*--cp == c)
		return pos - (starting_point - cp);

	if (pos >= b->firstsize)
	    pos = b->firstsize - 1;
	else
	    pos -= 1;
	starting_point = cp = &Bytestring_CharAt(b, pos) + 1;
	n = b->firstsize - limit;
	while (--n >= 0)
	    if (*--cp == c)
		return pos - (starting_point - cp) + 1;
    }
    return -1;
}
