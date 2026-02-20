// @(#) todofile.cc 1.3 91/03/01


#include "todofile.h"

static ItemEntry * ReadItem( ifstream& ins, int& n);
static int WriteItem(ofstream& ofs, ItemEntry * ie);
static char defaultDir[256];
static DIR * defaultD;
static struct dirent * curd;

// File handling


ItemEntry * InitItemList(char* itemFile, char * fileName, int& numberItems)
{
   
  // Construct default filename, of the form .user.ToDo
  struct stat S;
  char defaultFile[256];
  defaultDir[0] = 0;
  char * home = getenv("HOME");
  char * dummy = strcpy(defaultFile, home);
  dummy = strcat(defaultFile, "/.todo");
  // Check to see that directory ~/.todo exists; if not,
  // try to create it
  if (stat(dummy, &S)) {
    cerr << "Can't stat " << dummy << endl;
    if (errno == ENOENT)
      cerr << "Trying to create "<< dummy << endl;
    else
      return NULL;
    if (mkdir(dummy, 0755)) {
      cerr << "Can't create " << dummy << endl;
      return NULL;
    }
  }
  // Something exists with name dummy
  if (stat(dummy, &S) || ! S_ISDIR(S.st_mode)) {
    cerr << dummy << " is not a directory" << endl;
    return NULL;
  }

  // $HOME/.todo exists
  strcpy(defaultDir, defaultFile);

  // Open the default directory for reading
  if ((defaultD = opendir(defaultDir)) == NULL) {
    cerr << "Horrible error: couldn't open " << defaultDir << endl;
    exit(errno);
  }

  strcat(defaultFile, "/.");
  char * p = new char[L_cuserid];
  dummy = cuserid(p);
  dummy = strcat(defaultFile,p);
  strcat(defaultFile,".ToDo");
  numberItems = 0;
  ItemEntry * myItems, *currentItem, *lastItem;
  // Attemp to open a todo file, create one if necessary.
  ifstream itemfstream;
  if (itemFile == NULL || !strcmp(itemFile,"")) {
    itemfstream.open(defaultFile, ios::in);
    if (!itemfstream) {
      cerr << "Couldn't open item file: "
	   << defaultFile
	   << endl
	   << "Creating new default file"
	   << endl;
//           << "Do you wish to create a new file? [Y or N]" ;
//      char c;
//      do  {
//	cerr <<  endl << "Please type Y or N" << endl;
//	cin.get(c);
//      } while (!(c=='Y' || c=='N' || c=='y' || c=='n'));
//      if ( c=='Y' || c=='y' ) {
	itemfstream.open(defaultFile, ios::out);  // Create a default file
	if (!itemfstream) {
	  cerr << "IO error: couldn't create "
               << defaultFile
               << endl;
	  exit(1);
	} else {
	    strcpy( fileName, defaultFile);
	    itemfstream.close();
	    return NULL;
	}
//      } else {
//	exit(0);
//      }
    }
    strcpy( fileName, defaultFile);
  } else {
    // If itemFile is a relative pathname, convert it here to a full path
    char * fullPath = fullname(itemFile);
    itemfstream.open(fullPath, ios::in);
    if (!itemfstream) {
      cerr << "Couldn't open item file: "
	   << fullPath
	   << endl
	   << "Trying to create " << fullPath << endl;
      ofstream temp(fullPath, ios::out);
      if (!temp) {
	cerr << "Couldn't create new item file" << endl;
	//     << "Terminating!\n\n";
	//exit(1);
	return NULL;
      } else {
	temp.close();
	itemfstream.open(fullPath, ios::in);
	if (!itemfstream) {
	  cerr << "Couldn't open new item file\n" << endl;
	//       << "Terminating!!!\n\n";
//	  exit(1);
	  return NULL;
	}
      }
    }
  strcpy( fileName, fullPath);
  }
  myItems = lastItem = currentItem = ReadItem(itemfstream,numberItems);
  while(currentItem != NULL) {
    currentItem = ReadItem(itemfstream,numberItems);
    lastItem->SetNextItem(currentItem);
    lastItem = currentItem;

  }                                        // scroll list
  itemfstream.close();
  return myItems;
}

static ItemEntry * ReadItem( ifstream& ins, int& n)
{
  char header[HDRSIZE];
  char entry[ENTRYSIZE];

  if (!ins) return NULL;
  char * p, c;
  int charsread = 0;
  // Read the header
  if ((c = ins.peek()) == EOF || c == 0) return NULL;
  // Ignore initial newlines
  while ((c = ins.peek()) == '\n') ins.get(c);
  if ((c = ins.peek()) == '\0') return NULL;
  if (c != ':') {
    cerr << "Error reading ToDo list: "
         << "incorrect item header format, ':' missing" << endl;
    return NULL;
  }
  p = header;
  while (ins.get(c) && c != '\n' && charsread < HDRSIZE-1) {
    *p++ = c;
    charsread++;
  }

  if (!ins) return NULL;

  *p = '\0';

  //Read the item
  p = entry; charsread = 0;
  while (ins.get(c) && c != '\0' && ++charsread < ENTRYSIZE) {
      *p++ = c;
  }
  *p = '\0';

  if (!ins) {
    return NULL;
  }

  
  ItemEntry * result = new ItemEntry(header, entry, NULL);
  result->SetIndex(n++);
  return result;
}

