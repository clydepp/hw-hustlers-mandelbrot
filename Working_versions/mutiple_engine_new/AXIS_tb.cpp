#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h" // Include for VCD tracing
#include <iostream>
#include <fstream>
#include <cstdlib>
#include <ctime>

#define ENDTIME 30000000
#define TIMEOUT 50

int main(int argc, char **argv, char **env)
{
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true); // Enable tracing

    Vtop *top = new Vtop;
    // VerilatedVcdC *tfp = new VerilatedVcdC;
    // top->trace(tfp, 99);      // Attach trace
    // tfp->open("AXIS_tb.vcd"); // Open VCD file

    top->clk = 0;
    top->rst = 0;

    std::cout << "hello" << std::endl;

    std::ofstream csv("pixels.csv");
    csv << "x,y,r,g,b\n";

    int x = 0, y = 0;
    const int X_SIZE = 640;
    const int Y_SIZE = 480;

    std::cout << "hello" << std::endl;

    // Clock for reset
    for (int i = 0; i < 2; i++)
    {
        // tfp->dump(2 * i);
        top->clk = !top->clk;
        top->eval();
        // tfp->dump(2 * i + 1);
        top->clk = !top->clk;
        top->eval();
    }

    std::cout << "hello" << std::endl;

    top->rst = 1;

    // Simulation loop
    for (vluint64_t simcyc = 2; simcyc < ENDTIME; ++simcyc)
    {
        for (int tick = 0; tick < 2; ++tick)
        {
            // tfp->dump(2 * simcyc + tick);
            top->clk = !top->clk;
            top->eval();
        }

        if (top->valid_int_out)
        {
            uint32_t tdata = top->tdata;
            uint8_t r = static_cast<uint8_t>(top->r_out);
            uint8_t g = static_cast<uint8_t>(top->g_out);
            uint8_t b = static_cast<uint8_t>(top->b_out);

            // std::cout<< "r value at x value " << top->x_out << " and y value " << top->y_out << " is " << static_cast<int>(r) << std::endl;
            //  std::cout << "x: " << top->x_out << ", y: " << top->y_out
            //            << ", r: " << static_cast<int>(r)
            //            << ", g: " << static_cast<int>(g)
            //            << ", b: " << static_cast<int>(b) << std::endl;
            csv << top->x_out << "," << top->y_out << ","
                << static_cast<int>(r) << ","
                << static_cast<int>(g) << ","
                << static_cast<int>(b) << "\n";
        }

        if (Verilated::gotFinish())
            break;
    }

    csv.close();
    // tfp->close(); // Close VCD
    // delete tfp;
    delete top;
    return 0;
}
