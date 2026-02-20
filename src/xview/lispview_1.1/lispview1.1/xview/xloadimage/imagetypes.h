/* imagetypes.h:
 *
 * supported image types and the imagetypes array declaration.  when you
 * add a new image type, only the makefile and this header need to be
 * changed.
 *
 * jim frost 10.15.89
 */

Image *pbmLoad();
Image *sunRasterLoad();
Image *sunIconLoad();
Image *xwdLoad();
Image *xbitmapLoad();
Image *xpixmapLoad();

int pbmIdent();
int sunRasterIdent();
int sunIconIdent();
int xwdIdent();
int xbitmapIdent();
int xpixmapIdent();


/* some of these are order-dependent
 */

struct {
  int    (*identifier)(); /* print out image info if this kind of image */
  Image *(*loader)();     /* load image if this kind of image */
  char  *name;            /* name of this image format */
} ImageTypes[] = {
  sunRasterIdent, sunRasterLoad, "Sun Rasterfile",
  sunIconIdent,   sunIconLoad,    "Sun Pixrect/Icon",
  pbmIdent,       pbmLoad,       "Portable Bit Map (PBM)",
  xwdIdent,       xwdLoad,       "X Window Dump",
  xpixmapIdent,   xpixmapLoad,   "X Pixmap",
  xbitmapIdent,   xbitmapLoad,   "X Bitmap",
  NULL,           NULL,          NULL
};



/* 

This is the original version of the ImageTypes table.

Image *facesLoad();
Image *pbmLoad();
Image *sunRasterLoad();
Image *gifLoad();
Image *rleLoad();
Image *xwdLoad();
Image *xbitmapLoad();
Image *xpixmapLoad();
Image *g3Load();
Image *fbmLoad();
Image *macLoad();
Image *cmuwmLoad();

int facesIdent();
int pbmIdent();
int sunRasterIdent();
int gifIdent();
int rleIdent();
int xwdIdent();
int xbitmapIdent();
int xpixmapIdent();
int g3Ident();
int fbmIdent();
int macIdent();
int cmuwmIdent();


ImageTypes[] = {
  fbmIdent,       fbmLoad,       "FBM Image",
  sunRasterIdent, sunRasterLoad, "Sun Rasterfile",
  cmuwmIdent,     cmuwmLoad,     "CMU WM Raster",
  pbmIdent,       pbmLoad,       "Portable Bit Map (PBM)",
  facesIdent,     facesLoad,     "Faces Project",
  gifIdent,       gifLoad,       "GIF Image",
  rleIdent,       rleLoad,       "Utah RLE Image",
  xwdIdent,       xwdLoad,       "X Window Dump",
  macIdent,       macLoad,       "MacPaint Image",
  xpixmapIdent,   xpixmapLoad,   "X Pixmap",
  xbitmapIdent,   xbitmapLoad,   "X Bitmap",
  g3Ident,        g3Load,        "G3 FAX Image",
  NULL,           NULL,          NULL
};

*/
