/*
 * SPI.h
 *
 *  Created on: 2026. 6. 26.
 *      Author: kccistc
 */

#ifndef SRC_HAL_SPI_SPI_H_
#define SRC_HAL_SPI_SPI_H_

#include "xparameters.h"
#include <stdint.h>

typedef struct {
    uint32_t CR;   // [0]=start [1]=cpol [2]=cpha [15:8]=clk_div
    uint32_t TDR;  // 보낼 데이터
    uint32_t RDR;  // 받은 데이터
    uint32_t SR;   // [0]=busy [1]=done
} SPI_TypeDef_t;

#define SPI_MASTER_BASEADDR  XPAR_SPI_MASTER_0_S00_AXI_BASEADDR
#define SPI_SLAVE_BASEADDR   XPAR_AXI_SPI_SLAVE_0_S00_AXI_BASEADDR
#define SPI_MASTER           ((SPI_TypeDef_t *)SPI_MASTER_BASEADDR)
#define SPI_SLAVE            ((SPI_TypeDef_t *)SPI_SLAVE_BASEADDR)

#define SPI_SR_BUSY  (1 << 0)
#define SPI_SR_DONE  (1 << 1)

// clk_div=49 → 100MHz/50 = 2MHz SCLK
#define SPI_CLK_DIV  49

void SPI_Init(void);
void SPI_Transmit(uint8_t data);
uint8_t SPI_MasterReceive(void);
uint8_t SPI_SlaveReceive(void);

#endif /* SRC_HAL_SPI_SPI_H_ */
