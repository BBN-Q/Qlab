template<class T> inline Print &operator <<(Print &obj, T arg) { 
  obj.print(arg); return obj;
}

#include <EEPROM.h>

const int NO_MESSAGE = -1;
const byte COMMAND = 0;
const byte NUMBER = 1;
const byte CHANNEL = 2;
const byte IDENTIFY = 3;
const byte SETID = 4;
const byte DONE = 10;
const boolean VERBOSE = false;

const int attenuatorPins[3][6] = {{A5,A4,A3,A2,A1,A0}, {7,6,5,4,3,2}, {13,12,11,10,9,8}};

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
  Serial.begin(9600);
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
  byte mode = COMMAND;
  int channel = 1;
  double value = 0.0;
  unsigned int uvalue = 0;
  char* token = strtok(input, " ");
  while (token) {
    switch (mode) {
      case COMMAND:
        if (!strcasecmp(token, "SET")) {
          mode = CHANNEL;
        }
        if (!strcasecmp(token, "ID?")) {
          mode = IDENTIFY;
        }
        if (!strcasecmp(token, "ID")) {
          mode = SETID;
        }
        break;
      case CHANNEL:
        if (!strcasecmp(token, "1") || !strcasecmp(token, "2") || !strcasecmp(token, "3")) {
          channel = atoi(token);
          mode = NUMBER;
        }
        break; 
      case NUMBER:
        value = atof(token);
        mode = DONE;
        break;
      case SETID:
        uvalue = atoi(token);
        break;
    }
    
    token = strtok(NULL, " ");
  }
  
  if (mode == DONE) {
    Serial << "Setting channel " << channel << " to " << value;
    Serial.println();
    setAttenuator(channel, value);
    Serial.println("END");
    return DONE;
  } else if (mode == IDENTIFY) {
    Serial << getID();
    Serial.println();
    Serial.println("END");
    return DONE;
  } else if (mode == SETID) {
    Serial << "Setting board ID to " << uvalue;
    Serial.println();
    setID(uvalue);
    Serial.println("END");
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
  unsigned int id = word( EEPROM.read(1), EEPROM.read(0) );
  return id;
}

// write ID into first two bytes of EEPROM memory
void setID(unsigned int id) {
  if (VERBOSE) {
    Serial << "Low Byte 0: " << (id & 0xFF) << "\n";
    Serial << "High Byte 1: " << (id >> 7) << "\n";
  }
  EEPROM.write(0, id & 0xFF);
  EEPROM.write(1, (id >> 7) );
}
