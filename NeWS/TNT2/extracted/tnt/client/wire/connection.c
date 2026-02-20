/*
 * @(#)connection.c 1.31 91/02/21 Copyright 1990-91 Sun Microsystems
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
#include <errno.h>
#include <stdio.h>
#include <ctype.h>
#include <sys/time.h>
#include <sys/ioctl.h>

#ifdef SYSVREF
#  ifdef INTERLANTCP
#    include <interlan/il_types.h>
#    include <interlan/netdb.h>
#    include <interlan/in.h>
#  else
#    include <sys/types.h>
#  endif
#else
#  include <sys/types.h>
#  include <netdb.h>
#  include <netinet/in.h>
#endif

#include "wire.h"
#include "wire_private.h"
#include "connection_cps.h"

struct wire_Connection *wire_ConnectionTable[wire_MAXWIRES] = {0};

#define call_death(w)		\
	((*wire_ConnectionTable[w]->c_wire.death)(w), (void) wire_Close(w))
#define call_disease(w)		\
	((*wire_ConnectionTable[w]->c_wire.disease)(w))
#define call_unknowntag(w, tag)	\
	((*wire_ConnectionTable[w]->c_wire.unknowntag)(w, tag))

#define valid_wire(w)	((w) >= 0 && (w) <= max_valid_wire && \
			 (wire_ConnectionTable[(w)] != NULL) && \
			 (wire_ConnectionTable[(w)]->type == WIRE_TYPE))
#define valid_fd(fd)	((fd) >= 0 && (fd) <= max_enabled_fd)
#define CHECK_WIRE(w)	\
	if (!valid_wire(w)) { \
		wire_Errno = wire_EBADWIRE; \
		return FALSE; \
	}

int	wire_Errno;

static wire_Wire	wire_CurrentWire;
static wire_Wire	max_valid_wire = -1;

static void		call_file_handler();

extern char		*getenv();

/* Given a hostname, produce a string which can be parsed by the
   ps_open_server() routine.  Returns NULL if there is an error, and sets
   wire_Errno appropriately. */

#define DEFAULT_SERVER_PORT	2000

static char *
make_newshoststring(hostname)
char	*hostname;
{
	static char		server_string[128];
	char			host[128];
	register struct hostent	*hp;
	u_int			port;
	u_long			hostnum;
	
	/* Check NEWSSERVER style.  2173708678.2000;flam. */
	if (sscanf(hostname, "%lu.%u;%s", &hostnum, &port, host) != 3) {
		/* Check for DISPLAY style.  flam:0. */
		if (sscanf(hostname, "%[^:]:%u", host, &port) != 2) {
			strcpy(host, hostname);
			port = DEFAULT_SERVER_PORT;
		} else
			port += DEFAULT_SERVER_PORT;
		if ((hp = gethostbyname(host)) == NULL) {
			wire_Errno = wire_EUNKNOWNHOST;
			return NULL;
		}
		(void) sprintf(server_string, "%lu.%u;%s\n",
			       ntohl(*(u_long *)hp->h_addr), port,
			       host);
	} else
		strcpy(server_string, hostname);

	return server_string;
}

/* Open a connection to a NeWS server.  If server is NULL, check
   the NEWSSERVER environment variable.  If if exists, use it,
   otherwise, look for DISPLAY.  If no DISPLAY, use current host
   with default port 2000.

   If server is not NULL then it could be a hostname, a NEWSSERVER
   style string, or a DISPLAY style string.

   ps_open_server(server) uses the the default port of the server
   running on the local machine.

   Once we have the host and port, we try the connect.  If this fails,
   wire_Errno contains the reason for the error, and wire_INVALID_WIRE is
   returned.  Otherwise a valid wire_Wire is returned.

   This maintains max_valid_wire. */

static void
null_proc()
{
}

