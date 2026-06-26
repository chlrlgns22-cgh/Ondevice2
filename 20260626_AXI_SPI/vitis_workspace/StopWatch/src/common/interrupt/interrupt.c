/*
 * interrupt.c
 *
 *  Created on: 2026. 6. 26.
 *      Author: kccistc
 */

#include "interrupt.h"
#include "../delay/delay.h"
#include "../../driver/FND/FND.h"
#include "../../driver/LED/LED.h"
#include "../../HAL/UART/UART.h"
#include "../../HAL/SPI/SPI.h"

XIntc IntrController;

extern uint8_t rx_data;

void TMR_ISR(void *CallbackRef)
{
    FND_Excute();
    incTick();
}

void UART_ISR(void *CallbackRef)
{
    rx_data = UART_Receive(UART0);
}

void SPI_MASTER_ISR(void *CallbackRef)
{
    /* Slave가 MISO로 보낸 'a' 수신 → LED[10] 토글 */
    uint8_t slave_resp = SPI_MasterReceive();
    if (slave_resp == 'a') {
        LED_PinToggle(10);
    }
    /* SR 읽어서 done_latch 클리어 */
    volatile uint32_t sr = SPI_MASTER->SR;
    (void)sr;
}

void SPI_SLAVE_ISR(void *CallbackRef)
{
    /* Master가 MOSI로 보낸 명령 수신 → rx_data 반영 */
    uint8_t master_cmd = SPI_SlaveReceive();
    if (master_cmd != 0) {
        rx_data = master_cmd;
    }
}

int SetupInterruptSystem()
{
    int status;

    status = XIntc_Initialize(&IntrController, INTC_DEV_ID);
    if (status != XST_SUCCESS) return XST_FAILURE;

    status = XIntc_Connect(&IntrController, TMR_VEC_ID,
                           (XInterruptHandler)TMR_ISR, (void *)0);
    if (status != XST_SUCCESS) return XST_FAILURE;

    status = XIntc_Connect(&IntrController, UART_VEC_ID,
                           (XInterruptHandler)UART_ISR, (void *)0);
    if (status != XST_SUCCESS) return XST_FAILURE;

    status = XIntc_Connect(&IntrController, SPI_MASTER_VEC_ID,
                           (XInterruptHandler)SPI_MASTER_ISR, (void *)0);
    if (status != XST_SUCCESS) return XST_FAILURE;

    status = XIntc_Connect(&IntrController, SPI_SLAVE_VEC_ID,
                           (XInterruptHandler)SPI_SLAVE_ISR, (void *)0);
    if (status != XST_SUCCESS) return XST_FAILURE;

    status = XIntc_Start(&IntrController, XIN_REAL_MODE);
    if (status != XST_SUCCESS) return XST_FAILURE;

    XIntc_Enable(&IntrController, TMR_VEC_ID);
    XIntc_Enable(&IntrController, UART_VEC_ID);
    XIntc_Enable(&IntrController, SPI_MASTER_VEC_ID);
    XIntc_Enable(&IntrController, SPI_SLAVE_VEC_ID);

    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
                                 (Xil_ExceptionHandler)XIntc_InterruptHandler,
                                 &IntrController);
    Xil_ExceptionEnable();

    return XST_SUCCESS;
}
