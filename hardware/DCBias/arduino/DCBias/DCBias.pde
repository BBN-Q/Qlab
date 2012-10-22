/********************************************************************
 *
 * Module Name : Set DC Bias
 *   
 * Author/Date : E.M. Aylward / 07-Mar-08
 *
 * Description : This module is to set a potentiometer to san input
 *               value. The potentiometer is specified by a chip address
 *               (0-15) and a potentiometer number (0-1). 
 *
 * Restrictions/Limitations :
 *
 * Change Descriptions :
 *
 * Classification : Unclassified
 *
 * References : Module AD5235 by C.B. Lirakis. This module is to test 
 *                     code to see how to control the SPI with the AD5235
 *                     development board.
 *              http://www.arduino.cc/playground/Main/RotaryEncoders
 *              Analog devices AD2850 eval board spec sheet
 *              Analog devices AD5235 Digital Potentiometer spec sheet
 *
 *              NOTES: 
 *                     1) Thre is only have 1Kb of SRAM (used for stack and heap) so we have to be careful
 *                     2) HIGH is 1 and LOW is 0 in the header file for programming. In some cases to reduce
 *                        size we have taken advantage of this. It is not always clear. 
 *
 * RCS header info.
 * ----------------
 * $RCSfile: DCBias_CBL_V4.pde,v $
 * $Author: clirakis $
 * $Date: 2009/06/02 21:55:32 $
 * $Locker:  $
 * $Name:  $
 * $Revision: 1.1 $
 *
 * $Log: DCBias_CBL_V4.pde,v $
 * Revision 1.1  2009/06/02 21:55:32  clirakis
 * *** empty log message ***
 * SVN does not put comments in the log, big change. store the cal data in the eeprom. 
 * There are 512 bytes of eeprom. Here is the calc. 
 * 18 channels * (3 pot + pot intercept + adc slope + adc intercept)
 * 432 bytes. 
 * 
 * I will lay out the memory as follows. 
 * byte 0 - 15
 *      0 - board serial number
 *      1 - cal data present channels 0-7
 *      2 - cal data present channels 8-15
 *      3 - cal data present channels 9-31
 *      4-15 reserved for future use. 
 * 16-500 - constant storage. 
 * Indexing into device, this will repeat. 
 * Description         Bytes
 * -----------         -----
 * Pot 0 slope           4
 * Pot 1 slope           4
 * Pot 2 slope           4
 * Current Intercept     4
 * ADC Slope             4
 * ADC Intercept         4
 *----------------------------
 *                      24 bytes per channel. 
 *
 * 
 * Revision 1.9  2008/07/16 13:13:36  cbl
 * Removed some unnecessary print statements and shortened the puases in the 'M' case.  -WRK
 *
 * Revision 1.8  2008/07/15 22:17:50  cbl
 * initial version of code containing functionality where all 3 pots (coarse med and fine) can be set with the same command
 *
 * Revision 1.6  2008/05/08 21:19:57  cbl
 * This version uses the enable function inside of 'writePot'.  The Short-All command has not yet been included.  -WRK
 *
 * Revision 1.5  2008/05/06 13:57:21  cbl
 * Updated to include ENABLE pin.  By default the chip select is disabled.  To enable (disable) chip select type e1(0)  -WRK
 *
 * Revision 1.1  2008/03/18 13:02:18  cbl
 * Initial working version of arduino code for setting DC Bias  -- includes pot chip addressing.
 *
 *
 *******************************************************************
 */
#include <ctype.h>
#include <stdio.h>
#include <EEPROM.h>

#define DATAOUT     11   //MOSI
#define DATAIN      12   //MISO
#define SPICLOCK    13   //SCK
#define SLAVESELECT 10   //SS
#define D0          2    // A? pin designations conflict with the library from version 19 on
#define D1          3    // renamed to D?
#define D2          4
#define D3          5
#define ENABLE      6
#define SHORT       7


/* Commands that can be used on the individual pot chips. */
#define NOOP4       0x00
#define EEMEM2RDAC  0x01
#define RDAC2EEMEM  0x02
#define STORERDAC   0x03
#define DEC_6DB     0x04
#define DEC_ALL_6DB 0x05
#define DEC_ONE     0x06
#define DEC_ALL_ONE 0x07
#define RESET_EEMEM_RDAC 0x08
#define READ_EEMEM  0x09
#define READ_RDAC   0x0A
#define WRITE_DAC   0x0B
#define INC_6DB     0x0C
#define INC_ALL_6   0x0D
#define INC_ONE     0x0E
#define INC_ALL     0x0F

#define DB_ON         0 // debug mode
#define DBG_CURRENT   0

/* Enums to reference the pot number */
#define COARSE        0
#define MEDIUM        1
#define FINE          2
#define MAX_CHANNELS 12

/* Pot board resistor values along with voltage references */
/* OHMS used in summing circuit */
#define R_FEEDBACK  3.0e5
#define R_COARSE    1.5e5
#define R_MEDIUM    5.0e5
#define R_FINE      2.0e6
#define R_CURRENT   1.1e4 

/*  Gain through opamp */
#define GAIN_COARSE R_FEEDBACK/R_COARSE
#define GAIN_MEDIUM R_FEEDBACK/R_MEDIUM
#define GAIN_FINE   R_FEEDBACK/R_FINE


/* External resistor used on POT. */
#define R_EXT_COARSE 0.0
#define R_EXT_MEDIUM 5.0e5
#define R_EXT_FINE   1.0e6

/* 
 * Digitally controlled POT OHMS and dimensionless, The max value
 * can be 
 * 25K (AD5235BRU25-xx)
 * or 
 * 250K (AD5235BRU25-xx)
 * depending on the selected device.
 */
#define R_POT_MAX 2.5e4
#define R_POT_MIN 25.0
#define R_STEPS   1024
#define FR_STEPS  ((double) R_STEPS)
#define POT_STEP  R_POT_MAX/FR_STEPS

/* VOLTS */
#define VREF_PLUS  2.048   /* Currently a hardware issue. */
#define VREF_MINUS 0.0
#define VREF (VREF_PLUS-VREF_MINUS)

/*
 * Pot derivations.  Based on board configuration. 
 * These are the default values. An actual calibration
 * will replace these values. 
 */
#define CS_COARSE (VREF/FR_STEPS*GAIN_COARSE/R_CURRENT)
#define CS_MEDIUM (VREF*POT_STEP/(R_EXT_MEDIUM+R_POT_MAX)*GAIN_MEDIUM/R_CURRENT)
#define CS_FINE   (VREF*POT_STEP/(R_EXT_FINE+R_POT_MAX)*GAIN_FINE/R_CURRENT)

