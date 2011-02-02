/**********************************************
* Module Name : test.c
*
* Author/Date : B.C. Donovan / 21-Oct-08
*
* Description : Test bench for libdacii.dll
*
* Restrictions/Limitations :
*
*
* Change Descriptions :
*
* Classification : Unclassified
*
* References :
*
*
*    Modified    By    Reason
*    --------    --    ------
*                BCD
*
* CVS header info.
* ----------------
* $CVSfile$
* $Author: bdonovan $
* $Date$
* $Locker:  $
* $Name:  $
* $Revision$
*
* $Log: test.c,v $
* Revision 1.7  2008/12/03 15:47:57  bdonovan
* Added support for multiple DAC boxes to libdacii. Updated dacii.m for new api.
*
* Revision 1.1  2008/10/23 20:41:35  bdonovan
* First version of CMD Builder GUI that uses C dll to communicate with DACII board.
*
* C library to communicate with board is in ./lib.
*
* Matlab code has been reorganized into classes. GUI is not edited with the guide command
* in matlab.
*
* Independent triggering of each of the 4 DACs has been confirmed for both software
*  and hardware triggering with cbl_dac2_r3beta.bit
*
*
* Copyright (C) BBN Technologies Corp. 2008
**********************************************/

#include <stdio.h>
#include <string.h>

#ifdef __CYGWIN__
	#include "windows.h"
#elif __APPLE__
	#include "wintypes.h"
	#include <dlfcn.h>
#else
	#include "WinTypes.h"
	#include <dlfcn.h>
#endif

#include "dacii.h"

#ifdef __CYGWIN__
	#define GetFunction GetProcAddress
#else
	#define GetFunction dlsym
#endif

typedef int (*pfunc)();

void doToggleTest(HANDLE hdll, char * bitFile) {
	pfunc load;
	pfunc trigger;
	pfunc disable;
	pfunc open;
	pfunc close;
	pfunc prog;
	pfunc setup_vco;
	pfunc setup_pll;

	int waveformLen = 4000;
	int pulseLen = 10;
	int cnt;
	int ask;
	int ret;
	char cmd;
	FILE * fp;
	int bitFileSize,numRead;
	unsigned char * bitFileData;

	unsigned short * pulseMem;

	open = (pfunc)GetFunction(hdll,"DACII_Open");
	trigger = (pfunc) GetFunction(hdll,"DACII_TriggerFpga");
	disable = (pfunc) GetFunction(hdll,"DACII_DisableFpga");
	load    = (pfunc) GetFunction(hdll,"DACII_LoadWaveform");
	close = (pfunc)GetFunction(hdll,"DACII_Close");
	prog =  (pfunc)GetFunction(hdll,"DACII_ProgramFpga");
	setup_vco = (pfunc)GetFunction(hdll,"DACII_SetupVCXO");
	setup_pll = (pfunc)GetFunction(hdll,"DACII_SetupPLL");


	pulseMem = malloc(waveformLen * sizeof(unsigned short));
	if (!pulseMem) {
		printf("Error Allocating Memory\n");
		return;
	}

	fp = fopen(bitFile,"r");
	if (!fp) {
		printf("Error opening bit file: %s\n", bitFile);
		return;
	}

	fseek(fp,0,SEEK_END);
	bitFileSize = ftell(fp);
	fseek(fp,0,SEEK_SET);

	bitFileData = malloc(bitFileSize * sizeof(unsigned char));
	if (!bitFileData) {
		printf("Error allocating memory\n");
		goto dealloc;
	}

	numRead = fread(bitFileData,sizeof(unsigned char),bitFileSize,fp);
	if (numRead != bitFileSize) {
		printf("Error loading bit file data: Expected %i Got %i\n", bitFileSize, numRead);
		free(bitFileData);
		goto dealloc;
	}

	fclose(fp);

	printf("Openning Dac 0: ");
	fflush(stdout);
	if (open(0) < 0)  {
		printf("Error\n");
		return;
	}
	printf("Done\n");

	setup_vco(0);
	setup_pll(0);

	printf("Programming FPGAS: ");
	fflush(stdout);
	prog(0, bitFileData, bitFileSize, 3);
	printf("Done \n");

	free(bitFileData);

	for(cnt = 0; cnt < waveformLen; cnt++)
		pulseMem[cnt] = (cnt < pulseLen) ? (int) floor(0.8*8192) : 0;

	// load memory
	for (cnt = 0 ; cnt < 4; cnt++ ) {
		printf("Loading Waveform: %i ", cnt);
		fflush(stdout);
		ret = load(0, pulseMem, waveformLen,0, cnt);
		if (ret < 0)
			printf("Error: %i\n",ret);
		else
			printf("Done\n");
	}

	ask = 1;
	printf("Cmd: [t]rigger [p]ause [d]isable e[x]it: ");
	while(ask) {

		cmd = getchar();

		switch (toupper(cmd)) {

			case 'T':
				printf("Triggering");case 'x':
				trigger(0, 0, 1);
				trigger(0, 2, 1);
				break;

			case 'P':
				printf("Pausing");
				disable(0,0);
				disable(0,2);
				break;

			case 'D':
				printf("Disabling");
				disable(0,0);
				disable(0,2);
				break;

			case 'X':
				printf("Exiting\n");
				disable(0,0);
				disable(0,2);
				ask = 0;
				continue;
			case '\r':
			case '\n':
				continue;
			default:
				printf("No command: %c", cmd);
		}
		// written this way to handle interactive session where
		// input is buffered until \n'
		printf("\nCmd: [t]rigger [p]ause [d]isable e[x]it: ");
	}

dealloc:
	if (pulseMem) free(pulseMem);

	close(0);

}

