#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <fstream>
#include <cstdlib>
#include <ctime>

#define ENDTIME 700000 // End time of simulation, giving 500000 clock cycles
#define TIMEOUT 50     // Time to wait for valid to be true, scaling appropriately for simulation time

int main(int argc, char **argv, char **env)
{
    Verilated::commandArgs(argc, argv);
    Vtop *top = new Vtop;
    // turn on signal tracing, dump waveforms
    Verilated::traceEverOn(true);
    VerilatedVcdC *tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("AXIS_tb_new.vcd");

    // initialise signals
    top->clk = 0;
    top->rst = 0;

    for (int i = 0; i < 2; i++)
    {
        tfp->dump(2 * i);
        top->clk = !top->clk;
        top->eval();
        tfp->dump(2 * i + 1);
        top->clk = !top->clk;
        top->eval();
    }

    top->rst = 1;

    // main simulation loop
    for (vluint64_t simcyc = 2; simcyc < ENDTIME; ++simcyc)
    {
        for (int tick = 0; tick < 2; ++tick)
        {
            tfp->dump(2 * simcyc + tick);
            top->clk = !top->clk;
            top->eval();
        }

        if (Verilated::gotFinish())
        {
            std::cout << "Simulation finished" << std::endl;
            exit(0);
        }
    }

    tfp->close();
    exit(0);
}