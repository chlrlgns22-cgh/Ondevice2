/*
 * delay.h
 *
 *  Created on: 2026. 6. 24.
 *      Author: kccistc
 */
#include "sleep.h"
#include "stdint.h"

#ifndef SRC_COMMON_DELAY_DELAY_H_
#define SRC_COMMON_DELAY_DELAY_H_

uint32_t millis();
void incTick();
void delay_sec(uint32_t seconds);
void delay_ms(uint32_t mseconds);
void delay_us(uint32_t usec);

#endif /* SRC_COMMON_DELAY_DELAY_H_ */
