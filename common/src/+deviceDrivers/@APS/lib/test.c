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
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdint.h>
#include <limits.h>

// BUILD_DLL define
// Use to switch between a statically linked test and a dynamically linked test
// Static link test is useful for printing debug output to console during debug
// Set define using Makefile

#ifdef __CYGWIN__
	#include "windows.h"
#elif __APPLE__
	#include "WinTypes.h"
	#include <dlfcn.h>
#else
	#include "WinTypes.h"
	#include <dlfcn.h>
#endif

#ifdef BUILD_DLL
#include "aps.h"
#else
#include "libaps.h"
#endif

#include "waveform.h"

#ifdef __CYGWIN__
	#define GetFunction GetProcAddress
#else
	#define GetFunction dlsym
#endif

#define is64Bit (sizeof(size_t) == 8)

#define FALSE 0
#define TRUE 1

typedef int (*pfunc)();

// redefine names for APS library calls
// this is done to support both static and dynamic linking
#ifndef BUILD_DLL
#define prog              APS_ProgramFpga
#define setup_vco         APS_SetupVCXO
#define setup_pll         APS_SetupPLL
#define read_version      APS_ReadBitFileVersion
#define open              APS_Open
#define close             APS_Close
#define setWaveform       APS_SetWaveform
#define setLinkList       APS_SetLinkList
#define setWaveformOffset APS_GetWaveformOffset
#define getWaveformOffset APS_GetWaveformOffset
#define setWaveformScale  APS_SetWaveformScale
#define getWaveformScale  APS_GetWaveformScale
#define loadStored        APS_LoadStoredWaveform
#define loadAll       	  APS_LoadAllWaveforms
#define trigger           APS_TriggerFpga
#define disable           APS_DisableFpga
#define load              APS_LoadWaveform
#define serials           APS_GetSerialNum
#define listserials       APS_PrintSerialNumbers
#define getserial         APS_GetSerial
#define openbyserial      APS_OpenByID
#define saveCache         APS_SaveWaveformCache
#define loadCache         APS_LoadWaveformCache
#define startThread       APS_StartLinkListThread
#endif

void programFPGA(HANDLE hdll, int dac, char * bitFile, int progamTest) {

#ifdef BUILD_DLL
	pfunc prog;
	pfunc setup_vco;
	pfunc setup_pll;
	pfunc read_version;

	prog         = (pfunc) GetFunction(hdll,"APS_ProgramFpga");
	setup_vco    = (pfunc) GetFunction(hdll,"APS_SetupVCXO");
	setup_pll    = (pfunc) GetFunction(hdll,"APS_SetupPLL");
	read_version = (pfunc) GetFunction(hdll,"APS_ReadBitFileVersion");
#endif

	FILE * fp;
	int bitFileSize,numRead;
	unsigned char * bitFileData;

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
	}

	numRead = fread(bitFileData,sizeof(unsigned char),bitFileSize,fp);
	if (numRead != bitFileSize) {
		printf("Error loading bit file data: Expected %i Got %i\n", bitFileSize, numRead);
		free(bitFileData);
	}

	fclose(fp);

	printf("Read %i bytes\n", numRead);

	setup_vco(dac);
	setup_pll(dac);


	int progCnt = 0;
	int maxProg;

	maxProg = progamTest ? 100: 1;
	maxProg = 1;
	for (progCnt = 0; progCnt < maxProg; progCnt++) {
		printf("Programming FPGAS %i: ", progCnt);
		fflush(stdout);
		int numBytesProg;
		numBytesProg = prog(0, bitFileData, bitFileSize, 3, 0x10);
		printf("Done \n");

		printf("Programmed: %i bytes\n", numBytesProg);
		if (numBytesProg < 0) {
			printf("Failed at: %i\n", progCnt);
			break;
		}
	}

	free(bitFileData);

	if (progamTest)
		exit(0);

	// test bit file version
	int version;
	version = read_version(0);
	printf("Found bitfile version: %i\r\n", version);

	if (version != 16) {
		printf("Error version does not matched expected\n");
		exit(-1);
	}

	return;

}

