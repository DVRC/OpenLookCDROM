/* bright.c
 *
 * alter an image's brightness by a given percentage
 *
 * jim frost 10.10.89
 *
 * Copyright 1989 Jim Frost.  See included file "copyright.h" for complete
 * copyright information.
 */

#include "copyright.h"
#include "image.h"

void brighten(image, percent, verbose)
     Image        *image;
     unsigned int  percent;
     unsigned int  verbose;
{ int          a;
  unsigned int newrgb;
  float        fperc;

  if (! RGBP(image)) /* we're AT&T */
    return;

  if (verbose) {
    printf("  Brightening colormap by %d%%...", percent);
    fflush(stdout);
  }

  fperc= (float)percent / 100.0;
  for (a= 0; a < image->rgb.used; a++) {
    newrgb= *(image->rgb.red + a) * fperc;
    if (newrgb > 65535)
      newrgb= 65535;
    *(image->rgb.red + a)= newrgb;
    newrgb= *(image->rgb.green + a) * fperc;
    if (newrgb > 65535)
      newrgb= 65535;
    *(image->rgb.green + a)= newrgb;
    newrgb= *(image->rgb.blue + a) * fperc;
    if (newrgb > 65535)
      newrgb= 65535;
    *(image->rgb.blue + a)= newrgb;
  }

  if (verbose)
    printf("done\n");
}

void gammacorrect(image, disp_gam, verbose)
     Image        *image;
     float  disp_gam;
     unsigned int  verbose;
{ int          a;
  int gammamap[256];

  if (! RGBP(image)) /* we're AT&T */
    return;

  if (verbose) {
    printf("  Adjusting colormap for display gamma of %4.2f...", disp_gam);
    fflush(stdout);
  }

  make_gamma(disp_gam,gammamap);

  for (a= 0; a < image->rgb.used; a++) {
    *(image->rgb.red + a)= gammamap[(*(image->rgb.red + a))>>8]<<8;
    *(image->rgb.green + a)= gammamap[(*(image->rgb.green + a))>>8]<<8;
    *(image->rgb.blue + a)= gammamap[(*(image->rgb.blue + a))>>8]<<8;
  }

  if (verbose)
    printf("done\n");
}
