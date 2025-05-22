#include "Vtable_color.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char **argv, char **env) {
    Verilated::commandArgs(argc, argv);

    // Instantiate module
    Vtable_color* top = new Vtable_color;

    // Enable waveform tracing
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("table_color.vcd");

    // Initialize simulation inputs
    top->depth = 0;
    top->max_iterations = 100;
	top->en = 0;

    // Simulation loop
    for (int i = 0; i < 300; ++i) {
        // Clock toggle (2 edges per cycle)
        for (int clk = 0; clk < 2; ++clk) {
            tfp->dump(i * 2 + clk);  // Dump time step
            top->clk = !top->clk;    // Toggle clock
            top->eval();             // Evaluate model
        }

		top->depth = (i + 1);
		top->en = (i > 3);

        if (Verilated::gotFinish()) break;
    }

    // Finalize and clean up
    tfp->close();
    delete tfp;
    delete top;
}