wire_Wire
wire_Open(server)
char	*server;
{
	register int		i;
	register PSFILE		*psf;
	struct wire_Connection	*cp;
	int			saved_wire = wire_CurrentWire;

	if (server == NULL)
		server = getenv("NEWSSERVER");
	if (server == NULL)
		server = getenv("DISPLAY");
	if (server != NULL)
		if ((server = make_newshoststring(server)) == NULL)
			return wire_INVALID_WIRE;

	if ((psf = ps_open_server(server)) == NULL) {
		wire_Errno = wire_ENOSUCHSERVER;
		return wire_INVALID_WIRE;
	}

	i = psio_fileno(psf);
	assert(wire_ConnectionTable[i] == NULL);

	if (i > max_valid_wire)
		max_valid_wire = i;

	cp = wire_ConnectionTable[i] = Allocate(struct wire_Connection);
	bzero((char *) cp, sizeof (struct wire_Connection));
	cp->update_bfd = 0;
	cp->type = WIRE_TYPE;
	cp->c_wire.psin = psf;
	(void) wire_Enable(i);
	(void) wire_SetCurrent(i);
	
	{
		int	success = 0;

		wire_validate_connection(1, &success);
		if (success == 0) {
			wire_Close(i);
			wire_Errno = wire_ECONNECTIONREFUSED;
			if (!wire_SetCurrent(saved_wire))
				wire_CurrentWire = wire_INVALID_WIRE;
			return wire_INVALID_WIRE;
		}
	}

	(void) wire_Problems(i, wire_DeathDefault,
			     wire_DiseaseDefault, wire_UnknownTagDefault);
	wire_SyncInit(wire_CurrentWire);

	return wire_CurrentWire;
}

/* Close a connection.  This must remove the wire from the selection
   mask (with Disable), make the wire the current connection, call
   ps_close_PostScript() which use PostScript and PostScriptInput,
   and free the table entry.  If the connection being closed is the
   current connection, the current connection is made invalid.  This
   returns TRUE if success and FALSE if the connection is invalid.

   This maintains max_valid_wire. */

boolean
wire_Close(w)
wire_Wire	w;
{
	register boolean	is_current;
	register wire_Wire	save = wire_CurrentWire;

	if (w == wire_ALLWIRES) {
		boolean	success = TRUE;

		for (w = 0; w <= max_valid_wire; w++)
			if (valid_wire(w) && !wire_Close(w))
				success = FALSE;
		return success;
	}

	CHECK_WIRE(w);		/* returns if not a valid wire */
	save = wire_CurrentWire;
	is_current = (w == wire_CurrentWire);

	(void) wire_Disable(w);
	(void) wire_SetCurrent(w);
	ps_close_PostScript();
	free((char *) wire_ConnectionTable[w]);
	wire_ConnectionTable[w] = NULL;

	if (w == max_valid_wire) {
		while (--w >= 0 && wire_ConnectionTable[w] == NULL)
			;
		max_valid_wire = w;
	}


	if (!is_current)
		(void) wire_SetCurrent(save);

	return TRUE;
}

/* Returns TRUE if W is a valid wire. */

boolean
wire_Valid(w)
wire_Wire	w;
{
	return valid_wire(w);
}

/* Sets the current connection to W.  This means all subsequent
   cps calls will use this connection until somebody else comes
   along and sets the current selection to something else.  This
   returns TRUE if it succeeds (namely if W is a valid wire) and
   FALSE otherwise. */

boolean
wire_SetCurrent(w)
wire_Wire	w;
{
	register struct wire_Connection	*cp;

	CHECK_WIRE(w);		/* returns if not a valid wire */

	if (w != wire_CurrentWire) {
		cp = wire_ConnectionTable[w];
		PostScriptInput = cp->c_wire.psin;
		PostScript = psio_getassoc(cp->c_wire.psin);
		wire_CurrentWire = w;
	}

	return TRUE;
}

/* Returns the current wire. */

wire_Wire
wire_Current()
{
	return wire_CurrentWire;
}

/* Sets the client data field for the connection.  Returns FALSE if
   W is not valid, TRUE otherwise. */

