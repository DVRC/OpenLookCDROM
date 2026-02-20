/*
 * This file is a product of Sun Microsystems, Inc. and is provided for
 * unrestricted use provided that this legend is included on all tape
 * media and as a part of the software program in whole or part.  Users
 * may copy or modify this file without charge, but are not authorized to
 * license or distribute it to anyone else except as part of a product
 * or program developed by the user.
 * 
 * THIS FILE IS PROVIDED AS IS WITH NO WARRANTIES OF ANY KIND INCLUDING THE
 * WARRANTIES OF DESIGN, MERCHANTIBILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE, OR ARISING FROM A COURSE OF DEALING, USAGE OR TRADE PRACTICE.
 * 
 * This file is provided with no support and without any obligation on the
 * part of Sun Microsystems, Inc. to assist in its use, correction,
 * modification or enhancement.
 * 
 * SUN MICROSYSTEMS, INC. SHALL HAVE NO LIABILITY WITH RESPECT TO THE
 * INFRINGEMENT OF COPYRIGHTS, TRADE SECRETS OR ANY PATENTS BY THIS FILE
 * OR ANY PART THEREOF.
 * 
 * In no event will Sun Microsystems, Inc. be liable for any lost revenue
 * or profits or other special, indirect and consequential damages, even
 * if Sun has been advised of the possibility of such damages.
 * 
 * Sun Microsystems, Inc.
 * 2550 Garcia Avenue
 * Mountain View, California  94043
 *
 * Copyright (c) 1990 by Sun Microsystems, Inc.
 */


/*
 * gainTool
 * 	A program to display and modify several of the control values
 * associated with the SPARCstation audio device.
 */

#if !defined (lint)
static char sccsid[] = "@(#)gaintool.c 1.6 91/02/11 Copyright 1985 Sun Micro";
#endif

#include <stdio.h>
#include <fcntl.h>
#include <strings.h>
#include <stropts.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/file.h>

#include <sun/audioio.h>

#include <NeWS/wire/wire.h>
#include <NeWS/tntguide/alert.h>

#include "gaintool_cps.h"



/* ----------------------------------------------------------------
 *	A few generally useful macros...
 */

#if !defined(ANSI)

#if  defined(__STDC__)  ||  defined(__cplusplus)
#define	ANSI(stmt)	stmt
#define	TRAD(stmt)
#else
#define	ANSI(stmt)
#define	TRAD(stmt)	stmt
#endif	/* __STDC__ || __cplusplus */

#endif	/* ANSI */


#if !defined(IF_DEBUG)

#if defined(DEBUG)
#define	IF_DEBUG(stmt)	stmt
#else
#define	IF_DEBUG(stmt)
#endif	/* DEBUG */
#endif	/* IF_DEBUG */


/*---------------------------------------------------------------------------
 *	Constants
 */
#if  defined(__STDC__)  ||  defined(__cplusplus)

const char	audioIoDev []  = "/dev/audio" ;
const char	audioCtlDev [] = "/dev/audioctl" ;
const int	maxGain = 100 ;

#else	/* Neither ANSI nor C++ */

#define audioIoDev	"/dev/audio"
#define audioCtlDev	"/dev/audioctl"
#define maxGain		100

#endif	/* ANSI or C++ */



/*-----------------------------------------------------------------
 *	Object Number Definitions
 */
typedef enum {
    TAG_BAD_TAG = 0,		/* Real tags start at 1 */
    TAG_GAINWINDOW,
    TAG_PLAYGAIN,
    TAG_RECORDGAIN,
    TAG_MONITORVOLUME,
    TAG_OUTPUTCHOICE,
    TAG_PAUSEBUTTON,
    TAG_ENUM_LIMIT,
} objectTagType ;


boolean	gntquit = FALSE;
int	scratchTag;

int tk_gainWindow;		/* Token for gainWindow */ 
int tk_playGain;		/* Token for playGain */ 
int tk_recordGain;		/* Token for recordGain */ 
int tk_monitorVolume;		/* Token for monitorVolume */ 
int tk_outputChoice;		/* Token for outputChoice */ 
int tk_pauseButton;		/* Token for pauseButton */ 