/* Maximum values per pot configuration. */
#define I_MAX_COARSE (VREF*GAIN_COARSE/R_CURRENT)
#define I_MAX_MEDIUM (VREF*R_POT_MAX/(R_EXT_MEDIUM+R_POT_MAX) * GAIN_MEDIUM/R_CURRENT)
#define I_MAX_FINE   (VREF*R_POT_MAX/(R_EXT_FINE+R_POT_MAX) * GAIN_FINE/R_CURRENT)

// readLine support
#define LINE_LENGTH 64
static char Line[LINE_LENGTH];

#define TERM_CHAR ';'

// Masks for ADC.
// Extended range bit
#define EXR  0x10000000
// Sign bit
#define SGN  0x20000000
// Channel 0 not vs Channel 1
#define CH1  0x40000000
// End of conversion.
#define EOC  0x80000000

// Define a zero for data out
unsigned long Zero    = 0;
int Verbose = 0;
/*
 * A 'channel' is made up of 3 potentiometers. 
 * So really we have to have fully qualified (address,value) pairs
 * per channel.
 *
 * Then there are two ways to access this. Channel then Coarse, medium 
 * and fine.
 *
 * Version 2.0 
 * ----------------------
 * The addressing scheme has changed. Each slot is selected by
 * the address lines. The subaddress is used to select individual chips on 
 * a card and is controlled via the SPI. (ADG731 - 32 bit SPI switch). 
 * Finally there is a 0/1 specifying the pot in the chip. 
 * Channel Map. 
 * 2 pots per chip 
 * 3 pots per channel
 * # Chips = #Channels/2 * 3 
 * 
 * 8 bit word:
 * -----------
 * 7   - 0/1 - pot on chip.
 * 6:5 - Slot (0:3)
 * 5:0 - Sub Address on board (0:31)
 *
 * Input desired channel in Channel map and decode location. 
 * 10-APR-09 - CBL added in Slope.
 *
 * NOTE: The intercept is the same for all pots. It is
 * driven by external biases.
 * size = 7
 */
struct PotSet_t {
    unsigned int  Value;    // 0:1023;
    double        Slope;
    double        Max;
    double        Min;
};
/*
 * 10-Apr-09 CBL, extended to include other channel parameters. 
 *   DesiredSetting, ADCSlope, ADCIntercept. 
 *   Address was changed to PotData.
 * 37 bytes in size 
 */
struct ChannelData_t {
    PotSet_t PotData[3];
    double DesiredSetting;   /* Requested current in amps. */
    double CurrentIntercept; /* From calibration.          */
    double ADCSlope;         /* From calibration.          */
    double ADCIntercept;     /* From calibration           */
};

#define CHANNEL_DEFAULT { 0, CS_COARSE, I_MAX_COARSE, 0, 0, CS_MEDIUM, I_MAX_MEDIUM, 0, 0, CS_FINE, I_MAX_FINE, 0, 0.0, 0.0, 1.0, 0.0}

struct ChannelData_t ChannelMap[MAX_CHANNELS] =
{
    CHANNEL_DEFAULT,
    CHANNEL_DEFAULT,
    CHANNEL_DEFAULT, 
    CHANNEL_DEFAULT,
    CHANNEL_DEFAULT, 
    CHANNEL_DEFAULT,
    CHANNEL_DEFAULT, 
    CHANNEL_DEFAULT,
    CHANNEL_DEFAULT, 
    CHANNEL_DEFAULT,
    CHANNEL_DEFAULT, 
    CHANNEL_DEFAULT,
#if 0
    CHANNEL_DEFAULT, 
    CHANNEL_DEFAULT,
    CHANNEL_DEFAULT, 
    CHANNEL_DEFAULT,
    CHANNEL_DEFAULT, 
    CHANNEL_DEFAULT,
#endif
};

#define VERSION "2.5.0"

/**
 ******************************************************************
 *
 * Function Name : 
 *
 * Description : 
 *
 * Inputs : none
 *
 * Returns : none
 *
 * Error Conditions : none
 * 
 * Unit Tested on: 
 *
 * Unit Tested by: CBL
 *
 *
 *******************************************************************
 */
void PrintFloat(double val, int precision)
{
     int ix;
     char s[32];
     double mul = pow(10.0,precision);
     ix = (long)floor(val*mul);
     Serial.print(ix);
}
/**
 ******************************************************************
 *
 * Function Name : WriteFloat
 *
 * Description : 
 *
 * Inputs : none
 *
 * Returns : none
 *
 * Error Conditions : none
 * 
 * Unit Tested on: 
 *
 * Unit Tested by: CBL
 *
 *
 *******************************************************************
 */
void WriteFloat(int loc, double val)
{
    int i, index;
    unsigned char *p =(unsigned char *)&val;
    /*
     * As I said above, keep the first 16 bytes free. 
     */
    index = 16 + loc*sizeof(double);
    for (i=0;i<4;i++)
    {
        EEPROM.write(i+index,p[i]);
    }
}
/**
 ******************************************************************
 *
 * Function Name : 
 *
 * Description : 
 *
 * Inputs : none
 *
 * Returns : none
 *
 * Error Conditions : none
 * 
 * Unit Tested on: 
 *
 * Unit Tested by: CBL
 *
 *
 *******************************************************************
 */
double ReadFloat(int loc)
{
    int i, index;
    double rv;
    unsigned char *p = (unsigned char *) &rv;
    /*
     * As I said above, keep the first 16 bytes free. 
     */
    index = 16 + loc*sizeof(double);
    for (i=0;i<4;i++)
    {
        p[i]=EEPROM.read(i+index);
    }
#if 0
    Serial.print("loc: ");
    Serial.print(loc);
    PrintFloat( rv, 4);
#endif
    return rv;
}

#define RECSIZE 12
void ReadChannelMap(int channel)
{
  int index = channel * RECSIZE;
  ChannelMap[channel].PotData[0].Slope = ReadFloat(index);
  ChannelMap[channel].PotData[0].Max   = ReadFloat(index+1);
  ChannelMap[channel].PotData[0].Min   = ReadFloat(index+2);
  ChannelMap[channel].PotData[1].Slope = ReadFloat(index+3);
  ChannelMap[channel].PotData[1].Max   = ReadFloat(index+4);
  ChannelMap[channel].PotData[1].Min   = ReadFloat(index+5);
  ChannelMap[channel].PotData[2].Slope = ReadFloat(index+6);
  ChannelMap[channel].PotData[2].Max   = ReadFloat(index+7);
  ChannelMap[channel].PotData[2].Min   = ReadFloat(index+8);
  ChannelMap[channel].CurrentIntercept = ReadFloat(index+9);
  ChannelMap[channel].ADCSlope         = ReadFloat(index+10);
  ChannelMap[channel].ADCIntercept     = ReadFloat(index+11);
}

