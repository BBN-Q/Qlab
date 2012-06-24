/*
 * WinTypes.h
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#ifndef WINTYPES_H_
#define WINTYPES_H_


#ifdef __cplusplus
extern "C"
{
#endif

#ifndef BYTE
	typedef unsigned char BYTE;
#endif
	typedef unsigned char UCHAR;
	typedef unsigned char *PUCHAR;
	typedef unsigned short USHORT;

	typedef unsigned long ULONG;
	typedef void *LPVOID;
	typedef short BOOL;

	typedef unsigned long *PULONG;
	typedef const void *LPCVOID;
	typedef unsigned long DWORD;
	typedef unsigned long *PDWORD;
	typedef DWORD WORD;
	typedef long LONG;
	typedef long RESPONSECODE;
	typedef const char *LPCSTR;
	typedef const BYTE *LPCBYTE;
	typedef BYTE *LPBYTE;
	typedef DWORD *LPDWORD;
	typedef char *LPSTR;
	typedef char *LPTSTR;
	typedef char *LPCWSTR;

#ifdef __cplusplus
}
#endif


#endif /* WINTYPES_H_ */
