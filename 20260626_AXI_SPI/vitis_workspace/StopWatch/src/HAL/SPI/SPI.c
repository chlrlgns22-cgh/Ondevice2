/*
 * SPI.c
 *
 *  Created on: 2026. 6. 26.
 *      Author: kccistc
 */

#include "SPI.h"

extern uint32_t spiLedState;  // StopWatch.c 에서 관리

void SPI_Init(void)
{
    SPI_MASTER->CR = (SPI_CLK_DIV << 8) | 0x00;
    SPI_SLAVE->TDR = 'a';
}

void SPI_Transmit(uint8_t data)
{
    SPI_SLAVE->TDR = 'a';
    SPI_MASTER->TDR = data;
    SPI_MASTER->CR = (SPI_CLK_DIV << 8) | 0x01;  // start
    while (SPI_MASTER->SR & SPI_SR_BUSY);          // busy 대기

    // 전송 완료 후 처리
    uint8_t slave_resp = SPI_MasterReceive();
    if (slave_resp == 'a') {
        spiLedState ^= (1 << 2);  // LED10 = GPIOD bit2 토글
    }

    extern uint8_t rx_data;
    uint8_t slave_rx = SPI_SlaveReceive();
    if (slave_rx != 0) {
        rx_data = slave_rx;
    }
}

uint8_t SPI_MasterReceive(void)
{
    return (uint8_t)(SPI_MASTER->RDR & 0xFF);
}

uint8_t SPI_SlaveReceive(void)
{
    return (uint8_t)(SPI_SLAVE->RDR & 0xFF);
}
