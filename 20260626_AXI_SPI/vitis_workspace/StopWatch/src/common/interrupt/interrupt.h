/*
 * interrupt.h
 *
 *  Created on: 2026. 6. 26.
 *      Author: kccistc
 */

#ifndef SRC_COMMON_INTERRUPT_INTERRUPT_H_
#define SRC_COMMON_INTERRUPT_INTERRUPT_H_

#include "xparameters.h"
#include "xintc.h"
#include "xil_exception.h"

#define INTC_DEV_ID         XPAR_INTC_0_DEVICE_ID
#define TMR_VEC_ID          XPAR_INTC_0_TIMER_0_VEC_ID
#define UART_VEC_ID         XPAR_INTC_0_UART_0_VEC_ID
#define SPI_MASTER_VEC_ID   XPAR_MICROBLAZE_0_AXI_INTC_SPI_MASTER_0_M_INTR_INTR
#define SPI_SLAVE_VEC_ID    XPAR_MICROBLAZE_0_AXI_INTC_AXI_SPI_SLAVE_0_S_INTR_INTR

void TMR_ISR(void *CallbackRef);
void UART_ISR(void *CallbackRef);
void SPI_MASTER_ISR(void *CallbackRef);
void SPI_SLAVE_ISR(void *CallbackRef);
int SetupInterruptSystem();

#endif /* SRC_COMMON_INTERRUPT_INTERRUPT_H_ */
