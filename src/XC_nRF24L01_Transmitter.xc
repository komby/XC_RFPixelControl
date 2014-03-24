/*
 * XC_nRF24L01_Transmitter.xc
 *
 *  Created on: Feb 27, 2014
 *      Author: Greg
 */
#include <platform.h>
#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include <string.h>

#include <spi_master.h>
#include "XC_nRF24L01.h"


const char pipes[2][5] = { { 0xE1, 0xF0, 0xF0, 0xF0, 0xF0 }, { 0xD2, 0xF0,
        0xF0, 0xF0, 0xF0 } };


#define RF_DELAY 1500


/**
 * First define the Master SPI,  this is the spi used to talk to the transciever
 */
spi_master_interface spi_mif = {
        XS1_CLKBLK_1,
        XS1_CLKBLK_2,
        XS1_PORT_1F,//mosi out buffered port
        XS1_PORT_1G,//clock out buffered port
        XS1_PORT_1H //miso  in buffered port
        };

/**
 * Next define the nRFTransceiver.
 * Note CE and CSN are set here
 * Not using IRQ it is left disconnected ATM
 *
 */
xc_nRF24L01 nrf1 = {
     //   spi_mif,  //software spi
        XS1_PORT_1J,  //CE
        XS1_PORT_1K, //CSN
        80, //channel
        RF24_250KBPS,
        { 0xE1, 0xF0, 0xF0, 0xF0, 0xF0 }, //TX Pipe
        { 0xD2, 0xF0, 0xF0, 0xF0, 0xF0 }, //RX Pipe
        0,  //wideband
        {0,0,0,0,0}   //backup pipe addr
};


//TODO Move ShowUpdate to RF library?
/**
 *
 */
void rfPixelControlShowUpdate(char pChannelBuffer[], int pNumberOfChannels){
    char status = 0;
    char packet[32];
    int numChannelsOfColor =  pNumberOfChannels * 3;
        for(int ii=0, kk=0,jj=0;ii< numChannelsOfColor && kk<32 ;ii++)
        {
            packet[kk++] = pChannelBuffer[ii];//set the byte color
            if (kk == 30 || ii == (numChannelsOfColor -1) )
            {
                packet[kk] = jj++;
                kk=0;
                nrfWritePayload( nrf1, spi_mif,  packet, 32 );
                nrfDelayMicroseconds(RF_DELAY);
                status = nrfGetStatus(nrf1, spi_mif);

                while (status & 0x01)
                {
                    status = nrfGetStatus(nrf1, spi_mif);
                }
            }
        }
}



/**
 * Helper functions for the color wheel.  This was used from Adafruit's
 * WS2801 library.
 */
//Input a value 0 to 255 to get a color value.
//The colours are a transition r - g -b - back to r
{int, int, int} Wheel(char WheelPos)
{
    if (WheelPos < 85)
    {
        return {WheelPos * 3,  255 - WheelPos * 3, 0};
    }
    else if (WheelPos < 170)
    {
        WheelPos -= 85;
        return {255 - WheelPos * 3, 0, WheelPos * 3};
    }
    else
    {
        WheelPos -= 170;
        return {0, WheelPos * 3, 255 - WheelPos * 3};
    }
}

/**
 * Helper functions for the color wheel.  This was used from Adafruit's
 * WS2801 library.
 */
void rainbow( int pNum, char pChannelBuffer[] ){
    int i, j;

    for (j=0; j < 256; j++)     // 3 cycles of all 256 colors in the wheel
    {
        for (i=0; i < pNum; i++)
        {
            { pChannelBuffer[i * 3],  pChannelBuffer[i * 3 + 1],  pChannelBuffer[i * 3 + 2]} = Wheel( ((i * 256 / pNum) + j) % 256);
        }
        rfPixelControlShowUpdate(pChannelBuffer, pNum);
    }
}



/**
 * run_master is called from main in a par block.
 * this function is outputting 170 channels of data as a rainbow.
 *
 * Protocol used is the RFPixelControl packet format
 */
void run_master() {
    char channelsBuffer[512];
    spi_master_init(spi_mif, SPI_CLOCK_DIV);

    nrfBegin(nrf1, spi_mif);
    nrfPrintDetails(nrf1, spi_mif);

        while(1){
            rainbow(170, channelsBuffer);

        }
    spi_master_shutdown(spi_mif);
}


//Example main running a demo of the test RF Transmitter
int main(void) {
    printstr("Running in SPI mode ");
    printintln(SPI_MODE);

    printstr("with SPI frequency ");
    printint((100 / (2 * SPI_CLOCK_DIV)));
    printstrln("MHz");

    printstr("for ");
    //    printint(DEMO_RUNS);
    printstrln(" demo runs");

    // Run SPI master and slave on seperate logical cores
    par
    {
        run_master();
    }

    return 0;
}
