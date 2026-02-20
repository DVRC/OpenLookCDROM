/*
 * @(#)token.c 1.12 91/02/21 Copyright 1990-91 Sun Microsystems
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

#include "wire.h"
#include "wire_private.h"

#define NTOKENS		32768
#define BITSPERWORD	32
#define MAXLISTSIZE	(NTOKENS >> 5)

static void
grow_free_list(t, count)
struct token_list	*t;
int			count;
{
	int	new_size;

	count = 1 + count / BITSPERWORD;
	if (t->list_size == 0) {
		new_size = (count < 10) ? 10 : count;
		t->free_list = (long *) malloc(new_size * sizeof (long));
	} else {
		new_size = (t->list_size * 3) / 2;
		if (new_size <= t->list_size + count)
			new_size = count + 1;
		if (new_size > MAXLISTSIZE)
			new_size = MAXLISTSIZE;
		t->free_list = (long *) realloc((char *) t->free_list,
						new_size * sizeof (long));
	}
	bzero((char *) &t->free_list[t->list_size],
	      (new_size - t->list_size) * sizeof (long));
	t->last_alloc = t->list_size;	/* start off at the right place */
	t->list_size = new_size;
}

/* Allocate some tokens.  This uses a bitfield to tell whether or not a
   given token is allocated.  It's variable length, up to a max of
   32768/32 (bits per long).  The algorithm remembers where it allocated
   the last token, and begins its search there.  If it gets to the end of
   the freelist it goes back to the beginning.  If it finds nothing, it
   allocates more tokens at the end of the list.  They are marked
   allocated and will not be reused unless the are explicitely freed, one
   by one.  No record of how many were allocated at once is kept.

   This routine us split in half.  The first half deals with the case of
   trying to allocate more than 1 user token at a time.  When N is more
   than 1, we optimize the lookup by going through the whole table looking
   for enough contiguous empty words to fit N bits.  This is faster tham
   trying to find N contiguous bits not aligned to word bounderies.  If
   this fails, it allocates more words at the end of the free list.  In
   this case, it's about the same behavior we used to have before we could
   reclaim (deallocate) tokens. */

int
wire_AllocateTokens(w, n)
wire_Wire	w;
{
	struct wire_Connection	*cp;
	struct token_list	*t;
	int			i, word, bit;

	if (!wire_Valid(w))
		return -1;
	cp = wire_ConnectionTable[w];
	t = &cp->t_list;
	if (t->list_size == 0)
		grow_free_list(t, n);
	if (n > 1) {
		int	desired_contiguous_words = 1 + ((n - 1) / BITSPERWORD);
		int	nwords = 0;
		int	first_word, wordi;

		i = t->last_alloc;
		for (;;) {
			if (t->free_list[i] == 0) {
				nwords += 1;
				if (nwords == desired_contiguous_words)
					break;
			} else
				nwords = 0;
			if (++i == t->list_size) {
				nwords = 0;
				i = 0;
			}
			if (i == t->last_alloc)
				break;
		}
		if (nwords != desired_contiguous_words) {
			grow_free_list(t, n);
			for (i = t->last_alloc; t->free_list[i - 1] == 0; i -= 1)
				;
			first_word = i;
		} else
			first_word = (i - nwords) + 1;

		for (wordi = first_word, i = desired_contiguous_words;
		     --i > 0; )
			t->free_list[wordi++] = -1;
		t->free_list[wordi] = (1 << (n & 037)) - 1;
		t->last_alloc = wordi;

		return first_word * BITSPERWORD + t->reserved;
	}
	/* find a free bit */
	i = t->last_alloc;
	while ((word = t->free_list[i]) == -1) {
		if (++i >= t->list_size)
			i = 0;
		if (i == t->last_alloc)
			break;
	}

	if (t->free_list[i] == -1) {
		if (t->list_size == MAXLISTSIZE)
			return -1;
		grow_free_list(t, -1);
		i = t->last_alloc;
		word = t->free_list[i];
	}

	for (bit = 0; bit < BITSPERWORD; bit += 1)
		if ((word & (1 << bit)) == 0)
			break;
	t->free_list[i] |= (1 << bit);

	return (i * BITSPERWORD + bit) + t->reserved;
}

