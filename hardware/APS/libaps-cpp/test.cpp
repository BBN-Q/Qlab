/*
 * test.cpp
 *
 *  Created on: Jun 24, 2012
 *      Author: cryan
 */


#include "headings.h"

#include "libaps.h"

#include "test.h"

void test::programSquareWaves() {
	int waveformLen = 1001;
	int pulseLen = 500;
	int cnt;
	int ret;

	short int * pulseMem = 0;

	pulseMem = (short int *) buildPulseMemory(waveformLen , pulseLen,INT_TYPE);
	if (pulseMem == 0) return;

	// load memory
	for (cnt = 0 ; cnt < 4; cnt++ ) {
		printf("Loading Waveform: %i\n", cnt);
		fflush(stdout);
		ret = set_waveform_int(0, cnt, pulseMem, waveformLen);

		if (ret < 0)
			printf("Error: %i\n",ret);
		else
			printf("Done\n");
	}

	if (pulseMem) free(pulseMem);
}

void test::loadSequenceFile() {
	set_trigger_interval(0, 0.001);
	load_sequence_file(0, "U:\\AWG-Edison\\Ramsey\\Ramsey-BBNAPS1.h5");
	for (int ch = 0; ch < 4; ch++ ) {
		set_channel_enabled(0, ch, 1);
	}
	set_run_mode(0, 0, 1);
	set_run_mode(0, 2, 1);
}

void test::streaming() {
	set_trigger_interval(0, 0.0001);
	load_sequence_file(0, "U:\\APS\\Ramsey-Streaming.h5");
	set_channel_enabled(0, 0, 1);
	set_run_mode(0, 0, 1);
	run(0);
	Sleep(10000);
	stop(0);
}

void test::doBulkStateFileTest() {
	programSquareWaves();

	save_bulk_state_file();
	read_bulk_state_file();
}

void test::doStateFilesTest() {
	programSquareWaves();


	save_state_files();
	read_state_files();
}

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

	int ask;
	char cmd;

	programSquareWaves();

	set_trigger_source(0,0);

	//Enable all channels
	for (int ct=0; ct<4; ct++){
		set_channel_enabled(0, ct, 1);
	}

	ask = 1;
	cout << "Cmd: [t]rigger [d]isable e[x]it: ";
	while(ask) {

		cmd = getchar();

		switch (toupper(cmd)) {

		case 'T':
			printf("Triggering");
			run(0);
			break;

		case 'D':
			printf("Disabling");
			stop(0);
			break;

		case 'X':case 'x':
			printf("Exiting\n");
			stop(0);
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

	set_trigger_source(0, 0);
	run(0);

	printf("Press key:\n");
	getchar();

	stop(0);

}

void test::getSetTriggerInterval(){
	set_trigger_interval(0, 10e-3);
	double interval = get_trigger_interval(0);
	printf("Set trigger interval to 10e-3. Read back: %f\n", interval);
}

void test::printHelp(){
	string spacing = "   ";
	cout << "BBN APS C++ Test Bench" << endl;
	cout << spacing << "-b  <bitfile> Path to bit file" << endl;
	cout << spacing << "-t  Toggle Test" << endl;
	cout << spacing << "-w  Run Waveform StoreLoad Tests" << endl;
	cout << spacing << "-stream LL Streaming Test" << endl;
	cout << spacing << "-bf Run Bulk State File Test" << endl;
	cout << spacing << "-sf Run  State File Test" << endl;
	cout << spacing << "-d  Used default DACII bitfile" << endl;
	cout << spacing << "-0  Redirect log to stdout" << endl;
	cout << spacing << "-h  Print This Help Message" << endl;
	cout << spacing << "-wf Program square wave" << endl;
	cout << spacing << "-trig Get/Set trigger interval" << endl;
	cout << spacing << "-seq Load sequence file" << endl;
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

	int err;

	set_logging_level(logDEBUG1);

	if (cmdOptionExists(argv, argv + argc, "-h")) {
		test::printHelp();
		return 0;
	}

	string bitFile = getCmdOption(argv, argv + argc, "-b");

	if (cmdOptionExists(argv, argv + argc, "-d")) {
		bitFile = "../bitfiles/mqco_dac2_latest";
	}


	if (bitFile.length() == 0) {
		bitFile = "../bitfiles/mqco_aps_latest";
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

	err = initAPS(0, const_cast<char*>(bitFile.c_str()), true);

	if (err != APS_OK) {
		cout << "Error initializing APS Rack: " << err << endl;
		exit(-1);
	}

//	vector<float> waveform(0);
//
//	for(int ct=0; ct<1000;ct++){
//		waveform.push_back(float(ct)/1000);
//	}

//	stop(0);
//	set_waveform_float(0, 0, &waveform.front(), waveform.size());
//	set_run_mode(0, 0, 0);
//	run(0);
//	Sleep(1);
//	stop(0);

	// select test to run

	if (cmdOptionExists(argv, argv + argc, "-wf")) {
		test::programSquareWaves();
	}

	if (cmdOptionExists(argv, argv + argc, "-stream")) {
		test::streaming();
	}

	if (cmdOptionExists(argv, argv + argc, "-t")) {
		test::doToggleTest();
	}

	if (cmdOptionExists(argv, argv + argc, "-w")) {
		test::doStoreLoadTest();
	}

	if (cmdOptionExists(argv, argv + argc, "-bf")) {
		test::doBulkStateFileTest();
	}

	if (cmdOptionExists(argv, argv + argc, "-sf")) {
		test::doStateFilesTest();
	}

	if (cmdOptionExists(argv, argv + argc, "-trig")) {
		test::getSetTriggerInterval();
	}

	if (cmdOptionExists(argv, argv + argc, "-seq")) {
			test::loadSequenceFile();
	}

	disconnect_by_ID(0);

	cout << "Made it through!" << endl;

	return 0;

}


