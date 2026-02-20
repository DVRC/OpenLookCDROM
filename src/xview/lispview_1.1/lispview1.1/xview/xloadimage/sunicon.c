
#include <stdio.h>
#include <sys/types.h>
#include "image.h"

Image *sunIconLoad(fullname, name, verbose)
  char *fullname, *name;
  unsigned int  verbose;
{
  FILE *f;
  Image *image = (Image *)0;
  int format_version, width = 64, height = 64, depth = 1, valid_bits_per_item = 16;

#define EXIT_sunIconLoad(msg) \
  { \
   if (f) fclose(f); \
   if (image) freeImage(image); \
   fprintf(stderr, ";;; [sunIconLoad] loading %s failed: %s\n", fullname, msg); \
   return (Image *)0; \
  }

  if ((f = fopen(fullname, "r")) == (FILE *)0)
    return (Image *)0;

  while(1) {
    if (fscanf(f, "/* Format_version=%d", &format_version) == 1)
      break;
    else if ( feof(f) )
      {fclose(f); return (Image *)0;}
    getc(f);
  }

  if (format_version != 1)
    EXIT_sunIconLoad("only format version 1 Sun Icon files are supported")

  while(1) {
    char token[129];
    int value, n;

    fscanf(f, "%*[, ]");                          
    if ( feof(f) || fread(token, 1, 2, f) != 2 )
      EXIT_sunIconLoad("couldn't parse the file header")
    token[2] = '\0';
    if ( !strcmp(token, "*/") ) 
      break;
    ungetc(token[1], f);
 
    if ((n = fscanf(f, "%128[a-zA-Z0-9_]=%d", token+1, &value)) == 2) {
      if ( !strcmp(token, "Width") )  width = value;
      else if ( !strcmp(token, "Height") ) height = value;
      else if ( !strcmp(token, "Depth") ) depth = value;
      else if ( !strcmp(token, "Valid_bits_per_item") ) valid_bits_per_item = value;
    }
  }

  if (width % 16)
    EXIT_sunIconLoad("only icons whose width is a multiple of 16 are supported")

  if (depth != 1)
    EXIT_sunIconLoad("only icons whose depth is 1 are supported")

  if (verbose)
    printf(";;; %s is a Sun icon/pixrect file %dx%d\n", fullname, width, height);

  image= newBitImage(width, height);
  {
    int n, i, j, width16 = width / 16;
    short *data = (short *)(image->data);
    long value;

    for (i = 0; i < height; i++) {
      for (j = 0; j < width16; j++) {
	n = fscanf(f, " 0x%lx,", &value);
	if (n == 0 || n == EOF)
	  EXIT_sunIconLoad("couldn't read all of the bitmap data")
	else
	  data[j + (i * width16)] = value;
      }
    }
  }

  fclose(f); 
  return image;

#undef EXIT_sunIconLoad
}


int sunIconIdent(fullname, name)
     char         *fullname, *name;
{ Image *image;

  if (image= sunIconLoad(fullname, name, (unsigned int)1)) {
    freeImage(image);
    return(1);
  }
  return(0);
}
