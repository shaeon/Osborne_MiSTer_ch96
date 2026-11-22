# Osborne 1 MiSTer: progreso y pendientes

## Estado (21/11/2026)

El core original solo tenía CPU, ROM, RAM y el vídeo de texto: no había FDC, PIAs,
banco de memoria correcto ni interrupciones, por eso no pasaba de la pantalla inicial.
Se ha reescrito la máquina entera en `rtl/osborne1.sv`.

Comprobado en simulación (Verilator, `sim/`):
- ROM 1.44 llega a "Insert disk in Drive A and press RETURN"
- Arranca CP/M 2.2 desde disco de doble densidad (O1CPM) y de simple densidad (O1CPMS)
- HELP, ESC a CP/M, `DIR B:` con disco SD en B: y sistema DD en A:
- `STAT`, `SAVE` (escritura en la imagen) y scroll vertical por hardware

## Errores que había y arreglos

1. Faltaba todo el hardware de E/S: FDC, PIA de vídeo (scroll, DDEN, selección de
   unidad, zumbador), PIA IEEE, ACIA, teclado mal decodificado.
2. Banco de memoria: el modo ROM solo cubre 0000-3FFF (ROM 0000-1FFF, E/S 2000-3FFF),
   escrituras en ROM ignoradas, BIT 9 para la RAM de atributos, y los biestables
   UB4A/UB6A (M1 e INTA) que fuerzan modo ROM al atender una interrupción.
3. Interrupciones IM 2 con vector en el bus durante INTA (F0/F8/FC/FE).
4. Orden de filas del teclado: A0..A7 -> filas 0,1,3,4,5,2,6,7.
5. wd1793 de Sorgelig adaptado:
   - formato 10x256 (size_code 5)
   - `layout=1` para discos de una cara (con 0 la pista 1 leía la 2)
   - entrada `rnf`: Record Not Found si no hay disco o la densidad no coincide
   - SEEK actualiza el registro de pista; READ ADDRESS copia la pista al registro de sector
   - READ ADDRESS no comprueba el registro de sector
   - Force Interrupt con comando en curso conserva el formato de estado tipo II
     (la BIOS lo comprueba con AND 5Ch tras cada lectura multisector)

## Pendiente

- Probar en la placa (no se ha probado en hardware real)
- ACIA 6850 real conectada al UART de MiSTer
- Imágenes de doble cara / otros formatos (IBM 8x512, DEC 9x512, Xerox 18x128)
- SCREEN-PAC (104 columnas)
- Convertir TD0 directamente (ahora solo IMD; los TD0 del usuario tienen IMD equivalente)

## Compilación

- Quartus Prime Lite 17.0.2, MiSTer (5CSEBA6): 23 % ALMs, 1,15 Mbit de BRAM
- Todos los relojes cumplen tiempos (clk_sys 31,95 MHz: holgura setup +15,0 ns, hold +0,25 ns)
- RBF: `releases/Osborne_20261121.rbf`

## Siguiente fase (21/11/2026)

Plan acordado para revisar:
1. Puerto serie: ACIA 6850 real con el reloj de baudios de la placa (pares
   300/1200, 600/2400, 1200/4800, 2400/9600 como en MAME), IRQ con vector FC,
   DCD/CTS y RI (a CA2 de la PIA de vídeo), conectada al UART de MiSTer.
2. SCREEN-PAC (52/104 columnas): misma ROM 1.44; registro en 2400 (bit 0
   resolución, bit 1 HC-LEFT), presencia leyendo 2400 con bit 2 a 0. La CP/M
   de OS1XUTLS lo detecta y su SETUP elige el tamaño de pantalla. Salida de
   vídeo siempre a 15,97 MHz (modo normal con píxeles dobles) para no cambiar
   de resolución.
3. Nuevo Video (80x24 con SY6545): opcional; necesita la ROM monrom 1.51 y
   MAME lo tiene incompleto. El usuario tiene el disco OS1NUEVO (BIOS15).
4. IEEE-488: no prioritario (impresoras y unidades IEEE).

## Puerto serie (21/11/2026): hecho

