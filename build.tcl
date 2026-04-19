set_device GW2AR-LV18QN88C8/I7 -name GW2AR-18C

# CPU
add_file src/T65_Pack.vhd
add_file src/T65_ALU.vhd
add_file src/T65_MCode.vhd
add_file src/T65.vhd

# Minne (Verilog — Gowin infererar SPB/DPB korrekt)
add_file src/prog_ram.v
add_file src/disp_ram.v

# ROM (VHDL, kombinatorisk eller synkron)
add_file src/BasicRom.vhd
add_file src/CegmonRom.vhd
add_file src/CharRom.vhd

# Tangentbord och I/O
add_file src/ps2_intf.vhd
add_file src/UK101keyboard.vhd
add_file src/bufferedUART.vhd

# HDMI
add_file src/tmds_encoder.v
add_file src/hdmi_tx.v

# UK101-specifikt
add_file src/pll.v
add_file src/video.v
add_file src/uk101_top.v

add_file uk101.cst

set_option -synthesis_tool gowinsynthesis
set_option -output_base_name uk101
set_option -top_module uk101_top
set_option -verilog_std sysv2017
set_option -use_mspi_as_gpio 1
set_option -use_sspi_as_gpio 1

run all
