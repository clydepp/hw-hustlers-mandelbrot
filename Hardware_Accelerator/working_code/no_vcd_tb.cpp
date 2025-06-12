#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <fstream>

#define ENDTIME 180000000

int main(int argc, char **argv, char **env)
{
    Verilated::commandArgs(argc, argv);
    Vtop *top = new Vtop;

    // Verilated::traceEverOn(true);
    // VerilatedVcdC *tfp = new VerilatedVcdC;
    // top->trace(tfp, 99);
    // tfp->open("AXIS_tb_new.vcd");

    // Open CSV file
    std::ofstream csv("pixels.csv");
    csv << "x,y,r,g,b\n";  // CSV header

    // Initial reset
    top->clk = 0;
    top->rst = 0;

    for (int i = 0; i < 2; i++)
    {
        // tfp->dump(2 * i);
        top->clk = !top->clk;
        top->eval();
        // tfp->dump(2 * i + 1);
        top->clk = !top->clk;
        top->eval();
    }

    top->rst = 1;

    // Main simulation
    for (vluint64_t simcyc = 2; simcyc < ENDTIME; ++simcyc)
    {
        for (int tick = 0; tick < 2; ++tick)
        {
            // tfp->dump(2 * simcyc + tick);
            top->clk = !top->clk;
            top->eval();
        }

        // Dump pixel when valid
        if (top->valid_int)
        {
            csv << (int)top->x << "," << (int)top->y << ","
                << (int)top->r << "," << (int)top->g << "," << (int)top->b << "\n";
        }

        if (Verilated::gotFinish())
        {
            std::cout << "Simulation finished" << std::endl;
            break;
        }
    }

    // tfp->close();
    csv.close();
    std::cout << "Pixel data written to pixels.csv" << std::endl;
    exit(0);
}
