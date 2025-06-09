// testbench.cpp
#include "Vpixel_distributor.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <cstdint>

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    auto* dut = new Vpixel_distributor;

    // Setup VCD tracing
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("pixel_distributor.vcd");

    // Reset
    dut->sysclk      = 0;
    dut->ready_Signal= 0;
    dut->eval(); tfp->dump(main_time++);
    
    // Release reset (if you had one)
    // ...

    const int TOTAL_CYCLES = 7000;  // run a few lines
    std::cout << "cycle, re_c, im_c\n";
    for (int cycle = 0; cycle < TOTAL_CYCLES; ++cycle) {
        // Drive Ready_Signal high every cycle
        dut->ready_Signal = 1;

        // Toggle clock
        dut->sysclk = 1; dut->eval(); tfp->dump(main_time++);
        // Capture outputs at rising edge
        int32_t re = dut->re_c;
        int32_t im = dut->im_c;
        std::cout << cycle << ", "
                  << re << " (" << double(re)/(1<<16) << "), "
                  << im << " (" << double(im)/(1<<16) << ")\n";

        dut->sysclk = 0; dut->eval(); tfp->dump(main_time++);
    }

    // Finish
    tfp->close();
    dut->final();
    delete tfp;
    delete dut;
    return 0;
}
