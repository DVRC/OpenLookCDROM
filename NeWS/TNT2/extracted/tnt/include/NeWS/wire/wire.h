/*
 * @(#)wire.h 1.32 91/02/21 Copyright 1990-91 Sun Microsystems
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

#ifndef _WIRE_INCLUDED_

#define _WIRE_INCLUDED_

#include <NeWS/c_varieties.h>
#include <sys/types.h>
#include <NeWS/psmacros.h>

#include <NeWS/wire/wire_types.h>

/**********************\
   Published Types
\**********************/

typedef caddr_t	wire_RefAny;


/**********************\
   External Functions
\**********************/

/* In alphabetic order.  See the reference manual for functional groupings. */

EXTERN_FUNCTION( boolean	wire_AddFileHandler,	(FILE *fp, wire_FileHandler handler, wire_RefAny data) );
		/* Tells the notifier to call handler with fp and data as
		   arguments whenever there is input available on FILE
		   *fp.  Returns FALSE if handler is (should never be
		   NULL) or FP already has a handler; otherwise, returns
		   TRUE.  File: connection.c */

EXTERN_FUNCTION( boolean	wire_AllocateNamedTags,	(int **tag_array) );
		/* This takes an array of pointers to integers which
		   represent tags, and fills them in with allocated tags. 
		   File: tag.c */

EXTERN_FUNCTION( boolean	wire_AllocateNamedTokens, (wire_Wire wire, int **tag_array) );
		/* This is just like AllocateNamedTags only it allocates
		   named tokens on a particular wire. 
		   File: token.c */

EXTERN_FUNCTION( int	wire_AllocateTags,		(int n) );
		/* Allocate N tags, return the first one. 
		   File: tag.c */

EXTERN_FUNCTION( int	wire_AllocateTokens,	(wire_Wire wire, int n) );
		/* Allocate N tokens on a particular wire, return
		   the first one. File: token.c */

EXTERN_FUNCTION( boolean	wire_Close,	(wire_Wire wire) );
		/* Closes the connection associated with WIRE. 
		   File: connection.c */

EXTERN_FUNCTION( wire_Wire 	wire_Current,	(_VOID_) );
		/* Returns the current wire. File: connection.c */

EXTERN_FUNCTION( caddr_t	wire_Data,	(wire_Wire wire) );
		/* Returns the connection client data. File: connection.c */

EXTERN_FUNCTION( boolean	wire_DeallocateTokens,	(wire_Wire wire, int first_token, int n) );
		/* Deallocates N contiguous tokens starting from
		   token first_token. */

EXTERN_FUNCTION( void	wire_DeathDefault,	(_VOID_) );
		/* The default death problem handler. File: connection.c */

EXTERN_FUNCTION( boolean	wire_Disable,	(wire_Wire wire) );
		/* Prevents any notifies from occurring on WIRE. 
		   File: connection.c */

EXTERN_FUNCTION( void	wire_DiseaseDefault,	(_VOID_) );
		/* The default disease problem handler. File: connection.c */

EXTERN_FUNCTION( boolean wire_DrainSync, (wire_Wire wire) );

EXTERN_FUNCTION( boolean	wire_Enable,	(wire_Wire wire) );
		/* Allows notifies to occur on WIRE. File: connection.c */

EXTERN_FUNCTION( void	wire_EnterNotifier,	(_VOID_) );
		/* Enter a notifier loop, looping until the matching
		   ExitNotifier() is called. File: connection.c */

EXTERN_FUNCTION( char	*wire_ErrorString,	(_VOID_) );
		/* Returns the string associated with the current value
		   of wire_Errno. File: error.c */

EXTERN_FUNCTION( void	wire_ExitNotifier,	(_VOID_) );
		/* Terminate the current EnterNotifier() loop. 
		   File: connection.c */

EXTERN_FUNCTION (boolean wire_ExpectSync, (wire_Wire wire, void (*notifier)()) );

EXTERN_FUNCTION( void	wire_GobbleAny,		(_VOID_) );
		/* This simple procedure is meant for cleaning data off of 
		   the current connection.  It is meant to be used inside of
		   a notifier callback procdure. No error checking.   
		   File: util.c */

EXTERN_FUNCTION( boolean	wire_InSync,	(wire_Wire wire) );
		/* Returns TRUE if the wire is responding to a synchronised
		   request from PS, which means that PS code sent now may be
		   executed before PS code sent earlier. File: synch.c */

EXTERN_FUNCTION( boolean	wire_Notify,	(struct timeval *timeout) );
		/* Reads a tag from one of the active (enabled)
		   connections, and calls the tag proc associated with
		   the tag.  This returns TRUE of a notification
		   occurred, and FALSE if one didn't. File: connection.c */

EXTERN_FUNCTION( wire_Wire	wire_Open,	(char *host) );
		/* Returns a wire for an server connection to HOST.
		   Returns wire_INVALID_WIRE and sets wire_Errno if the
		   connection cannot be made. File: connection.c */

EXTERN_FUNCTION( void	wire_Perror,		(char *str) );
		/* Prints STR followed by ':' followed by the error
		   string associated with the current value of wire_Errno. 
		   File: error.c */

EXTERN_FUNCTION( boolean	wire_Problems,	(wire_Wire wire, wire_Handler death, wire_Handler disease, wire_Handler unknowntag) );
		/* This arranges to call DEATH when a connection dies,
		   DISEASE when there is an a protocol error on a
		   connection, and UNKNOWNTAG, when a tag which has no
		   callback or which is reserved is seen on a connection.
		   File: connection.c */

