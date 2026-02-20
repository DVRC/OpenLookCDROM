// @(#) itementry.cc 1.1 91/02/28


// Class implementation for class ItemEntry

#include "itementry.h"


ItemEntry::ItemEntry( char * iHeader, char * iItem, ItemEntry * next= 0)
{
  header = new char[strlen (iHeader)];
  item = new char[strlen (iItem)];
  nextItem = next;
  char * dummy = strcpy(header, iHeader);
  dummy = strcpy(item, iItem);
}

char * ItemEntry::GetHeader()
{
  char * result = strchr(header, ':');
  if (!result) 
    return result;
  else
    return ++result;             // strip the leading colon
}

// Called when the header is edited by the user
void ItemEntry::SetHeader(char * p)
{
  if (strcmp(header,""))
      delete [strlen(header)] header;
  header = new char[strlen(p)+1];
  for( int i = 1; i<strlen(p)+1;++i) header[i]=0;
  header[0] = ':';
  strcat(header,p);
}

// Called when the item is edited by the user
void ItemEntry::SetItem(char* p)
{
  if (strcmp(item,""))
    delete [strlen(item)] item;
  item = new char[strlen(p)];
  for( int i = 1; i<strlen(p)+1;++i) item[i]=0;
  strcpy(item,p);
}
  

ofstream & operator <<(ofstream& outfile, const ItemEntry& IE)
{
  outfile << IE.header
          << endl
          << IE.item
          << endl << endl;
  return outfile;
}

//ifstream& operator>>(ifstream& infile, const ItemEntry* ie)
//{
  
// For debugging
ostream & operator <<(ostream& outfile, const ItemEntry& IE)
{
  outfile << "Index: " << IE.itemIndex << endl
          << "Header: " << IE.header
          << endl
          << "Item entry: " <<IE.item
          << endl << endl;
  return outfile;
}