static int WriteItem(ofstream& ofs, ItemEntry * ie)
{
  if (!ofs) return -1;
  
  char headbuf[HDRSIZE];
  headbuf[0] = ':';
  headbuf[1] = '\0';
//  char* p = &headbuf[1]; 
  strncat(headbuf, ie->GetHeader(), HDRSIZE-2);
  ofs << headbuf << endl;
  ofs << ie->GetItem() /*<< endl*/;
  ofs.put('\0');
  /*ofs << endl;*/
  return !ofs ? -1 : 0;
}

int WriteItemFile( char *filename, ItemEntry * ie)
{
  ofstream ofs(filename, ios::out);
  if (!ofs) return -1;
  int err;
  ItemEntry * p = ie;
  while (p && ((err = WriteItem(ofs,p)) == 0))
    p = p->GetNextItem();
  ofs.put('\0');
  return err;
}


void UpdateIndices( ItemEntry * where)
{
  if (!where) return;

  ItemEntry * p = where;
  int numberItems = p->GetIndex();
  while (p) {
    p->SetIndex(numberItems++);
    p = p->GetNextItem();
  }
}

// List utilities
void AppendItem( ItemEntry *& where, ItemEntry * newItem )
{
  if (newItem == NULL) return;
  if (where == NULL) {
    where = newItem;
    return;
  }
  if (where->GetNextItem() == NULL)
    where->SetNextItem( newItem );
  else
    AppendItem(where->GetNextItem(), newItem);
}

void DeleteItem(ItemEntry *& where, ItemEntry * whichItem)
{
  ItemEntry * prev, * curr;

  if (where == NULL || whichItem == NULL) return;

  if (where == whichItem) {
    where = where->GetNextItem();
    if (where) {
      where->SetIndex(0);
      UpdateIndices(where);
    }
    delete whichItem;
    return;
  }

  prev = where;
  curr = where->GetNextItem();
  while (curr) {
    if ( curr == whichItem ) {
      prev->SetNextItem(curr->GetNextItem());
      UpdateIndices(prev);
      delete curr;
      break;
    }
    else {
      prev = curr;
      curr = curr->GetNextItem();
    }
  }
}

ItemEntry* FindItem( ItemEntry* where, int index)
{
  register ItemEntry * p = where;

  while(p) {
    if (p->GetIndex() == index)
      return p;
    p = p->GetNextItem();
  }
  return NULL;
}

void DeleteItem(ItemEntry*& where, int index)
{
  DeleteItem(where, FindItem(where,index));
}


int NewDefaultItem(int whichItem, int numberItems)
{
  if (whichItem>0 && whichItem<=numberItems)
    return whichItem-1;
  else if (whichItem == 0 && 0 < numberItems)
    return 0;
  else
    return -1;
}


char * get1todofile()
{
  struct stat S;
  char tmp[BUFSIZ];
  while (curd = readdir(defaultD))  {
    if (!strcmp(curd->d_name, ".") || ! strcmp(curd->d_name, ".."))
      continue;
    sprintf(tmp, "%s/%s", getdefaultdir(), curd->d_name);
    if (stat(tmp,&S) || S_ISDIR(S.st_mode))
      continue;
    return curd->d_name;
  }
  closedir(defaultD);
  return (char *)NULL;
}
 
char * getdefaultdir() { return defaultDir;}

static   char cwd[BUFSIZ];

char * pwd()
{
  FILE * CWD = popen("pwd", "r");
  fgets(cwd, BUFSIZ, CWD);
  pclose(CWD);
  return strtok(cwd,"\n");
}

static char fname[BUFSIZ];

// If the argument passed does not begin with a '/', interpret it as a
// relative pathname, and prepend the current working directory
char * fullname(char * filename)
{
  if (*filename == '/') return filename;

  strcpy(fname, pwd());
  strcat(fname, "/");
  strcat(fname, filename);
  return fname;
}

char * dirname(char * path)
{
  char cmd[BUFSIZ];
  strcpy(cmd, path);
  char * p = strrchr(cmd, '/');
  if (p != NULL) *p = 0;
  return cmd;

/*  sprintf(cmd,"dirname %s", path);
  FILE * D = popen(cmd, "r");
  fgets(cwd,BUFSIZ,D);
  return strtok(cwd,"\n");
  pclose(D);
*/
}

char * basename(char * path)
{
  char cmd[BUFSIZ];
  strcpy(cmd, path);
  char * p = strrchr(cmd, '/');
  if (p == NULL) return path;
  return ++p;

/*  sprintf(cmd,"basename %s", path);
  FILE * D = popen(cmd, "r");
  fgets(cwd,BUFSIZ,D);
  return strtok(cwd,"\n");
  pclose(D);
*/
}