static int  *tokenarray [] = {
    &tk_gainWindow,
    &tk_playGain,
    &tk_recordGain,
    &tk_monitorVolume,
    &tk_outputChoice,
    &tk_pauseButton,
    0
};


static int		 Audio_fd;
static int		 Audio_pause_fd = -1;
static audio_info_t	 Audio_info;
static audio_info_t	 Audio_new;

static short int	icon_data[] = {
#include "gaintool.icon"
} ;




/*
 * unscale_gain ()
 * 	Convert device gain into the local scaling factor.
 *
 * 	Date	Vers	Who	What
 * 	======================================================================
 * 	17aug90	1.0	PML	New - taken from SunView/XView version.
 */
unsigned
unscale_gain (ANSI(unsigned) g)
    TRAD(unsigned	g;)
{
    return ((unsigned) irint((double)maxGain *
			     (((double)(g - AUDIO_MIN_GAIN)) /
			      (double)(AUDIO_MAX_GAIN - AUDIO_MIN_GAIN))));
}   /* unscale_gain() */




/*
 * scale_gain ()
 * 	Convert local gain into device parameters
 *
 * 	Date	Vers	Who	What
 * 	======================================================================
 * 	17aug90	1.0	PML	New - taken from SunView/XView version.
 */
unsigned
scale_gain (ANSI(float) g)
    TRAD(float	g;)
{
    return (AUDIO_MIN_GAIN + (unsigned)
	    irint(((double) (AUDIO_MAX_GAIN - AUDIO_MIN_GAIN)) *
		  ((double)g / (double)maxGain)));
}   /* scale_gain() */




/*
 * getinfo ()
 * 	Get current audio state.
 *
 * 	Date	Vers	Who	What
 * 	======================================================================
 * 	17aug90	1.0	PML	New - taken from SunView/XView version.
 */
void
getinfo (ANSI(audio_info_t *) ap)
    TRAD(audio_info_t	*ap;)
{
    if (ioctl(Audio_fd, AUDIO_GETINFO, ap) < 0) {
	perror("AUDIO_GETINFO");
    }
    
    /* Set the output port to a value we understand */
    ap->play.port = ((ap->play.port == AUDIO_SPEAKER) ? 0 : 1);
    
    ap->play.gain    = unscale_gain(ap->play.gain);
    ap->record.gain  = unscale_gain(ap->record.gain);
    ap->monitor_gain = unscale_gain(ap->monitor_gain);
}   /* getinfo() */



/*
 * update_display ()
 * 	Update the display to match the current state of the audio
 * 	control device
 *
 * 	Date	Vers	Who	What
 * 	======================================================================
 * 	17aug90	1.0	PML	New - taken from SunView/XView version.
 */
void
update_display (ANSI(void))
{
    getinfo (&Audio_new) ;

    if  (Audio_new.play.gain != Audio_info.play.gain)
	cps_set_slider (tk_playGain, Audio_new.play.gain) ;

    if  (Audio_new.record.gain != Audio_info.record.gain)
	cps_set_slider (tk_recordGain, Audio_new.record.gain) ;

    if  (Audio_new.monitor_gain != Audio_info.monitor_gain)
	cps_set_slider (tk_monitorVolume, Audio_new.monitor_gain) ;

    if  (Audio_new.play.port != Audio_info.play.port)
	cps_set_choice (tk_outputChoice, Audio_new.play.port) ;


    /*
     * Pause is tricky, since we may be holding the device open.
     * If `resume', then release the device, if held.
     */
    if  ((!Audio_new.play.pause) &&  (Audio_pause_fd >= 0))  {
	(void) close (Audio_pause_fd) ;
	Audio_pause_fd = -1 ;
    }

    if  (Audio_new.play.pause != Audio_info.play.pause)  {
	if  (Audio_new.play.pause)  {
	    cps_relabel_button (tk_pauseButton, "Resume Play") ;
	} else {
	    cps_relabel_button (tk_pauseButton, "Pause Play") ;
	}
    }

    Audio_info = Audio_new ;
}   /* update_display() */



/*
 * windowquit
 *
 *	Automatically generated callback routine for the following object(s):
 *	gainWindow
 *
 * Revision History:
 *
 *	Date	Vers	Who	What
 *	===============================================================
 * 	17aug90	1.0	PML	New
 */
