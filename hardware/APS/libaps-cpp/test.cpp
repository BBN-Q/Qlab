/*
 * test.cpp
 *
 *  Created on: Jun 24, 2012
 *      Author: cryan
 */

#include "headings.h"

#include "libaps.h"

#include "test.h"


void * test::buildPulseMemory(int waveformLen , int pulseLen, int pulseType) {
	int cnt;
	void * pulseMem;
	float * pulseMemFloat;
	short int * pulseMemInt;

	if (pulseType == INT_TYPE) {
		pulseMemInt = (short int *) malloc(waveformLen * sizeof(short int));
		pulseMem = (void *) pulseMemInt;
	} else {
		pulseMemFloat = (float *) malloc(waveformLen * sizeof(float));
		pulseMem = (void *) pulseMemFloat;
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

void test::doToggleTest() {

	int waveformLen = 1000;
	int pulseLen = 500;
	int cnt;
	int ask;
	int ret;
	char cmd;

	short int * pulseMem = 0;

	pulseMem = (short int *) buildPulseMemory(waveformLen , pulseLen,INT_TYPE);
	if (pulseMem == 0) return;

	// load memory
	for (cnt = 0 ; cnt < 4; cnt++ ) {
		printf("Loading Waveform: %i ", cnt);
		fflush(stdout);
		ret = set_waveform_int(0, cnt, pulseMem, waveformLen);

		if (ret < 0)
			printf("Error: %i\n",ret);
		else
			printf("Done\n");
	}

	set_trigger_source(0,SOFTWARE_TRIGGER);

	ask = 1;
	cout << "Cmd: [t]rigger [d]isable e[x]it: ";
	while(ask) {

		cmd = getchar();

		switch (toupper(cmd)) {

		case 'T':
			printf("Triggering");
			trigger_FPGA_debug(0, 0);
			trigger_FPGA_debug(0, 2);
			break;

		case 'D':
			printf("Disabling");
			disable_FPGA_debug(0,0);
			disable_FPGA_debug(0,2);
			break;

		case 'X':case 'x':
			printf("Exiting\n");
			disable_FPGA_debug(0,0);
			disable_FPGA_debug(0,2);
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
		cout << "\nCmd: [t]rigger [d]isable e[x]it: ";
	}

	if (pulseMem) free(pulseMem);

	close(0);

}

void test::doStoreLoadTest() {
	int waveformLen = 1000;
	int pulseLen = 500;

	float * pulseMem;

	int cnt;

	pulseMem = (float *) buildPulseMemory(waveformLen , pulseLen, FLOAT_TYPE);
	if (pulseMem == 0) return;

	printf("Storing Waveform\n");

	for( cnt = 0; cnt < 4; cnt++)
		set_waveform_float(0, cnt, pulseMem, waveformLen);

	printf("Saving Cache\n");
	//saveCache(0,0);


	printf("Loading Cache\n");
	//loadCache(0,0);

	printf("Triggering:\n");

	set_trigger_source(0,SOFTWARE_TRIGGER);
	run(0);

	printf("Press key:\n");
	getchar();

	stop(0);

}

void test::printHelp(){
	string spacing = "   ";
	cout << "BBN APS C++ Test Bench" << endl;
	cout << spacing << "-b <bitfile> Path to bit file" << endl;
	cout << spacing << "-t Toggle Test" << endl;
	cout << spacing << "-w Run Waveform StoreLoad Tests" << endl;
	cout << spacing << "-0 Redirect log to stdout" << endl;
	cout << spacing << "-h Print This Help Message" << endl;
}

// command options functions taken from:
// http://stackoverflow.com/questions/865668/parse-command-line-arguments
string getCmdOption(char ** begin, char ** end, const std::string & option)
{
	char ** itr = std::find(begin, end, option);
	if (itr != end && ++itr != end)
	{
		return string(*itr);
	}
	return "";
}

bool cmdOptionExists(char** begin, char** end, const std::string& option)
{
	return std::find(begin, end, option) != end;
}


int main(int argc, char** argv) {

	if (cmdOptionExists(argv, argv + argc, "-h")) {
		test::printHelp();
		return 0;
	}

	string bitFile = getCmdOption(argv, argv + argc, "-b");

	if (bitFile.length() == 0) {
		bitFile = "../../../common/src/+deviceDrivers/@APS/mqco_aps_latest.bit";
	}

	cout << "Programming using: " << string(bitFile) << endl;

	//Initialize the APSRack from the DLL
	init();

	if (cmdOptionExists(argv, argv + argc, "-0")) {
		char s[] = "stdout";
		set_log(s);
	}

	//Connect to device
	connect_by_ID(0);

	initAPS(0, const_cast<char*>(bitFile.c_str()), false);

	vector<float> waveform(0);

	for(int ct=0; ct<1000;ct++){
		waveform.push_back(float(ct)/1000);
	}

	set_waveform_float(0, 0, &waveform.front(), waveform.size());

	// select test to run

	if (cmdOptionExists(argv, argv + argc, "-t")) {
		test::doToggleTest();
	}

	if (cmdOptionExists(argv, argv + argc, "-w")) {
		test::doStoreLoadTest();
	}


	disconnect_by_ID(0);

//	APS tmpAPS;
//	cout << "tmpAPS" << endl;
//	tmpAPS.load_sequence_file("RamseyBBNAPS34.h5");

	cout << "Made it through!" << endl;

	return 0;

}


