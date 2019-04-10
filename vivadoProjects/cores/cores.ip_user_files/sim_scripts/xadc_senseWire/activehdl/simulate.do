onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+xadc_senseWire -L xil_defaultlib -L xpm -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.xadc_senseWire xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {xadc_senseWire.udo}

run -all

endsim

quit -force