void WriteChannelMap(int channel)
{
    int index = channel * RECSIZE;
    WriteFloat(index,    ChannelMap[channel].PotData[0].Slope);
    WriteFloat(index+1,  ChannelMap[channel].PotData[0].Max);
    WriteFloat(index+2,  ChannelMap[channel].PotData[0].Min);
    WriteFloat(index+3,  ChannelMap[channel].PotData[1].Slope);
    WriteFloat(index+4,  ChannelMap[channel].PotData[1].Max);
    WriteFloat(index+5,  ChannelMap[channel].PotData[1].Min);
    WriteFloat(index+6,  ChannelMap[channel].PotData[2].Slope);
    WriteFloat(index+7,  ChannelMap[channel].PotData[2].Max);
    WriteFloat(index+8,  ChannelMap[channel].PotData[2].Min);
    WriteFloat(index+9,  ChannelMap[channel].CurrentIntercept);
    WriteFloat(index+10, ChannelMap[channel].ADCSlope);
    WriteFloat(index+11, ChannelMap[channel].ADCIntercept); 
}



/**
 ******************************************************************
 *
 * Function Name : InitializeSlopeIntercept
 *
 * Description : Initialize the table from the EEPROM
 * Why do this? Well, each access to the EEPROM costs 3.3ms
 * putting into the table should be faster. 
 *
 * Inputs : none
 *
 * Returns : none
 *
 * Error Conditions : none
 * 
 * Unit Tested on: 
 *
 * Unit Tested by: CBL
 *
 *
 *******************************************************************
 */
void InitializeSlopeIntercept()
{
  int channel;
  unsigned char rv;
  rv = EEPROM.read(1);
  for (channel=0;channel<8;channel++)
  {
    /* Don't overwrite channels that haven't been initialized */
    if ((rv&(1<<channel))>0)
    {
        ReadChannelMap(channel);
    }
  }
  
  rv = EEPROM.read(2);
  for (channel=8;channel<12;channel++)
  {
    if ((rv&(1<<(channel-8)))>0)
    {
        ReadChannelMap(channel);
    }
  }
#if 0
  rv = EEPROM.read(3);
  for (channel=16;channel<25;channel++)
  {
    if ((rv&(1<<(channel-16)))>0)
    {
        ReadChannelMap(channel);
    }
  }
#endif
}
/**
 ******************************************************************
 *
 * Function Name : SaveCalDat
 *
 * Description : Writes calibration data that is stored in RAM to the 
 *               EEPROM. Sets a dirty bit to indicate that the table 
 *               was written for a given channel.
 *
 * Inputs : 
 *          int channel - channel number to write to EEPROM
 *
 * Returns : none
 *
 * Error Conditions : none
 * 
 * Unit Tested on: 
 *
 * Unit Tested by: BCD
 *
 *
 *******************************************************************
 */
void SaveCalData(int channel)
{
    int index;
    unsigned char rv, mask;
    
    /* this is a very quick and dirty fix. */
    /* Expand on the concept later. */
    if (channel<8)
    {
        rv = EEPROM.read(1);
        mask = (1<<channel);
        rv |= mask;   /* set bits. */
        EEPROM.write(1, rv);
    } 
    else if (channel<16)
    {
        rv = EEPROM.read(2);
        rv |= (1<<(channel-8));   /* set bits. */
        EEPROM.write(2, rv);
    }
    else if (channel < 18)
    {
        rv = EEPROM.read(3);
        rv |= (1<<(channel-16));   /* set bits. */
        EEPROM.write(3, rv);
    }
    WriteChannelMap(channel);
}

/**
 ******************************************************************
 *
 * Function Name : SetEnable
 *
 * Description : Assert slot address on bus. 
 * In revision 2.0 of the DC bias the 74138 address select chip has
 * G2A\ wired to ENABLE and G2B\ wired to A3
 *
 * Inputs : 0 or 1
 *
 * Returns : none
 *
 * Error Conditions :
 * 
 * Unit Tested on: 01-May-09
 *
 * Unit Tested by: CBL
 *
 *
 *******************************************************************
 */
void SetEnable( unsigned char val)
{
    /* Note here, the values that val can take on are either HIGH or LOW */
    digitalWrite(SLAVESELECT, val);
    digitalWrite(     ENABLE, val);
    digitalWrite(         A3, val);	
}

/**
 ******************************************************************
 *
 * Function Name : SetSlotAddress
 *
 * Description : Set the appropriate address lines. 
 *               01-May-09 Changed name to be more consistent with 
 *               new hardware. This really is select slot. 
 *
 * Inputs : none
 *
 * Returns : none
 *
 * Error Conditions : none
 * 
 * Unit Tested on: 1-May-09
 *
 * Unit Tested by: CBL
 *
 *
 *******************************************************************
 */
void SetSlotAddress(unsigned char n)
{
#if 0
    Serial.print("Set Slot Address: ");
    Serial.println(n, DEC);
#endif
    if (n%2 == 0)
    {
	digitalWrite( D0, LOW);
    }
    else
    {
	digitalWrite( D0, HIGH);
    }
    n = n/2;
    if (n%2 == 0)
    {
	digitalWrite( D1, LOW);
    }
    else
    {
	digitalWrite( D1, HIGH);
    }
    n = n/2;
    if (n%2 == 0)
    {
	digitalWrite( D2, LOW);
    }
    else
    {
	digitalWrite( D2, HIGH);
    }
}
/**
 ******************************************************************
 *
 * Function Name : SetSubAddress
 *
 * Description : Use SPI bus to set ADG725 address block
 * which is one byte long. The byte breakdown is:
 *    0:4 - Switch to turn on. (0-31)
 *    5   - Unassigned
 *    6   - CS not if set to 1 retains last set value on output. 
 *    7   - Enable not, if set to 1 asserts results on output. 
 *          if 0 asserts 0 on all lines. 
 * 
 *    Note: As of 1-May-09 the subaddresses are allocated as follows.
 *    0-8  - Pot chips.
 *    9-14 - ADC (channel+9 if channel starts at 0)
 *
 * Inputs : address (0-31)
 *          enable - 1 assert data, 0 - assert zeros
 *
 * Returns : none
 *
 * Error Conditions : none
 * 
 * Unit Tested on: 01-May-09
 *
 * Unit Tested by: CBL
 *
 *
 *******************************************************************
 */
void SetSubAddress(unsigned char n, unsigned char enable)
{
    unsigned char val, rc;
    if (!enable)
    {
      val = 0x40;
    }
    else if (n<32)
    {
	val = n;
    }
    SetEnable(LOW);
    rc = SPI_Transfer(val);
    SetEnable(HIGH);
}
/**
 ******************************************************************
 *
 * Function Name : GetSpaceDelimitedString
 *
 * Description :  Command arguments are space delimted. Parse out
 * the individual commands into the "out" buffer provided by the user. 
 * The ptr is maintained by the calling program to know where to look
 * next in the input string. 
 *
 * Inputs : in  - the input string to be parsed. 
 *         *ptr - the last position searched in the input string. Maintaind
 *                by calling routine. 
 *
 * Returns : out which is 'zeroed' before filling. 
 *
 * Error Conditions : none
 * 
 * Unit Tested on: 07-Mar-08
 *
 * Unit Tested by: CBL
 *
 *
 *******************************************************************
 */
