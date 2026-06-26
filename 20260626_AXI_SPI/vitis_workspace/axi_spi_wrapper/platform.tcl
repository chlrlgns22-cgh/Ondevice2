# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct D:\Working\OndeviceAI2\20260626_AXI_SPI\vitis_workspace\axi_spi_wrapper\platform.tcl
# 
# OR launch xsct and run below command.
# source D:\Working\OndeviceAI2\20260626_AXI_SPI\vitis_workspace\axi_spi_wrapper\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {axi_spi_wrapper}\
-hw {D:\Working\OndeviceAI2\20260626_AXI_SPI\XSA\axi_spi_wrapper.xsa}\
-fsbl-target {psu_cortexa53_0} -out {D:/Working/OndeviceAI2/20260626_AXI_SPI/vitis_workspace}

platform write
domain create -name {standalone_microblaze_0} -display-name {standalone_microblaze_0} -os {standalone} -proc {microblaze_0} -runtime {cpp} -arch {32-bit} -support-app {empty_application}
platform generate -domains 
platform active {axi_spi_wrapper}
platform generate -quick
platform generate
platform config -updatehw {D:/Working/OndeviceAI2/20260626_AXI_SPI/XSA/axi_spi_wrapper.xsa}
platform config -updatehw {D:/Working/OndeviceAI2/20260626_AXI_SPI/XSA/axi_spi_wrapper.xsa}
platform generate -domains 
platform config -updatehw {D:/Working/OndeviceAI2/20260626_AXI_SPI/XSA/axi_spi_wrapper.xsa}
platform config -updatehw {D:/Working/OndeviceAI2/20260626_AXI_SPI/XSA/axi_spi_wrapper.xsa}
platform generate -domains 
