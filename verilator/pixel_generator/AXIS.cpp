#include "Vpixel_generator.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <fstream>
#include <cstdlib>
#include <ctime>

#define X_SIZE 480     // X dimension of image in words (words = pixels * 3/4)
#define Y_SIZE 480     // Y dimension of image
#define ENDTIME 500000 // End time of simulation, giving 500000 clock cycles
#define TIMEOUT 50     // Time to wait for valid to be true, scaling appropriately for simulation time

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
bool valid, sof, eof;

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
        // Clock low
        top->clk = 0;
        top->eval();
        tfp->dump(2 * simcyc);
        // Clock high
        top->clk = 1;

        // Ready signal generation
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

        // evaluate the DUT so can update the outputs
        top->eval();

        // read output signals
        valid = top->out_stream_tvalid;
        sof = top->out_stream_tuser;
        eol = top->out_stream_tlast;

        // Check for timeout waiting for valid
        if (valid)
        {
            checkpoint = simcyc;
        }
        if (simcyc > checkpoint + TIMEOUT)
        {
            std::cerr << "Error: Timeout waiting for valid" << std::endl;
            checkpoint = simcyc;
        }
        if (valid && ready)
        {

            // Check for Start of Frame (tuser in AXI Stream) on first word of each frame
            if (xCount == 0 && (yCount % Y_SIZE) == 0)
            {
                if (sof)
                {
                    std::cout << "SOF Ok on frame " << frameCount << std::endl;
                    yCount = 0;
                    frameCount++;
                }
                else
                {
                    std::cout << "Error: Expected SOF but not received" << std::endl;
                }
            }
            else if (sof)
            {
                std::cout << "Error: Unexpected SOF received on word " << xCount << " of line " << yCount << " of frame " << frameCount << std::endl;
                xCount = 0;
                yCount = 0;
                frameCount++;
            }

            // Check for End of Frame (tlast in AXI Stream) on last word of each frame
            if (xCount == X_SIZE - 1)
            {
                if (eol)
                {
                    std::cout << "EOF Ok on line " << yCount << std::endl;
                    xCount = 0;
                    yCount++;
                }
                else
                {
                    std::cout << "Error: No EOL on word " << xCount - 1 << " of line " << yCount << std::endl;
                    xCount++;
                }
            }
            else if (eol)
            {
                std::cout << "Error: Unexpected EOL received on word " << xCount << " of line " << yCount << std::endl;
                xCount = 0;
                yCount++;
            }
            else
            {
                xCount++;
            }
        }

        tfp->dump(2 * simcyc + 1);
    }

    tfp->close();
    exit(0);
}