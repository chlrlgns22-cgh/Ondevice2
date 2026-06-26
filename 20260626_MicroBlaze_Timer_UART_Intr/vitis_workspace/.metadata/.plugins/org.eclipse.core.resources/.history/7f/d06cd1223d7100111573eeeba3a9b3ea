/*
 * StopWatch.h
 *
 *  Created on: 2026. 6. 24.
 *      Author: kccistc
 */

#ifndef SRC_AP_STOPWATCH_H_
#define SRC_AP_STOPWATCH_H_

#include "../driver/Button/Button.h"
#include "../driver/FND/FND.h"
#include "../driver/LED/LED.h"
#include "../common/delay/delay.h"

#define STOP_STATE_LED 5
#define RUN_STATE_LED 7

typedef struct {
	uint8_t hour;
	uint8_t min;
	uint8_t sec;
	uint8_t ms;
} stopWatch_t;

typedef enum {
	STOP = 0, RUN, CLEAR
} stopWatch_e;

void StopWatch_Init();
void StopWatch_Excute();
void StopWatch_DispWatch();
void StopWatch_ControlState();
void StopWatch_ClearTime();
void StopWatch_IncTime();
void StopWatch_RunTime();
void StopWatch_ControlLed();
void StopWatch_RunLed();
void StopWatch_StopLed();
void StopWatch_ClearLed();


#endif /* SRC_AP_STOPWATCH_H_ */
