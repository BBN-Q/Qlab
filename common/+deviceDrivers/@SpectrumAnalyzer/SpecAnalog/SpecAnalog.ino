template<class T> inline Print &operator <<(Print &obj, T arg) { 
  obj.print(arg); 
  return obj;
}

const int NO_MESSAGE = -1;
const byte COMMAND = 0;
const byte NUMBER = 1;
const byte CHANNEL = 2;
const byte OPTIMIZE = 3;
const byte READPOWER = 4;
const byte DONE = 5;

const int sensorPin = A5; // pin for analog input from log amp
const int numAverages = 50;
const int verbose = 0;

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

  readString(input);
  //Serial.println(input);
  output = processInput(input);
  if ( output == NO_MESSAGE ) {
    Serial.println("ERROR Unknown command");
  }

  while (Serial.available() <= 0) {
    delay(100);
  }
}

/**
 * HELPER FUNCTIONS
 */

void readString(char* s) {
  int readCount = 0;
  while (Serial.available() > 0 && readCount < 255) {
    s[readCount++] = Serial.read();
  }
  s[readCount] = 0;
}

int processInput(char* input) {
  byte mode = COMMAND;
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
        value = READPOWER;
        mode = READPOWER;
      }
      break;
    case NUMBER:
      value = constrain(atoi(token), 0, 1023);
      mode = DONE;
      break;
    }

    token = strtok(NULL, " ");
  }

  if (mode == READPOWER) {
    Serial << readPower();
    Serial.println();
  }
  return DONE;
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

