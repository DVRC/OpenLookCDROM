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

#define ZERO_RELATIVE_TAG(tag) tag-*tagarray[0]
#define TOKEN_FROM_TAG(tag) tokenarray[tag-*tagarray[0]]


	/* Prototypes for all generated callback routines */


	/*
	 *    Callback Routine for: 
	 *
	 *	window1 (Notifier)
	 */

extern void windowquit (int tag, caddr_t data);

	/*
	 *    Callback Routine for: 
	 *
	 *	InsertButton (Notifier)
	 */

extern void InsertItemHandler (int tag, caddr_t data);

	/*
	 *    Callback Routine for: 
	 *
	 *	DeleteButton (Notifier)
	 */

extern void DeleteItemHandler (int tag, caddr_t data);

	/*
	 *    Callback Routine for: 
	 *
	 *	ToDoList (Notifier)
	 */

extern void ChooseItemHandler (int tag, caddr_t data);

	/*
	 *    Object number definitions
	 */

const WINDOW1 = 0;
const INSERTBUTTON = 1;
const DELETEBUTTON = 2;
const TODOLIST = 3;

	/*
	 *    Operational Functions
	 */

void Allocate_todo_min_Tags ();	/* Allocate the tokens/tags for the callbacks */
int runtodo_min (void);	/* Load PostScript Interface and Server Callbacks */


#endif
