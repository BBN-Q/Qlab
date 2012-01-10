/**********************************************
* Module Name : test.c
*
* Author/Date : B.C. Donovan / 21-Oct-08
*
* Description : Test bench for libaps.dll
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
* $Author: bdonovan $
* $Date$
* $Locker:  $
* $Name:  $
* $Revision$
*
* Copyright (C) BBN Technologies Corp. 2008-2011
**********************************************/

#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdint.h>
#include <limits.h>

#ifdef __CYGWIN__
	#include "windows.h"
#elif __APPLE__
	#include "WinTypes.h"
	#include <dlfcn.h>
#else
	#include "WinTypes.h"
	#include <dlfcn.h>
#endif

#include "aps.h"

#ifdef __CYGWIN__
	#define GetFunction GetProcAddress
#else
	#define GetFunction dlsym
#endif

#define is64Bit (sizeof(size_t)== 8)

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
	pfunc read_version;

	int waveformLen = 1000;
	int pulseLen = 500;
	int cnt;
	int ask;
	int ret;
	char cmd;
	FILE * fp;
	int bitFileSize,numRead;
	unsigned char * bitFileData;

	unsigned short * pulseMem;

	open = (pfunc)GetFunction(hdll,"APS_Open");
	trigger = (pfunc) GetFunction(hdll,"APS_TriggerFpga");
	disable = (pfunc) GetFunction(hdll,"APS_DisableFpga");
	load    = (pfunc) GetFunction(hdll,"APS_LoadWaveform");
	close = (pfunc)GetFunction(hdll,"APS_Close");
	prog =  (pfunc)GetFunction(hdll,"APS_ProgramFpga");
	setup_vco = (pfunc)GetFunction(hdll,"APS_SetupVCXO");
	setup_pll = (pfunc)GetFunction(hdll,"APS_SetupPLL");
	read_version = (pfunc)GetFunction(hdll,"APS_ReadBitFileVersion");


	pulseMem = malloc(waveformLen * sizeof(unsigned short));
	if (!pulseMem) {
		printf("Error Allocating Memory\n");
		return;
	}

	printf("Reading bitfile from %s.\n", bitFile);

	fp = fopen(bitFile,"rb");
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

	printf("Read %i bytes\n", numRead);

	printf("Opening Dac 0: ");
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
	int numBytesProg;
	numBytesProg = prog(0, bitFileData, bitFileSize, 3);
	printf("Done \n");

	printf("Programmed: %i bytes\n", numBytesProg);

	free(bitFileData);

	// test bit file version
	int version;
	version = read_version(0);
	printf("Found bitfile version: %i\r\n", version);

	if (version != 16) {
		printf("Error version does not matched expected\n");
		exit(-1);
	}

	for(cnt = 0; cnt < waveformLen; cnt++)
		pulseMem[cnt] = (cnt < pulseLen) ? (int) floor(0.8*8192) : 0;

	// load memory
	for (cnt = 0 ; cnt < 4; cnt++ ) {
		printf("Loading Waveform: %i ", cnt);
		fflush(stdout);
		ret = load(0, pulseMem, waveformLen,0, cnt, 0);
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
				printf("Triggering");
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

			case 'X':case 'x':
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
				break;
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
	int bitdepth = sizeof(size_t) == 8 ? 64 : 32;
	printf("BBN APS C Test Bench $Rev$ %i-Bit\n", bitdepth);
	printf("   -t <bitfile> Trigger Loop Test\n");
	printf("   -s List Available APS Serial Numbers\n");
	printf("   -ks List Known APS Serial Numbers\n");
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

	char *libName;

#ifdef __CYGWIN__
	if (!is64Bit) {
		libName = "libaps.dll";
	} else {
		libName = "libaps64.dll";
	}
	hdll = LoadLibrary(libName);
#elif __APPLE__
	hdll = dlopen("libaps.dylib",RTLD_LAZY);
#else
	hdll = dlopen("./libaps.so",RTLD_LAZY);
#endif

#ifdef __CYGWIN__
	if ((uintptr_t)hdll <= HINSTANCE_ERROR) {
		printf("Error opening libaps library\n");
		return -1;
	}
#else
	if (hdll == NULL){
	printf("Error opening libaps library: %s\n",dlerror());
	return -1;
	}

#endif

	open = (pfunc)GetFunction(hdll,"APS_Open");
	close = (pfunc)GetFunction(hdll,"APS_Close");
	setup_vco = (pfunc)GetFunction(hdll,"APS_SetupVCXO");
	setup_pll = (pfunc)GetFunction(hdll,"APS_SetupPLL");
	serials = (pfunc)GetFunction(hdll,"APS_GetSerialNumbers");
	listserials = (pfunc)GetFunction(hdll,"APS_ListSerials");
	getserial = (pfunc)GetFunction(hdll,"APS_GetSerial");
	openbyserial = (pfunc)GetFunction(hdll,"APS_OpenByID");

	if (argc == 1) printHelp();

	for(cnt = 0; cnt < argc; cnt++) {
		if (strcmp(argv[cnt],"-t") == 0)
			doToggleTest(hdll,argv[cnt+1]);
		if (strcmp(argv[cnt],"-ks") == 0) {
			listserials();
		}
		if (strcmp(argv[cnt],"-s") == 0) {
			serials();
		}
		if (strcmp(argv[cnt],"-h") == 0)
			printHelp();
	}


	return 0;
}
