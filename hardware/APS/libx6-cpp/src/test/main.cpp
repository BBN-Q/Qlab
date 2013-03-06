#include <iostream>

#include "libaps.h"

using namespace std;

int main ()
{
  cout << "BBN X6-1000 Test Executable" << endl;

  int numDevices;
  numDevices = get_numDevices();

  cout << numDevices << " X6 devices found" << endl;

  return 0;
}