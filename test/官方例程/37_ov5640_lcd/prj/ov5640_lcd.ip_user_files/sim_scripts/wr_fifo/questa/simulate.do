onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib wr_fifo_opt

do {wave.do}

view wave
view structure
view signals

do {wr_fifo.udo}

run -all

quit -force
