#ifndef TEST_H_
#define TEST_H_


namespace test {
	void * buildPulseMemory(int waveformLen , int pulseLen, int pulseType);
	void doStoreLoadTest();
	void doToggleTest();


	void printHelp();

	enum PULSE_TYPE {INT_TYPE, FLOAT_TYPE};

}; // name space test

#endif
