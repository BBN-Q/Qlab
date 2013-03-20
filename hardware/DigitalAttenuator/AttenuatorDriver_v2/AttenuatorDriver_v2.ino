template<class T> inline Print &operator <<(Print &obj, T arg) { 
  obj.print(arg); return obj;
}

#include <EEPROM.h>

const int NO_MESSAGE = -1;

// processInput state machine modes
const byte COMMAND = 0;
const byte CHANNEL = 1;
const byte REALNUMBER = 2;
const byte INTNUMBER = 3;
const byte DONE = 10;

// command modes
const byte GET = 1; // get attenuator value
const byte SET = 2; // set attenuator value
const byte GETID = 3; // get device ID
const byte SETID = 4; // set device ID
const byte UNKNOWN = -1;

const boolean VERBOSE = false;

const int attenuatorPins[3][6] = {{A5,A4,A3,A2,A1,A0}, {7,6,5,4,3,2}, {13,12,11,10,9,8}};

/**
 * EEPROM memory map (total size = 1024 bytes)
 * bytes 0-1: serial number
 *       2-3: channel 1 attenuator doubled value (int between 0-63)
 *       4-5: channel 2 attenuator doubled value
 *       6-7: channel 3 attenuator doubled value
 */
 
 const int ID_OFFSET = 0;
 const int CH_OFFSETS[3] = {2, 4, 6};

/**
 * MAIN PROGRAM
 */
 
void setup() {
  // setup pins for output
  for (int i = 0; i <= 2; i++ ) {
    for (int j = 0; j <= 5; j++ ) {
      pinMode( attenuatorPins[i][j], OUTPUT );
    }
  }
  
  // load stored channel values from EEPROM
  float val;
  for (int ch = 1; ch <= 3; ch++ ) {
    val = readStoredChannelValue(ch);
    setAttenuator(ch, val);
  }
  Serial.begin(115200);
}

void loop() {
  char input[255];
  int output;
  
  if (Serial.available() > 0) {
    readString(input);
    if (VERBOSE) Serial.println(input);
    output = processInput(input);
    if ( output == NO_MESSAGE ) {
      Serial.println("ERROR: Unknown command");
      Serial.println("END");
    }
    Serial.flush();
  }
}

/**
 * HELPER FUNCTIONS
 */
 
void readString(char* s) {
  int readCount = 0;
  unsigned long startTime = millis();
  char val;
  // terminate at 255 chars, a semicolon, or 100 ms timeout
  while (readCount < 255 && (millis() - startTime) < 100) {
    if (Serial.available() == 0) {
      continue;
    }
    val = Serial.read();
    if (val != '\n' && val != '\r' && val != ';') { // also ignore linefeeds and carriage returns
      s[readCount++] = val;
    }
    else {
      break;
    }
  }
  s[readCount] = 0;
}

int processInput(char* input) {
  byte mode = COMMAND; // processInput() state machine mode
  byte command = UNKNOWN; // the interpretted command mode
  int channel = 1;
  double value = 0.0;
  unsigned int uvalue = 0;
  char* token = strtok(input, " ");
  while (token) {
    switch (mode) {
      case COMMAND:
        if (!strcasecmp(token, "SET")) {
          command = SET;
          mode = CHANNEL;
        }
        if (!strcasecmp(token, "GET")) {
          command = GET;
          mode = CHANNEL;
        }
        if (!strcasecmp(token, "ID?")) {
          command = GETID;
          mode = DONE;
        }
        if (!strcasecmp(token, "ID")) {
          command = SETID;
          mode = INTNUMBER;
        }
        break;
      case CHANNEL:
        if (!strcasecmp(token, "1") || !strcasecmp(token, "2") || !strcasecmp(token, "3")) {
          channel = atoi(token);
          // if we are getting the current value, we are done
          // otherwise, we need another number
          if (command == SET)
            mode = REALNUMBER;
          else
            mode = DONE;
        }
        break; 
      case REALNUMBER:
        value = atof(token);
        mode = DONE;
        break;
      case INTNUMBER:
        uvalue = atoi(token);
        mode = DONE;
        break;
    }
    
    token = strtok(NULL, " ");
  }
  
  if (mode != DONE) {
    return NO_MESSAGE;
  }
  
  if (command == SET) {
    Serial << "Setting channel " << channel << " to " << value;
    Serial.println();
    setAttenuator(channel, value);
    writeStoredChannelValue(channel, value);
    Serial.println("END");
    return DONE;
  } else if (command == GET) {
    Serial << readStoredChannelValue(channel);
    Serial.println();
    Serial.println("END");
    return DONE;
  } else if (command == GETID) {
    Serial << getID();
    Serial.println();
    Serial.println("END");
    return DONE;
  } else if (command == SETID) {
    Serial << "Setting board ID to " << uvalue;
    Serial.println();
    setID(uvalue);
    Serial.println("END");
    return DONE;
  } else {
    return NO_MESSAGE;
  }
}

void setAttenuator(int channel, double val) {
  int value = (int) (2.0 * val);
  // check for out of range input
  channel = constrain(channel, 1, 3);
  value = constrain(value, 0, 63);
  if (VERBOSE) Serial.println(value, BIN);
  
  for (int bit = 0; bit <= 5; bit++ ) {
    if (VERBOSE) Serial << "Setting pin " << attenuatorPins[channel-1][bit] << " to ";
    if ( bitRead(value, bit) ) {
      if (VERBOSE) Serial.println("HIGH");
      digitalWrite( attenuatorPins[channel-1][bit], HIGH );
    } else {
      if (VERBOSE) Serial.println("LOW");
      digitalWrite( attenuatorPins[channel-1][bit], LOW );
    }
  }
}

// get first two bytes from EEPROM memory
unsigned int getID(void) {
  unsigned int id = word( EEPROM.read(ID_OFFSET+1), EEPROM.read(ID_OFFSET) );
  return id;
}

// write ID into first two bytes of EEPROM memory
void setID(unsigned int id) {
  if (VERBOSE) {
    Serial << "Low Byte 0: " << (id & 0xFF) << "\n";
    Serial << "High Byte 1: " << (id >> 7) << "\n";
  }
  EEPROM.write(ID_OFFSET, id & 0xFF);
  EEPROM.write(ID_OFFSET+1, (id >> 7) );
}

float readStoredChannelValue(int channel) {
  channel = constrain(channel, 1, 3);
  int value = word( EEPROM.read(CH_OFFSETS[channel-1]+1), EEPROM.read(CH_OFFSETS[channel-1]) );
  value = constrain(value, 0, 63);
  if (VERBOSE) {
    Serial << "Read stored value " << (float) value / 2.0 << ".\n";
  }
  return (float) value / 2.0;
}

void writeStoredChannelValue(int channel, float value) {
  channel = constrain(channel, 1, 3);
  int writeVal = constrain( (int) (value * 2.0), 0, 63 );
  // only write if the value is different from memory
  if (writeVal != (int) (readStoredChannelValue(channel)*2.0) ) {
    if (VERBOSE) {
      Serial << "Low Byte " << CH_OFFSETS[channel-1] << ": " << (writeVal & 0xFF) << "\n";
      Serial << "High Byte " << CH_OFFSETS[channel-1]+1 << ": " << (writeVal >> 7) << "\n";
    }
    EEPROM.write(CH_OFFSETS[channel-1], writeVal & 0xFF);
    EEPROM.write(CH_OFFSETS[channel-1]+1, writeVal >> 7);
  }
}

