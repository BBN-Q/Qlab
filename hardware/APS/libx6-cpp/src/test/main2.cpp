#include <iostream>

#include "ApplicationIo.h"

#include <thread>

using namespace std;

int main ()
{
  ApplicationIo *AppIo = new ApplicationIo();

  set_malibu_threading_enable(false);

  cout << "Openning" << endl;

  AppIo->Open();

  cout << "StartStreaming" << endl;  

  AppIo->StartStreaming();

  std::this_thread::sleep_for(std::chrono::seconds(5));

  cout << "StopStreaming" << endl;    

  cout << "Close" << endl;

  AppIo->Close();


}