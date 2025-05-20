#include "Vpixel_generator.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>

#define REG_COUNT 8

int main(int argc, char **argv, char **env)
{
    // Following IAC template for testbench
    uint64_t sim_time = 0;

    Verilated::commandArgs(argc, argv);

    // instantiate the module
    Vpixel_generator *top = new Vpixel_generator;
    VerilatedVcdC *tfp = new VerilatedVcdC;

    Verilated::traceEverOn(true);
    VerilatedVcdC *tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("AXIL_tb.vcd");

    uint64_t sim_time = 0;

    // Initial states
    top->clk = 0;
    top->rst = 0;
    top->writeAdd = 0;
    top->writeData = 0;
    top->writeAddValid = 0;
    top->writeValid = 0;
    top->respReady = 0;
    top->readAdd = 0;
    top->readAddValid = 0;
    top->readReady = 0;

    // Start simulation loop
    while (!Verilated::gotFinish() && sim_time < 2000)
    {
        // Clock toggle
        if (sim_time % 10 == 0)
            top->clk = !top->clk;

        // Deassert reset after 16 ns
        if (sim_time == 16)
            top->rst = 1;

        // Write registers
        if (sim_time >= 20 && sim_time < 400)
        {
            int index = (sim_time - 20) / 80;
            if (index < REG_COUNT)
            {
                if ((sim_time % 80) == 0)
                    top->writeAdd = index * 4;
                if ((sim_time % 80) == 20)
                    top->writeData = index * 0x11111111;
                if ((sim_time % 80) == 40)
                    top->writeAddValid = 1;
                if ((sim_time % 80) == 50)
                    top->writeAddValid = 0;
                if ((sim_time % 80) == 60)
                    top->writeValid = 1;
                if ((sim_time % 80) == 70)
                    top->writeValid = 0;
                if ((sim_time % 80) == 75)
                    top->respReady = 1;
                if ((sim_time % 80) == 78)
                    top->respReady = 0;
            }
        }

        // Read registers
        if (sim_time >= 500 && sim_time < 1000)
        {
            int index = (sim_time - 500) / 80;
            if (index < REG_COUNT)
            {
                if ((sim_time % 80) == 0)
                    top->readAdd = index * 4;
                if ((sim_time % 80) == 20)
                    top->readAddValid = 1;
                if ((sim_time % 80) == 30)
                    top->readAddValid = 0;
                if ((sim_time % 80) == 50)
                    top->readReady = 1;
                if ((sim_time % 80) == 60)
                    top->readReady = 0;
                if ((sim_time % 80) == 65 && top->readValid)
                {
                    std::cout << "Read[" << index << "] = 0x"
                              << std::hex << top->readData << std::dec << std::endl;
                }
            }
        }

        // Evaluate and dump signals
        top->eval();
        tfp->dump(sim_time);
        sim_time++;
    }

    tfp->close();
    delete top;
    delete tfp;
    return 0;
}