void
sigpoll_handler (ANSI(int)			sig,
		 ANSI(int)			code,
		 ANSI(struct sigcontext *)	scp,
		 ANSI(char *)			addr)
    TRAD(int			sig;)
    TRAD(int			code;)
    TRAD(struct sigcontext *	scp;)
    TRAD(char *			addr;)
{
    /*
     * We don't have to actually do anything here.  The signal will
     * cause wire_Notify() to return FALSE; and the main loop will
     * update the display.  But we do need a `real' signal handler
     * to make sure that the signal will actually be delivered...
     */
}   /* sigpoll_handler() */




/*
 * windowquit
 *
 *	Automatically generated callback routine for the following object(s):
 *	gainWindow
 *
 * Revision History:
 *
 *	Date	Vers	Who	What
 *	===============================================================
 * 	17aug90	1.0	PML	New
 */

void
windowquit(ANSI(int) tag, ANSI(caddr_t) data)
    TRAD(int		tag;)
    TRAD(caddr_t	data;)
{
    /* if (QuitConfirmed ()) */
    {
	/* cps_quit_gainWindow (tk_gainWindow) ; */
	gntquit = 1;    /* Used by main loop to find  when windows quit */
	IF_DEBUG (printf("gainWindow quit \n") );
    }
}   /* windowquit() */




/*
 * gainHandler
 *
 *	Automatically generated callback routine for the following object(s):
 *	playGain
 *	recordGain
 *	monitorVolume
 *
 * Revision History:
 *
 *	Date	Vers	Who	What
 *	===============================================================
 *	17aug90	1.0	PML	New
 */

void
gainHandler(ANSI(int) tag, ANSI(caddr_t) data)
    TRAD(int		tag;)
    TRAD(caddr_t	data;)
{
    float	 slidervalue;
    char	*msg;

    
    slidervalue  = wire_ReadFloat ();     /* Value of the slider */
    AUDIO_INITINFO (&Audio_new) ;
    
    IF_DEBUG (printf ("gainHandler: tag=%d, value=%f <%d>\n",
		      tag,
		      slidervalue,
		      scale_gain (slidervalue)) );
	    
    switch ((objectTagType) tag)
    {
    case TAG_PLAYGAIN:		/* class Slider object playGain */
	Audio_new.play.gain = scale_gain (slidervalue) ;
	msg = "Set play volume" ;
	break;
	
    case TAG_RECORDGAIN:	/* class Slider object recordGain */
	Audio_new.record.gain = scale_gain (slidervalue) ;
	msg = "Set record volume" ;
	break;
	
    case TAG_MONITORVOLUME:	/* class Slider object monitorVolume */
	Audio_new.monitor_gain = scale_gain (slidervalue) ;
	msg = "Set monitor volume" ;
	break;
	
    default:
	wire_SkipEvent ();    /* Clean up the wire */
	fprintf (stderr, "gainHandler(): Undefined Object number\n") ;
	return ;
    }

    if  (ioctl (Audio_fd, AUDIO_SETINFO, &Audio_new) < 0) {
	perror (msg) ;
    }
}   /* gainHandler() */



/*
 * outputHandler
 *
 *	Automatically generated callback routine for the following object(s):
 *		outputChoice
 *
 * Revision History:
 *
 *	Date	Vers	Who	What
 *	===============================================================
 *	900717	1.0	-Auto-	Stubs Generated by TNTGuide
 */

void
outputHandler(ANSI(int) tag, ANSI(caddr_t) data)
    TRAD(int		tag;)
    TRAD(caddr_t	data;)
{
    int    index;	/* index of selected item */
    int    state;	/* t/f of selected */
    
    

    /* class Setting object outputChoice */
    
    index = wire_ReadInt ();
    state = wire_ReadInt ();

    if  (state) {
	AUDIO_INITINFO (&Audio_new) ;
	Audio_new.play.port = ((index == 0) ? AUDIO_SPEAKER : AUDIO_HEADPHONE);

	if  (ioctl (Audio_fd, AUDIO_SETINFO, &Audio_new) < 0) {
	    perror ("Set output port") ;
	}
    }
    /* else ignore `off' transitions */
}   /* outputHandler() */