boolean
wire_SetData(w, data)
wire_Wire	w;
wire_RefAny	data;
{
	CHECK_WIRE(w);		/* returns if not a valid wire */
	wire_ConnectionTable[w]->data = data;

	return TRUE;
}

/* Returns the client data, or NULL if the connection is not valid.
   I know it's possible that the client data is NULL and so there is
   no way to tell the difference between a NULL piece of data and an
   invalid wire, but, well, that's what wire_Valid() is for. */

wire_RefAny
wire_Data(w)
wire_Wire	w;
{
	if (!valid_wire(w)) {
		wire_Errno = wire_EBADWIRE;
		return NULL;
	}
	return wire_ConnectionTable[w]->data;
}

static fd_set	enabled_mask;		/* fds for enabled connections */
static int	n_enabled_fds = 0;	/* number of enabled fds */
static int	max_enabled_fd = -1;	/* maximum enabled fd */
static fd_set	buffered_mask;		/* fds representing nonempty buffers */
static int	n_buffered_fds = 0;	/* num of fds set in buffered_mask */

/* Routine to keep max_enabled_fd up to date. */
static
update_max_enabled_fd(w, setit)
wire_Wire	w;
boolean		setit;
{
	if (setit == FALSE) {
		n_enabled_fds -= 1;
		if (w == max_enabled_fd) {
			register int	fd = max_enabled_fd - 1;

			while (fd >= 0 && !FD_ISSET(fd, &enabled_mask))
				fd -= 1;
			max_enabled_fd = fd;
		}
	} else {
		n_enabled_fds += 1;
		if (w > max_enabled_fd)
			max_enabled_fd = w;
	}
}

#define DISABLE_IT	1
#define ENABLE_IT	2
#define FIGURE_IT_OUT	3

/* Enable a connection.  Returns TRUE if succeeded, FALSE if W is not
   valid.  Also maintains the number of active connections and the maximum
   enabled fd. */

boolean
wire_Enable(w)
wire_Wire	w;
{
	if (w == wire_ALLWIRES) {
		boolean	success = TRUE;

		for (w = 0; w <= max_valid_wire; w++)
			if (valid_wire(w) && !wire_Enable(w))
				success = FALSE;
		return success;
	} else
		CHECK_WIRE(w);		/* returns if not a valid wire */

	if (!FD_ISSET(w, &enabled_mask)) {
		FD_SET(w, &enabled_mask);
		update_max_enabled_fd(w, TRUE);
		update_buffered_fds(w, FIGURE_IT_OUT);
	}

	return TRUE;
}

/* Disable a connection.  Returns TRUE if succeeded, FALSE if W is not
   valid.  Also maintains the number of active connections and the
   maximum enabled fd. */

boolean
wire_Disable(w)
wire_Wire	w;
{
	if (w == wire_ALLWIRES) {
		boolean	success = TRUE;

		for (w = 0; w <= max_valid_wire; w++)
			if (valid_wire(w) && !wire_Disable(w))
				success = FALSE;
		return success;
	} else
		CHECK_WIRE(w);		/* returns if not a valid wire */

	if (FD_ISSET(w, &enabled_mask)) {
		FD_CLR(w, &enabled_mask);
		update_max_enabled_fd(w, FALSE);
		update_buffered_fds(w, DISABLE_IT);
	}

	return TRUE;
}

/* Returns TRUE if W is enabled, FALSE otherwise.  Note, this also
   returns FALSE if the connection is not valid.  So if you have
   any reason to believe the connection is not valid, you can check
   with wire_Valid(). */

boolean
wire_Enabled(w)
wire_Wire	w;
{
	if (w == wire_ALLWIRES) {
		for (w = 0; w <= max_valid_wire; w++)
			if (valid_wire(w))
				if (!wire_Enabled(w))
					return FALSE;
		return TRUE;
	}
	return (valid_wire(w) && FD_ISSET(w, &enabled_mask));
}

