cdef PS_Paint(token cv)
	/PreviewColor cv send 
	
cdef PS_SetSliderVariable(token cv,string slidername,float val)
	cv slidername cvn val put
	
cdef PS_RegisterTag(token obj, string tagname, int tagvalue)
	tagname cvn tagvalue /wire_definetag obj send
	
cdef PS_AssociateTokens(int tk1, int tk2)
	tk1 /wire_settoken canvas1 send
	tk2 /wire_settoken window1 send
	
cdef PS_LoadClasses(int tk1, int tk2)
#include "chooser.ps"
	tk1 /wire_settoken canvas1 send
	tk2 /wire_settoken window1 send
