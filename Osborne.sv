//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

module emu
(
	`include "sys/emu_ports.vh"
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;  

assign VGA_F1 = 0;
assign VGA_SCALER  = 0;
assign VGA_DISABLE = 0;
assign HDMI_FREEZE = 0;
assign HDMI_BLACKOUT = 0;
assign HDMI_BOB_DEINT = 0;

assign AUDIO_S   = 0;
assign AUDIO_MIX = 0;
assign AUDIO_L   = {1'b0, speaker, 14'd0};
assign AUDIO_R   = AUDIO_L;

assign LED_POWER = 0;
assign BUTTONS   = 0;

//////////////////////////////////////////////////////////////////

wire [1:0] ar = status[122:121];

assign VIDEO_ARX = (!ar) ? 12'd4 : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? 12'd3 : 12'd0;

`include "build_id.v" 
localparam CONF_STR = {
	"Osborne;UART1200:300:2400:600:4800:9600:2600:650;",
	"-;",
	"S0,IMGDSK,Drive A:;",
	"S1,IMGDSK,Drive B:;",
	"-;",
	"O[122:121],Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O[4:3],Phosphor,Green,Amber,White;",
	"O[6:5],Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"-;",
	"O[8:7],Serial speed,300/1200,600/2400,1200/4800,2400/9600;",
	"O[9],Serial handshake,Off,On;",
	"-;",
	"O[10],SCREEN-PAC (104 col),Off,On;",
	"-;",
	"T[0],Reset;",
	"R[0],Reset and close OSD;",
	"I,F10 = Osborne RESET key;",
	"v,0;",
	"V,v",`BUILD_DATE 
};

wire         forced_scandoubler;
wire   [1:0] buttons;
wire [127:0] status;
wire  [10:0] ps2_key;
wire  [21:0] gamma_bus;

wire  [1:0] img_mounted;
wire        img_readonly;
wire [63:0] img_size;
wire [31:0] sd_lba[2];
wire  [1:0] sd_rd, sd_wr, sd_ack;
wire  [8:0] sd_buff_addr;
wire  [7:0] sd_buff_dout;
wire  [7:0] sd_buff_din[2];
wire        sd_buff_wr;

hps_io #(.CONF_STR(CONF_STR), .VDNUM(2)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),
	.gamma_bus(gamma_bus),

	.forced_scandoubler(forced_scandoubler),

	.buttons(buttons),
	.status(status),
	.status_menumask(16'd0),

	.ps2_key(ps2_key),

	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),
	.sd_lba(sd_lba),
	.sd_blk_cnt('{6'd0, 6'd0}),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr)
);

///////////////////////   CLOCKS   ///////////////////////////////

wire clk_sys, clk_vid;
pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys),
	.outclk_1(clk_vid)
);

reg reset;
always @(posedge clk_sys) reset <= RESET | status[0] | buttons[1];

//////////////////////////////////////////////////////////////////

wire HBlank, HSync, VBlank, VSync;
wire ce_pix;
wire [7:0] video;
wire speaker;
wire [1:0] fdd_led;
wire ser_rts_n;

// UART de MiSTer: líneas de módem activas a nivel alto
assign UART_RTS = ~ser_rts_n;
assign UART_DTR = 1;

osborne1 osborne1
(
	.clk_sys(clk_sys),
	.clk_vid(clk_vid),
	.reset(reset),

	.screenpac(status[10]),

	.ps2_key(ps2_key),

	.ce_pix(ce_pix),
	.hsync(HSync),
	.vsync(VSync),
	.hblank(HBlank),
	.vblank(VBlank),
	.video(video),

	.speaker(speaker),

	.serial_cfg(status[8:7]),
	.ser_rxd(UART_RXD),
	.ser_txd(UART_TXD),
	.ser_cts_n(~(UART_CTS | ~status[9])),
	.ser_dcd_n(~(UART_DSR | ~status[9])),
	.ser_ri_n(1'b1),
	.ser_rts_n(ser_rts_n),

	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),
	.sd_lba(sd_lba),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr),

	.fdd_led(fdd_led)
);

assign LED_DISK  = {1'b0, |fdd_led};
assign LED_USER  = |fdd_led;

// Color del fósforo
wire [1:0] phos = status[4:3];
wire [7:0] R = (phos == 1) ? video : (phos == 2) ? video : {1'b0, video[7:1]} - {3'b0, video[7:3]};
wire [7:0] G = (phos == 1) ? {1'b0, video[7:1]} + {2'b0, video[7:2]} : video;
wire [7:0] B = (phos == 2) ? video : {2'b0, video[7:2]};

wire [1:0] scale = status[6:5];
assign VGA_SL = scale[1] ? scale : 2'd0;

assign CLK_VIDEO = clk_vid;

video_mixer #(.LINE_LENGTH(840), .GAMMA(1)) video_mixer
(
	.CLK_VIDEO(CLK_VIDEO),
	.CE_PIXEL(CE_PIXEL),
	.ce_pix(ce_pix),

	.scandoubler(scale || forced_scandoubler),
	.hq2x(scale == 1),
	.gamma_bus(gamma_bus),

	.R(R),
	.G(G),
	.B(B),

	.HSync(HSync),
	.VSync(VSync),
	.HBlank(HBlank),
	.VBlank(VBlank),

	.HDMI_FREEZE(HDMI_FREEZE),
	.freeze_sync(),

	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.VGA_DE(VGA_DE)
);

endmodule
