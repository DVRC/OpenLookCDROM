/*
 * @(#)wire_private.h 1.13 91/02/21 Copyright 1990-91 Sun Microsystems
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

#ifndef DEBUG
#  define assert(b) 0
#else
#  define assert(b) (!(b) ? (fprintf(stderr, "Assertion failed: b, at line %d in %s\n", __LINE__, __FILE__), abort()) : 0)
#endif


#define Allocate(type)	(type *) malloc(sizeof (type)) 	/* for code readability */

extern char	*sprintf();				/* to shut up lint */

extern boolean	wire_InvokeTagProc();

extern void	wire_SyncInit(/* wire */);

/* Connection table.  The connection table is used for connections to
   servers and for simple file handlers.  All connections have a client
   data field.

   When it's a server connection, the table contains a pointer to the
   psio input file pointer, which in turn contains a pointer to the
   corresponding output side.  This also contains three function pointers
   to be called when certain events occur on the wire.  Death is called
   when the connection has terminated unexpectedly for some reason.
   Disease is called when something other than a tag is the first thing
   in the wire.  And unknowntag is called whenever a tag which either has
   no callback or wasn't registered, or is a reserved tag, is read from
   the wire.

   When it's a file handler it contains a pointer to the stdio FILE,
   and the routine (the handler) to call when there is input available
   on the wire.

   wire_Wire's are used to index this table for speed.  The wires
   are actually the file descriptors (psio_fileno() of the psin field,
   and fileno() of the fp field). */

#define WIRE_TYPE	1
#define FILE_TYPE	2

struct wire_Connection {
	char		type;
	char		sync_level;
	char		update_bfd;
	char		expected_syncs;
	wire_RefAny	data;

	struct token_list {
		long    *free_list;
		short	list_size;
		short	last_alloc;
		short	reserved;
		wire_RefAny	*objects;	/* registered objects */
		short	nobjects;		/* number allocated slots */
	} t_list;

	union {
		struct {
			PSFILE	*psin;
			void	(*death)();
			void	(*disease)();
			void	(*unknowntag)();
		} C_wire;
		struct {
			FILE	*fp;
			void	(*handler)();
		} C_file;
	} ctsd;		/* Connection Type Specific Data */
};

#define c_file	ctsd.C_file
#define c_wire	ctsd.C_wire

extern struct wire_Connection *wire_ConnectionTable[];