/*
 * pauseHandler
 *
 *	The Pause/Resume button only affects output.
 * 	When pushed, it toggles between Pause and Resume.
 *
 * 	Setting the pause bit on a device that is not open has no effect.
 *	If the button is pressed when the play stream of audioIoDev is
 * 	closed, we open the device here in order to make sure no output occurs.
 *
 * 	If the resume button is pressed or any other process sets play.resume,
 * 	we let go of the device in update_display().
 *
 * 	Since device open/close signals a state change, update_display()
 * 	will take care of switching the button text.
 *
 * Revision History:
 *
 *	Date	Vers	Who	What
 *	===============================================================
 *	900717	1.0	-Auto-	Stubs Generated by TNTGuide
 */

void
pauseHandler(ANSI(int) tag, ANSI(caddr_t) data)
    TRAD (int		tag;)
    TRAD (caddr_t	data;)
{
    /*
     * If trying to pause, try to open audioIoDev first.
     */
    if  ((! Audio_info.play.pause)  &&  (Audio_pause_fd < 0))  {
	Audio_pause_fd = open (audioIoDev, O_WRONLY | O_NDELAY) ;
    }

    /*
     * Toggle the pause bit.
     */
    AUDIO_INITINFO (&Audio_new) ;
    Audio_new.play.pause = ! Audio_info.play.pause ;

    IF_DEBUG (printf ("pauseButton called - new value %d \n",
		      Audio_new.play.pause) );

    if  (ioctl (Audio_fd, AUDIO_SETINFO, &Audio_new) < 0)  {
	perror ("pause/resume") ;
    }
}   /* pauseHandler() */



/*
 * Allocate_gaintool_Tokens ()
 *
 *	Automatically sets up callback routines for each object.
 *	Code is generated by TNTGuide cside
 * 
 * Revision History:
 *
 *	Date	Vers	Who	What
 *	===============================================================
 *	900717	1.0	-Auto-	Stubs Generated by TNTGuide from gaintool.G
 */

void
Allocate_gaintool_Tokens()
{
    wire_Wire	thewire;
    
    
    /*
     *    Allocate user tokens for the objects
     */
    thewire = wire_Current () ;
    wire_AllocateNamedTokens (thewire, tokenarray) ;
    
    wire_RegisterTag (TAG_GAINWINDOW,		windowquit,	0) ;
    wire_RegisterTag (TAG_PLAYGAIN,		gainHandler,	0) ;
    wire_RegisterTag (TAG_RECORDGAIN,		gainHandler,	0) ;
    wire_RegisterTag (TAG_MONITORVOLUME,	gainHandler,	0) ;
    wire_RegisterTag (TAG_OUTPUTCHOICE,		outputHandler,	0) ;
    wire_RegisterTag (TAG_PAUSEBUTTON,		pauseHandler,	0) ;


    cps_set_object (TAG_GAINWINDOW,	tk_gainWindow,	"gainWindow") ;
    cps_set_object (TAG_PLAYGAIN,	tk_playGain,	"playGain") ;
    cps_set_object (TAG_RECORDGAIN,	tk_recordGain,	"recordGain") ;
    cps_set_object (TAG_MONITORVOLUME,	tk_monitorVolume,"monitorVolume") ;
    cps_set_object (TAG_OUTPUTCHOICE,	tk_outputChoice,"outputChoice") ;
    cps_set_object (TAG_PAUSEBUTTON,	tk_pauseButton,	"pauseButton") ;
}   /* Allocate_gaintool_Tokens() */




/*
 * rungaintool
 *	Loads callbacks and the Interface File
 *
 * Revision History:
 *
 *	Date	Vers	Who	What
 *	===============================================================
 *	900717	1.0	-Auto-	Stubs Generated by TNTGuide from gaintool.G
 */

