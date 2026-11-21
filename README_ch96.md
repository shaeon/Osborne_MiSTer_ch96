# Osborne 1 para Chameleon96

*English summary below.*

Este repositorio es la versión para la **Chameleon96** (Cyclone V SoC
5CSEBA6U19I7, 512 MB de DDR3) del core Osborne 1 de
[shaeon/Osborne_MiSTer](https://github.com/shaeon/Osborne_MiSTer). La máquina
es la misma: este repositorio lleva todo el de la DE10-Nano más la capa de la
placa. Los `README.md` y `README_es.md` son los del repositorio principal y
explican el core; este fichero solo cubre lo propio de la Chameleon96.

## Ficheros

El RBF se llama `Osborne_AAAAMMDD_ch96.rbf`, con el sufijo al final como los
demás cores de la Chameleon96, y está en `releases/`. En `releases/` solo hay
RBF de la Chameleon96: los de la DE10-Nano se quitan al sincronizar.

## Qué cambia respecto a la DE10-Nano

Basado en el port de TS2068_MiSTer de Maverick:

- `ch96_top.sv` envuelve `sys_top` en los pines de la placa: vídeo RGB565 al
  TDA19988 (HDMI), audio I2S, I2C del HDMI y LEDs.
- La placa no tiene oscilador en la FPGA: los 50 MHz salen del HPS
  (`h2f_user1_clk`), que `sys_top` y `sysmem` sacan como `clk_50m`.
- El búfer del escalador (`ascal`) pasa a 0x1E800000 para caber en los 512 MB.
- El HDMI va a 74,25 MHz (720p) y sin ALSA (`MISTER_DISABLE_ALSA`).
- Revisión de Quartus `Osborne_ch96` (`Osborne_ch96.qpf/.qsf/.sdc`), con
  `sys/pins_ch96.tcl`, `sys/hps_ch96.tcl` y `sys/pll_q22.qip`. `sys.qip` no
  incluye `sys_top.sdc`: la Chameleon96 usa `Osborne_ch96.sdc`.

El Osborne no usa la DDR3 ni la SDRAM, así que la máquina (`rtl/`) no cambia.
El puerto serie usa el UART del HPS, igual que en MiSTer.

## Sincronización con el repositorio principal

`.github/workflows/sync.yml` se ejecuta cada noche (03:23 UTC) y se puede
lanzar a mano desde *Actions > Sync > Run workflow*:

1. Trae `main` de shaeon/Osborne_MiSTer y lo mezcla con `main`.
2. Los conflictos en `releases/` se resuelven solos quitando el fichero.
3. Quita de `releases/` todo RBF que no termine en `_ch96.rbf`.
4. Sube el resultado y lanza la compilación (`build_ch96.yml`).

Si hay un conflicto en otro fichero (lo normal sería en `sys/`, si el
framework de MiSTer cambia en el repositorio principal), el workflow para y el
resumen de la ejecución dice qué ficheros son. Se resuelve a mano:

```
git remote add upstream https://github.com/shaeon/Osborne_MiSTer.git
git fetch upstream
git merge upstream/main
# resolver los conflictos manteniendo los cambios de la Chameleon96
git rm releases/Osborne_*[0-9].rbf     # si ha entrado algún RBF de la DE10-Nano
git commit
git push
```

El `build.yml` del repositorio principal viene en la sincronización pero aquí
no se ejecuta (solo corre en shaeon/Osborne_MiSTer), así que no hay que tocarlo.

## Compilación

`.github/workflows/build_ch96.yml` compila `Osborne_ch96` con Quartus 17.0
(`raetro/quartus:17.0`):

- En cada push a `main` (o al lanzarlo a mano o desde la sincronización)
  compila, deja el RBF y los informes en *Actions* y guarda
  `releases/Osborne_AAAAMMDD_ch96.rbf` con un commit.
- Al subir una etiqueta `v*` crea una Release con el RBF.
- En los pull requests solo compila.

En local: abre `Osborne_ch96.qpf` en Quartus Prime Lite 17.0. Con 17.0.2:
22 % de ALMs y todos los relojes con holgura positiva (peor setup +4,0 ns, en
el reloj de 100 MHz del HPS).

Sin probar en la placa todavía.

## Créditos

- Core Osborne 1: Shaeon (Carlos Palmero), a partir del proyecto de Jeremy
  Soller (jackpot51). Ver `README_es.md`.
- Port de MiSTer a la Chameleon96: Maverick (Maverick-Shark), de su rama
  `ch96` de TS2068_MiSTer.
- Documentación de la placa: Manuel Teira (teiram),
  [chameleon96-workbench](https://github.com/teiram/chameleon96-workbench).

---

## English summary

Chameleon96 build of the Osborne 1 core from
[shaeon/Osborne_MiSTer](https://github.com/shaeon/Osborne_MiSTer). The machine
is unchanged; this repository adds the board wrapper (`ch96_top.sv`, pin and
HPS files, `Osborne_ch96` Quartus revision) and the MiSTer framework changes
from Maverick's TS2068_MiSTer port.

- RBF files: `releases/Osborne_YYYYMMDD_ch96.rbf` (Chameleon96 only).
- `sync.yml` merges the main repository every night, drops non-`_ch96` RBF
  files and starts `build_ch96.yml`. Other conflicts stop the workflow and are
  listed in the run summary.
- `build_ch96.yml` builds with Quartus 17.0, commits the RBF to `releases/` on
  `main` and creates a release for `v*` tags.

Not tested on the board yet.
