# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: D:\Working\OndeviceAI2\20260626_MicroBlaze_Timer_UART_Intr\vitis_workspace\StopWatch_system\_ide\scripts\debugger_stopwatch-default.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source D:\Working\OndeviceAI2\20260626_MicroBlaze_Timer_UART_Intr\vitis_workspace\StopWatch_system\_ide\scripts\debugger_stopwatch-default.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -filter {jtag_cable_name =~ "Digilent Basys3 210183BEA2BEA" && level==0 && jtag_device_ctx=="jsn-Basys3-210183BEA2BEA-0362d093-0"}
fpga -file D:/Working/OndeviceAI2/20260626_MicroBlaze_Timer_UART_Intr/vitis_workspace/StopWatch/_ide/bitstream/design_1_wrapper.bit
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
loadhw -hw D:/Working/OndeviceAI2/20260626_MicroBlaze_Timer_UART_Intr/vitis_workspace/design_1_wrapper/export/design_1_wrapper/hw/design_1_wrapper.xsa -regs
configparams mdm-detect-bscan-mask 2
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
rst -system
after 3000
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
dow D:/Working/OndeviceAI2/20260626_MicroBlaze_Timer_UART_Intr/vitis_workspace/StopWatch/Debug/StopWatch.elf
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
con
