import { createSignal, createEffect, onMount, onCleanup } from 'solid-js';
import { createMousePosition } from '@solid-primitives/mouse';
import { createScrollPosition } from '@solid-primitives/scroll';

import Button from './components/Button';
import CascadeButton from './components/CascadeButton';
import SideCascade from './components/SideCascade';
import Modal from './components/Modal';
import { useTranslation } from './i18n/useTranslation.js';

// Q4.28 Fixed-Point Helper Functions
const Q4_28_SCALE = 1 << 28; // 2^28 = 268,435,456

const floatToQ4_28 = (value) => {
  return Math.round(value * Q4_28_SCALE) | 0; // | 0 ensures 32-bit signed int
};

const q4_28ToFloat = (q_value) => {
  return q_value / Q4_28_SCALE;
};

function App() {
  const { t, setLanguage, currentLanguage } = useTranslation();
  
  const compScroll = createScrollPosition();
  const pos = createMousePosition(window);
  const [mouseWheelDelta, setMouseWheelDelta] = createSignal(1);
  const [isDarkMode, setIsDarkMode] = createSignal(false);
  const [isModalOpen, setIsModalOpen] = createSignal(false);

  // modal signals
  const [isOptiModal, setIsOptiModal] = createSignal(false);
  const [isConfigModal, setIsConfigModal] = createSignal(false);
  const [isTheoryModal, setIsTheoryModal] = createSignal(false);
  const [isEBIModal, setIsEBIModal] = createSignal(false);
  const [isUsageBlur, setIsUsageBlur] = createSignal(false);

  const [zoom, setZoom] = createSignal(1);
  const [centerX_Q4_28, setCenterX_Q4_28] = createSignal(floatToQ4_28(-0.5));
  const [centerY_Q4_28, setCenterY_Q4_28] = createSignal(floatToQ4_28(0.0));

  // Derived getters for display/calculation
  const centerX = () => q4_28ToFloat(centerX_Q4_28());
  const centerY = () => q4_28ToFloat(centerY_Q4_28());

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
      const newValue = Math.floor(mouseWheelDelta() + (-event.deltaY) * 0.01);
      
      // Cap between 0 and 2^32 (4,294,967,296)
      const clampedValue = Math.max(1, Math.min(newValue, Math.pow(2, 32)));
      
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

  // Updated input handlers
  const handleCenterXInput = (e) => {
    const floatValue = parseFloat(e.target.value) || 0;
    // Clamp to Q4.28 range: -8.0 to 7.999999999
    const clampedValue = Math.max(-8.0, Math.min(7.999999999, floatValue));
    setCenterX_Q4_28(floatToQ4_28(clampedValue));
  };
  
  const handleCenterYInput = (e) => {
    const floatValue = parseFloat(e.target.value) || 0;
    const clampedValue = Math.max(-8.0, Math.min(7.999999999, floatValue));
    setCenterY_Q4_28(floatToQ4_28(clampedValue));
  };

  const [mandelbrotImage, setMandelbrotImage] = createSignal('');
  const [websocket, setWebsocket] = createSignal(null);

  // WebSocket connection on mount
  onMount(() => {
    const ws = new WebSocket('ws://192.168.137.175:8000'); // No '/websocket' endpoint
    
    ws.onopen = () => {
      console.log('Connected to PYNQ WebSocket server!');
      setWebsocket(ws);
    };

    ws.onmessage = (event) => {
      // Receive base64 image from PYNQ
      setMandelbrotImage(event.data);
    };

    ws.onerror = (error) => {
      console.error('WebSocket error:', error);
    };

    ws.onclose = () => {
      console.log('WebSocket connection closed');
    };

    onCleanup(() => {
      if (ws) ws.close();
    });
  });
  
  // Send parameters when they change
  createEffect(() => {
    const ws = websocket();
    if (ws && ws.readyState === WebSocket.OPEN) {
      const params = {
        re_c: centerX(),
        im_c: centerY(), 
        zoom: mouseWheelDelta(),
        max_iter: counter(),
        colour_sch: "classic"
      };
      ws.send(JSON.stringify(params));
    }
  });

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
        
        /* Keep UI controls on the left even in RTL mode */
        .ui-controls {
          direction: ltr !important;
          left: 0px !important;
          right: auto !important;
        }
        
        /* Keep coordinate display on the left in RTL */
        .coordinates {
          direction: ltr !important;
          text-align: left !important;
          left: 8px !important;
          right: auto !important;
        }
      `}</style>

      <div class={`w-[640px] h-[480px] border overflow-hidden shadow-lg relative ${isDarkMode() ? 'bg-gray-900' : 'bg-white'}`}>
        <div style={{
          "background-image": mandelbrotImage() ? `url('${mandelbrotImage()}')` : "url('data:image/jpeg;base64,iVBORw0K...')", // Your default image
          "background-size": "cover",
          "background-position": "center",
          "background-repeat": "no-repeat",
          "width": "100%",
          "height": "100%"
        }}>
          {/* UI Controls - Force left positioning */}
          <div 
            class="p-3 ui-controls" 
            style={{ 
              position: "absolute", 
              "z-index": "10",
              left: "0",
              right: "auto"
            }}
          >
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
                    isUsageBlur={isUsageBlur}
                    setIsUsageBlur={setIsUsageBlur}
                  />
                </div>
              </div>
            </div>
          </div>
          
          {/* Coordinates - Force left positioning */}
          <div 
            class={`absolute bottom-2 left-3 text-sm font-mono px-2 py-1 rounded coordinates ${
              !isDarkMode() ? 'text-black bg-white/50' : 'text-white bg-black/50'
            }`}
            style={{ 
              "z-index": "10",
              left: "15px",
              right: "15px"
            }}
          >
            X: {pos.x} Y: {pos.y}<br/>
            {t('zoom')}: {mouseWheelDelta()}
          </div>
        </div>
      </div>
      
      <Modal 
        title={t('title')}
        content={
          <div>
            <h3 class="mb-4">{t('subtitle')}</h3>
            <div class="grid grid-cols-2 gap-3">
              <button
                type="button" 
                class="w-full py-2.5 px-5 text-sm font-medium text-gray-900 focus:outline-none bg-white rounded-lg border border-gray-200 hover:bg-gray-100 hover:text-blue-700 focus:z-10 focus:ring-4 focus:ring-gray-100 dark:focus:ring-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:border-gray-600 dark:hover:text-white dark:hover:bg-gray-700"
                onClick={() => {
                  setIsModalOpen(false);
                  setIsTheoryModal(true);
                }}
              >
                {t('theory')}
              </button>
              <button 
                type="button" 
                class="w-full py-2.5 px-5 text-sm font-medium text-gray-900 focus:outline-none bg-white rounded-lg border border-gray-200 hover:bg-gray-100 hover:text-blue-700 focus:z-10 focus:ring-4 focus:ring-gray-100 dark:focus:ring-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:border-gray-600 dark:hover:text-white dark:hover:bg-gray-700"
              >
                {t('usage')}
              </button>
              <button 
                type="button" 
                class="w-full py-2.5 px-5 text-sm font-medium text-gray-900 focus:outline-none bg-white rounded-lg border border-gray-200 hover:bg-gray-100 hover:text-blue-700 focus:z-10 focus:ring-4 focus:ring-gray-100 dark:focus:ring-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:border-gray-600 dark:hover:text-white dark:hover:bg-gray-700"
                onClick={() => {
                  setIsOptiModal(true);
                  setIsModalOpen(false);
                }}
              >
                {t('optimisations')}
              </button>
              <button 
                type="button" 
                class="w-full py-2.5 px-5 text-sm font-medium text-gray-900 focus:outline-none bg-white rounded-lg border border-gray-200 hover:bg-gray-100 hover:text-blue-700 focus:z-10 focus:ring-4 focus:ring-gray-100 dark:focus:ring-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:border-gray-600 dark:hover:text-white dark:hover:bg-gray-700"
                onClick={() => {
                  setIsModalOpen(false);
                  setIsEBIModal(true);
                }}
              >
                {t('accessibility')}
              </button>
            </div>
          </div>
        }
        isOpen={isModalOpen} 
        onClose={() => setIsModalOpen(false)} 
      />
      <Modal 
        title={t('theory')}
        content={
          <div class="max-h-96 overflow-y-auto pr-2">
            <pre class="whitespace-pre-wrap text-sm leading-relaxed text-gray-600 dark:text-gray-300">
              {t('theoryContent')}
            </pre>
          </div>
        }
        isOpen={isTheoryModal} 
        onClose={() => setIsTheoryModal(false)} 
      />
      <Modal 
        title={t('manualConfig')}
        content={
          <div>
            <div class="grid grid-cols-1 gap-4">
              <div>
                <label class="block text-sm font-medium mb-1">Re(c):</label>
                <input
                  type="number"
                  step="0.0000001"
                  min="-8"
                  max="7.999999999"
                  value={centerX().toFixed(8)}
                  onInput={handleCenterXInput}
                  class="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white text-sm focus:border-green-500 focus:outline-none"
                />
                <div class="text-xs text-gray-400 mt-1">
                  Q4.28: {centerX_Q4_28().toString(16)}h
                </div>
              </div>
              
              <div>
                <label class="block text-sm font-medium mb-1">Im(c):</label>
                <input
                  type="number"
                  step="0.0000001"
                  min="-8"
                  max="7.999999999"
                  value={centerY().toFixed(8)}
                  onInput={handleCenterYInput}
                  class="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white text-sm focus:border-green-500 focus:outline-none"
                />
                <div class="text-xs text-gray-400 mt-1">
                  Q4.28: {centerY_Q4_28().toString(16)}h
                </div>
              </div>
            </div>
          </div>
        }
        isOpen={isConfigModal}
        onClose={() => setIsConfigModal(false)}
      />
      <Modal 
        title={t('optimisations')}
        content={t('optimisationsContent')}
        isOpen={isOptiModal}
        onClose={() => setIsOptiModal(false)}
      />
      <Modal 
        title={t('accessibility')}
        content={
          <div>
            <div class="mb-6">
              <h4 class="text-lg font-semibold mb-3 text-gray-900 dark:text-gray-100">Language Settings</h4>
              <select 
                value={currentLanguage()}
                onChange={(e) => setLanguage(e.target.value)}
                class="w-full px-3 py-2 rounded-lg text-sm bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 focus:ring-2 focus:ring-blue-500"
              >
                <option value="en">🇺🇸 English</option>
                <option value="es">🇪🇸 Español</option>
                <option value="zh">🇨🇳 中文</option>
                <option value="ar">🇸🇦 العربية</option>
              </select>
            </div>
            
            <div class="border-t border-gray-200 dark:border-gray-700 pt-4">
              <p class="text-sm text-gray-600 dark:text-gray-300">
                {t('accessibilityContent')}
              </p>
            </div>
          </div>
        }
        isOpen={isEBIModal}
        onClose={() => setIsEBIModal(false)}
      />
    </>
  );
}

export default App;