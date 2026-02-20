/*
 *	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
 *	Sun design patents pending in the U.S. and foreign countries.
 *	See LEGAL_NOTICE file for terms of the license.
 */

/*
 * Macros and other stubs defined as functions for the Lisp Xview interface 
*/


#include <stdio.h>
#include <xview/xview.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <fcntl.h>
#include <sys/filio.h>
#include <signal.h>


/* macros from x11/Xutil.h */

int
macro_XDestroyImage(ximage)
 XImage *ximage;
{return XDestroyImage(ximage);}

unsigned long
macro_XGetPixel(ximage, x, y)
 XImage *ximage;
 int x,y;
{return XGetPixel(ximage, x, y);}

int
macro_XPutPixel(ximage, x, y, pixel)
 XImage *ximage;
 int x,y;
 unsigned long pixel;
{return XPutPixel(ximage, x, y, pixel);} 

XImage *
macro_XSubImage(ximage, x, y, subimage_width, subimage_height)
 XImage *ximage;
 int x, y;
 unsigned int subimage_width, subimage_height;
{return XSubImage(ximage, x, y, subimage_width, subimage_height);}

int
macro_XAddPixel(ximage, value) 
 XImage *ximage;
 long value;
{return XAddPixel(ximage, value);}

void
lisp_XDrawString(dpy, d, gc, x, y, string, start, end)
  Display *dpy;
  Drawable d;
  GC gc;
  int x, y, start, end;
  char *string;
{
   XDrawString(dpy, d, gc, x, y, string + start, end - start);
}


int lisp_sigio_flag = 0;

/* ARGSUSED */
lisp_sigio_handler(client, sig, when)
  Notify_client client;
  int sig;
  Notify_signal_mode when;
{
  lisp_sigio_flag = 1;
}


int
lisp_setup_sigio_handler(client, fd)
  int fd;
  Notify_client client;
{
  if (fcntl(fd, F_SETFL, fcntl(fd, F_GETFL, 0) | FASYNC) == -1)
    return -1;
  if (fcntl(fd, F_SETOWN, getpid()) == -1)
    return -1;
  notify_set_signal_func(client, lisp_sigio_handler, SIGIO, NOTIFY_ASYNC);
  return(0);
}



void
offset_bcopy(b1, b2, length, offset1, offset2)
 char *b1, *b2;
 int length, offset1, offset2;
{
  bcopy(b1 + offset1, b2 + offset2, length);
}

