import { createSignal, createEffect, onMount, onCleanup } from 'solid-js';
import { createMousePosition } from '@solid-primitives/mouse';
import { createScrollPosition } from '@solid-primitives/scroll';

import Button from './components/Button';
import CascadeButton from './components/CascadeButton';
import SideCascade from './components/SideCascade';

function App() {
  
  const compScroll = createScrollPosition();
  const pos = createMousePosition(window);
  const [mouseWheelDelta, setMouseWheelDelta] = createSignal(1);
  const [isDarkMode, setIsDarkMode] = createSignal(false);
  
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
                  />
                </div>
              </div>
            </div>
          </div>

          {/* Mouse and Wheel Coordinates - Bottom Left */}
          <div 
            class={`absolute bottom-3 left-3 text-sm font-mono px-2 py-1 rounded ${
              isDarkMode() ? 'text-black bg-white/50' : 'text-white bg-black/50'
            }`}
            style={{ "z-index": "10" }}
          >
            X: {pos.x} Y: {pos.y}<br/>
            Zoom: {mouseWheelDelta()}
          </div>
        </div>
      </div>
    </>
  );
}

export default App;