/* AllocateNamedTokens takes a pointer to a null terminated array of
   integers, and fills them in with unique tokens.  E.g.,
	int	kbd_tag, mouse_dragged_tag;
	int	*tokenlist[] = { &bold_font, &italic_font, (int *) 0};

	wire_AllocateNamedTokens(tokenlist);
   */

boolean
wire_AllocateNamedTokens(w, array)
wire_Wire	w;
register int	**array;
{
	register int	length, **ap;

	for (length = 0, ap = array; *ap++ != 0; )
		length += 1;
	while (--length >= 0)
		**(array++) = wire_AllocateTokens(w, 1);

	return TRUE;
}

/* Deallocate N tokens at START. */

boolean
wire_DeallocateTokens(w, start, n)
wire_Wire	w;
int		start, n;
{
	struct token_list	*t;

	if (!wire_Valid(w))
		return FALSE;
	t = &wire_ConnectionTable[w]->t_list;

	start -= t->reserved;
	t->last_alloc = start>>5;
	while (--n >= 0) {
		if (!(t->free_list[start>>5] & (1 << (start & 037)))) {
			fprintf(stderr, "Warning: Attempt to free unallocated user token, wire = %d, token = %d\n", w, start);
			return FALSE;
		}
		t->free_list[start>>5] &= ~(1 << (start & 037));
		start += 1;
	}
	return TRUE;
}

/* ReserveTokens is provided to allow dynamically-allocated tokens to
   coexist with old-style constant tokens.  If you know that some piece
   of code uses tokens values 1 thru 50 (inclusive), then before calling
   AllocateTokens you must first call ReserveTokens(50).  This facility
   may also be used to to leave space for your own token allocator if this
   one doesn't meet your needs.

   It is a protocol error to reserve tokens after you have already
   allocated some; it returns FALSE and sets wire_Errno when that
   happens.  It is an error to reserve more tokens than the maximum number
   of tokens; this returns FALSE and sets wire_Errno when that happens.
   Otherwise this returns TRUE.

   REMIND: Right now this can't tell the difference between two
   ReserveTokens() and an AllocateTokens() followed by a ReserveTokens(),
   so two ReserveTokens() in a row will fail. */

boolean
wire_ReserveTokens(w, largest)
wire_Wire	w;
{
	struct wire_Connection	*c;
	register PSFILE	*ps;

	if (!wire_Valid(w))
		return FALSE;
	c = wire_ConnectionTable[w];
	if (c->t_list.reserved > 0) {	/* we've been here before */
		wire_Errno = wire_EBADRESERVE;
		return FALSE;
	}
	if (c->t_list.free_list != 0) {	/* we've allocated some already */
		wire_Errno = wire_EBADRESERVE;
		return FALSE;
	}
	if (largest >= NTOKENS) {
		wire_Errno = wire_ERANGECHECK;
		return FALSE;
	}
	c->t_list.reserved = largest + 1;

	return TRUE;
}

boolean
wire_RegisterToken(w, token, obj)
wire_Wire	w;
int		token;
wire_RefAny	obj;
{
	struct token_list	*t;
	int			n;

	if (!wire_Valid(w))
		return FALSE;
	t = &wire_ConnectionTable[w]->t_list;
	token -= t->reserved;
	if (token >= t->nobjects) {
		if (t->nobjects == 0)
			n = token < 10 ? 10 : token + 1;
		else
			n = (t->nobjects * 3) / 2;
		if (t->objects == 0)
			t->objects = (wire_RefAny *)
				malloc(n * sizeof (wire_RefAny));
		else
			t->objects = (caddr_t *)
				realloc((char *) t->objects,
					n * sizeof (wire_RefAny));
		t->nobjects = n;
	}
	t->objects[token] = obj;

	return TRUE;
}

wire_RefAny
wire_TokenData(w, token)
wire_Wire	w;
int		token;
{
	struct token_list	*t;
	int			n;

	if (!wire_Valid(w))
		return (wire_RefAny) NULL;
	t = &wire_ConnectionTable[w]->t_list;
	token -= t->reserved;
	if (token < 0 || token >= t->nobjects)	/* REMIND: New errno? */
		return (wire_RefAny) NULL;
	return (t->objects[token]);
}