/* Skip an entire event in the current wire.  This reads and ignores an
   entire event OR a partial event in the current wire.  This can be used
   by disease, when something other than a tag appears in the input
   queue, or by unknowntag, when a tag appears which should just be
   ignored.

   This returns FALSE if the current wire is somehow invalid (e.g., it's
   just been closed), returns TRUE if it succeeds.  It may call death
   if the connection dies in the middle, in which case it returns FALSE
   as well. */

boolean
wire_SkipEvent()
{
	int	dummy, status;

	CHECK_WIRE(wire_CurrentWire);	/* returns if not a valid wire */
	do
		ps_skip_input_value();
	while ((status = ps_check_input()) > 0 &&
	       (status = ps_peek_tag(&dummy)) == 0);
	if (status == -1) {
		call_death(wire_CurrentWire);
		wire_Errno = wire_ECONNECTIONDIED;
		return FALSE;
	}
	return TRUE;
}

void
wire_DeathDefault(w)
wire_Wire	w;
{
	(void) fprintf(stderr, "Connection died on wire %d\n", w);
}

static void
pp_char(c, fp)
int	c;
FILE	*fp;
{
    if (c & 0200) {
	fprintf(fp, "M-");
	c &= 0177;
    }
    if ((c < ' ' || c == '\177') && c != '\n') {
	putc('^', fp);
	c = (c == '\177') ? '?' : c + '@';
    }
    putc(c, fp);
}

void
wire_DiseaseDefault(w)
wire_Wire	w;
{
    int	status, dummy, c;

    (void) fprintf(stderr, "Tag expected but not found on wire %d\n", w);
    do {
	c = psio_getc(PostScriptInput);
	pp_char(c, stderr);
    } while ((status = ps_check_input()) > 0 &&
	     (status = ps_peek_tag(&dummy)) == 0);
    (void) wire_SkipEvent();
}

void
wire_UnknownTagDefault(w, tag)
wire_Wire	w;
{
	(void) fprintf(stderr, "Tag %d seen on wire %d has no callback.\n",
		       tag, w);
	(void) wire_SkipEvent();
}

/* Sets the callbacks.  The callbacks are called with the guilty wire as
   an argument.  A function argument of NULL means leave the associated
   callback unchanged. This returns FALSE when wire is not valid, or TRUE
   otherwise. */

boolean
wire_Problems(w, death, disease, unknowntag)
wire_Wire	w;
wire_Handler	death, disease, unknowntag;
{
	if (w == wire_ALLWIRES) {
		for (w = 0; w <= max_valid_wire; w++)
			if (valid_wire(w))
				wire_Problems(w, death, disease, unknowntag);
		return TRUE;
	} else
		CHECK_WIRE(w);		/* returns if not a valid wire */
	if (death != NULL)
		wire_ConnectionTable[w]->c_wire.death = death;
	if (disease != NULL)
		wire_ConnectionTable[w]->c_wire.disease = disease;
	if (unknowntag != NULL)
		wire_ConnectionTable[w]->c_wire.unknowntag = unknowntag;

	return TRUE;
}

/* Flushs all the connections. */

static void
flush_connections()
{
	register int	i, max;

	max = max_valid_wire;
	for (i = 0; i <= max; i++)
		if (valid_wire(i))
			psio_flush(psio_getassoc(wire_ConnectionTable[i]->c_wire.psin));
}

/* This OR's the two fd_set's together and returns the number of bits
   set in the result.  This only enables the first N fd_mask's of the bit
   masks, where N is the enough to cover all the currently enabled
   connections. */

static int
OR_fd_sets(dest, src)
fd_set	*dest, *src;
{
	register int		n = 1 + (max_enabled_fd / NFDBITS);
	register fd_mask	*mp1, *mp2;
	register int		bitcount, i, ch;

	mp1 = (fd_mask *) dest;
	mp2 = (fd_mask *) src;
	bitcount = 0;
	while (--n >= 0) {
		ch = (*mp1++ |= *mp2++);
		if (ch != 0) {
			for (i = 0; ch != 0 && i < NFDBITS; i++) {
				bitcount += (ch & 01);
				ch >>= 1;
			}
		}
	}

	return bitcount;
}

