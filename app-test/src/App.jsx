import { createSignal, createEffect } from 'solid-js';
import { createMousePosition } from '@solid-primitives/mouse';
import { createScrollPosition } from '@solid-primitives/scroll';

import Button from './components/Button';
import CascadeButton from './components/CascadeButton';

function App() {
  
  const compScroll = createScrollPosition();
  const pos = createMousePosition(window);
  createEffect(() => {
    console.log(pos.x, pos.y);
    compScroll.y;
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
      
      <div class="w-[640px] h-[480px] border bg-white overflow-hidden shadow-lg relative">
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
            <div class="flex flex-col items-start gap-3">
              <Button onClick={toggleCollapse}>
                {showNumbers() ? "-10" : (isCollapsed() ? "+" : "-")}
              </Button>
              
              <div 
                class="flex flex-col gap-3 overflow-hidden transition-all duration-500 ease-in-out origin-top"
                style={{
                  "transform": isCollapsed() ? "scaleY(0)" : "scaleY(1)",
                  "opacity": isCollapsed() ? "0" : "1"
                }}
              >
                <CascadeButton 
                  showNumbers={showNumbers()} 
                  onMinusOne={handleMinusOne}
                />
                <Button onClick={handlePlusClick}>
                  {showNumbers() ? counter() : (
                    <svg width="20" height="20" data-slot="icon" aria-hidden="true" fill="none" stroke-width="1.5" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <path d="M12 9v6m3-3H9m12 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" stroke-linecap="round" stroke-linejoin="round"></path>
                    </svg>
                  )}
                </Button>
                <Button onClick={handlePlusOne}>
                  {showNumbers() ? "+1" : (
                    <svg width="20" height="20" data-slot="icon" aria-hidden="true" fill="none" stroke-width="1.5" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <path d="M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" stroke-linecap="round" stroke-linejoin="round"></path>
                    <path d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1 1 15 0Z" stroke-linecap="round" stroke-linejoin="round"></path>
                    </svg>
                  )}
                </Button>
                <Button onClick={handlePlusTen}>
                  {showNumbers() ? "+10" : (
                    <svg width="20" height="20" data-slot="icon" aria-hidden="true" fill="none" stroke-width="1.5" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <path d="M3 8.25V18a2.25 2.25 0 0 0 2.25 2.25h13.5A2.25 2.25 0 0 0 21 18V8.25m-18 0V6a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 6v2.25m-18 0h18M5.25 6h.008v.008H5.25V6ZM7.5 6h.008v.008H7.5V6Zm2.25 0h.008v.008H9.75V6Z" stroke-linecap="round" stroke-linejoin="round"></path>
                    </svg>
                  )}
                </Button>
              </div>
            </div>
          </div>

          {/* Mouse and Scroll Coordinates - Bottom Left */}
          <div 
            class="absolute bottom-3 left-3 text-white text-sm font-mono bg-black/50 px-2 py-1 rounded"
            style={{ "z-index": "10" }}
          >
            X: {pos.x} Y: {pos.y}<br/>
            Scroll: {compScroll.y}
          </div>
        </div>
      </div>
    </>
  );
}

export default App;