int
rungaintool (ANSI(void))
{
    int	 i;
    

    scratchTag = wire_AllocateTags (1) ;
	
#if defined (COMPILE_POSTSCRIPT)
    cps_startup (scratchTag) ;
#else
    /*
     *	Load the server interface file gaintool.ps from the current directory
     */
    
    if ((i = loadPostScript("gaintool.ps")) != 0)    /* non zero is a error */
    {
	fprintf (stderr, "gaintool.ps did not load\n") ;
	return  (i) ;		/* Error condition from loadPostScript */
    }
#endif
    
    Allocate_gaintool_Tokens () ;
    
    /*
     * Activate all windows and open those mapped true
     */
    cps_open_windows    () ;
    ps_flush_PostScript () ;
    
    return (0) ;		    /* No error */ 
}   /* rungaintool() */




/*
 * audio_open
 *
 * 	Date	Vers	Who	What
 * 	======================================================================
 * 	17aug90	1.0	PML	New - taken from SunView/XView version.
 */
void
audio_open(ANSI(void))
{
    if  ((Audio_fd = open (audioCtlDev, O_RDWR)) < 0)  {
	perror (audioCtlDev) ;
	exit   (1) ;
    }

    /*
     * Set the notify flag so that this program (and all others with this
     * stream open) will be send a SIGPOLL if changes are made to the
     * parameters of the audio device.
     */
    if  (ioctl (Audio_fd, I_SETSIG, S_MSG) < 0)  {
	perror ("I_SETSIG") ;
	exit   (1) ;
    }

    /*
     * Init the state structure so update_display() will set everything
     */
    AUDIO_INITINFO (&Audio_info) ;
}   /* audio_open() */



/*
 * main ()
 *
 * Revision History:
 *
 *	Date	Vers	Who	What
 *	===============================================================
 *	900717	1.0	-Auto-	Stubs Generated by TNTGuide from gaintool.G
 */

int
main (ANSI(int) argc, ANSI(char *) argv ANSI([]))
    TRAD(int	argc;)
    TRAD(char *	argv[];)
{
    wire_Wire	 thiswire;
    int	 errno;
    int	 results = 0;
    


    /*
     * Open the audio device
     */
    audio_open() ;

    /*
     * Changes to the audio state are signaled to interested programs
     * via SIGPOLL.  Set up a handler.
     */
    signal (SIGPOLL, sigpoll_handler) ;

    /*
     * Reserve some tag values before opening any connections.
     * We use static tag values for these objects so that they can appear
     * as case labels in switch statements.
     */
    if  (! wire_ReserveTags (TAG_ENUM_LIMIT))
    {
	fprintf (stderr, "Could not reserve %d tags.\n", TAG_ENUM_LIMIT) ;
	wire_Close (thiswire) ;
	exit (1) ;
    }

    /*
     * Now open the wire.
     */
    if  ((thiswire = wire_Open (NULL)) == wire_INVALID_WIRE)
    {
	errno = wire_Errno ;
	fprintf(stderr, "\nWire Open Error # %d\n", errno);
    } else {
	/* Successful connection */
	wire_SetCurrent (thiswire) ;
	IF_DEBUG( printf ("\n Wire opened without error\n") );
	errno = 0 ;
    }

    if  (rungaintool())
    {
	fprintf (stderr, "Load File Error \n") ;
	exit (1) ;
    }

    cps_set_icon (tk_gainWindow, icon_data, sizeof(icon_data)) ;

    /*
     * Initialize the display
     */
    getinfo (&Audio_info) ;
    
    cps_set_slider (tk_playGain,      Audio_info.play.gain) ;
    cps_set_slider (tk_recordGain,    Audio_info.record.gain) ;
    cps_set_slider (tk_monitorVolume, Audio_info.monitor_gain) ;
    cps_set_choice (tk_outputChoice,  Audio_info.play.port) ;
    cps_relabel_button (tk_pauseButton,
			Audio_info.play.pause ? "Resume Play" : "Pause Play") ;
    
    
    while (!gntquit)
    {
	/*
	 * Wait for a signal or a tag on the wire.  If a tag is found,
	 * dispatch the handler before returning.
	 */
	(void) wire_Notify ((struct timeval*)NULL) ;

	/*
	 * If there is more on the wire, skip the rest of this loop.
	 */
	if  (wire_WouldNotify(thiswire))	continue ;

	/*
	 * Make sure that the display is in sync with the device.
	 */
	update_display() ;
    }
    
    return 0 ;
}   /* main() */
