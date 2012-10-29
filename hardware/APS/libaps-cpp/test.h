#ifndef TEST_H_
#define TEST_H_

#define APS_TEST 1

namespace test {
	void * buildPulseMemory(int waveformLen , int pulseLen, int pulseType);
	void doStoreLoadTest();
	void doToggleTest();

	void programSquareWaves();
	void streaming();
	void doBulkStateFileTest();
	void doStateFilesTest();

	void printHelp();

	enum PULSE_TYPE {INT_TYPE, FLOAT_TYPE};

}; // name space test

#endif
