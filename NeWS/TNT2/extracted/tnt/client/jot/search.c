/*
 *	@(#)search.c 1.9 91/02/20 Copyright 1990-91 Sun Microsystems
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

#include <setjmp.h>
#include <ctype.h>
#include "jot.h"
#include "text.h"
#include "bytestring.h"
#include "search.h"
#include "selection.h"
#include "assert.h"
#include "span.h"

#define STAR 1

/* Expression verbs:  Verbs are even numbers.  If they are STAR'd
   the low order bit is turned on. */

#define beginning_of_line 2
#define end_of_line 4
#define beginning_of_word 6
#define end_of_word 8
#define submatch_begin 10
#define submatch_end 12
#define nested_begin 14

#define first_starable 16   /* first construct we can '*' */

#define any_character 16
#define normal_characters 18
#define case_independent_characters 20
#define char_member 22
#define char_not_member 24
#define submatch_reference 26
#define end_of_pattern 28

static int	REpeekc;
static char	*REptr;

#define NCHARS	256
static u_char mapped_chars[NCHARS] = {
	'\000',	'\001',	'\002',	'\003',	'\004',	'\005',	'\006',	'\007',
	'\010',	'\011',	'\012',	'\013',	'\014',	'\015',	'\016',	'\017',
	'\020',	'\021',	'\022',	'\023',	'\024',	'\025',	'\026',	'\027',
	'\030',	'\031',	'\032',	'\033',	'\034',	'\035',	'\036',	'\037',
	'\040',	'!',	'"',	'#',	'$',	'%',	'&',	'\'',
	'(',	')',	'*',	'+',	',',	'-',	'.',	'/',
	'0',	'1',	'2',	'3',	'4',	'5',	'6',	'7',
	'8',	'9',	':',	';',	'<',	'=',	'>',	'?',
	'@',	'A',	'B',	'C',	'D',	'E',	'F',	'G',
	'H',	'I',	'J',	'K',	'L',	'M',	'N',	'O',
	'P',	'Q',	'R',	'S',	'T',	'U',	'V',	'W',
	'X',	'Y',	'Z',	'[',	'\\',	']',	'^',	'-',
	'`',	'A',	'B',	'C',	'D',	'E',	'F',	'G',
	'H',	'I',	'J',	'K',	'L',	'M',	'N',	'O',
	'P',	'Q',	'R',	'S',	'T',	'U',	'V',	'W',
	'X',	'Y',	'Z',	'{',	'|',	'}',	'~',	'\177',

	128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140,
	141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153,
	154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166,
	167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179,
	180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192,
	193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205,
	206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218,
	219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231,
	232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244,
	245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255
};

#define cind_cmp(a, b)	(mapped_chars[(a)] == mapped_chars[(b)])

static void do_comp();

static int
REgetc()
{
	register int	c;

	if ((c = REpeekc) != -1)
		REpeekc = -1;
	else if (*REptr)
		c = *REptr++;
	else
		c = 0;

	return c;
}

/* The char_{not_,}member functions are represented as a bit vector.
   These symbols parameterize the representation. */

#define	BYTESIZE	8
#define	SETSIZE		(NCHARS / BYTESIZE)
#define	SETBYTE(c)	((c) / BYTESIZE)
#define	SETBIT(c)	(1 << ((c) % BYTESIZE))

#define MAX_SUBMATCHES	10
    /* [0-9] - 0th is the entire matched string, i.e. & */

static jmp_buf	re_jmpbuf;

boolean
JotSearch_CompileExpression(expr, string, regular)
JotSearch   *expr;
char	    *string;
boolean	    regular;
{
    /* set up the "input" for compilation */
    REptr = string;
    REpeekc = -1;

    expr->error = Jot_NOERROR;
    if ((expr->error = setjmp(re_jmpbuf)) != 0)
	return_error(FALSE, Jot_ESYNTAX);

    if (expr->buf == 0) {
	expr->buf = Bytestring_New(64);
	if (expr->buf == 0)
	    return_error(FALSE, Jot_Errno);
    } else
	Bytestring_Delete(expr->buf, 0, Bytestring_Length(expr->buf));

    expr->alts[0] = 0;
    expr->alt_count = 1;
    do_comp(expr, regular);
    Bytestring_MoveGap(expr->buf, Bytestring_Length(expr->buf));

    /* do a little post processing */
    expr->anchored = 0;
    expr->firstc = -1;
    if (expr->alt_count <= 1) {
	u_char	*p;

	p = &Bytestring_CharAt(expr->buf, expr->alts[0]);
	for (;;) {
	    switch (*p) {
	    case submatch_begin:
	    case submatch_end:
		p += 2;
		continue;

	    case beginning_of_word:
	    case end_of_word:
		p += 1;
		continue;

	    case beginning_of_line:
		expr->anchored = 1;
		break;

	    case normal_characters:
		expr->firstc = p[2];
		break;

	    default:
		break;
	    }
	    break;
	}
    }
    return TRUE;
}

