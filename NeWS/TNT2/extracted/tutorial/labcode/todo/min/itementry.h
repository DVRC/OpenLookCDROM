// @(#) itementry.h 1.1 91/02/28


// Class definition for class ItemEntry
// A ToDo item is represented by a header, a string beginning with ':'
// followed by a string representing the text of the item

#ifndef _ITEMENTRY_H_
#define _ITEMENTRY_H_
#include <strings.h>
#include <iostream.h>
#include <fstream.h>

class ItemEntry  {
  friend ofstream& operator<< (ofstream&, const ItemEntry&);
  friend ostream& operator<< (ostream&, const ItemEntry&);
private:
  char * header;
  char * item;
  int itemIndex;
  ItemEntry * nextItem;
public:
  ItemEntry(char * iHeader, char * iItem, ItemEntry * next);
  ~ItemEntry() {delete header; delete item;}
  ItemEntry * GetNextItem() {return nextItem;}
  void SetNextItem( ItemEntry * next) { nextItem = next;}
  char  * GetHeader() ;
  char * GetItem() { return item;}
  void SetIndex( int newindex ) {itemIndex = newindex;}
  int GetIndex() { return itemIndex; }
  void SetHeader(char * newHeader);
  void SetItem( char * newItem);
};
    
#endif
