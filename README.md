# Raspberry Pi LED control

Control LEDs (power, activity, ethernet, etc.) on Raspberry Pi

## Dev notes

gpioinfo output shows the raw GPIOs used for RPi LEDs that are
consumed/used

```
gpiochip0 - 58 lines:
	line   0:     "ID_SDA"       unused   input  active-high 
	line   1:     "ID_SCL"       unused   input  active-high 
	line   2:       "SDA1"       unused   input  active-high 
	line   3:       "SCL1"       unused   input  active-high 
	line   4:  "GPIO_GCLK"       unused   input  active-high 
	line   5:      "GPIO5"       unused   input  active-high 
	line   6:      "GPIO6"       unused   input  active-high 
	line   7:  "SPI_CE1_N"       unused   input  active-high 
	line   8:  "SPI_CE0_N"       unused   input  active-high 
	line   9:   "SPI_MISO"       unused   input  active-high 
	line  10:   "SPI_MOSI"       unused   input  active-high 
	line  11:   "SPI_SCLK"       unused   input  active-high 
	line  12:     "GPIO12"       unused   input  active-high 
	line  13:     "GPIO13"       unused   input  active-high 
	line  14:       "TXD1"       unused   input  active-high 
	line  15:       "RXD1"       unused   input  active-high 
	line  16:     "GPIO16"       unused   input  active-high 
	line  17:     "GPIO17"       unused   input  active-high 
	line  18:     "GPIO18"       unused   input  active-high 
	line  19:     "GPIO19"       unused   input  active-high 
	line  20:     "GPIO20"       unused   input  active-high 
	line  21:     "GPIO21"       unused   input  active-high 
	line  22:     "GPIO22"       unused   input  active-high 
	line  23:     "GPIO23"       unused   input  active-high 
	line  24:     "GPIO24"       unused   input  active-high 
	line  25:     "GPIO25"       unused   input  active-high 
	line  26:     "GPIO26"       unused   input  active-high 
	line  27:     "GPIO27"       unused   input  active-high 
	line  28: "RGMII_MDIO"       unused   input  active-high 
	line  29:  "RGMIO_MDC"       unused   input  active-high 
	line  30:       "CTS0"       unused   input  active-high 
	line  31:       "RTS0"       unused   input  active-high 
	line  32:       "TXD0"       unused   input  active-high 
	line  33:       "RXD0"       unused   input  active-high 
	line  34:    "SD1_CLK"       unused   input  active-high 
	line  35:    "SD1_CMD"       unused   input  active-high 
	line  36:  "SD1_DATA0"       unused   input  active-high 
	line  37:  "SD1_DATA1"       unused   input  active-high 
	line  38:  "SD1_DATA2"       unused   input  active-high 
	line  39:  "SD1_DATA3"       unused   input  active-high 
	line  40:  "PWM0_MISO"       unused   input  active-high 
	line  41:  "PWM1_MOSI"       unused   input  active-high 
	line  42: "STATUS_LED_G_CLK" "ACT" output active-high [used]
	line  43: "SPIFLASH_CE_N" unused input active-high 
	line  44:       "SDA0"       unused   input  active-high 
	line  45:       "SCL0"       unused   input  active-high 
	line  46: "RGMII_RXCLK" unused input active-high 
	line  47: "RGMII_RXCTL" unused input active-high 
	line  48: "RGMII_RXD0"       unused   input  active-high 
	line  49: "RGMII_RXD1"       unused   input  active-high 
	line  50: "RGMII_RXD2"       unused   input  active-high 
	line  51: "RGMII_RXD3"       unused   input  active-high 
	line  52: "RGMII_TXCLK" unused input active-high 
	line  53: "RGMII_TXCTL" unused input active-high 
	line  54: "RGMII_TXD0"       unused   input  active-high 
	line  55: "RGMII_TXD1"       unused   input  active-high 
	line  56: "RGMII_TXD2"       unused   input  active-high 
	line  57: "RGMII_TXD3"       unused   input  active-high 
gpiochip1 - 8 lines:
	line   0:      "BT_ON"       unused  output  active-high 
	line   1:      "WL_ON"       unused  output  active-high 
	line   2: "PWR_LED_OFF" "PWR" output active-low [used]
	line   3: "GLOBAL_RESET" unused output active-high 
	line   4: "VDD_SD_IO_SEL" "vdd-sd-io" output active-high [used]
	line   5:   "CAM_GPIO" "cam1_regulator" output active-high [used]
	line   6:  "SD_PWR_ON" "sd_vcc_reg"  output  active-high [used]
	line   7:    "SD_OC_N"       unused   input  active-high 
gpiochip2 - 4 lines:
	line   0:      unnamed       unused   input  active-high 
	line   1:      unnamed       unused   input  active-high 
	line   2:      unnamed       unused  output  active-high 
	line   3:      unnamed       unused   input  active-high 
```
