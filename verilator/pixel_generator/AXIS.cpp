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

// prbs for random ready
const int READY_MODE = RANDOM_READY;
const uint32_t RND_SEED = 1246504138;

// Output counters
int xCount = 0, yCount = 0, frameCount = 0;
vluint64_t checkpoint = 0;

int main(int argc, char **argv, char **env)
{
    Verilated::commandArgs(argc, argv);
    Vpixel_generator *top = new Vpixel_generator;
    // turn on signal tracing, dump waveforms
    Verilated::traceEverOn(true);
    VerilatedVcdC *tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("AXIS_tb.vcd");

    // initialise signals
    top->clk = 0;
    top->rst = 0;
    top->out_stream_tready = 0;

    // initialise top variables
    top->s_axi_lite_araddr = 0;
    top->s_axi_lite_arvalid = 0;
    top->s_axi_lite_awaddr = 0;
    top->s_axi_lite_awvalid = 0;
    top->s_axi_lite_bready = 0;
    top->s_axi_lite_rready = 0;
    top->s_axi_lite_wdata = 0;
    top->s_axi_lite_wvalid = 0;

    // PRBS for random ready
    uint32_t prbs = RND_SEED;
    int ready = 0;

    // Reset initial
    for (int i = 0; i < 4; ++i)
    {
        top->clk = 0;
        top->eval();
        tfp->dump(2 * i);
        top->clk = 1;
        top->eval();
        tfp->dump(2 * i + 1);
    }
    top->rst = 1;

    // main simulation loop
    for (vluint64_t simcyc = 0; simcyc < ENDTIME; ++simcyc)
    {
        for (vluint64_t tick = 0; tick < 2; ++tick)
        {
            switch (READY_MODE)
            {
            case ALWAYS_READY:
                ready = 1;
                break;
            case RANDOM_READY:
                prbs = (prbs << 1) | (((prbs >> 32) ^ (~(prbs >> 19))) & 1);
                ready = (prbs >> 32) & 1;
                break;
            case READY_AFTER_VALID:
                if (top->out_stream_tvalid && ready)
                    ready = 0;
                else if (top->out_stream_tvalid)
                    ready = 1;
                else
                    ready = 0;
                break;
            }
            top->out_stream_tready = ready;

            top->clk = !top->clk;
            top->eval();
            tfp->dump(2 * simcyc + tick);
        }
    }

    tfp->close();
    exit(0);
}