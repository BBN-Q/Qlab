template<class T> inline Print &operator <<(Print &obj, T arg) { 
  obj.print(arg); 
  return obj;
}

#include <EEPROM.h>

const int NO_MESSAGE = -1;

// processInput states
const byte COMMAND = 0;
const byte NUMBER = 1;
const byte DONE = 10;

// command modes
const byte READPOWER = 1; // read ADC value
const byte GETID = 2; // get device ID
const byte SETID = 3; // set device ID
const byte UNKNOWN = -1;

const int sensorPin = A5; // pin for analog input from log amp
const int numAverages = 50;

const boolean VERBOSE = false;

/**
 * EEPROM memory map (total size = 1024 bytes)
 * bytes 0-1: serial number
 */
 
 const int ID_OFFSET = 0;

/* for simulating operation */
const int simulate = 0;

/**
 * MAIN PROGRAM
 */

void setup() {
  // open serial interface to host computer
  Serial.begin(115200);

  while (Serial.available() <= 0) {
    delay(100);
  }
}

void loop() {
  char input[255];
  int output;
  
  if (Serial.available() > 0) {
    readString(input);
    if (VERBOSE) Serial.println(input);
    output = processInput(input);
    if ( output == NO_MESSAGE ) {
      Serial.println("ERROR Unknown command");
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
  byte mode = COMMAND; // state
  byte command = UNKNOWN; // the interpretted command mode
  int value = NO_MESSAGE;
  char* token = strtok(input, " ");
  while (token) {
    /*Serial.print("token: ");
     Serial.println(token);
     Serial.print("mode: ");
     Serial.println(mode);*/
    switch (mode) {
    case COMMAND:
      if (!strcasecmp(token, "READ")) {
        command = READPOWER;
        mode = DONE;
      }
      if (!strcasecmp(token, "ID?")) {
        command = GETID;
        mode = DONE;
      }
      if (!strcasecmp(token, "ID")) {
        command = SETID;
        mode = NUMBER;
      }
      break;
    case NUMBER:
      value = atoi(token);
      mode = DONE;
      break;
    }

    token = strtok(NULL, " ");
  }

  if (mode != DONE) {
    return NO_MESSAGE;
  }
  
  if (command == READPOWER) {
    Serial << readPower();
    Serial.println();
    return DONE;
  } else if (command == GETID) {
    Serial << getID();
    Serial.println();
    return DONE;
  } else if (command == SETID) {
    Serial << "Setting board ID to " << value;
    Serial.println();
    setID(value);
    return DONE;
  } else {
    return NO_MESSAGE;
  }
}

double analogReadAverage(int pin, int numavg) {
  int sensorInput = 0;
  double averageInput = 0.0;

  for (int count = 0; count < numavg; count++) {
    sensorInput = analogRead(pin);
    averageInput += sensorInput;
  }

  averageInput /= numavg;
  return averageInput;
}

double readPower() {
  return analogReadAverage(sensorPin, numAverages);
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