EXTERN_FUNCTION( PSFILE	*wire_PSinput,		(wire_Wire wire) );
		/* Returns the PSFILE input side of the connection, or
		   NULL if WIRE is not valid. File: connection.c */

EXTERN_FUNCTION( PSFILE	*wire_PSoutput,		(wire_Wire wire) );
		/* Returns the PSFILE output side of the connection, or
		   NULL if WIRE is not valid. File: connection.c */

EXTERN_FUNCTION( int	wire_ReadTag,		(_VOID_) );
EXTERN_FUNCTION( int	wire_ReadInt,		(_VOID_) );
EXTERN_FUNCTION( float	wire_ReadFloat,		(_VOID_) );
EXTERN_FUNCTION( char    *wire_ReadString,	(char *str) );
		/* These simple procedures for reading data off of the current
		   connection.  They are meant to be used inside of a notifier
		   callback procdure. No error checking. File: util.c  */

EXTERN_FUNCTION( boolean	wire_RegisterTag,	(int tag, wire_Handler proc, wire_RefAny data) );
		/* Arranged to call PROC with TAG and DATA as arguments
		   whenever TAG is seen on a wire. File: tag.c */

EXTERN_FUNCTION( boolean	wire_RegisterToken,	(wire_Wire wire, int token, wire_RefAny obj) );
		/* Associate an object with a wire/token pair. */

EXTERN_FUNCTION( boolean	wire_RemoveFileHandler,	(FILE *fp) );
		/* Tells the notifier to stop looking for input from
		   FILE *fp.  This returns FALSE if FP does not have
		   a file handler to remove; otherwise returns TRUE. 
		   File: connection.c */
		   
EXTERN_FUNCTION( boolean	wire_ReserveTags,	(int largest) );
		/* Reserve tags up to and including LARGEST for uses
		   other than with dynamic tags. File: tag.c */

EXTERN_FUNCTION( boolean	wire_ReserveTokens,	(wire_Wire wire, int largest) );
		/* ReserveTokens does the same thing as ReserveTags
		   only for tokens on a particular wire. File: token.c */

EXTERN_FUNCTION( boolean	wire_SetCurrent,	(wire_Wire wire) );
		/* Sets the current wire to WIRE, if it's a valid wire. 
		   File: connection.c */

EXTERN_FUNCTION( boolean	wire_SetData,		(wire_Wire wire, wire_RefAny data) );
		/* Sets the client data for the connection. 
		   File: connection.c */

EXTERN_FUNCTION( boolean	wire_SkipEvent,		(_VOID_) );
		/* Skip an entire event in the current wire.  Returns FALSE
		   iff the wire is somehow invalid.  May be called by death
		   or disease */

EXTERN_FUNCTION( caddr_t	wire_TagData,		(int tag) );
		/* Return the tag data specifed by RegisterTag(). 
		   File: tag.c */

EXTERN_FUNCTION( wire_Handler	wire_TagProc,		(int tag) );
		/* Returns the tag proc specified by RegisterTag(). 
		   File: tag.c */ 

EXTERN_FUNCTION( caddr_t	wire_TokenData,		(wire_Wire wire, int token) );

EXTERN_FUNCTION( void	wire_UnknownTagDefault,		(_VOID_) );
		/* The default unknowntag problem handler. File: connection.c */
		
EXTERN_FUNCTION( boolean	wire_Valid,		(wire_Wire wire) );
		/* Returns TRUE if WIRE is a valid wire. File: connection.c */

EXTERN_FUNCTION( boolean	wire_WouldNotify,	(wire_Wire wire) );
		/* Returns TRUE if the Notify() would notify right away
		   without blocking. File: connection.c */



/************************\
   Constants and Macros
\************************/

#define wire_INVALID_WIRE	((wire_Wire) -1)
#define wire_ALLWIRES		((wire_Wire) FD_SETSIZE)
#define wire_MAXWIRES		(FD_SETSIZE)
#define wire_WireToInt(w)	((int) w)
#define wire_IntToWire(i)	((wire_Wire) i)


/**********************\
   External Variables
\**********************/

extern int	wire_Errno;  	


/**********************\
    Error Numbers
\**********************/

#define wire_EUNKNOWNHOST	1
		/* Attempt to connect to a server on an unknown host. */

#define wire_ENOSUCHSERVER	2
		/* An attempt to connect to a server failed because there
		   was no server running at the specified port on that
		   host. */

#define wire_EBADWIRE		3
		/* Tried an operation on an invalid connection, i.e.,
		   either wire was out of range or it referred to an
		   unopen connection. */

#define wire_ECONNECTIONDIED	4
		/* The server connection died for some unknown reason. */

#define wire_ENOWIRES		5
		/* No currently open wires. */

#define wire_ETIMEOUT		6
		/* Notify timed out. */

#define wire_EINTR		7
		/* Notify was interrupted. */

#define wire_ERANGECHECK	8
		/* Token or tag out of range. */

#define wire_EBADRESERVE	9
		/* An illegal attempt to reserve tags/tokens after some
		   were already allocated. */

#define wire_EFILEINUSE		10
		/* An attempt to add a file handler for a file which
		   either already has AddFileHandler or is a currently
		   open wire (connection to a server). */

#define wire_ENOFILEHANDLER	11
		/* An attempt to remove a nonexistant file handler. */

#define wire_ECONNECTIONREFUSED	12
		/* Connection was refused by server due to net security
		   violations (most likely). */

#endif