void printHelp(){
	printf("BBN DacII C Test Bench $Rev$\n");
	printf("   -t Trigger Loop Test\n");
	printf("   -s List Available Dac Serial Numbers\n");
	printf("   -ks List Known Dac Serial Numbers\n");
	printf("   -h Print This Help Message\n");
}

int main (int argc, char** argv) {

	HANDLE hdll;

	pfunc open;
	pfunc close;
	pfunc setup_vco;
	pfunc setup_pll;
	pfunc serials;
	pfunc listserials;
	pfunc openbyserial;
	pfunc getserial;

	int cnt;
	int ret;

#ifdef __CYGWIN__
	hdll = LoadLibrary("libdacii.dll");
#elif __APPLE__
	hdll = dlopen("libdacii.dylib",RTLD_LAZY);
#else
	hdll = dlopen("./libdacii.so",RTLD_LAZY);
#endif

#ifdef __CYGWIN__
	if ((int)hdll <= HINSTANCE_ERROR) {
		printf("Error opening libdacii library\n");
		return -1;
	}
#else
	if (hdll == NULL){
	printf("Error opening libdacii library: %s\n",dlerror());
	return -1;
	}

#endif

	open = (pfunc)GetFunction(hdll,"DACII_Open");
	close = (pfunc)GetFunction(hdll,"DACII_Close");
	setup_vco = (pfunc)GetFunction(hdll,"DACII_SetupVCXO");
	setup_pll = (pfunc)GetFunction(hdll,"DACII_SetupPLL");
	serials = (pfunc)GetFunction(hdll,"DACII_GetSerialNumbers");
	listserials = (pfunc)GetFunction(hdll,"DACII_ListCBLSerials");
	getserial = (pfunc)GetFunction(hdll,"DACII_GetCBLSerial");
	openbyserial = (pfunc)GetFunction(hdll,"DACII_OpenByCBLID");

	if (argc == 1) printHelp();

	int id;
	for(cnt = 0; cnt < argc; cnt++) {
		if (strcmpi(argv[cnt],"-t") == 0)
			doToggleTest(hdll,argv[cnt+1]);
		if (strcmpi(argv[cnt],"-ks") == 0)
			listserials();
		if (strcmpi(argv[cnt],"-s") == 0)
			serials();
		if (strcmpi(argv[cnt],"-h") == 0)
			printHelp();
	}


	return 0;
}
