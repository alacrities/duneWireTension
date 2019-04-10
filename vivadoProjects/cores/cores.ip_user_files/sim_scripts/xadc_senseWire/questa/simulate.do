onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib xadc_senseWire_opt

do {wave.do}

view wave
view structure
view signals

do {xadc_senseWire.udo}

run -all

quit -force
