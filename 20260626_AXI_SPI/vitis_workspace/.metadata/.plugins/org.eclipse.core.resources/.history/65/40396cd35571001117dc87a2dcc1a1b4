/*
 * SPI.c
 *
 *  Created on: 2026. 6. 26.
 *      Author: kccistc
 */

#include "SPI.h"

void SPI_Init(void)
{
    // CPOL=0, CPHA=0, clk_div=49
    SPI_MASTER->CR = (SPI_CLK_DIV << 8) | 0x00;
    // Slave는 항상 'a' 응답 준비
    SPI_SLAVE->TDR = 'a';
}

void SPI_Transmit(uint8_t data)
{
    SPI_SLAVE->TDR = 'a';                           // Slave 응답 항상 'a'
    SPI_MASTER->TDR = data;                          // 보낼 데이터 세팅
    SPI_MASTER->CR = (SPI_CLK_DIV << 8) | 0x01;    // start 펄스
    while (!(SPI_MASTER->SR & SPI_SR_DONE));         // done 대기
}

uint8_t SPI_MasterReceive(void)
{
    return (uint8_t)(SPI_MASTER->RDR & 0xFF);
}

uint8_t SPI_SlaveReceive(void)
{
    return (uint8_t)(SPI_SLAVE->RDR & 0xFF);
}