static
re_error(error, string, arg)
int	error, arg;
char	*string;
{
    fprintf(stderr, string, arg);
    longjmp(re_jmpbuf, error);
}

/* compile the pattern into an internal code */

static void
do_comp(expr, regular)
JotSearch   *expr;	/* compiled expression buffer */
boolean	    regular;
{
    register Bytestring	*b;
    register int	c;
    register int	comp_pos;
    int			parens[NSUBMATCHES], *parenp, paren_count;
    int			this_verb, prev_verb, start_pos;

    parenp = parens;
    paren_count = 0;
    this_verb = -1;
    comp_pos = 0;
    b = expr->buf;

#define add_char(c)	Bytestring_InsertChar(b, comp_pos++, (c), 1)
#define char_at(pos)	Bytestring_CharAt(b, (pos))
#define replace_char(pos, c) (*(&Bytestring_CharAt(b, pos)) = (c))
#define delete_char(n)	Bytestring_Delete(b, comp_pos--, -n)

    /* wrap the whole expression around (implied) parens */
    if (regular) {
	add_char(submatch_begin);
	add_char(paren_count);
	*parenp++ = paren_count++;
    }

    start_pos = comp_pos;

    while ((c = REgetc()) != '\0') {
	prev_verb = this_verb;
	this_verb = comp_pos;

	if (!regular)
	    goto defchar;
	switch (c) {
	case '\\':
	    switch (c = REgetc()) {
	    case '\0':
		re_error(Jot_PEOP, "Premature end of pattern");
		/*NOTREACHED*/

	    case '(':
		if (paren_count >= NSUBMATCHES)
		    re_error(Jot_PARENCOUNT, "Too many ('s - max is %d",
			     NSUBMATCHES);
		add_char(submatch_begin);
		add_char(paren_count);
		*parenp++ = paren_count++;
		break;

	    case ')':
		if (parenp == parens)
		    re_error(Jot_UNMATCHED, "Too many )'s.");
		add_char(submatch_end);
		add_char(*--parenp);
		break;

	    case '|':
		if (expr->alt_count >= Jot_MAX_ALTS)
		    re_error(Jot_ALTCOUNT, "Too many alternates - max %d.",
			     Jot_MAX_ALTS);
		/* close off previous alternate */
		add_char(submatch_end);
		add_char(*--parenp);
		add_char(end_of_pattern);
		expr->alts[expr->alt_count++] = comp_pos;

		/* start a new one */
		paren_count = 0;
		add_char(submatch_begin);
		add_char(paren_count);
		*parenp++ = paren_count++;
		start_pos = comp_pos;
		break;

	    case '1':
	    case '2':
	    case '3':
	    case '4':
	    case '5':
	    case '6':
	    case '7':
	    case '8':
	    case '9':
		if (c - '0' >= paren_count)
		    re_error(Jot_FORWARDREF, "\\%c is a forward reference.", c);
		add_char(submatch_reference);
		add_char(c - '0');
		break;

	    case '<':
		add_char(beginning_of_word);
		break;

	    case '>':
		add_char(end_of_word);
		break;

	    default:
		goto defchar;
	    }
	    break;

	case '.':
	    add_char(any_character);
	    break;

	case '^':
	    if (comp_pos == start_pos) {
		add_char(beginning_of_line);
		break;
	    }
	    goto defchar;

	case '$':
	    if ((REpeekc = REgetc()) != 0 && REpeekc != '\\')
		goto defchar;
	    add_char(end_of_line);
	    break;

	case '[':
	    {
		int	chrcnt;
		char	member_set[SETSIZE];

		bzero(member_set, SETSIZE);
		if ((REpeekc = REgetc()) == '^') {
		    add_char(char_not_member);
		    (void) REgetc();
		} else
		    add_char(char_member);

		chrcnt = 0;
		while ((c = REgetc()) != ']' && c != 0) {
		    if (c == '\\') {
			c = REgetc();
			if (c == 0)
			    break;
		    } else if ((REpeekc = REgetc()) == '-') {
			int	i;

			i = c;
			(void) REgetc();     /* reread '-' */
			c = REgetc();
			if (c == 0)
			    break;
			while (i < c) {
			    member_set[SETBYTE(i)] |= SETBIT(i);
			    i += 1;
			}
		    }
		    member_set[SETBYTE(c)] |= SETBIT(c);
		    chrcnt += 1;
		}
		if (c == 0)
		    re_error(Jot_UNMATCHED, "Missing ]");
		if (chrcnt == 0)
		    re_error(Jot_EMPTYCHRCLASS, "Empty []");
		Bytestring_Insert(expr->buf, comp_pos, member_set, SETSIZE);
		comp_pos += SETSIZE;
		break;
	    }

	case '*':
	    /* The * operator applies only to the previous character.
	       Since we were building a string-matching command
	       (normal_characters or case_independent_characters), we must
	       split it up into two parts.  We remember the last character,
	       decrement the count, and create a new verb with a count of
	       1.  If the number of characters is already one, we just
	       STAR it. */
	    {
		char	verb_char;
		char    count;
		char    lastc;

		verb_char = (prev_verb >= 0) ? char_at(prev_verb) : 0;

		if (verb_char < first_starable ||
		    (verb_char & STAR) != 0)
			goto defchar;

		if ((verb_char == normal_characters ||
		     verb_char == case_independent_characters) &&
		    (count = char_at(prev_verb + 1)) > 1) {

		    lastc = char_at(comp_pos - 1);
		    replace_char(prev_verb + 1, count - 1);
		    delete_char(1);
		    this_verb = comp_pos;
		    add_char(char_at(prev_verb) | STAR);
		    add_char(1);
		    add_char(lastc);
		} else {
		    /* This command is just the previous one,
		       whose verb we will modify. */
		    this_verb = prev_verb;
		    replace_char(this_verb, char_at(this_verb) | STAR);
		}
		break;
	    }
	default:
defchar:
	    if ((prev_verb == -1) ||
		!(char_at(prev_verb) == normal_characters ||
		  char_at(prev_verb) == case_independent_characters) ||
		(char_at(prev_verb + 1) >= 255)) {
		/* create new string command */
		add_char(normal_characters);
		add_char(0);
	    } else {
		/* merge this into previous string command */
		this_verb = prev_verb;
	    }
	    /* bump the count by one */
	    replace_char(this_verb + 1, char_at(this_verb + 1) + 1);
	    add_char(c);
	    break;
	}
    }
outahere:

    /* end of pattern, let's do some error checking: */
    if (regular) {
	add_char(submatch_end);
	add_char(*--parenp);
    }
    if (parenp != parens)
	re_error(Jot_UNMATCHED, "Unmatched ()'s");
    add_char(end_of_pattern);

#undef add_char
#undef char_at
#undef replace_char
#undef delete_char
}

