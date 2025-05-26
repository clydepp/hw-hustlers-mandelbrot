#include "Vtop_connection.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <fstream>
#include <cstdint>

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vtop_connection* dut = new Vtop_connection;
	// Disable VCD tracing
    // Verilated::traceEverOn(true);
    // VerilatedVcdC *tfp = new VerilatedVcdC;
    // dut->trace(tfp, 99);
    // tfp->open("top_connection.vcd");

    //const int W = 640, H = 480;
    std::ofstream csv("mandelbrot_rgb.csv");
    csv << "x,y,R,G,B\n";

    // Reset
    dut->reset  = 1;
    dut->sysclk = 0;
    dut->start  = 0;
    dut->eval(); 
	 // tfp->dump(main_time);
	main_time++;
    dut->sysclk = 1;
    dut->eval();
	 // tfp->dump(main_time);
	main_time++;
    dut->reset = 0;

    // Start processing
    dut->SCREEN_WIDTH = 1280;
    dut->SCREEN_HEIGHT = 720;
    dut->start = 1;
    //dut->FRAC=16;
    dut->ZOOM=1024;
    int FRAC = 60;
    double x = -0.75; 
    double y = 0.1; 
    int64_t real_center = (int64_t)(x * (1LL << FRAC));
    int64_t imag_center = (int64_t)(y * (1LL << FRAC));
    dut->real_center = real_center;
    dut->imag_center = imag_center;
    dut->sysclk = 0; dut->eval();
	main_time++;
    dut->sysclk = 1; dut->eval(); 
	main_time++;
    dut->start = 0;

    int pixel_count = 0;
    const int total_pixels =(dut->SCREEN_WIDTH) * (dut->SCREEN_HEIGHT);

    while (pixel_count < total_pixels) {
        dut->sysclk = 0; dut->eval(); main_time++;
        dut->sysclk = 1; dut->eval(); main_time++;
 
        if (dut->done) {
			dut->start = 1;
            uint32_t color = dut->color;
            uint8_t r = (color >> 16) & 0xFF;
            uint8_t g = (color >> 8) & 0xFF;
            uint8_t b = color & 0xFF;

            int x = dut->x_cnt;
            int y = dut->y_cnt;
            csv << x << "," << y << "," << int(r) << "," << int(g) << "," << int(b) << "\n";

            pixel_count++;
            if (pixel_count % 1000 == 0)
                std::cerr << "Pixels: " << pixel_count << "/" << total_pixels << "\n";
        }
	   else{
		dut->start = 0;
	   }
    }

    csv.close();
    dut->final();
    delete dut;
    std::cout << "Done! RGB data saved to mandelbrot_rgb.csv\n";
    return 0;
}
