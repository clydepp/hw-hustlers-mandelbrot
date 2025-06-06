import { createSignal, createEffect, onMount, onCleanup } from 'solid-js';
import { createMousePosition } from '@solid-primitives/mouse';
import { createScrollPosition } from '@solid-primitives/scroll';

import Button from './components/Button';
import CascadeButton from './components/CascadeButton';
import SideCascade from './components/SideCascade';
import Modal from './components/Modal';

function App() {
  const compScroll = createScrollPosition();
  const pos = createMousePosition(window);
  const [mouseWheelDelta, setMouseWheelDelta] = createSignal(1);
  const [isDarkMode, setIsDarkMode] = createSignal(false);
  const [isModalOpen, setIsModalOpen] = createSignal(false);

  const [isOptiModal, setIsOptiModal] = createSignal(false);
  const [isConfigModal, setIsConfigModal] = createSignal(false);
  const [isTheoryModal, setIsTheoryModal] = createSignal(false);
  const [isEBIModal, setIsEBIModal] = createSignal(false);
  const [isUsageBlur, setIsUsageBlur] = createSignal(false); // Add this

  createEffect(() => {
    console.log(pos.x, pos.y);
  });

  // Add this effect to toggle the dark class
  createEffect(() => {
    if (isDarkMode()) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  });

  onMount(() => {
    const handleWheel = (event) => {
      // Reverse scroll direction by negating deltaY
      const newValue = mouseWheelDelta() + (-event.deltaY) * 0.2;
      
      // Cap between 0 and 2^32 (4,294,967,296)
      const clampedValue = Math.max(0, Math.min(newValue, Math.pow(2, 32)));
      
      setMouseWheelDelta(clampedValue);
      console.log('Mouse wheel:', -event.deltaY, 'Total:', clampedValue);
    };

    window.addEventListener('wheel', handleWheel);
    
    onCleanup(() => {
      window.removeEventListener('wheel', handleWheel);
    });
  });
  
  const [isCollapsed, setIsCollapsed] = createSignal(false);
  const [showNumbers, setShowNumbers] = createSignal(false);
  const [counter, setCounter] = createSignal(200);

  const toggleCollapse = () => {
    if (showNumbers()) {
      setCounter(counter() - 10);
    } else {
      setIsCollapsed(!isCollapsed());
    }
  };

  const handlePlusClick = () => {
    setShowNumbers(!showNumbers());
  };

  const handlePlusOne = () => {
    setCounter(counter() + 1);
  };

  const handleMinusOne = () => {
    setCounter(counter() - 1);
  };

  const handlePlusTen = () => {
    setCounter(counter() + 10);
  };

  const handleMinusTen = () => {
    setCounter(counter() - 10);
  };

  return (
    <>
      {/* Blur Overlay - at App level */}
      {isUsageBlur() && (
        <div 
          class="fixed inset-0 backdrop-blur-md bg-opacity-20 z-40"
          onClick={() => setIsUsageBlur(false)}
          style={{ "pointer-events": "all" }}
        />
      )}
      
      <style jsx global>{`
        html, body {
          margin: 0;
          padding: 0;
          width: 640px;
          height: 480px;
          overflow: hidden;
        }
        #root {
          width: 640px;
          height: 480px;
        }
      `}</style>
      
      <div class={`w-[640px] h-[480px] border overflow-hidden shadow-lg relative ${isDarkMode() ? 'bg-gray-900' : 'bg-white'}`}>
        <div style={{
          "background-image": "url('https://upload.wikimedia.org/wikipedia/commons/2/21/Mandel_zoom_00_mandelbrot_set.jpg')",
          "background-size": "cover",
          "background-position": "center",
          "background-repeat": "no-repeat",
          "width": "100%",
          "height": "100%"
        }}>
          {/* UI Controls - Top Left */}
          <div class="p-3" style={{ position: "absolute", "z-index": "10" }}>
            <div class="flex flex-col items-start gap-3 w-fit">
              <Button onClick={toggleCollapse} isDarkMode={isDarkMode()}>
                {showNumbers() ? "-10" : (isCollapsed() ? "+" : "-")}
              </Button>
              
              <div 
                class="flex flex-col gap-3 overflow-hidden transition-all duration-500 ease-in-out origin-top"
                style={{
                  "transform": isCollapsed() ? "scaleY(0)" : "scaleY(1)",
                  "opacity": isCollapsed() ? "0" : "1"
                }}
              >
                <div class="relative">
                  <CascadeButton 
                    showNumbers={showNumbers()} 
                    onMinusOne={handleMinusOne}
                    isDarkMode={isDarkMode()}
                  />
                </div>
                <Button onClick={handlePlusClick} isDarkMode={isDarkMode()}>
                  {showNumbers() ? counter() : (
                    <svg width="20" height="20" data-slot="icon" aria-hidden="true" fill="none" stroke-width="1.5" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <path d="M12 9v6m3-3H9m12 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" stroke-linecap="round" stroke-linejoin="round"></path>
                    </svg>
                  )}
                </Button>
                <Button onClick={handlePlusOne} isDarkMode={isDarkMode()}>
                  {showNumbers() ? "+1" : (
                    <svg width="20" height="20" data-slot="icon" aria-hidden="true" fill="none" stroke-width="1.5" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <path d="M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" stroke-linecap="round" stroke-linejoin="round"></path>
                    <path d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1 1 15 0Z" stroke-linecap="round" stroke-linejoin="round"></path>
                    </svg>
                  )}
                </Button>
                
                <div class="w-fit">
                  <SideCascade
                    showNumbers={showNumbers()} 
                    onMinusOne={handlePlusTen}
                    isDarkMode={isDarkMode()}
                    setIsDarkMode={setIsDarkMode}
                    setIsModalOpen={setIsModalOpen}
                    setIsConfigModal={setIsConfigModal}
                    // isUsageBlur={isUsageBlur}
                    // setIsUsageBlur={setIsUsageBlur}
                  />
                </div>
              </div>
            </div>
          </div>
          {/* Mouse and Wheel Coordinates - Bottom Left */}
          <div 
            class={`absolute bottom-3 left-3 text-sm font-mono px-2 py-1 rounded ${
              !isDarkMode() ? 'text-black bg-white/50' : 'text-white bg-black/50'
            }`}
            style={{ "z-index": "10" }}
          >
            X: {pos.x} Y: {pos.y}<br/>
            Zoom: {mouseWheelDelta()}
          </div>
        </div>
      </div>
      <Modal 
        title="Mandelbrot Viewer"
        content={
          <div>
            <h3 class="mb-4">Hardware Hustlers, Mathematics Accelerator</h3>
            <div class="grid grid-cols-2 gap-3">
              <button
                type="button" 
                class="w-full py-2.5 px-5 text-sm font-medium text-gray-900 focus:outline-none bg-white rounded-lg border border-gray-200 hover:bg-gray-100 hover:text-blue-700 focus:z-10 focus:ring-4 focus:ring-gray-100 dark:focus:ring-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:border-gray-600 dark:hover:text-white dark:hover:bg-gray-700"
                onClick={() => {
                  setIsModalOpen(false);
                  setIsTheoryModal(true);
                }}
              >
                Theory
              </button>
              <button 
                type="button" 
                class="w-full py-2.5 px-5 text-sm font-medium text-gray-900 focus:outline-none bg-white rounded-lg border border-gray-200 hover:bg-gray-100 hover:text-blue-700 focus:z-10 focus:ring-4 focus:ring-gray-100 dark:focus:ring-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:border-gray-600 dark:hover:text-white dark:hover:bg-gray-700"
              >
                Usage
              </button>
              <button 
                type="button" 
                class="w-full py-2.5 px-5 text-sm font-medium text-gray-900 focus:outline-none bg-white rounded-lg border border-gray-200 hover:bg-gray-100 hover:text-blue-700 focus:z-10 focus:ring-4 focus:ring-gray-100 dark:focus:ring-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:border-gray-600 dark:hover:text-white dark:hover:bg-gray-700"
                onClick={() => {
                  setIsOptiModal(true);
                  setIsModalOpen(false);
                }}
              >
                Optimisations
              </button>
              <button 
                type="button" 
                class="w-full py-2.5 px-5 text-sm font-medium text-gray-900 focus:outline-none bg-white rounded-lg border border-gray-200 hover:bg-gray-100 hover:text-blue-700 focus:z-10 focus:ring-4 focus:ring-gray-100 dark:focus:ring-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:border-gray-600 dark:hover:text-white dark:hover:bg-gray-700"
                onClick={() => {
                  setIsModalOpen(false);
                  setIsEBIModal(true);
                }}
              >
                Accessibility
              </button>
            </div>
          </div>
        }
        isOpen={isModalOpen} 
        onClose={() => setIsModalOpen(false)} 
      />
      <Modal 
        title="Theory"
        content={
          <div class="max-h-96 overflow-y-auto pr-2">
            <pre class="whitespace-pre-wrap text-sm leading-relaxed text-gray-600 dark:text-gray-300">
{`The Mandelbrot set is the set of complex numbers c for which the sequence defined by:

    z₀ = 0
    zₙ₊₁ = zₙ² + c

remains bounded (does not escape to infinity) as n increases.

To determine whether a point c is in the Mandelbrot set:
1. Start with z = 0.
2. Repeatedly apply the function z = z² + c.
3. If |z| ever becomes greater than 2, the point c is NOT in the set.
4. If |z| stays less than or equal to 2 after many iterations, c is LIKELY in the set.

In practice:
- Each pixel on the screen represents a complex number c.
- We iterate z = z² + c for each pixel.
- Points that escape are colored based on how quickly they escape.
- Points that don't escape (stay bounded) are colored black.

This creates the famous fractal: infinitely detailed, self-similar, and complex.

Terms:
- c: complex number (real + imaginary part)
- |z|: magnitude of the complex number z
- Escape radius: usually set to 2
- Iteration count: how many times to repeat z = z² + c (e.g., 100–1000 times)

The boundary of the Mandelbrot set marks the edge between stability and chaos.`}
            </pre>
          </div>
        }
        isOpen={isTheoryModal} 
        onClose={() => setIsTheoryModal(false)} 
      />
      <Modal 
        title="Manual Config"
        contents={
          <div>
            <h3>hello</h3>
          </div>
        }
        isOpen={isConfigModal}
        onClose={() => setIsConfigModal(false)}
      />
      <Modal 
        title="Optimisations"
        content="To speedup the Mandelbrot calculation: ..."
        isOpen={isOptiModal}
        onClose={() => setIsOptiModal(false)}
      />
      <Modal 
        title="Accessibility"
        content="Put some languages and colourblind mode? here"
        isOpen={isEBIModal}
        onClose={() => setIsEBIModal(false)}
      />


      
      {/* <Modal 
        title="Seahorse Valley"
        content={`Coordinates: -0.75 + 0.1j
          Zoom: 50x
          `}
      />
      <Modal 
        title="Spiral Arms"
        content={`Coordinates: -0.16 + 1.04j
          Zoom: 100x
          `}
      />
      <Modal 
        title="Minibrot"
        content={`Coordinates: -1.25 + 0.02j
          Zoom: 300x
          `}
      />
      <Modal
        title="Farey Addition"
        content={`Coordinates: -1.25 + 0.02j
          Zoom: 10x
          `}
      /> */}
    </>
  );
}

export default App;