static int  sm_begin[NSUBMATCHES];	/* index into buffer */
static int  sm_end[NSUBMATCHES];	/* index into buffer */
static int  match_start;		/* buffer pos of start of match */
static int  match_end;			/* buffer pos of end of match */

static int
backref(b, n, pos)
Bytestring	*b;
register int	pos;
int		n;
{
    register int    bp,
		    limit;

    bp = sm_begin[n];
    limit = sm_end[n];
    while (Bytestring_CharAt(b, bp) == Bytestring_CharAt(b, pos)) {
	if (++bp >= limit)
	    return 1;
	pos += 1;
    }
    return 0;
}

static int
match_expression(b, expr_ptr, buffer_pos, ignorecase)
register Bytestring *b;
register u_char	    *expr_ptr;
register int	    buffer_pos;
boolean		    ignorecase;
{
    register int    star_start_pos, n;
    register int    buf_len = Bytestring_Length(b);

#define char_at(pos)	Bytestring_CharAt(b, pos)

    for (;;) switch (*expr_ptr++) {
    case end_of_pattern:
	match_end = buffer_pos;
	return TRUE;	/* success */

    case normal_characters:
	n = *expr_ptr++;
	if (ignorecase) {
	    while (--n >= 0) {
		if (!cind_cmp(char_at(buffer_pos), *expr_ptr++))
		    return FALSE;
		buffer_pos += 1;
	    }
	} else {
	    while (--n >= 0) {
		if (char_at(buffer_pos) != *expr_ptr++)
		    return FALSE;
		buffer_pos += 1;
	    }
	}
	continue;

    case beginning_of_line:
	if (buffer_pos == 0 || char_at(buffer_pos - 1) == '\n')
	    continue;
	return FALSE;

    case end_of_line:
	if (buffer_pos == buf_len || char_at(buffer_pos) == '\n')
	    continue;
	return FALSE;

    case any_character:
	if (buffer_pos < buf_len) {
	    buffer_pos += 1;
	    continue;
	}
	return FALSE;

    case beginning_of_word:
	if (buffer_pos == 0 || isalnum(char_at(buffer_pos)) &&
	    !isalnum(char_at(buffer_pos - 1)))
	    continue;
	return FALSE;

    case end_of_word:
	if (buffer_pos > 0 && isalnum(char_at(buffer_pos - 1)) &&
	    !isalnum(char_at(buffer_pos)))
	    continue;
	return FALSE;

    case char_member:
    case char_not_member:
#define member(c, af) ((expr_ptr[SETBYTE(c)] & SETBIT(c)) ? (af) : !(af))

	if (member(char_at(buffer_pos), expr_ptr[-1] == char_member)) {
	    buffer_pos += 1;
	    expr_ptr += SETSIZE;
	    continue;
	}
	return FALSE;

    case submatch_begin:
	sm_begin[*expr_ptr++] = buffer_pos;
	continue;

    case submatch_end:
	sm_end[*expr_ptr++] = buffer_pos;
	continue;

    case submatch_reference:
	n = *expr_ptr++;
	if (backref(b, n, buffer_pos)) {
	    buffer_pos += sm_end[n] - sm_begin[n];
	    continue;
	}
	return FALSE;

    case any_character | STAR:
	star_start_pos = buffer_pos;
	while (buffer_pos < buf_len && char_at(buffer_pos) != '\n')
	    buffer_pos += 1;
	goto star;

    case normal_characters | STAR:
	expr_ptr++;
	assert(expr_ptr[-1] == 1);
	star_start_pos = buffer_pos;
	if (ignorecase)
	    while (cind_cmp(*expr_ptr, char_at(buffer_pos)))
		buffer_pos += 1;
	else
	    while (*expr_ptr == char_at(buffer_pos))
		buffer_pos += 1;
	expr_ptr += 1;
	goto star;

    case char_member | STAR:
    case char_not_member | STAR:
	star_start_pos = buffer_pos;
	while (member(char_at(buffer_pos),
		      expr_ptr[-1] == (char_member | STAR)))
	    buffer_pos += 1;
	expr_ptr += SETSIZE;
	/* fall through */
star:
	/* buffer_pos points *after* first unmatched char.
	   star_start_pos points at where starred element started
	   matching */
	while (buffer_pos > star_start_pos) {
	    if ((*expr_ptr != normal_characters ||
		 char_at(buffer_pos) == expr_ptr[2]) &&
		match_expression(b, expr_ptr, buffer_pos, ignorecase))
		return TRUE;
	    buffer_pos -= 1;
	}
	continue;

    case submatch_reference | STAR:
	star_start_pos = buffer_pos;
	n = *expr_ptr++;
	while (backref(b, n, buffer_pos))
	    buffer_pos += sm_end[n] - sm_begin[n];
	while (buffer_pos > star_start_pos) {
	    if (match_expression(b, expr_ptr, buffer_pos, ignorecase))
		return TRUE;
	    buffer_pos -= sm_end[n] - sm_begin[n];
	}
	continue;

    default:
oops:	fprintf(stderr, "match_expression error (%d).\n", expr_ptr[-1]);
	abort(0);
    }
    /* NOTREACHED */
#undef char_at
#undef member
}

