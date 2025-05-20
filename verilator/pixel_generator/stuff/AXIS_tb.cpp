#include "Vpixel_generator.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <fstream>
#include <cstdlib>
#include <ctime>

#define X_SIZE 480       // X dimension of image in words (words = pixels * 3/4)
#define Y_SIZE 480       // Y dimension of image
#define ENDTIME 10000000 // End time of simulation
#define TIMEOUT 1000     // Time to wait for valid to be true

// Ready modes
enum ReadyMode
{
    ALWAYS_READY = 1,     // Ready signal is always true
    RANDOM_READY = 2,     // Ready signal is true 50% of the time according to pseudo-random sequence
    READY_AFTER_VALID = 3 // Ready signal goes true after valid is true, then goes false
};

const int READY_MODE = RANDOM_READY;
const uint32_t RND_SEED = 1246504138;

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

int main(int argc, char **argv, char **env)
{
    Verilated::commandArgs(argc, argv);
    Vpixel_generator *top = new Vpixel_generator;
    // turn on signal tracing, dump waveforms
    Verilated::traceEverOn(true);
    VerilatedVcdC *tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("AXIS_tb.vcd");

    // Simulation variables
    int xCount = 0, yCount = 0, frameCount = 0;
    vluint64_t checkpoint = 0;

    // Random ready
    uint32_t prbs = RND_SEED;
    bool ready = false;

    // Simulation
    top->axi_resetn = 0;
    top->periph_resetn = 0;
    top->out_stream_tready = ready;

    // Reset
    for (int i = 0; i < 4; i++)
    {
        top->out_stream_aclk = 0;
        top->s_axi_lite_aclk = 0;
        top->eval();
        main_time++;
        top->out_stream_aclk = 1;
        top->s_axi_lite_aclk = 1;
        top->eval();
        main_time++;
    }
    top->axi_resetn = 1;
    top->periph_resetn = 1;

    // Main loop
    while (!Verilated::gotFinish() && main_time < ENDTIME)
    {

        // Clock low
        top->out_stream_aclk = 0;
        top->s_axi_lite_aclk = 0;
        top->eval();
        main_time++;

        // Clock high
        top->out_stream_aclk = 1;
        top->s_axi_lite_aclk = 1;

        // READY generation
        prbs = (prbs << 1) | ((prbs >> 19) ^ (prbs >> 32));
        switch (READY_MODE)
        {
        case ALWAYS_READY:
            ready = true;
            break;
        case RANDOM_READY:
            ready = prbs & 1;
            break;
        case READY_AFTER_VALID:
            if (top->out_stream_tvalid)
            {
                ready = !ready;
            }
            else
            {
                ready = false;
            }
            break;
        }
        top->out_stream_tready = ready;

        top->eval();
        main_time++;

        // Timeout check
        if (top->out_stream_tvalid)
        {
            checkpoint = main_time;
        }
        if (main_time > checkpoint + TIMEOUT)
        {
            std::cerr << "Error: Timeout waiting for valid\n";
            checkpoint = main_time;
        }

        // Check stream
        if (top->out_stream_tvalid && top->out_stream_tready)
        {
            if (xCount == 0 && (yCount % Y_SIZE) == 0)
            {
                if (top->out_stream_tuser)
                {
                    std::cout << "SOF Ok on frame " << frameCount << std::endl;
                    yCount = 0;
                    frameCount++;
                }
                else
                {
                    std::cerr << "Error: Expected SOF but not received\n";
                }
            }
            else if (top->out_stream_tuser)
            {
                std::cerr << "Error: Unexpected SOF received at word " << xCount
                          << " line " << yCount << " frame " << frameCount << std::endl;
                xCount = 0;
                yCount = 0;
                frameCount++;
            }

            if (xCount == X_SIZE - 1)
            {
                if (top->out_stream_tlast)
                {
                    std::cout << "EOL Ok on line " << yCount << std::endl;
                    xCount = 0;
                    yCount++;
                }
                else
                {
                    std::cerr << "Error: No EOL on last word of line " << yCount << std::endl;
                    xCount++;
                }
            }
            else if (top->out_stream_tlast)
            {
                std::cerr << "Error: Unexpected EOL at word " << xCount << " of line " << yCount << std::endl;
                xCount = 0;
                yCount++;
            }
            else
            {
                xCount++;
            }
        }
    }

    top->final();
    delete top;
    return 0;
}
