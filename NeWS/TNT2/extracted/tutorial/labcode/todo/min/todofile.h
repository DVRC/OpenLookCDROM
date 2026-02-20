// @(#) todofile.h 1.2 91/02/28


// todofile.h
// Function prototypes for file handling used in todo application
#define ENTRYSIZE 4096
#define HDRSIZE 128
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <strings.h>
#include <stream.h>
#include <stdio.h>
#include <stdiostream.h>
#include <fstream.h>
#include <libc.h>
#include <dirent.h>
#include "itementry.h"

int WriteItemFile( char *filename, ItemEntry * ie);
ItemEntry * InitItemList(char* itemFile,char * fileName,int& numberItems);
void DeleteItem(ItemEntry *& rt, ItemEntry * item);
void DeleteItem(ItemEntry*& where, int index);
void AppendItem( ItemEntry *& where, ItemEntry * newItem );
ItemEntry* FindItem( ItemEntry* where, int index);
int NewDefaultItem(int whichItem, int numberItems);
char * get1todofile();
char * getdefaultdir();
char * fullname(char *);
char * pwd();
char * dirname(char*);
char * basename(char*);