boolean
JotSearch_MatchPattern(expr, range, match, direction, ignorecase)
JotSearch   *expr;
JotSpan	    *range, *match;
int	    direction;
boolean	    ignorecase;
{
    register Bytestring	*b;
    register int	pos, limit;
    JotText		*text;
    u_char		*expr_start;

    text = JotSpan_Text(range);
    expr->text = text;
    b = text->data;
    if (direction == Jot_BACKWARD) {
	limit = JotSpan_QuickP(range);
	pos = limit + JotSpan_QuickL(range);
    } else {
	pos = JotSpan_QuickP(range);
	limit = pos + JotSpan_QuickL(range);
    }
    expr_start = &Bytestring_CharAt(expr->buf, 0);
    if (expr->firstc != -1) {
	int c;

	if (direction == Jot_FORWARD) {
	    for (; pos < limit; pos++) {
		c = Bytestring_CharAt(b, pos);
		if (ignorecase) {
		    if (!cind_cmp(c, expr->firstc))
			continue;
		} else {
		    if (c != expr->firstc)
			continue;
		}
		if (match_expression(b, expr_start, pos, ignorecase)) {
		    match_start = pos;
		    break;
		}
	    }
	    if (pos >= limit)
		return FALSE;
	} else {
	    while (--pos >= limit) {
		c = Bytestring_CharAt(b, pos);
		if (ignorecase) {
		    if (!cind_cmp(c, expr->firstc))
			continue;
		} else {
		    if (c != expr->firstc)
			continue;
		}

		if (match_expression(b, expr_start, pos, ignorecase)) {
		    match_start = pos;
		    break;
		}
	    }
	    if (pos < limit)
		return FALSE;
	}
    } else {
	register int	i;

	if (direction == Jot_BACKWARD) {
	    while (--pos >= limit) {
		if (expr->anchored && pos > 0 &&
		    Bytestring_CharAt(b, pos - 1) != '\n')
		    continue;
		for (i = 0; i < expr->alt_count; i++)
		    if (match_expression(b, expr_start + expr->alts[i], pos, ignorecase)) {
			match_start = pos;
			goto breakout;
		    }
	    }
	    return FALSE;
	} else {
	    for (; pos < limit; pos += 1) {
		if (expr->anchored && pos > 0 &&
		    Bytestring_CharAt(b, pos - 1) != '\n')
		    continue;
		for (i = 0; i < expr->alt_count; i++)
		    if (match_expression(b, expr_start + expr->alts[i], pos, ignorecase)) {
			match_start = pos;
			goto breakout;
		    }
	    }
	    return FALSE;
	}
    }
breakout:
    if ((direction == Jot_FORWARD && match_end > limit) ||
	(direction == Jot_BACKWARD && match_start < limit))
	return FALSE;

    bcopy((char *) sm_begin, (char *) expr->sm_begin, sizeof (sm_begin));
    bcopy((char *) sm_end, (char *) expr->sm_end, sizeof (sm_end));
    JotSpan_SetText(match, text, match_start, match_end - match_start);

    return TRUE;
}

