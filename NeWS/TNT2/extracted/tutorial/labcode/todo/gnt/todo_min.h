#ifndef TODO_MIN_H
#define TODO_MIN_H

/* ----------------------------------------------------------------
 *	A few generally useful macros...
 */

#if !defined(ANSI)

#if  defined(__STDC__)  ||  defined(__cplusplus)
#define	ANSI(stmt)	stmt
#define	TRAD(stmt)
#else
#define	ANSI(stmt)
#define	TRAD(stmt)	stmt
#endif	/* __STDC__ || __cplusplus */

#endif	/* ANSI */


#if !defined(IF_DEBUG)

#if defined(DEBUG)
#define	IF_DEBUG(stmt)	stmt
#else
#define	IF_DEBUG(stmt)
#endif	/* DEBUG */
#endif	/* IF_DEBUG */



	/* Prototypes for all generated callback routines */


	/*
	 *    Callback Routine for: 
	 *
	 *	window1 (Notifier)
	 */

extern void windowquit (int tag, caddr_t data);

	/*
	 *    Object number definitions
	 */

const WINDOW1 = 0;

	/*
	 *    Operational Functions
	 */

void Allocate_todo_min_Tags ();	/* Allocate the tokens/tags for the callbacks */
int runtodo_min (void);	/* Load PostScript Interface and Server Callbacks */


#endif
