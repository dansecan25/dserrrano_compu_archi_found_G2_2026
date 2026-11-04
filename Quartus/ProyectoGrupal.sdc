# ProyectoGrupal.sdc - DE10-Nano / Cyclone V
# Restricciones válidas para el TOP.

# Reloj FPGA principal: 50 MHz
create_clock -name CLK_50 -period 20.000 [get_ports {CLK_50}]

# Reloj interno del PWM: 50 MHz / (2 * 1563) = 15.995 kHz
# Periodo = 62520 ns, dentro del rango de Timing Analyzer.
create_generated_clock \
    -name clk_pwm \
    -source [get_ports {CLK_50}] \
    -divide_by 3126 \
    [get_registers {clock_divider:u_pwm_clk|d_flipflop:u_out|Q}]

# clk_test: 50 MHz / (2 * 75_000_000) = 1/3 Hz.
# Periodo real = 3_000_000_000 ns.
# Quartus Timing Analyzer 25.1 admite como maximo 2_147_483.647 ns
# para el periodo de reloj: NO se puede declarar su periodo real.
# No usar -divide_by 150000000: Quartus ignora esa restriccion.
# Para cobertura temporal completa se requiere una estrategia de
# analisis representativa, o redisenar prueba con enable sobre CLK_50.

# Incertidumbre de los relojes declarados
derive_clock_uncertainty