JotSearch *
JotSearch_New()
{
    JotSearch	*s;

    s = (JotSearch *) jot_alloc(sizeof (JotSearch));
    if (s == 0)
	return_error((JotSearch *) NULL, Jot_Errno);
    bzero((char *) s, sizeof (JotSearch));

    return s;
}

void
JotSearch_Free(s)
JotSearch   *s;
{
    if (s->buf != 0)
	Bytestring_Free(s->buf);
    free((char *) s);
}

static JotSearch *
get_expression()
{
    static JotSearch	*expr;

    if (expr == 0)
	expr = JotSearch_New();
    return expr;
}

boolean
JotSearch_Find(text, pos, direction, string)
JotText	*text;
int	pos, direction;
char	*string;
{
    static JotSpan	*s = 0;
    JotSearch		*expr;
    int			limit;

    expr = get_expression();
    if (JotSearch_CompileExpression(expr, string, FALSE) == 0) {
	printf("Compile failed.\n");
	return FALSE;
    }
    if (s == 0)
	s = JotSpan_NewI(NULL, 0, 0);

    if (direction == Jot_FORWARD)
	limit = JotText_Characters(text);
    else {
	limit = pos;
	pos = 0;
    }
    if (!JotSpan_SetText(s, text, pos, limit - pos)) {
	printf("Stupid SetText didn't work!\n");
	return FALSE;
    }
    if (JotSearch_MatchPattern(expr, s, s, direction)) {
	JotSelection_Set(s, Jot_PRIMARY, TRUE);
	if (direction == Jot_FORWARD)
	    JotText_SetCaret(JotSpan_Text(s), JotSpan_Position(s) +
			     JotSpan_Length(s));
	else
	    JotText_SetCaret(JotSpan_Text(s), JotSpan_Position(s));
	return TRUE;
    }
    return FALSE;
}

boolean
JotSearch_MatchString(string, range, match, direction, ignorecase)
char	*string;
JotSpan	*range, *match;
int	direction;
boolean	ignorecase;
{
    JotSearch	*expr;

    expr = get_expression();
    if (!JotSearch_CompileExpression(expr, string, FALSE))
	return_error(FALSE, Jot_Errno);
    return JotSearch_MatchPattern(expr, range, match, direction, ignorecase);
}

boolean
JotSearch_Substring(expr, substring, match)
JotSearch   *expr;
int	    substring;
JotSpan	    *match;
{
    return JotSpan_SetText(match, expr->text, expr->sm_begin[substring],
			   expr->sm_end[substring] - expr->sm_begin[substring]);
}