/* This makes sure the number of connections with bytes
   still left in the buffer is kept accurate.  Basically,
   if the bit was set, but shouldn't be anymore (because
   the buffer is empty) the count is decremented.  Or,
   if there are bytes in the buffer but there weren't
   before, then the count is incremented. */

update_buffered_fds(fd, how)
int	fd, how;
{
	register int		was_set;
	int			nbytes = 0;
	struct wire_Connection	*cp;

	was_set = (FD_ISSET(fd, &buffered_mask) ? 1 : 0);
	cp = wire_ConnectionTable[fd];
	if (how == FIGURE_IT_OUT) {
		if (cp->type == WIRE_TYPE)
			how = cp->c_wire.psin->cnt +
			      cp->c_wire.psin->protected_size > 0 ?
			      ENABLE_IT : DISABLE_IT;
		else
			how = cp->c_file.fp->_cnt > 0 ?
				ENABLE_IT : DISABLE_IT;
	}

	if (how == ENABLE_IT) {
		FD_SET(fd, &buffered_mask);
		n_buffered_fds += !was_set;
	} else {
		FD_CLR(fd, &buffered_mask);
		n_buffered_fds -= was_set;
	}
	cp->update_bfd = FALSE;
}

/* This procedure processes an event on W.  It is called by wire_Notify().
   It calls the user callback, or calls one of the three problem
   functions.  It updates buffered_mask and n_buffered_fds after it's
   processed the event.  W is passed as an argument, but W is also the
   current wire, if called from Notify, which is currently the only guy
   that calls process_event().

   When the callback routine is envoked, the tag which triggered it will
   have been consumed from the wire input. */

static void
process_event(w)
register wire_Wire	w;
{
	struct wire_Connection	*cp;
	int			tag, status;

	assert(valid_wire(w));
	cp = wire_ConnectionTable[w];
	cp->update_bfd = TRUE;
	if ((status = ps_read_tag(&tag)) == 0)
		call_disease(w);
	else if (status == -1) {
		call_death(w);
		return;
	} else if (!wire_InvokeTagProc(tag))
		call_unknowntag(w, tag);
	if (cp->update_bfd == TRUE)
		update_buffered_fds(w, FIGURE_IT_OUT);
}

/* This routine returns the wire on which the next event is going to take
   place (or -1 if no wire will Notify right now).  This uses a
   round-robin scheduling and an anti-starvation algorithm.  The goal was
   to do this with as few calls to select() as possible since we believe
   that select() is an expensive operation.  Also, we will implement a
   special case check for a single connection with a NULL timeout (which
   means blocking), since we believe that is the 95% case.

   In order to implement the round-robin scheduling, this routine has to
   maintain state between calls.  Some of the state is local to the
   procedure, and some is local to the file.  The routine maintains THE
   NUMBER of connections that are known to have either input in the wire
   (indicated by select) OR input in the corresponding psio buffer, and a
   select() bitmask which indicates WHICH CONNECTIONS those are.  It also
   maintains a separate count and bitmask for those connections which
   are known to have bytes available for reading in their psio buffers.

   Select() is not called as long as that number of connections with input
   immediately available (nfds) is > 0.  Whenever a connection is
   processed, that number is decremented, and the associated bit is
   turned off in the first of the two bitmasks (rmask).  When the number
   is 0, a new select() is performed.  This select is performed even if
   we know there are connections with bytes available in buffers, so that
   we can prevent starvation of the wires which currently don't have bytes
   available but DO have chars on the wire waiting to be read.

   The select is a nonblocking select when we know there are wires with
   buffered data available, and blocking (per the timeout parameter) when
   we know there is no buffered data available.

   REMIND:  For now this does not special case the single connection with
   blocking timeout. */

static int		nselects = 0;
static int		nnotifies = 0;
static wire_Wire	peek_notify = wire_INVALID_WIRE;

