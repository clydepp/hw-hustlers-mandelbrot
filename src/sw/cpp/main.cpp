#include <complex>
#include <fstream>
#include <iostream>
#include <mutex>
#include <thread>
#include <vector>

#include <SFML/Graphics.hpp>
#include "Application.cpp"

int main() {
  int width = 1152;
  int height = 864;
  int maxIter = 200;
  int numThreads = std::thread::
      hardware_concurrency();  // Number of threads for multithreading

  Application application(width, height, maxIter, numThreads);

  application.run();

  return 0;
}