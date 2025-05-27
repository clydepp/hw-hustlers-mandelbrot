import { createSignal, createMemo, onMount } from 'solid-js';

function App() {
  const [selectedRegion, setSelectedRegion] = createSignal('overview');
  const [canvasRef, setCanvasRef] = createSignal();
  const [zoom, setZoom] = createSignal(1);
  const [centerX, setCenterX] = createSignal(-0.5);
  const [centerY, setCenterY] = createSignal(0);

  const regions = {
    overview: {
      title: "The Complete Mandelbrot Set",
      description: "The Mandelbrot set is the set of complex numbers c for which the function f(z) = z² + c does not diverge when iterated from z = 0. The main body (cardioid) and circular bulb form the heart of the set.",
      centerX: -0.5,
      centerY: 0,
      zoom: 1,
      color: "#4F46E5"
    },
    cardioid: {
      title: "Main Cardioid Body",
      description: "The large heart-shaped region is called a cardioid. Points inside this region have periodic orbits of period 1. This is the most stable part of the set, where iterations quickly converge to a fixed point.",
      centerX: -0.25,
      centerY: 0,
      zoom: 3,
      color: "#EF4444"
    },
    bulb: {
      title: "Circular Bulb",
      description: "The circular region to the left of the main cardioid contains points with periodic orbits of period 2. This bulb is perfectly circular and represents 2-cycle behavior in the iteration.",
      centerX: -1,
      centerY: 0,
      zoom: 8,
      color: "#10B981"
    },
    seahorse: {
      title: "Seahorse Valley",
      description: "This intricate region shows self-similar seahorse-like patterns. It demonstrates the fractal nature of the Mandelbrot set boundary, where similar structures repeat at different scales.",
      centerX: -0.75,
      centerY: 0.1,
      zoom: 50,
      color: "#F59E0B"
    },
    spiral: {
      title: "Spiral Arms",
      description: "The spiral tendrils extending from the main set show how the boundary becomes increasingly complex. These regions contain points that are barely within the set, creating beautiful spiral patterns.",
      centerX: -0.16,
      centerY: 1.04,
      zoom: 100,
      color: "#8B5CF6"
    }
  };

  // Mandelbrot calculation
  const mandelbrot = (cx, cy, maxIter = 80) => {
    let x = 0, y = 0;
    let iter = 0;
    
    while (x * x + y * y <= 4 && iter < maxIter) {
      const temp = x * x - y * y + cx;
      y = 2 * x * y + cy;
      x = temp;
      iter++;
    }
    
    return iter;
  };

  // Draw the Mandelbrot set
  const drawMandelbrot = () => {
    const canvas = canvasRef();
    if (!canvas) return;
    
    const ctx = canvas.getContext('2d');
    const width = canvas.width;
    const height = canvas.height;
    const imageData = ctx.createImageData(width, height);
    
    const currentZoom = zoom();
    const currentCenterX = centerX();
    const currentCenterY = centerY();
    
    for (let px = 0; px < width; px++) {
      for (let py = 0; py < height; py++) {
        const x = (px - width / 2) / (width / 4) / currentZoom + currentCenterX;
        const y = (py - height / 2) / (height / 4) / currentZoom + currentCenterY;
        
        const iter = mandelbrot(x, y);
        const index = (py * width + px) * 4;
        
        if (iter === 80) {
          // Inside the set - black
          imageData.data[index] = 0;
          imageData.data[index + 1] = 0;
          imageData.data[index + 2] = 0;
        } else {
          // Outside the set - color based on iteration count
          const hue = (iter * 10) % 360;
          const saturation = 100;
          const lightness = 50;
          
          const rgb = hslToRgb(hue / 360, saturation / 100, lightness / 100);
          imageData.data[index] = rgb[0];
          imageData.data[index + 1] = rgb[1];
          imageData.data[index + 2] = rgb[2];
        }
        imageData.data[index + 3] = 255; // Alpha
      }
    }
    
    ctx.putImageData(imageData, 0, 0);
  };

  // HSL to RGB conversion
  const hslToRgb = (h, s, l) => {
    const c = (1 - Math.abs(2 * l - 1)) * s;
    const x = c * (1 - Math.abs((h * 6) % 2 - 1));
    const m = l - c / 2;
    
    let r, g, b;
    if (h < 1/6) [r, g, b] = [c, x, 0];
    else if (h < 2/6) [r, g, b] = [x, c, 0];
    else if (h < 3/6) [r, g, b] = [0, c, x];
    else if (h < 4/6) [r, g, b] = [0, x, c];
    else if (h < 5/6) [r, g, b] = [x, 0, c];
    else [r, g, b] = [c, 0, x];
    
    return [(r + m) * 255, (g + m) * 255, (b + m) * 255];
  };

  // Navigate to a specific region
  const navigateToRegion = (regionKey) => {
    setSelectedRegion(regionKey);
    const region = regions[regionKey];
    setCenterX(region.centerX);
    setCenterY(region.centerY);
    setZoom(region.zoom);
  };

  // Redraw when parameters change
  createMemo(() => {
    zoom();
    centerX();
    centerY();
    setTimeout(drawMandelbrot, 10);
  });

  onMount(() => {
    drawMandelbrot();
  });

  return (
    <div class="min-h-screen bg-gray-900 text-white p-6">
      <div class="max-w-7xl mx-auto">
        <header class="text-center mb-8">         
          <h1 class="text-4xl font-bold mb-4 bg-gradient-to-r from-purple-400 to-pink-600 bg-clip-text text-transparent">
            Mandelbrot Set
          </h1>
          <p class="text-xl text-gray-300">
           Hardware Hustlers: Mathematics Accelerator Project.
          </p>
        </header>

        <div class="grid lg:grid-cols-2 gap-8">
          {/* Canvas Section */}
          <div class="bg-gray-800 rounded-lg p-6">
           {/* <h2 class="text-2xl font-semibold mb-4"></h2> */}
            <div class="bg-black rounded-lg p-4 mb-4">
              <canvas
                ref={setCanvasRef}
                width="640"
                height="480"
                class="w-full h-auto border border-gray-600 rounded"
              />
            </div>
            
            {/* Navigation Controls */}
            <div class="grid grid-cols-2 md:grid-cols-3 gap-2">
              {Object.entries(regions).map(([key, region]) => (
                <button
                  onClick={() => navigateToRegion(key)}
                  class={`px-3 py-2 rounded text-sm font-medium transition-all ${
                    selectedRegion() === key
                      ? 'bg-blue-600 text-white shadow-lg'
                      : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
                  }`}
                  style={{ 'border-left': `4px solid ${region.color}` }}
                >
                  {region.title.split(' ').slice(0, 2).join(' ')}
                </button>
              ))}
            </div>
          </div>

          {/* Information Section */}
          <div class="bg-gray-800 rounded-lg p-6">
            <div 
              class="border-l-4 pl-4 mb-6"
              style={{ 'border-color': regions[selectedRegion()].color }}
            >
              <h2 class="text-2xl font-semibold mb-3">
                {regions[selectedRegion()].title}
              </h2>
              <p class="text-gray-300 leading-relaxed">
                {regions[selectedRegion()].description}
              </p>
            </div>

            {/* Mathematical Details */}
            <div class="bg-gray-900 rounded-lg p-4 mb-6">
              <h3 class="text-lg font-semibold mb-2 text-yellow-400">Mathematical Formula</h3>
              <code class="text-green-400 font-mono">
                z<sub>n+1</sub> = z<sub>n</sub>² + c
              </code>
              <p class="text-sm text-gray-400 mt-2">
                Where z starts at 0 and c is the complex number being tested
              </p>
            </div>

            {/* Current View Info */}
            <div class="bg-gray-900 rounded-lg p-4">
              <h3 class="text-lg font-semibold mb-2 text-blue-400">Current View</h3>
              <div class="text-sm space-y-1">
                <div>Center: ({centerX().toFixed(6)}, {centerY().toFixed(6)})</div>
                <div>Zoom: {zoom()}x</div>
                <div>Complex Range: Real [{(centerX() - 2/zoom()).toFixed(3)}, {(centerX() + 2/zoom()).toFixed(3)}]</div>
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>
  );
}

export default App;