static wire_Wire
next_Notify(timeout)
struct timeval	*timeout;
{
	static fd_set	rmask;			/* mask returned from select */
	static int	nfds = 0;		/* numbers of fds with input */
	static int	last_index = -1;	/* last notified wire */
	register int	i, max;
	register struct wire_Connection	**cpp;
	static struct timeval		poll_tv = {0, 0};

	if (peek_notify != wire_INVALID_WIRE)
		return peek_notify;

	nnotifies += 1;
	/* If last_index + 1 > max_enabled_fd and ndfs != 0 then
	   a wire has died or a file handler has been removed since
	   the last time we did a select. */
	if (nfds <= 0 || last_index + 1 > max_enabled_fd) {
		if (n_enabled_fds == 0) {
			wire_Errno = wire_ENOWIRES;
			return wire_INVALID_WIRE;
		}

		/* Make sure buffered fds is accurate.  Any cps
		   call could have invalidated the buffered fds,
		   so we have to make sure they are OK.  The
		   question is, do we have to do this every time
		   or just whenever n_buffered_fds == 0? */

		if (n_buffered_fds == 0) {
		    max = max_valid_wire;
		    for (i = 0; i <= max; i++)
			if (valid_wire(i))
			    update_buffered_fds(i, FIGURE_IT_OUT);
		}

		nselects += 1;
		flush_connections();
		rmask = enabled_mask;
		nfds = select(max_enabled_fd + 1, &rmask, (fd_set *) 0,
			      (fd_set *) 0,
			      (n_buffered_fds == 0) ? timeout : &poll_tv);
		if (nfds == -1 && (errno == EBADF || errno == EINVAL ||
		    errno == EFAULT)) {
			(void) fprintf(stderr, "Internal error %d during select\n", errno);
			abort();
		}
		/* If the select was interrupted BUT we know there are
		   some buffered bytes available, we don't return an
		   error.

		   When the select is NOT interrupted, the returned
		   mask is OR'd with the buffered bytes mask and used
		   in the next stage of the procedure. */
		if (nfds == -1) {
			if (n_buffered_fds == 0) {
				wire_Errno = wire_EINTR;
				return wire_INVALID_WIRE;
			}
			rmask = buffered_mask;
			nfds = n_buffered_fds;
		} else {
			nfds = OR_fd_sets(&rmask, &buffered_mask);
			if (nfds == 0) {
				wire_Errno = wire_ETIMEOUT;
				return wire_INVALID_WIRE;
			}
		}
		last_index = -1;
	}

	/* continue where we left off last time */
	for (i = last_index + 1; i <= max_enabled_fd; i++) {
		if (!FD_ISSET(i, &enabled_mask) ||	/* If disabled or */
		    !FD_ISSET(i, &rmask))		/* nothing in wire */
			continue;			/* or buffer. */
		/* input available */
		nfds -= 1;
		assert(nfds >= 0);
		FD_CLR(i, &rmask);
		break;
	}
	assert(i <= max_enabled_fd);
	last_index = i;

	return (peek_notify = i);
}

/* Notify causes a single tag to be read from one of the active
   connections.  This tag is used as an index into the table of
   registered procedures.  The procedure is then called with the handle
   and registered data as arguments.  Notify has the side-effect of
   setting the current connection so that registered procedures can read
   further arguments from the wire using normal CPS and psio functions.
   If there is no data available on any of the connections, Notify will
   block until some message arrives or the period specified in the
   timeout parameter expires.  This is handled by process_event().

   Notify returns TRUE if there was a notification and FALSE otherwise. */

boolean
wire_Notify(timeout)
struct timeval	*timeout;
{
	register wire_Wire	w;

	w = next_Notify(timeout);
	if (w == wire_INVALID_WIRE)
		return FALSE;
	peek_notify = wire_INVALID_WIRE;
	if (wire_ConnectionTable[w]->type == WIRE_TYPE) {
		(void) wire_SetCurrent(w);
		process_event(w);
	} else
		call_file_handler(w);

