import { createSignal } from 'solid-js';
import Button from './Button.jsx'

const regions = {
  seahorse: {
    centerX: -0.74,
    centerY: 0.13,
    zoom: 7
  },
  spiralArms: {
    centerX: -0.15,
    centerY: 0.85,
    zoom: 5
  },
  minibrot: {
    centerX: -0.235125,
    centerY: 0.827215,
    zoom: 10
  },
  scepter: {
    centerX: -1.25,
    centerY: 0.02,
    zoom: 8
  },
  tripleSpiral: {
    centerX: -0.11,
    centerY: 0.75,
    zoom: 6
  }
};

export default function RegionCascade(props) { 
  const [isHovered, setIsHovered] = createSignal(false);

  const handleMouseEnter = () => {
    if (!props.showNumbers) {
      setIsHovered(true);
    }
  };

  const handleMouseLeave = () => {
    if (!props.showNumbers) {
      setIsHovered(false);
    }
  };

  const regionChange = (regionKey) => {
    const location = regions[regionKey];
    props.onJump(location);
  }; 

  const handleClick = () => { 
    if (props.showNumbers && props.onPlusOne) {  
       props.onPlusOne();
    } else {
      setIsHovered(!isHovered());
    }
  };

  return (

    <div 
      class="flex flex-row gap-1"
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
    >
      <Button onClick={handleClick} isDarkMode={props.isDarkMode}>
        {props.showNumbers ? "+1" : (
          <svg width="20" height="20" data-slot="icon" aria-hidden="true" fill="none" stroke-width="1.5" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" stroke-linecap="round" stroke-linejoin="round"></path>
            <path d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1 1 15 0Z" stroke-linecap="round" stroke-linejoin="round"></path>
          </svg>
        )}
      </Button>
      
      <div 
        class="flex flex-row gap-2 overflow-hidden transition-all duration-500 ease-in-out origin-left"
        style={{
          "opacity": (isHovered()) ? "1" : "0",
          "transform": (isHovered()) ? "scaleX(1)" : "scaleX(0)",
          "max-width": (isHovered()) ? "500px" : "0px",
          "margin-left": (isHovered()) ? "4px" : "0px"
        }}
      >
        <Button 
          onClick={() => regionChange('minibrot')}
          isDarkMode={props.isDarkMode}  // ← Change all isDarkMode
          title="Mini Mandelbrot (-0.235, 0.827)"
        >
          <svg width="20" height="20" data-slot="icon" aria-hidden="true" fill="none" stroke-width="1.5" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M12 18v-5.25m0 0a6.01 6.01 0 0 0 1.5-.189m-1.5.189a6.01 6.01 0 0 1-1.5-.189m3.75 7.478a12.06 12.06 0 0 1-4.5 0m3.75 2.383a14.406 14.406 0 0 1-3 0M14.25 18v-.192c0-.983.658-1.823 1.508-2.316a7.5 7.5 0 1 0-7.517 0c.85.493 1.509 1.333 1.509 2.316V18" stroke-linecap="round" stroke-linejoin="round"></path>
          </svg>
        </Button>

        <Button 
          onClick={() => regionChange('seahorse')}
          isDarkMode={props.isDarkMode}
          title="Seahorse Valley (-0.74, 0.13)"
        >
          🌊
        </Button>

        <Button 
          onClick={() => regionChange('spiralArms')}
          isDarkMode={props.isDarkMode}
          title="Spiral Arms (-0.15, 0.85)"
        >
          <svg width="20" height="20" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M10 12.057a1.9 1.9 0 0 0 .614 .743c1.06 .713 2.472 .112 3.043 -.919c.839 -1.513 -.022 -3.368 -1.525 -4.08c-2 -.95 -4.371 .154 -5.24 2.086c-1.095 2.432 .29 5.248 2.71 6.246c2.931 1.208 6.283 -.418 7.438 -3.255c1.36 -3.343 -.557 -7.134 -3.896 -8.41c-3.855 -1.474 -8.2 .68 -9.636 4.422c-1.63 4.253 .823 9.024 5.082 10.576c4.778 1.74 10.118 -.941 11.833 -5.59a9.354 9.354 0 0 0 .577 -2.813" />
          </svg>
        </Button>

        <Button 
          onClick={() => regionChange('scepter')}
          isDarkMode={props.isDarkMode}
          title="Scepter (-1.25, 0.02)"
        >
          👑
        </Button>

        <Button 
          onClick={() => regionChange('tripleSpiral')}
          isDarkMode={props.isDarkMode}
          title="Triple Spiral (-0.11, 0.75)"
        >
          🌪️
        </Button>
      </div>
    </div>
  );
}