unsigned char GetDelimitedString( const char *in, char *out, 
				  unsigned char *ptr)
{
    unsigned char i, cnt;
    cnt = 0;
    for (i=*ptr;i<strlen(in);i++)
    {
	if ((in[i] == ' ') || (in[i]==TERM_CHAR))
	{
	    memcpy(out, &in[*ptr], cnt);
	    *ptr = i+1; // Advance past delimeter, may want to elminate preceeding delimters
	    break;
	}
	cnt++;
    }
    return cnt;
}

/**
 ******************************************************************
 *
 * Function Name : SetCalibration
 *
 * Description : Parse out calibration data and set appropriate value.
 *
 * Inputs : command - Channel Pot Slope Intercept Terminator
 *                                  
 * Returns : none
 *
 * Error Conditions : none
 * 
 * Unit Tested on: 
 *
 * Unit Tested by: CBL
 *
 *
 *******************************************************************
 */
unsigned char SetCalibration(const char *command)
{
    unsigned char channel, pot, ptr;
    char     *inptr;
    char     cmd[16];
    double   val;
    
    inptr = (char *) command;
    inptr += 3;
    ptr = 0;
    memset(cmd, 0, sizeof(cmd));
    // Parse out the channel
    if (GetDelimitedString( inptr, cmd, &ptr)<1)
    {
	return 1;
    }
    channel = (unsigned char) atoi(cmd);
    if (channel > MAX_CHANNELS)
    {
        return 2;
    }
    
    if(GetDelimitedString( inptr, cmd, &ptr)<1)
    {
	return 3;
    }
    pot = (unsigned char) atoi(cmd);
    pot = pot%3;

    if(GetDelimitedString( inptr, cmd, &ptr)<1)
    {
	return 4;
    }
#if 0
    // Parse out sub command set
    if (Verbose>0)
    {
        Serial.print("Cl:");
        Serial.print(channel, DEC);
        Serial.print(" P: ");
        Serial.print(pot, DEC);
    }
#endif
    switch (command[1])
    {
      case 'P':    // Pot Slope
          ChannelMap[channel].PotData[pot].Slope = atof(cmd);
          break;
      case 'A':   // Pot Max
          ChannelMap[channel].PotData[pot].Max = atof(cmd);
          break;
      case 'B':   // Pot Min
          ChannelMap[channel].PotData[pot].Min = atof(cmd);
          break;    
      case 'D':   // ADC Slope
          ChannelMap[channel].ADCSlope = atof(cmd);
          break;
      case 'I':
          // Current intercept
          ChannelMap[channel].CurrentIntercept = atof(cmd);
          break;
      case 'J':
          // ADC Intercept
          ChannelMap[channel].ADCIntercept = atof(cmd);
          break;
    }
    SaveCalData(channel);
    return 0;
}

/**
 ******************************************************************
 *
 * Function Name : GetCalibration
 *
 * Description : Parse out calibration data and set appropriate value.
 *
 * Inputs : command - Channel Pot Slope Intercept Terminator
 *                                  
 * Returns : none
 *
 * Error Conditions : none
 * 
 * Unit Tested on: 
 *
 * Unit Tested by: CBL
 *
 *
 *******************************************************************
 */
unsigned char GetCalibration(const char *command)
{
    unsigned char channel, pot, ptr;
    char     *inptr;
    char     cmd[16];
    double   val;
    
    inptr = (char *) command;
    inptr += 3;
    ptr = 0;
    memset(cmd, 0, sizeof(cmd));
    // Parse out the channel
    if (GetDelimitedString( inptr, cmd, &ptr)<1)
    {
	return 1;
    }
    channel = (unsigned char) atoi(cmd);
    if (channel > MAX_CHANNELS)
    {
        return 2;
    }
    
    if(GetDelimitedString( inptr, cmd, &ptr)<1)
    {
	return 3;
    }
    pot = (unsigned char) atoi(cmd);
    pot = pot%3;

    switch (command[1])
    {
      case 'P':    // Pot Slope
          val = ChannelMap[channel].PotData[pot].Slope;
          break;
      case 'A':
          val = ChannelMap[channel].PotData[pot].Max;
          break;    
      case 'B':
          val = ChannelMap[channel].PotData[pot].Min;
          break;        
      case 'D':   // ADC Slope
          val = ChannelMap[channel].ADCSlope;
          break;
      case 'I':
          // Current intercept
          val = ChannelMap[channel].CurrentIntercept;
          break;
      case 'J':
          // ADC Intercept
          val = ChannelMap[channel].ADCIntercept;
          break;
    }
    Serial.println(val,10);
    return 0;
}

/**
 ******************************************************************
 *
 * Function Name : PotFromCurrent
 *
 * Description : Calculate current value based on set value. 
 *
 * Inputs : set - the setting 0:1023
 *          pot - 0 - coarse
 *                1 - medium
 *                2 - fine
 * Side note: Trying to optimize total space. array vs case statement
 *   5694 vs 5740 savings 46 bytes.
 *
 * Returns : none
 *
 * Error Conditions : if input exceeds maximum set to 1024.
 * 
 * Unit Tested on: 07-Mar-09
 *
 * Unit Tested by: CBL
 *
 *
 *******************************************************************
 */
unsigned int PotFromCurrent(double current, unsigned char Channel, 
			    unsigned char Pot)
{
    unsigned int set = R_STEPS;
    double       IMax;  // Maximum value for pot. 
    switch(Pot)
    {
    case COARSE:
	IMax = I_MAX_COARSE;
	break;
    case MEDIUM:
	IMax = I_MAX_MEDIUM;	
	break;
    case FINE:
	IMax = I_MAX_FINE;
	break;
    default:
	IMax = I_MAX_COARSE;
	break;
    }
    
    // Override IMax with that of InterceptTable
    // Adjust for current intercept to prevent apparent requested current above max
    // It is a subtraction to be consistent with PotsFromCurrent
    IMax = ChannelMap[Channel].PotData[Pot].Max - ChannelMap[Channel].CurrentIntercept;
    
    /* Deterimine maximum current for this pot as an error check. */

#if DBG_CURRENT
    Serial.print("Req: ");
    Serial.println(current,10);
    Serial.print( "Max : ");
    Serial.println(IMax,10);
    Serial.print( "Slope: ");
    Serial.println(ChannelMap[Channel].PotData[Pot].Slope,10);
#endif

     if (current<IMax)
     {
	set = (unsigned int) floor(current/ChannelMap[Channel].PotData[Pot].Slope);
#if DBG_CURRENT
        if (1)// (Verbose>1)
        {
            Serial.print("P2C:");
            Serial.print(Channel, DEC);
            Serial.print(" Pot:");
            Serial.print(Pot, DEC);
            Serial.print(" ");
            PrintFloat(ChannelMap[Channel].PotData[Pot].Slope, 9);
            Serial.print(" Set: ");
            Serial.println(set, DEC);
        }
#endif
    }
    
    // prevent set from exceeding the maximum value for a pot
    // this can happen in the slope from calibration is too step
    // this is currently happening with a single slope for the coarse pot
    if (set > R_STEPS)
      set = R_STEPS;
      
    return set;
}

