#include "Vtop.h"
#include "verilated.h"
#include <iostream>
#include <fstream>
#include <cstdlib>
#include <ctime>


#define ENDTIME 70000000
#define TIMEOUT 50

int main(int argc, char **argv, char **env)
{
    Verilated::commandArgs(argc, argv);
    Vtop *top = new Vtop;

    // Comment out VCD dump
    // Verilated::traceEverOn(true);
    // VerilatedVcdC *tfp = new VerilatedVcdC;
    // top->trace(tfp, 99);
    // tfp->open("AXIS_tb_new.vcd");

    top->clk = 0;
    top->rst = 0;

    std::ofstream csv("pixels.csv");
    csv << "x,y,r,g,b\n";

    int x = 0, y = 0;
   // const int X_SIZE = 640;
    const int X_SIZE = 640;
    const int Y_SIZE = 480;

    // Clock for reset
    for (int i = 0; i < 2; i++) {
        top->clk = !top->clk;
        top->eval();
    }

    top->rst = 1;

    // Simulation loop
    for (vluint64_t simcyc = 2; simcyc < ENDTIME; ++simcyc) {
        for (int tick = 0; tick < 2; ++tick) {
            top->clk = !top->clk;
            top->eval();
        }

        if (top->valid && top->ready) {
            uint32_t tdata = top->tdata;
            uint8_t r = top->top->p1->r_reg;
            uint8_t g = top->top->p1->g_reg;
            uint8_t b = top->top->p1->b_reg;

            csv << x << "," << y << ","
                << static_cast<int>(r) << ","
                << static_cast<int>(g) << ","
                << static_cast<int>(b) << "\n";

            if (x == X_SIZE - 1) {
                x = 0;
                y++;
            } else {
                x++;
            }

            if (y == Y_SIZE) break; // Stop after one frame
        }

        if (Verilated::gotFinish())
            break;
    }

    csv.close();
    // tfp->close();

    delete top;
    return 0;
}
