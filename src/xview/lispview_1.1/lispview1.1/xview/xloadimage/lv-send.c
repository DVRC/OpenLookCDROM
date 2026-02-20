/* send.c:
 *
 * send an Image to an X pixmap
 *
 * jim frost 10.02.89
 *
 * Copyright 1989, 1990 Jim Frost.  See included file "copyright.h" for
 * complete copyright information.
 */

#include "copyright.h"
#include "xloadimage.h"

unsigned int sendImageToX(disp, scrn, visual, image, index)
     Display      *disp;
     int           scrn;
     Visual       *visual;
     Image        *image;
     Pixel        *index;
{ 
  unsigned int  a, b, newmap, x, y, linelen, ddepth, dpixlen;
  unsigned long plane;
  byte         *pixptr, *destline, *destptr, *bitplane, destmask;
  byte	       *modimageptr;
  XColor        xcolor;
  XGCValues     gcv;
  GC            gc;
  XImage       *ximage;
  Pixmap       pixmap;


  /* ddepth= DefaultDepth(disp, scrn); */
  ddepth = image->depth;
  pixmap= XCreatePixmap(disp, RootWindow(disp, scrn), image->width,
			 image->height, ddepth);
  /* blast the image across
   */

  switch (image->type) {
  case IBITMAP:
    gcv.function= GXcopy;
    gcv.foreground= *(index + 1);
    gcv.background= *index;
    gc= XCreateGC(disp, pixmap, GCFunction | GCForeground | GCBackground,
		  &gcv);
    ximage= XCreateImage(disp, visual, image->depth, XYBitmap, 0, image->data,
			 image->width, image->height, 8, 0);
    ximage->bitmap_bit_order= MSBFirst;
    ximage->byte_order= MSBFirst;
    XPutImage(disp, pixmap, gc, ximage, 0, 0, 0, 0,
	      image->width, image->height);
    XFreeGC(disp, gc);
    break;

  case IRGB:

    /* modify image data to match colormap and pack pixels if necessary
     */

    pixptr= image->data;
    modimageptr = image->data;
    dpixlen = ddepth / 8;
    if(image->pixlen != dpixlen) {  /* Need to convert depth */
	modimageptr = (byte *)lmalloc(image->height * image->width * dpixlen);
    }
    destptr = modimageptr;
	
    for (y= 0; y < image->height; y++)
      for (x= 0; x < image->width; x++) {
	valToMem(*(index + memToVal(pixptr, image->pixlen)),
		 destptr, dpixlen);
	pixptr += image->pixlen;
        destptr += dpixlen;
      }

    /* if the destination depth is not a multiple of 8, then we send each
     * plane as a bitmap because otherwise we would have to pack the pixel
     * data and the XImage format is pretty vague about how that should
     * be done.  this is not as fast as it would be if it were packed but
     * it should be a lot more portable and only slightly slower.
     */

    if (ddepth % 8) {
#ifndef SERVER_HAS_BROKEN_PLANEMASK /* see README */
      gcv.function= GXcopy;
#else
      gcv.function= GXor;
#endif
      gcv.background= 0;
      gc= XCreateGC(disp, pixmap, GCFunction | GCBackground, &gcv);
      linelen= (image->width / 8) + (image->width % 8 ? 1 : 0);
      bitplane= lmalloc(image->height * linelen);
      ximage= XCreateImage(disp, visual, 1, XYBitmap, 0, bitplane,
			   image->width, image->height, 8, 0);
      ximage->bitmap_bit_order= MSBFirst;
      ximage->byte_order= MSBFirst;

      for (plane= 1 << (ddepth - 1); plane; plane >>= 1) {
	pixptr= image->data;
	destline= bitplane;
	for (y= 0; y < image->height; y++) {
	  destmask= 0x80;
	  destptr= destline;
	  for (x= 0; x < image->width; x++) {
	    if (*pixptr & plane)
	      *destptr |= destmask;
	    else
	      *destptr &= ~destmask;
	    if (!(destmask >>= 1)) {
	      destmask= 0x80;
	      destptr++;
	    }
	    pixptr += image->pixlen;
	  }
	  destline += linelen;
	}
	XSetForeground(disp, gc, plane);
	XSetPlaneMask(disp, gc, plane);
	XPutImage(disp, pixmap, gc, ximage, 0, 0, 0, 0,
		  image->width, image->height);
      }

      ximage->data= NULL;
      XDestroyImage(ximage);
      lfree(bitplane);
      break;
    }

    /* send image across in one whack
     */

    gcv.function= GXcopy;
    gc= XCreateGC(disp, pixmap, GCFunction, &gcv);
    ximage= XCreateImage(disp, visual, ddepth, ZPixmap, 0, modimageptr,
			 image->width, image->height, 8, 0);
    ximage->byte_order= MSBFirst; /* trust me, i know what i'm talking about */

    XPutImage(disp, pixmap, gc, ximage, 0, 0,
	      0, 0, image->width, image->height);
    if(image->data == modimageptr)
        ximage->data= NULL;
    XDestroyImage(ximage); /* waste not want not */
    XFreeGC(disp, gc);
    break;

  default:
    return(0);
  }

  return(pixmap);
}
