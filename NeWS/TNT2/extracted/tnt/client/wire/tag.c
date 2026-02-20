/*
 * @(#)tag.c 1.11 91/02/21 Copyright 1990-91 Sun Microsystems
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

#include <malloc.h>
#include <stdio.h>
#include <sys/types.h>
#include "wire.h"
#include "wire_private.h"

static struct tagpair {
	void		(*proc)();
	wire_RefAny	data;
} *tagtable = 0;

static int	tagtable_size = 0;
static int	high_water_mark = 0;	/* last legal tag + 1 */
static boolean	tags_allocated = FALSE;

#define MAX_TAG		32767
#define valid_tag(t)	((t) >= 0 && (t) < high_water_mark)

/* void (*wire_TagProc(tag))() */
wire_Handler wire_TagProc(tag)
int	tag;
{
	if (valid_tag(tag))
		return tagtable[tag].proc;
	return (void (*)()) NULL;
}

wire_RefAny
wire_TagData(tag)
int	tag;
{
	if (valid_tag(tag))
		return tagtable[tag].data;
	return (wire_RefAny) NULL;
}

/* AllocateTags takes a number N and returns another M, such that
   none of the integers M, M+1, ..., M+N-1 are already allocated.
   These integers are handles whose primary use will be to dispatch
   messages from the server to the client functions. */

int
wire_AllocateTags(n)
{
	register int	m;

	tags_allocated = TRUE;
	m = high_water_mark;
	if (m + n > MAX_TAG)
		return -1;
	high_water_mark += n;

	return m;
}

/* AllocateNamedTags takes a pointer to a null terminated array of
   integers, and fills them in with unique tags.  E.g.,
	int	kbd_tag, mouse_dragged_tag;
	int	*taglist[] = { &kbd_tag, &mouse_dragged_tag, (int *) 0};

	wire_AllocateNamedTags(taglist);
   */

boolean
wire_AllocateNamedTags(array)
register int	**array;
{
	register int	length, **ap, tag;

	for (length = 0, ap = array; *ap++ != 0; )
		length += 1;
	tag = wire_AllocateTags(length);
	if (tag == -1)
		return FALSE;
	while (--length >= 0)
		**(array++) = tag++;
	return TRUE;
}

/* ReserveTags is provided to allow dynamically-allocated tags to coexist
   with old-style constant tags.  If you know that some piece of code
   uses tag values 1 thru 50 (inclusive), then before calling AllocateTags
   you must first call ReserveTags(50).  This facility may also be used
   to to leave space for your own tag allocate if this one doesn't meet
   your needs.

   It is a protocol error to reserve tags after you have already
   allocated some; it returns FALSE and sets wire_Errno when that
   happens.  It is an error to reserver more tags than the maximum number
   of tags; this returns FALSE and sets wire_Errno when that happens.
   Otherwise this returns TRUE. */

boolean
wire_ReserveTags(largest)
{
	if (tags_allocated == TRUE) {
		wire_Errno = wire_EBADRESERVE;
		return FALSE;
	}
	if (largest > MAX_TAG) {
		wire_Errno = wire_ERANGECHECK;
		return FALSE;
	}
	high_water_mark = largest + 1;

	return TRUE;
}

/* RegisterTag allows you to associate a function pointer and a user
   data pointer with a tag.  If this tag is ever found on the wire by
   the notifier, your function will be called. 

   This returns FALSE if tag is out of range, exexcute abort() if the tag
   table needs to grow and there isn't enough memory, and returns TRUE if
   all goes well. */

boolean
wire_RegisterTag(tag, proc, data)
int		tag;
wire_Handler	proc;
wire_RefAny	data;
{
	if (!valid_tag(tag)) {
		wire_Errno = wire_ERANGECHECK;
		return FALSE;
	}
	if (tag >= tagtable_size) {		/* grow tag table */
		unsigned int	size;

		tagtable_size = high_water_mark;
		size = sizeof (struct tagpair) * tagtable_size;
		if (tagtable == 0)
			tagtable = (struct tagpair *) malloc(size);
		else
			tagtable = (struct tagpair *) realloc((char *) tagtable, size);
		assert(tagtable != 0);
	}
	tagtable[tag].proc = proc;
	tagtable[tag].data = data;

	return TRUE;
}

boolean
wire_InvokeTagProc(tag)
register int	tag;
{
	register struct tagpair	*tp;

	if (!valid_tag(tag)) {
		wire_Errno = wire_ERANGECHECK;
		return FALSE;
	}
	tp = &tagtable[tag];
	if (tp->proc == 0)
		return FALSE;

	(*tp->proc)(tag, tp->data);
	return TRUE;
}
