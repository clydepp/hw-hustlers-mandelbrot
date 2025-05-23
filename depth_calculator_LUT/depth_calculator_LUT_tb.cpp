#include "Vdepth_calculator_LUT.h"
#include "verilated.h"
#include <iostream>
#include <fstream>
#include <cstdint>
#include <cmath>

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

// Convert a double into Q16.16 fixed-point
static int32_t to_fixed(double x, int frac = 16) {
    return int32_t(std::round(x * (1 << frac)));
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vdepth_calculator_LUT* dut = new Vdepth_calculator_LUT;

    const int W = 2000, H = 1000;
    const double re_min = -2.0, re_max = 1.0;
    const double im_min = -1.5, im_max = 1.5;
    const int FRAC = 16;

    std::ofstream csv("mandelbrot_rgb.csv");
    csv << "x,y,R,G,B\n";

    // Reset
    dut->reset  = 1;
    dut->sysclk = 0;
    dut->start  = 0;
    dut->eval(); main_time++;
    dut->sysclk = 1;
    dut->eval(); main_time++;
    dut->reset = 0;

    for (int py = 0; py < H; ++py) {
        for (int px = 0; px < W; ++px) {
            double cre = re_min + double(px) * (re_max - re_min) / double(W - 1);
            double cim = im_max - double(py) * (im_max - im_min) / double(H - 1);

            // Assign inputs
            dut->x     = px;
            dut->y     = py;
            dut->re_c  = to_fixed(cre, FRAC);
            dut->im_c  = to_fixed(cim, FRAC);
            dut->start = 1;

            // Pulse sysclk once for the start signal
            dut->sysclk = 1; dut->eval(); main_time++;
            dut->sysclk = 0; dut->eval(); main_time++;
            dut->start = 0;

            // Wait for done
            while (!dut->done) {
                dut->sysclk = 1; dut->eval(); main_time++;
                dut->sysclk = 0; dut->eval(); main_time++;
            }

            uint32_t color = dut->color;
            uint8_t r = (color >> 16) & 0xFF;
            uint8_t g = (color >> 8)  & 0xFF;
            uint8_t b =  color        & 0xFF;

            csv << px << "," << py << "," << int(r) << "," << int(g) << "," << int(b) << "\n";
        }

        if (py % 50 == 0)
            std::cerr << "Completed row " << py << "/" << H << "\n";
    }

    csv.close();
    dut->final();
    delete dut;
    std::cout << "Done! RGB data saved to mandelbrot_rgb.csv\n";
    return 0;
}