/**
 ******************************************************************
 *
 * Function Name : CurrentFromPot
 *
 * Description : Calculate current value based on set value. 
 *
 * Inputs : set - the setting 0:1023
 *          pot - 0 - coarse
 *                1 - medium
 *                2 - fine
 *
 * Side note: Trying to optimize total space. Doing it this way vs using
 * return set*I_Mult[pot] is 5740 vs 6196 for a savings of 456 bytes.
 *
 * Returns : none
 *
 * Error Conditions : if input set value is above 1023 return -1.
 * 
 * Unit Tested on: 07-Mar-09
 *
 * Unit Tested by: CBL
 *
 *
 *******************************************************************
 */
double CurrentFromPot(unsigned int set, unsigned char Channel,
		      unsigned char Pot)

{
    double dset = (double) set;
    if (set>=R_STEPS)
    {
	return -1.0;
    }
#if 0 
    /* 
     * This is an issue, but
     * needs to have an associated offset. 
     */
    else if (set <= 1)
    {
         // Hit the minimum resistance. 
         dset = 1.0;
    }
#endif
    return ChannelMap[Channel].PotData[Pot].Slope * dset; // + Intercept;
}

/**
 ******************************************************************
 *
 * Function Name : PotsFromCurrent
 *
 * Description :  Determine the best pot values to achieve the 
 * desired current.
 *
 * Inputs : current - Desired current.
 *
 * Returns : Coarse Medium and Fine settings. 
 *
 * Error Conditions : none
 * 
 * Unit Tested on: 01-May-09
 *
 * Unit Tested by: CBL
 *
 *
 *******************************************************************
 */
char PotsFromCurrent( double current, unsigned char channel, 
		      unsigned short *Value)
{
    unsigned char pot;
    double        val = current;
    double        calc;
    unsigned int  set;
    char          rc = 0;

    double IMax, IMin;
    
    // Override IMax with that of InterceptTable
    IMax = ChannelMap[channel].PotData[0].Max;
    IMax +=  ChannelMap[channel].PotData[1].Max;
    IMax +=  ChannelMap[channel].PotData[2].Max;
    
    IMin = ChannelMap[channel].PotData[0].Min;
    
    memset( Value, 0, 3*sizeof(unsigned char));
    
    if ((current < IMax) && (current >= IMin))
    {
        /* 27-Jul-09  remove bias, then find settings. */
       
#if DBG_CURRENT
       Serial.print(" Set Current: ");
       Serial.println(val,10);
       Serial.print(" CurrentIntercept ");
       Serial.println(ChannelMap[channel].CurrentIntercept,10);
#endif
       
        val -= ChannelMap[channel].CurrentIntercept;
        
#if DBG_CURRENT
        Serial.print( " After Adjust ");
        Serial.println(val, 10); 
#endif
	
        for (pot = 0; pot<FINE+1;pot++)
	{
 
#if DBG_CURRENT
            Serial.println(val, 10); 
#endif
	    
            set  = PotFromCurrent( val, channel, pot);
            set--;
	    calc = CurrentFromPot( set, channel, pot);
              
#if DBG_CURRENT            
            Serial.print("Set Point: ");
            Serial.println(set);
            Serial.print("Estimated Current: ");
            Serial.println(calc,10);
#endif            

	    if ((val-calc)<0.0)
	    {

#if DBG_CURRENT
                Serial.println("Adjusting\n");
#endif
  		set--;
		calc = CurrentFromPot ( set, channel, pot);
	    }
	    Value[pot] = set;
	    val -= calc;
	}
        rc = 1;
    }
    return rc;
}

/**
 ******************************************************************
 *
 * Function Name : SetCurrent
 *
 * Description : Parse out channel, and value then do it. 
 *
 * Inputs : command - 
 *          ExpectedLength - either 26 for a M command or 
 *                                   9 for a single command
 *                                  
 * Returns : none
 *
 * Error Conditions : none
 * 
 * Unit Tested on: 08-Mar-09
 *
 * Unit Tested by: CBL
 *
 *
 *******************************************************************
 */
unsigned char SetCurrent(const char *command)
{
    unsigned char  channel, pot;
    unsigned char  ptr;
    unsigned short Value[3];
    char           cmd[16];
    double         set;

    ptr = 0;
    memset(cmd, 0, sizeof(cmd));
    // Parse out the individual wiper values.
    if (GetDelimitedString( command, cmd, &ptr)<1)
    {
	return 1;
    }
    channel = (unsigned char) atoi(cmd);
    
    memset(cmd, 0, sizeof(cmd));
    if(GetDelimitedString( command, cmd, &ptr)<3)
    {
	return 2;
    }

    set = atof(cmd);
    ChannelMap[channel].DesiredSetting   = set;
     
    if(PotsFromCurrent( set, channel, Value)>0)
    {  
#if DBG_CURRENT
        unsigned long IIset;
        Serial.print("Chan:");
        Serial.print(channel, DEC);
        Serial.print(" ");
        IIset = (int) (1.0e9*set);
        Serial.print(IIset, DEC);
        Serial.print(" ");
        Serial.print( Value[COARSE]);
        Serial.print(" ");
        Serial.print( Value[MEDIUM]);
        Serial.print(" ");
        Serial.print( Value[FINE]);
        Serial.println(" ");
#endif
        //Write wiper value to specified pot
        write_pot( WRITE_DAC, channel, COARSE, Value[COARSE], 1);
        write_pot( WRITE_DAC, channel, MEDIUM, Value[COARSE], 1);
        write_pot( WRITE_DAC, channel, FINE,   Value[FINE],   1);
    }  else {
       return 3;
    }
}

/**
 ******************************************************************
 *
 * Function Name : GetCurrent
 *
 * Description : Get the Current value for a given channel by
 *               reading the ADC
 *
 * Inputs : command - 
 *          ExpectedLength - either 26 for a M command or 
 *                                   9 for a single command
 *                                  
 * Returns : none
 *
 * Error Conditions : none
 * 
 * Unit Tested on: 08-Mar-09
 *
 * Unit Tested by: CBL
 *
 *
 *******************************************************************
 */