int openDac(HANDLE hdll, int dac) {

#ifdef BUILD_DLL
	pfunc open;
	open = (pfunc) GetFunction(hdll, "APS_Open");
#endif

	int err;

	printf("Opening Dac %i: ", dac);
	fflush(stdout);
	err = open(dac,TRUE);
	if (err < 0)  {
		printf("Error Opened Return %i\n", err);
		return -1;
	}
	printf("Done\n");
	return 0;
}


// integerVersion

void * buildPulseMemory(int waveformLen , int pulseLen, int pulseType) {
	int cnt;
	void * pulseMem;
	float * pulseMemFloat;
	unsigned short * pulseMemInt;
	if (pulseType == INT_TYPE) {
		pulseMemInt = malloc(waveformLen * sizeof(short));
		pulseMem = pulseMemInt;
	} else {
		pulseMemFloat = malloc(waveformLen * sizeof(float));
		pulseMem = pulseMemFloat;
	}

	if (!pulseMem) {
		printf("Error Allocating Memory\n");
		return 0;
	}

	for(cnt = 0; cnt < waveformLen; cnt++) {
		if (pulseType == INT_TYPE) {
			pulseMemInt[cnt] = (cnt < pulseLen) ? (int) floor(0.8*8192) : 0;
		} else {
			pulseMemFloat[cnt] = (cnt < pulseLen) ? 1.0 : 0;
		}
	}
	return pulseMem;
}

void doStoreLoadTest(HANDLE hdll, char * bitFile, int doSetup) {
	int waveformLen = 1000;
	int pulseLen = 500;

	short * pulseMem;

	int cnt;

#ifdef BUILD_DLL
	pfunc close;
	pfunc setWaveform, setLinkList;
	pfunc setWaveformOffset, getWaveformOffset;
	pfunc setWaveformScale,  getWaveformScale;
	pfunc loadStored, loadAll;
	pfunc load;
	pfunc saveCache, loadCache;

	pfunc trigger;
	pfunc disable;

	close             = (pfunc) GetFunction(hdll, "APS_Close");
	setWaveform       = (pfunc) GetFunction(hdll, "APS_SetWaveform");
	setLinkList       = (pfunc) GetFunction(hdll, "APS_SetLinkList");
	setWaveformOffset = (pfunc) GetFunction(hdll, "APS_GetWaveformOffset");
	getWaveformOffset = (pfunc) GetFunction(hdll, "APS_GetWaveformOffset");
	setWaveformScale  = (pfunc) GetFunction(hdll, "APS_SetWaveformScale");
	getWaveformScale  = (pfunc) GetFunction(hdll, "APS_GetWaveformScale");
	load              = (pfunc) GetFunction(hdll,"APS_LoadWaveform");
	loadStored        = (pfunc) GetFunction(hdll, "APS_LoadStoredWaveform");
	loadAll           = (pfunc) GetFunction(hdll, "APS_LoadAllWaveforms");
	saveCache         = (pfunc) GetFunction(hdll, "APS_SaveWaveformCache");
	loadCache         = (pfunc) GetFunction(hdll, "APS_LoadWaveformCache");

	trigger      = (pfunc) GetFunction(hdll,"APS_TriggerFpga");
	disable      = (pfunc) GetFunction(hdll,"APS_DisableFpga");

#endif

	pulseMem = (short *) buildPulseMemory(waveformLen, pulseLen, INT_TYPE);
	if (pulseMem == 0) return;

	if (openDac(hdll,0) < 0) return;

	if (doSetup) {
		programFPGA(hdll,0, bitFile,0);

		printf("Loading and storing waveforms\n");

		for( cnt = 0; cnt < 4; cnt++)
			load(0, pulseMem, waveformLen, 0, cnt, FALSE, TRUE);

		//printf("Loading Waveform\n");
		//loadAll(0);

		printf("Saving Cache\n");
		saveCache(0,0);
	}

	printf("Loading Cache\n");
	loadCache(0,0);

	printf("Triggering:\n");

	trigger(0, 0, 1);
	trigger(0, 2, 1);

	printf("Press key:\n");
	getchar();

	disable(0,0);
	disable(0,2);

	close(0);
}

