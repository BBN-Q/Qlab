#include <iostream>

#include "constants.h"
#include <thread>
#include <string>
#include <algorithm>
#include "logger.h"

#include "EthernetControl.h"


using namespace std;

// command options functions taken from:
// http://stackoverflow.com/questions/865668/parse-command-line-arguments
string getCmdOption(char ** begin, char ** end, const std::string & option)
{
  char ** itr = std::find(begin, end, option);
  if (itr != end && ++itr != end)
  {
    return string(*itr);
  }
  return "";
}

bool cmdOptionExists(char** begin, char** end, const std::string& option)
{
  return std::find(begin, end, option) != end;
}


int main (int argc, char* argv[])
{
  cout << "BBN AP2 Test Echo Executable" << endl;

  FILELog::ReportingLevel() = TLogLevel(5);
  // lookup based on device name
  //string dev("\\Device\\NPF_{F47ACE9E-1961-4A8E-BA14-2564E3764BFA}");
  
  // lookup based on description
  string dev("Intel(R) 82579LM Gigabit Network Connection");

  EthernetControl::debugAPSEcho(dev);
  
  return 0;
}