	return TRUE;
}

/* WouldNotify does not block and reports whether there are any
   pending messages on any of the active connections. */

boolean
wire_WouldNotify(w)
wire_Wire	w;
{
	if (w == wire_ALLWIRES) {
		struct timeval	tv;

		for (w = 0; w <= max_valid_wire; w++)
			if (valid_wire(w) &&
			    wire_ConnectionTable[w]->update_bfd)
				update_buffered_fds(w, FIGURE_IT_OUT);

		tv.tv_sec = 0;
		tv.tv_usec = 0;
		return (next_Notify(&tv) != wire_INVALID_WIRE);
	} else {
		if (!valid_fd(w)) {
			wire_Errno = wire_EBADWIRE;
			return FALSE;
		}
		if (wire_ConnectionTable[w]->update_bfd)
			update_buffered_fds(w, FIGURE_IT_OUT);
		if (FD_ISSET(w, &buffered_mask))
			return TRUE;
#ifdef FIONREAD
		{
			long	nbytes = 0;


			(void) ioctl(w, FIONREAD, &nbytes);
			if (nbytes > 0)
				return TRUE;
		}
#endif
		return FALSE;
	}
	/* NOTREACHED */
}

static int	RecursiveNotifiers = 0;

void
wire_EnterNotifier()
{
	register int	level = RecursiveNotifiers;

	RecursiveNotifiers += 1;

	while (RecursiveNotifiers > level)
		if (!wire_Notify((struct timeval *) 0)) {
			if (errno == EINTR)
				continue;
			wire_ExitNotifier();
		}
}

void
wire_ExitNotifier()
{
	RecursiveNotifiers -= 1;
}

PSFILE *
wire_PSinput(w)
register wire_Wire	w;
{
	register struct wire_Connection	*cp;

	CHECK_WIRE(w);
	cp = wire_ConnectionTable[w];
	return cp->c_wire.psin;
}

PSFILE *
wire_PSoutput(w)
register wire_Wire	w;
{
	register struct wire_Connection	*cp;

	CHECK_WIRE(w);
	cp = wire_ConnectionTable[w];
	return psio_getassoc(cp->c_wire.psin);
}


/* File handlers. */

boolean
wire_AddFileHandler(fp, handler, data)
register FILE		*fp;
wire_FileHandler	 handler;
wire_RefAny		 data;
{
	register int			fd;
	register struct wire_Connection	*cp;

	fd = fileno(fp);
	if ((cp = wire_ConnectionTable[fd]) != NULL) {
		wire_Errno = wire_EFILEINUSE;
		return FALSE;
	}
	assert(!FD_ISSET(fd, &enabled_mask));
	cp = wire_ConnectionTable[fd] = Allocate(struct wire_Connection);
	cp->type = FILE_TYPE;
	cp->data = data;
	cp->c_file.fp = fp;
	cp->c_file.handler = handler;

	FD_SET(fd, &enabled_mask);
	update_max_enabled_fd(fd, TRUE);

	return TRUE;
}

boolean
wire_RemoveFileHandler(fp)
register FILE	*fp;
{
	register int		fd;
	struct wire_Connection	*cp;

	fd = fileno(fp);
	if ((cp = wire_ConnectionTable[fd]) == NULL) {
		wire_Errno = wire_ENOFILEHANDLER;
		return FALSE;
	}
	FD_CLR(fd, &enabled_mask);
	free((char *) cp);
	wire_ConnectionTable[fd] = NULL;
	update_max_enabled_fd(fd, FALSE);

	return TRUE;
}

static void
call_file_handler(fd)
int	fd;
{
	register struct wire_Connection	*cp;

	cp = wire_ConnectionTable[fd];
	assert(cp != NULL && cp->type == FILE_TYPE);
	(*cp->c_file.handler)(cp->c_file.fp, cp->data);
	update_buffered_fds(fd, FIGURE_IT_OUT);
}