void doToggleTest(HANDLE hdll, char * bitFile, int programTest) {

	int waveformLen = 1000;
	int pulseLen = 500;
	int cnt;
	int ask;
	int ret;
	char cmd;

	unsigned short * pulseMem = 0;

#ifdef BUILD_DLL
	pfunc load;
	pfunc trigger;
	pfunc disable;
	pfunc close;

	trigger      = (pfunc) GetFunction(hdll,"APS_TriggerFpga");
	disable      = (pfunc) GetFunction(hdll,"APS_DisableFpga");
	load         = (pfunc) GetFunction(hdll,"APS_LoadWaveform");
	close        = (pfunc) GetFunction(hdll,"APS_Close");
#endif

	pulseMem = (unsigned short *) buildPulseMemory(waveformLen, pulseLen, INT_TYPE);
	if (pulseMem == 0) return;

	if (openDac(hdll,0) < 0) return;

	programFPGA(hdll,0, bitFile, 0);

	// load memory
	for (cnt = 0 ; cnt < 4; cnt++ ) {
		printf("Loading Waveform: %i ", cnt);
		fflush(stdout);
		ret = load(0, pulseMem, waveformLen,0, cnt, FALSE, FALSE);

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
	printf("   -p <bitfile> Program Loop Test\n");
	printf("   -s List Available APS Serial Numbers\n");
	printf("   -ks List Known APS Serial Numbers\n");
	printf("   -w  Run Waveform StoreLoad Tests\n");
	printf("   -x  Test Threading\n");
	printf("   -h  Print This Help Message\n");
}

int main (int argc, char** argv) {

	// require that the handle to the dll is declared
	// even if it is not being used
	HANDLE hdll = 0;

#ifdef BUILD_DLL
	pfunc serials;
	pfunc listserials;
	pfunc openbyserial;
	pfunc getserial;
	pfunc startThread;
	char *libName;
#endif

	int cnt;

	char *defaultBitFile = "../mqco_aps_latest.bit";
	char *bitFile = defaultBitFile;

#ifdef BUILD_DLL
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

	serials      = (pfunc)GetFunction(hdll,"APS_GetSerialNum");
	listserials  = (pfunc)GetFunction(hdll,"APS_PrintSerialNumbers");
	getserial    = (pfunc)GetFunction(hdll,"APS_GetSerial");
	openbyserial = (pfunc)GetFunction(hdll,"APS_OpenByID");
	//startThread  = (pfunc)GetFunction(hdll,"APS_StartLinkListThread");
#endif

	char serialBuffer[100];

	if (argc == 1) printHelp();

	for(cnt = 0; cnt < argc; cnt++) {

		if (strcmp(argv[cnt],"-t") == 0) {
			// allow bit file to be passed in otherwise use default
			if (argc > (cnt+1)) bitFile = argv[cnt+1];
				doToggleTest(hdll,bitFile,0);
		}
		if (strcmp(argv[cnt],"-p") == 0) {
			if (argc > (cnt+1)) bitFile = argv[cnt+1];
				doToggleTest(hdll,bitFile,1);
		}
		if (strcmp(argv[cnt],"-ks") == 0) {
			listserials();
		}
		if (strcmp(argv[cnt],"-s") == 0) {
			serials(0,serialBuffer,100);
			printf("Serial #: %s\n", serialBuffer);
		}
		if (strcmp(argv[cnt],"-h") == 0)
			printHelp();
		if (strcmp(argv[cnt],"-x") == 0) {
			//startThread(0,0);
			//startThread(0,1);
			Sleep(10);
		}
		if (strcmp(argv[cnt],"-w") == 0) {
			// allow bit file to be passed in otherwise use default
			if (argc > (cnt+1)) bitFile = argv[cnt+1];
			int doSetup;
			doSetup = (argc > (cnt+2)) ? atoi(argv[cnt+2]) : 1;
			doStoreLoadTest(hdll,bitFile,doSetup);
		}
	}


	return 0;
}
