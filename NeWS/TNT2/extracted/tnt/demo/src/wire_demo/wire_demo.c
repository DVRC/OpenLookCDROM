/*
 * @(#)wire_demo.c 1.6 91/02/21 Copyright 1990-91 Sun Microsystems
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
 * Sample program to illustrate the proposed NeWS Wire Service.
 * A slider is placed on the framebuffer, and values are notified
 * back to the client. If the slider is dragged to 0, the program
 * terminates.
 */

#include <NeWS/wire.h>
#include "wire_demo_cps.h"

/*
 * Slider callback function.
 */
void
my_slider_handler(tag, data)
int	tag;
caddr_t	data;
{
    /* 
     * Let's assume that the client wants to know the new value of the
     * slider when it changes. He must read it himself in this procedure.
     * The data argument in this case holds the server handle provided to
     * wire_RegisterTag().
     */
    float 	value;
    
    /* Suck the value off the wire */
    value = wire_ReadFloat();
    
    printf("The value of the slider is now %f\n", value);
    
    if  (value == 10.0)  {
	/*
	 * Modify the slider if its value is now 10.0!
	 */
	ps_grow_slider((int) data, 10);
    }
}   /* my_slider_handler() */


/*
 * Quit callback function.
 * Triggered from the Quit window menu item.
 */
void
my_quit_handler(tag, data)
int	tag;
caddr_t	data;
{
    /*
     * Assume that there is no application specific cleanup required.
     */
    wire_ExitNotifier();
}   /* my_slider_handler() */


/*
 * Wire demo main program.
 */
main()
{
    wire_Wire	w;		/* My connection */
    int		slider_tag;	/* Client-side handle */
    int		quit_tag;
    int		slider_token;	/* Server-side handle */
    
    /* Open a connection to your default NeWS server */
    w = wire_Open(NULL);
    
    /*
     * Reserve a set of tokens (1 in this case) by which
     * the client can refer to objects on the server. This will
     * only be necessary if 1) you need to refer to an object after
     * it has been created, and 2) you don't want to provide your
     * own set of names.
     */
    slider_token = wire_AllocateTokens(w, 1);
    
    /*
     * Reserve a set of tags (2 in this case) by which
     * server-based objects can call functions on the client-side.
     * Then register my functions to be called when this tag is received.
     * The registration function also takes an arbitrary client data
     * value, which in this case we choose to use to store the server
     * handle.
     */
    slider_tag = wire_AllocateTags(1);
    wire_RegisterTag(slider_tag, my_slider_handler, (caddr_t) slider_token);
    
    quit_tag = wire_AllocateTags(1);
    wire_RegisterTag(quit_tag, my_quit_handler, (caddr_t) slider_token);
    
    
    /* 
     * Send PS to the server to create a slider on the framebuffer.	
     * THIS IS NOT A FUNCTION PROVIDED BY THE WIRE SERVICE.
     * (Implementation below).
     */
    ps_create_slider(slider_tag, quit_tag, slider_token, 100, 100, 200);
    
    /* 
     * Enter the read/dispatch loop. This function will not return
     * until after wire_ExitNotifier() has been called from inside
     * some callback function -- in this case my_quit_handler()
     */
    wire_EnterNotifier();
    
    /* Close and exit gracefully */
    wire_Close(w);
    exit(0);
}
