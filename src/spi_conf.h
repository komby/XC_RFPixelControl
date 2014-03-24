#define DEFAULT_SPI_CLOCK_DIV 50 // docs say a div of 50 produces a 1MHz clock

#define SPI_CLOCK_DIV 6.25 // Set the clock div to 50 ( 100 / 2* SPI_CLOCK_DIV)

//#define SPI_MODE 3
//nrf library was using mode 0
#define SPI_MODE 0
// Ensure that master and slave always operate in the same mode
#define SPI_MASTER_MODE SPI_MODE
//#define SPI_SLAVE_MODE SPI_MODE