- `rtl/acia6850.sv`: ACIA completa (formatos, ÷1/÷16/÷64, paridad, FE/OVRN,
  TDRE bloqueado por /CTS, IRQ por RDRF/OVRN/DCD y TDRE)
- Reloj de baudios como en MAME, con el bug original de 600/2400 (650/2600)
- OSD: *Serial speed* (status[8:7]) y *Serial handshake* (status[9])
- CONF_STR declara las velocidades del UART de MiSTer
- RI del RS-232 va a CA2 de la PIA de vídeo (sin señal en MiSTer: a 1)
- Comprobado: test unitario con iverilog y consola CP/M por serie (CON:=CRT:)
  en la simulación completa
- La BIOS: CON: TTY = pantalla/teclado, CRT = serie; RDR: PTR y PUN: PTP = serie

Siguiente: SCREEN-PAC.

## SCREEN-PAC (21/11/2026): hecho

- Registro en 2400 (D0 = 104 columnas, D1 = 0 -> HC-LEFT), lectura con D2 = 0
  para que la BIOS la detecte; opción del OSD status[10]
- Vídeo reescrito a 1024 relojes de 15,97 MHz por línea en un dominio
  clk_vid = 63,89 MHz (PLL: 31,944 + 63,889 MHz, 50*115/6/{30,15}); la
  CPU sigue en clk_sys
- Comprobado en simulación con OS1XUTLS: la BIOS escribe 00 en 2400 al
  arrancar, SETUP la detecta, se elige 104 físicas, se guarda en memoria y
  XDIR sale en 104 columnas
- Banco de pruebas: -p (SCREEN-PAC), -save/-load (estado completo)
- Quartus 17.0.2: clk_vid +4,1 ns, clk_sys +8,6 ns, 23 % ALMs

Pendiente: Nuevo Video (necesita monrom 1.51), IEEE-488.

## Chameleon96 (21/11/2026): repositorio aparte

- shaeon/Osborne_MiSTer_ch96: este repositorio + capa de la placa
  (ch96_top.sv, Osborne_ch96.qpf/.qsf/.sdc, sys/pins_ch96.tcl,
  sys/hps_ch96.tcl, sys/pll_q22.qip y cambios en sys_top.v, sysmem.sv,
  pll_hdmi, sys.qip y Osborne.qsf), basado en la rama ch96 de TS2068_MiSTer
  (Maverick)
- Se sincroniza solo (sync.yml, cada noche o a mano): merge de main, quita
  los RBF que no terminan en _ch96.rbf, resuelve solos los conflictos en
  releases/ y lanza build_ch96.yml; otros conflictos los avisa y para
- build_ch96.yml compila Osborne_ch96, guarda Osborne_AAAAMMDD_ch96.rbf en
  releases/ y crea Releases con las etiquetas v*
- build.yml de este repositorio solo corre en shaeon/Osborne_MiSTer, así que
  viaja sin cambios al de la ch96 y no provoca conflictos
- Quartus 17.0.2: Osborne_ch96 compila con holgura positiva en todos los
  relojes (peor setup +4,0 ns); sin probar en la placa

## Framework de MiSTer al día (22/11/2026)

- sys/ actualizado al Template_MiSTer de MiSTer-devel del 3/11/2026 (e901a9f),
  la misma base que Template_MiSTer_ch96 de Manuel Teira
- Osborne.sv declara los puertos con `include "sys/emu_ports.vh"`
- Osborne_MiSTer_ch96 pasa a usar el sys/ de Template_MiSTer_ch96 tal cual
  (ventilador PWM, PSRAM QSPI, OSD en color, búferes de memoria de la ch96) en
  vez del port de Maverick; ch96_top.sv va en sys/
- Diferencia entre los dos repositorios en sys/: exactamente la de Manuel.
  Actualizar: framework de MiSTer -> sys/ del principal; cambios de Manuel ->
  sys/ del repositorio ch96
- Quartus 17.0.2: Osborne 24 % ALMs, peor setup +0,50 ns (HDMI 148,5 MHz,
  normal en la DE10-Nano), emu +3,95 ns; Osborne_ch96 22 % ALMs, peor setup
  +4,34 ns (HPS 100 MHz), emu +4,85 ns; sin holguras negativas de hold,
  recovery ni removal. Sin probar en la placa