unsigned char GetCurrent(const char *command)
{
unsigned char   ptr, channel;
    char            cmd[16];
    long            rv;
    float           current;
    float           slope;
    float           intercept;

    ptr = 2; // Skip the command prefix of G

    memset(cmd, 0, sizeof(cmd));
    if (GetDelimitedString( command, cmd, &ptr)<1)
    {
	Serial.println("EA1");
	return 1;
    }
    channel = atoi(cmd);
    rv = ReadADC(channel);
    
    slope = ChannelMap[channel].ADCSlope;
    intercept = ChannelMap[channel].ADCIntercept;
    
    current = rv * slope + intercept;
    
    Serial.println(current);
    return 0;

}


/**
 ******************************************************************
 *
 * Function Name : SetSingle
 *
 * Description : Based on input from command line, parse data and set pot
 * directly, don't set the set based on the current. 
 *
 * Inputs : command in the format S Channel Pot Address Value
 *
 * Returns : 0 on success, number to indicate where failure occured. 
 *
 * Error Conditions : 
 * 
 * Unit Tested on: 01-May-09
 *
 * Unit Tested by: CBL
 *
 *
 *******************************************************************
 */
unsigned char SetSingle (const char *command)
{
    unsigned char   ptr, channel, Pot;
    char            cmd[16];
    unsigned short  Val;
    int             rc;

    ptr = 2; // Skip the command prefix of S

    memset(cmd, 0, sizeof(cmd));
    if (GetDelimitedString( command, cmd, &ptr)<1)
    {
	return 1;
    }
    channel = atoi(cmd);

    memset(cmd, 0, sizeof(cmd));
    if (GetDelimitedString( command, cmd, &ptr)<1)
    {
	return 2;
    }
    Pot = atoi(cmd);

    memset(cmd, 0, sizeof(cmd));
    if (GetDelimitedString( command, cmd, &ptr)<1)
    {
	return 3;
    }
    Val = atoi(cmd);

    //Write wiper value to specified pot
    rc = write_pot( WRITE_DAC, channel, Pot, Val, 0);
#if 0
    Serial.print("Data returned: ");
    Serial.println( rc);
#endif
    return 0;
}

/**
 ******************************************************************
 *
 * Function Name : GetADC
 *
 * Description : Based on input from command line, parse data and Get ADC
 * data directly.
 *
 * Inputs : command in the format R Channel
 *
 * Returns : none
 *
 * Error Conditions : 
 * 
 * Unit Tested on: 01-May-09
 *
 * Unit Tested by: CBL
 *
 *
 *******************************************************************
 */
unsigned char GetADC (const char *command)
{
    unsigned char   ptr, channel;
    char            cmd[16];
    long            rv;

    ptr = 2; // Skip the command prefix of G

    memset(cmd, 0, sizeof(cmd));
    if (GetDelimitedString( command, cmd, &ptr)<1)
    {
	Serial.println("EA1");
	return 1;
    }
    channel = atoi(cmd);
    rv = ReadADC(channel);
    Serial.println(rv);
    return 0;
}

/**
 ******************************************************************
 *
 * Function Name : Short
 *
 * Description : Apply the short to ground option.
 *
 * Inputs : none
 *
 * Returns : none
 *
 * Error Conditions : none
 * 
 * Unit Tested on: 
 *
 * Unit Tested by: CBL
 *
 *
 *******************************************************************
 */
unsigned char Short (const char *command)
{
    unsigned char   ptr;
    char            cmd[16];
    ptr = 2;        // Skip the command prefix of S

    memset(cmd, 0, sizeof(cmd));
    if (GetDelimitedString( command, cmd, &ptr)<1)
    {
	return 1;
    }
    digitalWrite( SHORT, atoi(cmd)%2);
    return 0;
}

/**
 ******************************************************************
 *
 * Function Name : ZeroAllCurrents
 *
 * Description : Used to zero all channels
 *
 * Inputs : none
 *
 * Returns : none
 *
 * Error Conditions : none
 * 
 * Unit Tested on: 
 *
 * Unit Tested by: CBL
 *
 *
 *******************************************************************
 */
unsigned char ZeroAllCurrents()
{
    char      channel, pot;

    for (channel = 0; channel <  MAX_CHANNELS; channel++)
    {
        ChannelMap[channel].DesiredSetting   = 0.0;
        for (pot=0;pot<3;pot++)
        {
            ChannelMap[channel].PotData[pot].Value = 0;
            write_pot( WRITE_DAC, channel, pot, 0, 0);
        }
    }
    return 0;
}
/**
 ******************************************************************
 *
 * Function Name :  ParseCommand
 *
 * Description :
 *
 * Inputs : command - the full line upto the EOL termination. 
 * this may be CR/LF or anything else that the person chooses. 
 *
 * Note: Readback of DAC settings is not supported. There is 
 * an error in the hardware layout that does not allow clock inversion. 
 *
 * Commands
 *  
 *   Initialize/Setup - IE load table or set into calibrate mode.
 *
 *   Access an actual channel. 
 *   
 * Returns : none
 *
 * Error Conditions :
 * 
 * Unit Tested on: 01-May-09
 *
 * Unit Tested by: CBL
 *
 *
 *******************************************************************
 */
void ParseCommand(const char *command)
{
    unsigned char count;  
    char rc = 0;

    if (strlen(command) > 1)
    {
        // Remove leading spaces.
        count = 0;
        while ((count<4) && (command[count]==' ')) count++;
    
        switch (command[count])
        {
        case 'A':  // Read ADC Value
            rc = GetADC( &command[count]);
            break;
         case 'C':
            /*
             * Set Cal value
             * CP Channel Pot Slope Terminator
             */
            rc = SetCalibration(&command[count]);
            break;
        case 'B': // Get Calibration Value
            rc = GetCalibration(&command[count]);
            break;
        case 'D':
            Verbose = atoi(&command[1]);
            Serial.print("Verbose: ");
            Serial.println(Verbose);
            break;
        case 'H':
	    Serial.print("Bias: ");
	    Serial.println(VERSION);
	    Serial.print("I CC(0:15) Value(A) Max(");
            Serial.print(I_MAX_COARSE*100);
            Serial.println(")");
	    Serial.println("S Channel Pot Value");
            rc = 0;
	    break;
        case 'I':
            rc = SetCurrent(&command[2+count]);
            break;
        case 'G':
            rc = GetCurrent(&command[count]);
            break;
        case 'O':
            rc = Short(&command[count]);
            break;
        case 'Q':
            EEPROM.write(1,0);
            EEPROM.write(2,0);
            EEPROM.write(3,0);
            break;
        case 'S': 
	    /*
	     * S indicates single command (calibrate mode) 
	     * check that we have an appropriate number of digits
	     */
	    rc = SetSingle( &command[count]);
	    break;
        case 'Z':
	    rc = ZeroAllCurrents();
	    break;
	    /*
	     * Need a short to ground command 
	     */
        case ';': // A matlab odditiy.
            rc = -1; // Don't print anything 
            break;
        default:
            Serial.print("huh?  ");
            Serial.println(command);
            rc = -1; // We already have been informed that we have failed.
	    break;
        }
    }
    if (rc == 0)
    {
        Serial.println("OK");
    }
    else if (rc>0)
    {
        Serial.print("FAIL: ");
        Serial.println(rc, DEC);
    }
}

