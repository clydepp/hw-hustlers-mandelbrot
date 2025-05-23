// testbench.cpp
#include "Vpixel_to_complex.h"
#include "verilated.h"
#include "verilated_vcd_c.h"    // <— for tracing
#include <iostream>
#include <vector>

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    // instantiate DUT
    Vpixel_to_complex* dut = new Vpixel_to_complex;

    // --------- set up VCD tracing ---------
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);               // trace DUT with up to 99 levels
    tfp->open("pixel_to_complex.vcd"); // name of the dump file

    // Simulation parameters
    const int SCREEN_W = 640, SCREEN_H = 480, FRAC = 16, SHIFT = FRAC;
    auto to_double = [&](int32_t v) { return double(v) / double(1 << SHIFT); };

    // test points
    std::vector<std::pair<int,int>> tests = {
        {0, 0}, {SCREEN_W-1, 0}, {0, SCREEN_H-1},
        {SCREEN_W-1, SCREEN_H-1}, {SCREEN_W/2, SCREEN_H/2}
    };

    // initial clock
    dut->clk = 0;
    dut->eval();
    tfp->dump(main_time++);

    for (auto [x,y] : tests) {
        dut->x = x;
        dut->y = y;

        // toggle clock low→high
        dut->clk = 1; dut->eval(); tfp->dump(main_time++);
        // high→low
        dut->clk = 0; dut->eval(); tfp->dump(main_time++);

        // capture & print
        int32_t r = dut->real_part, i = dut->im_part;
        std::cout << "Pixel("<<x<<","<<y<<"): "
                  << "real="<<r<<"("<<to_double(r)<<") "
                  << "imag="<<i<<"("<<to_double(i)<<")\n";
    }

    // wrap up tracing
    tfp->close();

    dut->final();
    delete tfp;
    delete dut;
    return 0;
}
