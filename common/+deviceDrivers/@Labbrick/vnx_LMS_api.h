// Include file for 64 Bit Vaunix Lab Brick LMS Synthesizer DLL
//
// 10/2013	RD	64 Bit DLL version.
//


// The following ifdef block is the standard way of creating macros which make exporting
// from a DLL simpler. All files within this DLL are compiled with the VNX_FSYNSTH_EXPORTS
// symbol defined on the command line. this symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see
// VNX_LMS_API functions as being imported from a DLL, wheras this DLL sees symbols
// defined with this macro as being exported.

#ifdef VNX_FMSYNTH_EXPORTS
#define VNX_LMS_API __declspec(dllexport)
#else
#define VNX_LMS_API __declspec(dllimport)
#endif

#ifdef __cplusplus
extern "C" {
#endif


// ----------- Global Equates ------------
#define MAXDEVICES 64
#define MAX_MODELNAME 32

// ----------- Data Types ----------------
#define DEVID unsigned int

// ----------- Mode Bit Masks ------------
#define MODE_RFON	0x00000010			// bit is 1 for RF on, 0 if RF is off
#define MODE_INTREF	0x00000020			// bit is 1 for internal osc., 0 for external reference
#define MODE_SWEEP	0x0000000F			// bottom 4 bits are used to keep the sweep control bits
#define MODE_PWMON	0x00000100			// we keep a copy of the PWM control bits here, 1 for int PWM on
#define MODE_EXTPWM	0x00000200			// 1 for ext. PWM input enabled
#define PWM_MASK	0x00000300

// ----------- Command Equates -----------
// Status returns for commands
#define LVSTATUS int
#define STATUS_OK 0
#define BAD_PARAMETER		0x80010000		// out of range input -- frequency outside min/max etc.
#define BAD_HID_IO			0x80020000
#define DEVICE_NOT_READY	0x80030000		// device isn't open, no handle, etc.
#define F_INVALID_DEVID		-1.0		// for functions that return a float
#define F_DEVICE_NOT_READY	-3.0

// Status returns for DevStatus
#define INVALID_DEVID		0x80000000		// MSB is set if the device ID is invalid
#define DEV_CONNECTED		0x00000001		// LSB is set if a device is connected
#define DEV_OPENED			0x00000002		// set if the device is opened
#define SWP_ACTIVE			0x00000004		// set if the device is sweeping
#define SWP_UP				0x00000008		// set if the device is sweeping up in frequency
#define SWP_REPEAT			0x00000010		// set if the device is in continuous sweep mode
#define SWP_BIDIRECTIONAL	0x00000020		// set if the device is in bi-directional sweep mode
#define PLL_LOCKED			0x00000040		// set if the PLL lock status is TRUE (both PLL's are locked)
#define	FAST_PULSE_OPTION	0x00000080		// set if the fast pulse mode option is installed

// Flags to encode pulse mode time ranges
#define PM48Mhz				0x10000000		// used to select the 48Mhz pulse mod clock
#define PM1Mhz				0x00000000		// used to select the 1Mhz pulse mod clock or sw pulsing

VNX_LMS_API void fnLMS_SetTestMode(bool testmode);
VNX_LMS_API int fnLMS_GetNumDevices();
VNX_LMS_API int fnLMS_GetDevInfo(DEVID *ActiveDevices);
VNX_LMS_API int fnLMS_GetModelNameA(DEVID deviceID, char *ModelName);
// VNX_LMS_API int fnLMS_GetModelNameW(DEVID deviceID, wchar_t *ModelName);
VNX_LMS_API int fnLMS_InitDevice(DEVID deviceID);
VNX_LMS_API int fnLMS_CloseDevice(DEVID deviceID);
VNX_LMS_API int fnLMS_GetSerialNumber(DEVID deviceID);
VNX_LMS_API int fnLMS_GetDLLVersion();
VNX_LMS_API LVSTATUS fnLMS_SetFrequency(DEVID deviceID, int frequency);
VNX_LMS_API LVSTATUS fnLMS_SetStartFrequency(DEVID deviceID, int startfrequency);
VNX_LMS_API LVSTATUS fnLMS_SetEndFrequency(DEVID deviceID, int endfrequency);
VNX_LMS_API LVSTATUS fnLMS_SetSweepTime(DEVID deviceID, int sweeptime);
VNX_LMS_API LVSTATUS fnLMS_SetPowerLevel(DEVID deviceID, int powerlevel);
VNX_LMS_API LVSTATUS fnLMS_SetRFOn(DEVID deviceID, bool on);
VNX_LMS_API LVSTATUS fnLMS_SetPulseOnTime(DEVID deviceID, float pulseontime);
VNX_LMS_API LVSTATUS fnLMS_SetPulseOffTime(DEVID deviceID, float pulseofftime);
VNX_LMS_API LVSTATUS fnLMS_EnableInternalPulseMod(DEVID deviceID, bool on);
VNX_LMS_API LVSTATUS fnLMS_SetUseExternalPulseMod(DEVID deviceID, bool external);
VNX_LMS_API LVSTATUS fnLMS_SetFastPulsedOutput(DEVID deviceID, float pulseontime, float pulsereptime, bool on);
VNX_LMS_API LVSTATUS fnLMS_SetUseInternalRef(DEVID deviceID, bool internal);
VNX_LMS_API LVSTATUS fnLMS_SetSweepDirection(DEVID deviceID, bool up);
VNX_LMS_API LVSTATUS fnLMS_SetSweepMode(DEVID deviceID, bool mode);
VNX_LMS_API LVSTATUS fnLMS_SetSweepType(DEVID deviceID, bool swptype);
VNX_LMS_API LVSTATUS fnLMS_StartSweep(DEVID deviceID, bool go);
VNX_LMS_API LVSTATUS fnLMS_SaveSettings(DEVID deviceID);
VNX_LMS_API int fnLMS_GetFrequency(DEVID deviceID);
VNX_LMS_API int fnLMS_GetStartFrequency(DEVID deviceID);
VNX_LMS_API int fnLMS_GetEndFrequency(DEVID deviceID);
VNX_LMS_API int fnLMS_GetSweepTime(DEVID deviceID);
VNX_LMS_API int fnLMS_GetRF_On(DEVID deviceID);
VNX_LMS_API int fnLMS_GetUseInternalRef(DEVID deviceID);
VNX_LMS_API int fnLMS_GetPowerLevel(DEVID deviceID);
VNX_LMS_API int fnLMS_GetAbsPowerLevel(DEVID deviceID);
VNX_LMS_API int fnLMS_GetMaxPwr(DEVID deviceID);
VNX_LMS_API int fnLMS_GetMinPwr(DEVID deviceID);
VNX_LMS_API int fnLMS_GetMaxFreq(DEVID deviceID);
VNX_LMS_API int fnLMS_GetMinFreq(DEVID deviceID);
VNX_LMS_API float fnLMS_GetPulseOnTime(DEVID deviceID);
VNX_LMS_API float fnLMS_GetPulseOffTime(DEVID deviceID);
VNX_LMS_API int fnLMS_GetPulseMode(DEVID deviceID);
VNX_LMS_API int fnLMS_GetHasFastPulseMode(DEVID deviceID);
VNX_LMS_API int fnLMS_GetUseInternalPulseMod(DEVID deviceID);
VNX_LMS_API int fnLMS_GetDeviceStatus(DEVID deviceID);

#ifdef __cplusplus
}
#endif