/**
 ******************************************************************
 *
 * Function Name : readLine
 *
 * Description :  Input data using the Arduino serial library. 
 * Loop and read valid input. The input should be terminated by -1.
 * A line is terminated by a ; or cr or lf. The first found termination
 * is substitued by a ;
 *
 * Global variables:
 *     Line    - Where to put the data. 
 *
 * Inputs : none
 *
 * Returns : none
 *
 * Error Conditions : none
 * 
 * Unit Tested on: 07-Mar-08
 *
 * Unit Tested by: CBL
 *
 *
 *******************************************************************
 */
char readLine()
{
    static char LinePtr = 0;
    int c;
 
    while ((c = Serial.read()) >0)
    {
	switch (c)
	{
	case '\n':
	case '\r':
	case TERM_CHAR:
	    Line[LinePtr] = TERM_CHAR;
	    c = LinePtr+1;
	    LinePtr = 0;
	    return c;
	    break;
	case -1:
	    // Do nothing.
	    break;
	default:
	    if (LinePtr == 0)
	    {
		memset( Line, 0, sizeof(Line));
	    }
	    Line[LinePtr] = c;
	    LinePtr++;
	    if (LinePtr >= sizeof(Line))
	    {
		LinePtr = 0;
	    }
	}  
    }
    return 0;
}

/*
 ******************************************************************
 * Function Name    : SPI_Transfer
 * Description      : Write data on SPI bus. 
 * Inputs           : data - bytewise data to send.
 * Returns          : returns data from chip.
 * Error Conditions : None
 *
 * Unit Tested on: 28-Jan-08
 * Unit Tested by: CBL
 *
 *******************************************************************
 */
unsigned char SPI_Transfer(volatile unsigned char data)
{
    // Transfer the data to the Serial Peripheral Data Register. 
    // This initiates the transfer over the SPI 
    SPDR = data;                    // Start the transmission

    // Loop until the SPI Interrupt flag (SPIF) is set. 
    // This tells us that the data transmission has successfully completed.
    while (!(SPSR & (1<<SPIF)))     // Wait the end of the transmission
    {
    };
    // Reading the SPSR should clear it.
    return SPDR;                    // return any received byte
}
/*
 ******************************************************************
 * Function Name    : ReadADCData
 * Description      : Read back the 32 bit ADC values. LTC2401 once all setup
 *                    has been performed. Conversion starts when data output
 *                    completes
 * Inputs           : None
 * Returns          : The 32 bit scaled value. Note that on the Arduino 
 *                    int is 2 bytes long. 
 * Error Conditions : None
 *
 * Unit Tested on: 28-May-09
 * Unit Tested by: CBL
 *
 *******************************************************************
 */
unsigned long ReadADCData()
{
    int            i;
    unsigned long   *value;
    unsigned char  *dataOut, dataIn[4];
    // Set the address of value to the starting address of the character array
    // rc since we can only read bytewise data. 
    value   = (unsigned long *)dataIn;
    dataOut = (unsigned char *)Zero;
    for (i=0;i<4;i++)
    {
	dataIn[3-i] = SPI_Transfer(dataOut[i]);
    }
    return *value;
}
/**
 ******************************************************************
 *
 * Function Name : ADC_SubAddress
 *
 * Description : Based on the channel, return the sub-address of the 
 * ADC
 *
 * Inputs : Desired ADC channel
 *
 * Returns : subaddress to get data from ADC. 
 *
 * Error Conditions : none
 * 
 * Unit Tested on: 01-May-09
 *
 * Unit Tested by: CBL
 *
 *
 *******************************************************************
 */
unsigned char ADC_Subchannel(unsigned char channel)
{
    unsigned char subchannel = channel%6;
    if (subchannel%2 == 0)
    {
	subchannel = (5*subchannel)/2;
    }
    else
    {
	subchannel--;
	subchannel = (5*subchannel)/2 + 4;
    }
    return subchannel;
}
/*
 ******************************************************************
 * Function Name    : ReadADC
 * Description      : Read back the 32 bit ADC values. LTC2401
 * Inputs           : None
 * Returns          : The 32 bit scaled value. 
 * Error Conditions : None
 *
 * Unit Tested on: 28-May-09
 * Unit Tested by: CBL
 *
 *******************************************************************
 */
long ReadADC(unsigned char channel)
{
    /* channel starts at 0. slot 0 covers 0-5 */
    unsigned char slot, address, subchannel;
    unsigned long rv;
    long          Value;

    slot       = channel/6;
    subchannel = ADC_Subchannel(channel);
    address    = slot * 2;

#if 0
    Serial.print("ADC: ");
    Serial.print(channel, DEC);
    Serial.print(" Subchannel: ");
    Serial.println(subchannel, DEC);
#endif
    SetSlotAddress ( address);
    SetSubAddress  ( subchannel, 1);
    /* Now we can get at the additional devices on the board. */
    SetSlotAddress( address+1);
    SetEnable(LOW);

    /* Debug, look at bits. 
     * Bit patterns. 
     * 31 EOC\         - Conversion complete should be zero if complete
     * 30 CH0\ : CH1   - Since the 2401 is a single channel device should be low.
     * 29 SIGN bit     - High when Vin > 0
     * 28 Extended range set.  - Set when Vin > VRef or Vin < 0
     * 27:4 Data
     *
     * Rough conversion time is 200ms
     *
     * Do two reads, the readout starts a conversion cycle. 
     * cycle is CS low and rising edge of clock
     */
    rv = ReadADCData();
    delay(400);
    rv = ReadADCData();
    // Complete transaction.
    SetEnable(HIGH);
    //Serial.println( rv, HEX);
    
    // Only really 20 bits of real data. Get rid of the low 4 bits and mask the rest.
    Value = (rv>>4)&0x00FFFFFF;
    //Value = rv&0x0FFFFFFF;
    // Not really sure how I want to handle the extended range bit.
    // Is the sign bit set?
    if ((rv&EXR)==1)
    {
      Serial.println("EXR");
    }
    if ((rv&SGN)==1)
    {
	Value *= -1;
    }
    return Value; 
}

/**
 ******************************************************************
 * Function Name    : WritePot
 * Description      : Write a value to address given. 
 *
 * Inputs :   command    - (Should be WRITE_DAC)
 *            channel    - (can be 0 - 18)
 *            PotNum     - (COARSE, MEDIUM, FINE)
 *            Value      - (0:1023)
 *            UseCalData - Direct set or use calibration data.
 *
 * The pot is controlled with a single 24 bit data word. 
 * The format of this word is:
 *
 *
 * Returns           : integer value of composed of the second and 
 *                      third bytes returned by the chip.
 * Error Conditions  : None
 * 
 * v1.1 Unit Tested on: 
 *      Unit Tested by: CBL
 * 
 *******************************************************************
 */
