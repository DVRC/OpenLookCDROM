/*
 * @(#)psio.h 1.6 91/02/21 Copyright 1985-91 Sun Microsystems
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

/*-
	stdio for NeWS.  Can't use the "real" stdio since
		a) it's non-portable (!!)
		b) is missing some crucial features (like string files)
 */

/*
 * The psio package is essentially equivalent to stdio except that it has some
 * extensions for NeWS.  The extensions are that it supports reading from
 * strings, it supports the non-blocking escape required by the lwp mechanism,
 * it supports "reading ahead" past a protected part of the input buffer, it
 * supports a hook to the output file for automatic flushing, and it supports
 * more file descriptors than stdio.  [many stdio implementations only allow
 * one iob per fd; with read/write descriptors, two are needed]
 */


#ifndef PSFILE

#include <NeWS/c_varieties.h>

#ifndef FILE
#include <stdio.h>
#endif

#define PSBUFSIZ	1024
#define PSKEEPBUFSIZ	(PSBUFSIZ * 4)
#define PSMAXBUFSIZ	(PSBUFSIZ * 1024)

#define PSFILE struct psiobuf

struct psiobuf {
    int         cnt;
    unsigned char *ptr;
    unsigned char *base;
    int         bufsiz;
    short       flag;
    short       file;
    int         protected_size;
    union {
	PSFILE     *outputside;
	unsigned   next_user_token;
    } assoc;
};

EXTERN_FUNCTION( int	pprintf,	(PSFILE *file, const unsigned char fmt[], int len, DOTDOTDOT) );
EXTERN_FUNCTION( int	pscanf,		(PSFILE *file, const unsigned char fmt[], DOTDOTDOT) );
EXTERN_FUNCTION( int	ps_checkfor,	(PSFILE *file, int action, int tag) );


#define PSREAD		0x0001	/* file being read */
#define PSWRITE		0x0002	/* file being written */
#define PSNBF		0x0004	/* non buffered (not supported) */
#define PSMYBUF		0x0008	/* buffer alloced by psio */
#define PSEOF		0x0010	/* eof seen on file */
#define PSERR		0x0020	/* some kind of error */
#define PSSTRG		0x0040	/* string file */
#define PSLINEBUF	0x0080	/* flush on each newline (only in fprintf) */
#define PSRW		0x0100	/* read&write allowed (not supported) */
#define PSBLOCKED	0x0200	/* if last fill got EWOULDBLOCK */
#define PSBLOCKOK	0x0400	/* force blocking even if EWOULDBLOCK */
#define PSNONBLOCK	0x0800	/* perform nonblocking I/O on behalf of user */
#define PSOUTBLOCKED	0x1000	/* if last flush got EWOULDBLOCK */
#define PSDNI		0x2000	/* SunLink DNI connection */
#define PSunused1	0x4000	/* unused... */
#define PSunused2	0x8000	/* unused... */

#define PSIO_WAIT_TAG		0	/* wait for tag in input queue */
#define PSIO_FIND_TAG		1	/* find tag in input queue */
#define PSIO_CHECK_INPUT	2	/* see if input queue is non-empty */
#define PSIO_GET_TAG		3	/* get next tag in input queue */
#define PSIO_PEEK_TAG		4	/* leave next tag in input queue */


#define	psio_getc(p)	(--(p)->cnt>=0? ((int)*(p)->ptr++): \
			    (psio_setblockok(p), psio_filbuf(p)))
/*
 * psio_pgetc is like psio_getc except that the result of the "getc" is
 * assigned to "dest", and if the operation needs to pause, "pausecode" is
 * executed first.
 *
 * The pause code is executed every time the buffer is emptied.  An attempt
 * to refill the buffer is made before the pause code is executed, so that
 * the pause code can determine if there is more input available to the
 * client.
 */
#define psio_pgetc(p, dest, pausecode) {				\
    if (--(p)->cnt >= 0)						\
	(dest) = *(p)->ptr++ & 0377;					\
    else								\
	while (1) {							\
	    psio_clearblockok(p);					\
	    if (psio_filbuf(p) >= 0) {					\
		p->cnt++;						\
		p->ptr--;						\
	    }								\
	    pausecode;							\
	    dest = psio_getc(p);					\
	    if ((int)dest >= 0 || !psio_error(p) || errno != EWOULDBLOCK)\
		break;							\
	    (p)->flag &= ~PSERR;					\
	}								\
}

/*
 * psio_pgetc_nb is like psio_pgetc except that it tries to fill
 * the buffer before before pausing -- useful with nonblocking IO
 */
#define psio_pgetc_nb(p, dest, pausecode) {				\
    if (--(p)->cnt >= 0)						\
	(dest) = *(p)->ptr++ & 0377;					\
    else								\
	while (1) {							\
	    psio_clearblockok(p);					\
	    dest = psio_filbuf(p);					\
	    if ((int)dest >= 0 || (!psio_error(p) && !psio_blocked(p)))	\
		break;							\
	    (p)->flag &= ~PSERR;					\
	    pausecode;							\
	}								\
}

