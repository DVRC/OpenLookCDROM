/* compress.c:
 *
 * compress a colormap by removing unused RGB colors
 *
 * jim frost 10.05.89
 *
 * Copyright 1989, 1990 Jim Frost.  See included file "copyright.h" for
 * complete copyright information.
 */

#include "copyright.h"
#include "image.h"

void compress(image, verbose)
     Image        *image;
     unsigned int  verbose;
{ Pixel        *index;
  unsigned int *used;  
  RGBMap        rgb;
  byte         *pixptr, *pixptr2;
  unsigned int  a, x, y;
  Pixel         color, newpixlen;

  goodImage(image, "compress");
  if (! RGBP(image)) /* we're AT&T */
    return;

  if (verbose) {
    printf("  Compressing colormap...");
    fflush(stdout);
  }

  newRGBMapData(&rgb, image->rgb.size);
  index= (Pixel *)lmalloc(sizeof(Pixel) * image->rgb.used);
  used= (unsigned int *)lmalloc(sizeof(unsigned int) * image->rgb.used);
  for (x= 0; x < image->rgb.used; x++)
    *(used + x)= 0;

  pixptr= image->data;
  for (y= 0; y < image->height; y++)
    for (x= 0; x < image->width; x++) {
      color= memToVal(pixptr, image->pixlen);
      if (*(used + color) == 0) {
	for (a= 0; a < rgb.used; a++)
	  if ((*(rgb.red + a) == *(image->rgb.red + color)) &&
	      (*(rgb.green + a) == *(image->rgb.green + color)) &&
	      (*(rgb.blue + a) == *(image->rgb.blue + color)))
	    break;
	*(index + color)= a;
	*(used + color)= 1;
	if (a == rgb.used) {
	  *(rgb.red + a)= *(image->rgb.red + color);
	  *(rgb.green + a)= *(image->rgb.green + color);
	  *(rgb.blue + a)= *(image->rgb.blue + color);
	  rgb.used++;
	}
      }
      valToMem(*(index + color), pixptr, image->pixlen);
      pixptr += image->pixlen;
    }

  if (verbose)
    if (rgb.used < image->rgb.used)
      printf("%d unique colors of %d\n", rgb.used, image->rgb.used);
    else
      printf("no improvement\n");

  freeRGBMapData(&(image->rgb));
  image->rgb= rgb;

/* Okay, we've compressed the colors, let's do the image */
  for (y=0,x=1;rgb.used>x;y++) x=x*2;
  newpixlen = (y / 8) + (y % 8 ? 1 : 0);
  if (newpixlen < image->pixlen)
  {
	if (verbose)
		printf("  Compressing image...");fflush(stdout);
	pixptr = image->data; pixptr2 = image->data;
	for (y= 0; y < image->height; y++)
	 for (x= 0; x < image->width; x++) {
		valToMem(memToVal(pixptr2,image->pixlen), pixptr, newpixlen);
		pixptr2 += image->pixlen;
		pixptr += newpixlen;
	 }
	image->pixlen = newpixlen;
	if (verbose)
		printf("done\n");
   }

}