int write_pot(char command, unsigned char channel, unsigned char Pot, 
	      unsigned int Value, char UseCalData)
{
    int           i;
    unsigned int  valueIn;
    unsigned char address, slot, subchannel, pot, dataOut[4], rc[4];
    /*
     * There are 2 address per slot. 
     * The first address selects the SPI address switch on the board.
     * The second selects the secondary chip on the board. 
     */
    slot       = channel/6;
    address    = 2 * slot;
    pot        = (Pot%3+1)%2;

    subchannel = ADC_Subchannel(channel);
    
    /*
     * Subchannel selection is a bit more difficult.
     * easier to work back from ADC subchannel.
     */
    if (channel%2 == 0)
    {
	subchannel++;
	if (Pot%3>1)
	{
	    subchannel++;
	}
    }
    else
    {
	// Odd.
	subchannel--;
	if (Pot%3>1)
	{
	    subchannel--;
	    pot = 0;
	}	
    }
    /* Setup the data we want to output. */
    dataOut[0]  = ((command<<4) + pot)&0xFF;
    dataOut[1]  = (Value>>8)&0xFF;
    dataOut[2]  = (Value & 0xFF);
    
#if 0
    Serial.print("Com: ");
    Serial.print(command, HEX);
    Serial.print(" Chan: ");
    Serial.print(channel, DEC);
    Serial.print(" ADCSub: ");
    Serial.print( ADC_Subchannel(channel), DEC);
    Serial.print(" Slot: ");
    Serial.print(slot, DEC);
    Serial.print(" Add: ");
    Serial.print(address, DEC);
    Serial.print(" Subadd:");
    Serial.print(subchannel, DEC);
    Serial.print(" Pot: ");
    Serial.print(pot, DEC);
#endif
#if 0
    Serial.print(" Value:");
    Serial.print(Value, DEC);
    Serial.println(" ");
    
    Serial.print( dataOut[0], HEX);
    Serial.print( " " );    
    Serial.print( dataOut[1], HEX);
    Serial.print( " " );    
    Serial.print( dataOut[2], HEX);
    Serial.println( " " );    
#endif
    /* Sequence of events... 
     * 1) Set the slot address onto the backplane. This selects the SPI Address chip. 
     * 2) Set the sub address by sending the value over the SPI bus. 
     * 3) Increment the address by 1, this disables our communications with the SPI Address chip
     *    and brings the D line on the chip to ground selecting the next device in the chain. 
     */
    /* Enable our ability to get at the SPI switch device */
    SetSlotAddress( address);
    /* Set the address used on the board */
    SetSubAddress ( subchannel, 1);
    /* 
     * Now we can get at the additional devices on the board. 
     * The actual device CS line doesn't go low until we bring the enable line low. 
     */
    SetSlotAddress( address+1);
    SetEnable(LOW);  // Bringing the enable lines low asserts the new slot subaddress low.     
    for (i=0;i<3;i++)
    {
	rc[i] = SPI_Transfer(dataOut[i]);
    }

    /*
     * Finalize the session, The line has to go high. 
     * This also disables further talk with the selected device. 
     */
    SetEnable(HIGH);
    
#if 0
    Serial.print("Data: ");
    Serial.print( rc[0], HEX);
    Serial.print(" ");
    Serial.print( rc[1], HEX);
    Serial.print(" ");
    Serial.print( rc[2], HEX);
    Serial.println(" ");
#endif
    // Read back pot setting as well.
    valueIn = rc[1]*256 + rc[2];
    /* Disable comms */
    return valueIn;
}

/**
 ******************************************************************
 *
 * Function Name : setup
 *
 * Description : Run once when sketch starts. 
 *
 * Inputs : None
 *
 * Returns : None
 *
 * Error Conditions : None
 * 
 * v1.1 Unit Tested on: 06-Jan-08
 *      Unit Tested by: CBL
 *
 * v1.2 Redesigned for 15 pot chip board. 10 MAR 2008 Erin M Aylward
 *
 *******************************************************************
 */
void setup() 
{
    int BAUD_RATE = 9600;
    int ichan, rc;
    byte clr;


    pinMode(DATAOUT    , OUTPUT);
    pinMode(DATAIN     , INPUT);
    pinMode(SPICLOCK   , OUTPUT);

    pinMode(SLAVESELECT, OUTPUT);  
    digitalWrite(SLAVESELECT,HIGH); 
 
    /* check to make sure these should be output pins. It seems 
     *  to me that they should as they turn on a chip just as the 
     * slave select did in the single chip case. 
     */
 
     
    pinMode(D0, OUTPUT); 
    pinMode(D1, OUTPUT);
    pinMode(D2, OUTPUT);
    pinMode(D3, OUTPUT);
    pinMode(ENABLE, OUTPUT);
    pinMode(SHORT, OUTPUT);
   
   
    // Set all bits to high to deselect all chips
    // TODO: Check this once we have boards.
   
    
    digitalWrite(D0,HIGH);
    digitalWrite(D1,HIGH);
    digitalWrite(D2,HIGH);
    SetEnable(HIGH);
    
    /*
     * Enable SPI 
     * Set as bus master
     * Set clock rate to Fosc/64
     * Clock polarity is Rising.
     * Clock phase is Setup.
     */
     
     
    Serial.begin(BAUD_RATE);
    SPCR = (1<<SPE)|(1<<MSTR)|(0x02);
  

#if DB_ON
    Serial.println(SPE, BIN);
    Serial.println(MSTR,BIN);
    Serial.println(SPCR,BIN);
#endif


    clr=SPSR;    // Read the status register - clears interrupts
    clr=SPDR;    // Clear out the data register by reading it. 
    delay(10);   // delay is in milliseconds
  
    // Startup Serial coms for user I/O
    
    Serial.begin (BAUD_RATE);

    rc = EEPROM.read(1);
    if (rc>0)
    {
        InitializeSlopeIntercept();
    }

    //ZeroAllCurrents();

#if DB_ON    
    Serial.println("start");  // Tell user we are starting the program. 
#endif
}  // end setup

/**
 ******************************************************************
 *
 * Function Name : loop
 * 
 * Description : sort of the main body of the program, never exits.
 *
 * Inputs : none
 *
 * Returns : none
 *
 * Error Conditions : none
 * 
 * v1.1 Unit Tested on: 06-Jan-08
 *      Unit Tested by: CBL
 *
 * v1.2 Resigned for addressing 15 different pot chips. 10 MAR 2008 
 *      Erin M Aylward
 *
 *******************************************************************
 */
void loop()
{
    delay(100);
    if (readLine())
    {
        ParseCommand(Line);
    }
}