#define psio_putc(c,f)		(--(f)->cnt >= 0 ? (int)(*((f)->ptr)++ = (unsigned char) (c))  \
						 : psio_flushbuf(c,f))
#define psio_flush_nb(p)	(psio_clearblockok(p), psio_flush(p))
/*
 * psio_pputc is like psio_putc except that if the operation needs
 * to pause, "pausecode" is executed first.
 */
#define psio_pputc(c, f, pausecode) {				\
    if (--(f)->cnt >= 0)					\
	*((f)->ptr)++ = (unsigned char) (c);			\
    else							\
	while (1) {						\
	    psio_flush_nb(f);					\
	    pausecode;						\
	    if (psio_putc(c, f) >= 0 || psio_error(f))		\
		break;						\
	}							\
}

#define	psio_eof(p)		(((p)->flag&PSEOF)!=0)
#define	psio_error(p)		(((p)->flag&PSERR)!=0)
#define	psio_fileno(p)		((p)->file)
#define	psio_clearerr(p)	(void) ((p)->flag &= ~(PSERR|PSEOF))
#define psio_availinputbytes(p)	((p)->cnt)
#define psio_availoutputbytes(p)((p)->cnt)
#define psio_bytesoutput(p)	((p)->bufsiz - (p)->cnt)
#define psio_inputbytes(p)	((p)->bufsiz - (p)->cnt)
#define psio_assoc(p,f)		((p)->assoc.outputside = (f))
#define psio_getassoc(p)	((p)->assoc.outputside)
#define psio_setnexttoken(p,n)	((p)->assoc.next_user_token = (n))
#define psio_getnexttoken(p)	((p)->assoc.next_user_token++)
#define psio_dropbuf(f) 	((f)->cnt = 0)
#define psio_isstringfile(f)	((f)->flag & PSSTRG)
#define psio_readable(f)	(((f)->flag & (PSREAD|PSEOF|PSERR)) == PSREAD)
#define psio_writeable(f)	(((f)->flag & (PSWRITE|PSERR)) == PSWRITE)
#define psio_needsflush(f)	((f)->ptr > (f)->base)
#define psio_blocked(f)		((f)->flag & PSBLOCKED)
#define psio_setblocked(f)	((f)->flag |= PSBLOCKED)
#define psio_clearblocked(f)	((f)->flag &= ~PSBLOCKED)
#define psio_blockok(f)		((f)->flag & PSBLOCKOK)
#define psio_setblockok(f)	((f)->flag |= PSBLOCKOK)
#define psio_clearblockok(f)	((f)->flag &= ~PSBLOCKOK)
#define psio_nonblock(f)	((f)->flag & PSNONBLOCK)
#define psio_setnonblock(f)	((f)->flag |= PSNONBLOCK)
#define psio_clearnonblock(f)	((f)->flag &= ~PSNONBLOCK)
#define psio_outblocked(f)	((f)->flag & PSOUTBLOCKED)
#define psio_setoutblocked(f)	((f)->flag |= PSOUTBLOCKED)
#define psio_clearoutblocked(f)	((f)->flag &= ~PSOUTBLOCKED)
#define psio_linebuf(f)		((f)->flag & PSLINEBUF)
#define psio_setlinebuf(f)	((f)->flag |= PSLINEBUF)
#define psio_clearlinebuf(f)	((f)->flag &= ~PSLINEBUF)
#define psio_dnimode(f)		((f)->flag & PSDNI)
#define psio_setdnimode(f)	((f)->flag |= PSDNI)
#define psio_cleardnimode(f)	((f)->flag &= ~PSDNI)

EXTERN_FUNCTION( PSFILE *psio_open,	(char *name,   char *mode) );
EXTERN_FUNCTION( PSFILE *psio_fdopen,	(int   fd,     char *mode) );
EXTERN_FUNCTION( PSFILE *psio_sopen,	(unsigned char *string, int   length, char *mode) );
EXTERN_FUNCTION( int    psio_close,	(PSFILE *psiobuf) );
EXTERN_FUNCTION( int	psio_flush,	(PSFILE *file) );
EXTERN_FUNCTION( int	psio_flushbuf,	(unsigned char c, PSFILE *file) );
EXTERN_FUNCTION( int	psio_read,	(unsigned char *dest, int size, int n, PSFILE *file) );
EXTERN_FUNCTION( int	psio_write,	(unsigned char *src, int size, int n, PSFILE *file) );
EXTERN_FUNCTION( int	psio_ungetc,	(int c, PSFILE *file) );


extern PSFILE     *psio_stdin;
extern PSFILE     *psio_stdout;
extern PSFILE     *psio_stderr;
extern int         psio_bufsiz;
extern long	   psio_bufspace;
extern int	   psio_bufcount;
#endif
