import React from 'react';
import './GpioPinDiagram.css';

interface GpioPinDiagramProps {
  gpioPins: number[];
  sensors?: string[];
}

interface PinInfo {
  physical: number;
  bcm?: number;
  name: string;
  function: string;
  type: 'power' | 'ground' | 'gpio' | 'special';
}

// Complete 40-pin GPIO header mapping
const PIN_LAYOUT: PinInfo[] = [
  { physical: 1, name: '3.3V', function: '3.3V Power', type: 'power' },
  { physical: 2, name: '5V', function: '5V Power', type: 'power' },
  { physical: 3, bcm: 2, name: 'GPIO2', function: 'SDA1 (I2C)', type: 'special' },
  { physical: 4, name: '5V', function: '5V Power', type: 'power' },
  { physical: 5, bcm: 3, name: 'GPIO3', function: 'SCL1 (I2C)', type: 'special' },
  { physical: 6, name: 'GND', function: 'Ground', type: 'ground' },
  { physical: 7, bcm: 4, name: 'GPIO4', function: 'GPCLK0', type: 'gpio' },
  { physical: 8, bcm: 14, name: 'GPIO14', function: 'TXD0 (UART)', type: 'special' },
  { physical: 9, name: 'GND', function: 'Ground', type: 'ground' },
  { physical: 10, bcm: 15, name: 'GPIO15', function: 'RXD0 (UART)', type: 'special' },
  { physical: 11, bcm: 17, name: 'GPIO17', function: 'General Purpose', type: 'gpio' },
  { physical: 12, bcm: 18, name: 'GPIO18', function: 'PCM_CLK / PWM0', type: 'special' },
  { physical: 13, bcm: 27, name: 'GPIO27', function: 'General Purpose', type: 'gpio' },
  { physical: 14, name: 'GND', function: 'Ground', type: 'ground' },
  { physical: 15, bcm: 22, name: 'GPIO22', function: 'General Purpose', type: 'gpio' },
  { physical: 16, bcm: 23, name: 'GPIO23', function: 'General Purpose', type: 'gpio' },
  { physical: 17, name: '3.3V', function: '3.3V Power', type: 'power' },
  { physical: 18, bcm: 24, name: 'GPIO24', function: 'General Purpose', type: 'gpio' },
  { physical: 19, bcm: 10, name: 'GPIO10', function: 'MOSI (SPI)', type: 'special' },
  { physical: 20, name: 'GND', function: 'Ground', type: 'ground' },
  { physical: 21, bcm: 9, name: 'GPIO9', function: 'MISO (SPI)', type: 'special' },
  { physical: 22, bcm: 25, name: 'GPIO25', function: 'General Purpose', type: 'gpio' },
  { physical: 23, bcm: 11, name: 'GPIO11', function: 'SCLK (SPI)', type: 'special' },
  { physical: 24, bcm: 8, name: 'GPIO8', function: 'CE0 (SPI)', type: 'special' },
  { physical: 25, name: 'GND', function: 'Ground', type: 'ground' },
  { physical: 26, bcm: 7, name: 'GPIO7', function: 'CE1 (SPI)', type: 'special' },
  { physical: 27, bcm: 0, name: 'GPIO0', function: 'ID_SD (EEPROM)', type: 'special' },
  { physical: 28, bcm: 1, name: 'GPIO1', function: 'ID_SC (EEPROM)', type: 'special' },
  { physical: 29, bcm: 5, name: 'GPIO5', function: 'General Purpose', type: 'gpio' },
  { physical: 30, name: 'GND', function: 'Ground', type: 'ground' },
  { physical: 31, bcm: 6, name: 'GPIO6', function: 'General Purpose', type: 'gpio' },
  { physical: 32, bcm: 12, name: 'GPIO12', function: 'PWM0', type: 'special' },
  { physical: 33, bcm: 13, name: 'GPIO13', function: 'PWM1', type: 'special' },
  { physical: 34, name: 'GND', function: 'Ground', type: 'ground' },
  { physical: 35, bcm: 19, name: 'GPIO19', function: 'PCM_FS / PWM1', type: 'special' },
  { physical: 36, bcm: 16, name: 'GPIO16', function: 'General Purpose', type: 'gpio' },
  { physical: 37, bcm: 26, name: 'GPIO26', function: 'General Purpose', type: 'gpio' },
  { physical: 38, bcm: 20, name: 'GPIO20', function: 'PCM_DIN', type: 'special' },
  { physical: 39, name: 'GND', function: 'Ground', type: 'ground' },
  { physical: 40, bcm: 21, name: 'GPIO21', function: 'PCM_DOUT', type: 'special' },
];

