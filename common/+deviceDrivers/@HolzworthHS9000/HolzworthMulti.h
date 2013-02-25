/*******************************************************************/
/*                                                                 */
/* File Name:   HolzworthMulti.h                                   */
/*                                                                 */
/*                                                                 */
/*******************************************************************/

#ifdef __cplusplus
extern "C" {
#endif

    //Use the functions below for HS9000 series or legacy
	__declspec(dllexport) int deviceAttached(const char *serialnum);
	__declspec(dllexport) int openDevice(const char *serialnum);
    __declspec(dllexport) char* getAttachedDevices(void);
    __declspec(dllexport) void close_all (void);
    
    //Use the function below for HS9000 series only
	__declspec(dllexport) char* usbCommWrite(const char *serialnum, const char *pBuf);
    
    //Use the functions below for legacy only
	__declspec(dllexport) int RFPowerOn(const char *serialnum);
	__declspec(dllexport) int RFPowerOff(const char *serialnum);
	__declspec(dllexport) short isRFPowerOn(const char *serialnum);
	__declspec(dllexport) int setPower(const char *serialnum, short powernum);
	__declspec(dllexport) int setPowerS(const char *serialnum, const char *powerstr);
	__declspec(dllexport) short readPower(const char *serialnum);
	__declspec(dllexport) int setPhase(const char *serialnum, short phasenum);
	__declspec(dllexport) int setPhaseS(const char *serialnum, const char *phasestr);
	__declspec(dllexport) short readPhase(const char *serialnum);
	__declspec(dllexport) int setFrequency(const char *serialnum, long long frequencynum);
	__declspec(dllexport) int setFrequencyS(const char *serialnum, const char *frequencystr);
	__declspec(dllexport) long long readFrequency(const char *serialnum);
	__declspec(dllexport) int recallFactoryPreset(const char *serialnum);
	__declspec(dllexport) int saveCurrentState(const char *serialnum);
	__declspec(dllexport) int recallSavedState(const char *serialnum);
	__declspec(dllexport) int ModEnableNo(const char *serialnum);
	__declspec(dllexport) int ModEnableFM(const char *serialnum);
	__declspec(dllexport) int ModEnablePulse(const char *serialnum);
	__declspec(dllexport) int ModEnablePM(const char *serialnum);
	__declspec(dllexport) int setFMDeviation(const char *serialnum, short fmDevnum);
	__declspec(dllexport) int setFMDeviationS(const char *serialnum,const char *fmDevstr);
	__declspec(dllexport) int setPMDeviation(const char *serialnum, short pmnum);
	__declspec(dllexport) int setPMDeviationS(const char *serialnum,const char *pmstr);

	__declspec(dllexport) char* write_string3(const char* serialnum, const char *pBuf);

#ifdef __cplusplus
}
#endif