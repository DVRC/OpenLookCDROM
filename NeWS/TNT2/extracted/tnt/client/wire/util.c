/*
 * @(#)util.c 1.8 91/02/21 Copyright 1990-91 Sun Microsystems
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

/*
 * These are the ease-of-use procedures that are meant to be used
 * inside of client callbacks.  Each procedure reads different types
 * of data from the wire.
 *
 * Note: These routines are merely wrappers around CPS code, provided
 * for programs that do not want to use the CPS preprocessor.  There is 
 * no error checking, wire validation, or typechecking.  If there is
 * no data on the wire, the routine will block.  If the data is of the
 * wrong type, garbage will be returned and the wire may be left in an
 * undetermined state. The caveat to this is numeric arguments are converted
 * by CPS. (floats to ints, ints to floats, etc)
 *
 */
 
#ifndef PSMACROS_H
#include <NeWS/psmacros.h>		/* standard cdef macros */
#endif
 
int 
wire_ReadTag()  
{
	int tempTag;
	ps_read_tag(&tempTag);
	return tempTag;
}

int 
wire_ReadInt() 
{
	int tempInt;
	pscanf(PostScriptInput,"d", &tempInt);
	return tempInt;
}

float
wire_ReadFloat() 
{
	float tempFloat;
	pscanf(PostScriptInput,"f", &tempFloat);
	return  tempFloat;
}

char *
wire_ReadString(str) 
char *str;
{
	pscanf(PostScriptInput,"s", str);
	return str;
}	

void	
wire_GobbleAny() 
{
	ps_skip_input_value();
}