export const GpioPinDiagram: React.FC<GpioPinDiagramProps> = ({ gpioPins, sensors = [] }) => {
  // Check if a pin is being used by the module
  const isPinUsed = (pin: PinInfo): boolean => {
    return pin.bcm !== undefined && gpioPins.includes(pin.bcm);
  };

  // Get the sensor for a specific GPIO pin
  const getSensorForPin = (bcm: number | undefined): string | null => {
    if (bcm === undefined || !gpioPins.includes(bcm)) return null;
    
    // If we have sensors and the number matches, associate them
    const pinIndex = gpioPins.indexOf(bcm);
    if (sensors && sensors.length > pinIndex) {
      return sensors[pinIndex];
    }
    
    return null;
  };

  // Get CSS class for pin based on its state and type
  const getPinClass = (pin: PinInfo): string => {
    const baseClass = 'gpio-pin';
    const typeClass = `gpio-pin--${pin.type}`;
    const usedClass = isPinUsed(pin) ? 'gpio-pin--used' : '';
    
    return `${baseClass} ${typeClass} ${usedClass}`.trim();
  };

  // Split pins into left and right columns (odd/even physical numbers)
  const leftPins = PIN_LAYOUT.filter(pin => pin.physical % 2 === 1);
  const rightPins = PIN_LAYOUT.filter(pin => pin.physical % 2 === 0);

  return (
    <div className="gpio-diagram">
      <div className="gpio-diagram__header">
        <h3 className="gpio-diagram__title">Raspberry Pi GPIO Pinout</h3>
        <div className="gpio-diagram__legend">
          <span className="gpio-diagram__legend-item">
            <span className="gpio-diagram__legend-color gpio-diagram__legend-color--used"></span>
            Used by Module
          </span>
          <span className="gpio-diagram__legend-item">
            <span className="gpio-diagram__legend-color gpio-diagram__legend-color--power"></span>
            Power
          </span>
          <span className="gpio-diagram__legend-item">
            <span className="gpio-diagram__legend-color gpio-diagram__legend-color--ground"></span>
            Ground
          </span>
          <span className="gpio-diagram__legend-item">
            <span className="gpio-diagram__legend-color gpio-diagram__legend-color--gpio"></span>
            GPIO
          </span>
        </div>
      </div>

      <div className="gpio-diagram__board">
        <div className="gpio-diagram__column gpio-diagram__column--left">
          {leftPins.map((pin) => {
            const sensor = pin.bcm !== undefined ? getSensorForPin(pin.bcm) : null;
            const isUsed = isPinUsed(pin);
            
            return (
              <div
                key={pin.physical}
                className={getPinClass(pin)}
                title={`Pin ${pin.physical}: ${pin.name} - ${pin.function}${sensor ? `\n→ ${sensor}` : ''}`}
              >
                <span className="gpio-pin__number">{pin.physical}</span>
                <span className="gpio-pin__name">{pin.name}</span>
                {isUsed && sensor && (
                  <span className="gpio-pin__sensor">→ {sensor}</span>
                )}
              </div>
            );
          })}
        </div>

        <div className="gpio-diagram__column gpio-diagram__column--right">
          {rightPins.map((pin) => {
            const sensor = pin.bcm !== undefined ? getSensorForPin(pin.bcm) : null;
            const isUsed = isPinUsed(pin);
            
            return (
              <div
                key={pin.physical}
                className={getPinClass(pin)}
                title={`Pin ${pin.physical}: ${pin.name} - ${pin.function}${sensor ? `\n→ ${sensor}` : ''}`}
              >
                <span className="gpio-pin__name">{pin.name}</span>
                <span className="gpio-pin__number">{pin.physical}</span>
                {isUsed && sensor && (
                  <span className="gpio-pin__sensor">{sensor} ←</span>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Show summary of used pins */}
      <div className="gpio-diagram__summary">
        <h4>Pin Connections:</h4>
        {gpioPins.map((bcmPin, index) => {
          const pinInfo = PIN_LAYOUT.find(p => p.bcm === bcmPin);
          const sensor = sensors && sensors.length > index ? sensors[index] : null;
          
          if (!pinInfo) return null;
          
          return (
            <div key={bcmPin} className="gpio-diagram__connection">
              <span className="gpio-diagram__connection-pin">
                Pin {pinInfo.physical} (GPIO{bcmPin})
              </span>
              {sensor && (
                <span className="gpio-diagram__connection-sensor">
                  → {sensor}
                </span>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
};
