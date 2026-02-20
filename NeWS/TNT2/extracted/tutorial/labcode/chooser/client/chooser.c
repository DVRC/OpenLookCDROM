#include <NeWS/wire/wire.h>
#include <NeWS/tntguide/alert.h>
#include "chooser_cps.h"

void Quit();
void ChangeColors();
int canvastoken;

main()
{
	wire_Wire thiswire;
	int errno;
	int windowtoken;
	int color_changedTag, quitTag;
	int * tagptrs[3];
	int * tokenptrs[3];
	tagptrs[0] = &color_changedTag;
	tagptrs[1] = &quitTag;
	tagptrs[2] = 0;
	tokenptrs[0] = &canvastoken;
	tokenptrs[1] = &windowtoken;
	tokenptrs[2] = 0;
	
	if ((thiswire = wire_Open(NULL)) == wire_INVALID_WIRE) {
		errno = wire_Errno;
		printf("\nWire open Error # %d\n", errno);
	} else {
		wire_SetCurrent(thiswire);
		printf("\nWire opened without error\n");
		errno = 0;
	}
	
	wire_AllocateNamedTags(tagptrs);
	wire_AllocateNamedTokens(thiswire,tokenptrs);
	
	wire_RegisterTag(color_changedTag,ChangeColors,NULL);
	wire_RegisterTag(quitTag, Quit, NULL);
	
#ifdef DEVELOP
	loadPostScript("chooser.ps");
	PS_AssociateTokens(canvastoken,windowtoken);
#else
	PS_LoadClasses(canvastoken,windowtoken);
#endif

	PS_RegisterTag(canvastoken,"COLOR_CHANGE",color_changedTag);
	PS_RegisterTag(windowtoken,"QUIT",quitTag);
	
	wire_EnterNotifier();
	wire_Close(thiswire);
	exit(0);
}

void
Quit(tag,data)
int tag;
caddr_t data;
{
	wire_ExitNotifier();
}

void ChangeColors(tag,data)
int tag;
caddr_t data;
{
	float newval;
	char slidername[10];
	char * slider;
	
	newval = wire_ReadFloat();
	slider = wire_ReadString(slidername);
	PS_SetSliderVariable(canvastoken,slidername,newval);
	PS_Paint(canvastoken);
}

