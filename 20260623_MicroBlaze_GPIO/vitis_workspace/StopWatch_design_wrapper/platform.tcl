# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct D:\Working\OndeviceAI2\20260623_MicroBlaze_GPIO\vitis_workspace\StopWatch_design_wrapper\platform.tcl
# 
# OR launch xsct and run below command.
# source D:\Working\OndeviceAI2\20260623_MicroBlaze_GPIO\vitis_workspace\StopWatch_design_wrapper\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {StopWatch_design_wrapper}\
-hw {D:\Working\OndeviceAI2\20260623_MicroBlaze_GPIO\XSA\StopWatch_design_wrapper.xsa}\
-fsbl-target {psu_cortexa53_0} -out {D:/Working/OndeviceAI2/20260623_MicroBlaze_GPIO/vitis_workspace}

platform write
domain create -name {standalone_microblaze_0} -display-name {standalone_microblaze_0} -os {standalone} -proc {microblaze_0} -runtime {cpp} -arch {32-bit} -support-app {hello_world}
platform generate -domains 
platform active {StopWatch_design_wrapper}
platform generate -quick
platform generate
platform write
platform active {StopWatch_design_wrapper}
platform config -updatehw {D:/Working/OndeviceAI2/20260623_MicroBlaze_GPIO/StopWatch_design_wrapper.xsa}
platform generate -domains 
platform active {StopWatch_design_wrapper}
platform config -updatehw {D:/Working/OndeviceAI2/20260623_MicroBlaze_GPIO/XSA/StopWatch_design_wrapper.xsa}
platform generate -domains 
