// tb_top_connection.cpp

#include <verilated.h>
#include <verilated_vcd_c.h>
#include <iostream>
#include "Vtop_connection.h"

static const int WIDTH       = 640;
static const int HEIGHT      = 480;
static const int TOTAL_PIXELS = WIDTH * HEIGHT;

// Toggle clock and optionally dump waveform
void tick(Vtop_connection* dut, VerilatedVcdC* tfp = nullptr) {
    // Rising edge
    dut->sysclk = 1;
    dut->eval();
    if (tfp) tfp->dump(2 * Verilated::time());
    // Advance half‐period
    Verilated::timeInc(5);  // 5 ns → half‐period (100 MHz)
    // Falling edge
    dut->sysclk = 0;
    dut->eval();
    if (tfp) tfp->dump(2 * Verilated::time() + 1);
    Verilated::timeInc(5);
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vtop_connection* dut = new Vtop_connection;

    // Optional: enable VCD waveform tracing by defining WAVES
    VerilatedVcdC* tfp = nullptr;
    #ifdef WAVES
    Verilated::traceEverOn(true);
    tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("waveform.vcd");
    #endif

    // INITIAL RESET
    dut->reset  = 1;
    dut->sysclk = 0;
    dut->eval();
    for (int i = 0; i < 10; i++)
        tick(dut, tfp);
    dut->reset = 0;
    dut->eval();

    // MAIN PIXEL LOOP
    int count = 0;
    while (count < TOTAL_PIXELS) {
        tick(dut, tfp);
        // sample when ready goes high
        if (dut->ready) {
            std::cout << "Pixel #" << count
                      << "  x=" << dut->x_cnt
                      << "  y=" << dut->y_cnt
                      << "  re_c=" << dut->re_c
                      << "  im_c=" << dut->im_c
                      << "  depth=" << dut->final_depth
                      << std::endl;
            count++;
        }
    }

    std::cout << "Processed " << TOTAL_PIXELS << " pixels. Testbench complete." << std::endl;

    #ifdef WAVES
    tfp->close();
    delete tfp;
    #endif
    delete dut;
    return 0;
}
