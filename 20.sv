module alu #(
	parameter MSB = 7 
)(
	output signed [MSB:0] z, 
	input sel_inv_z, 
	input sel_rbo_z, 
	input sel_shl_z, 
	input sel_add, 
	input sel_inv_x, sel_inv_y, 
	input sel_zero_x, sel_zero_y, 
	input signed [MSB:0] x, y 
);

wire signed [MSB:0] x1 = sel_zero_x ? {(MSB+1){1'b0}} : x;
wire signed [MSB:0] y1 = sel_zero_y ? {(MSB+1){1'b0}} : y;
wire signed [MSB:0] x2 = sel_inv_x ? ~x1 : x1;
wire signed [MSB:0] y2 = sel_inv_y ? ~y1 : y1;
wire signed [MSB:0] z1 = sel_add ? (x2 + y2) : (x2 & y2);
wire signed [MSB:0] z2 = sel_shl_z ? z1 << 1 : z1;
wire signed [MSB:0] z2_r;
genvar i;
generate
	for(i=0;i<=MSB;i=i+1) begin :rbo_i
		assign z2_r[i] = z2[MSB-i];
	end
endgenerate
wire signed [MSB:0] z3 = sel_rbo_z ? z2_r : z2;
wire signed [MSB:0] z4 = sel_inv_z ? ~z3 : z3;
assign z = z4;

endmodule


/*
`timescale 1ps/1ps

module alu_tb;

	parameter MSB = 7 ;
	wire signed [MSB:0] z;
	reg [7:0] f;
	reg signed [MSB:0] x, y;

alu #(
	. MSB (MSB)
) u_alu(
	.z(z), 
	.sel_inv_z(f[7]), 
	.sel_rbo_z(f[6]), 
	.sel_shl_z(f[5]), 
	.sel_add(f[4]), 
	.sel_inv_x(f[3]), .sel_inv_y(f[2]), 
	.sel_zero_x(f[1]), .sel_zero_y(f[0]), 
	.x(x), .y(y) 
);

initial begin
	$dumpfile("a.fst");
	$dumpvars(0, alu_tb);
	f = 8'b00000000;
	repeat(9'b100000000) begin
		#1;
		x = $urandom_range(0, 1<<(MSB+1)-1);
		y = $urandom_range(0, 1<<(MSB+1)-1);
		f = f + 1;
	end
	$finish;
end

endmodule
*/


module cpu #(
	parameter IMSB = 15, 
	parameter PMSB = 7, 
	parameter AMSB = 7, 
	parameter DMSB = 7 
)(
	output idle, 
	input signed [DMSB:0] rdata, 
	output write, 
	output reg signed [DMSB:0] wdata, 
	output reg [AMSB:0] addr, 
	input [IMSB:0] inst, 
	output reg [PMSB:0] pc, 
	input rstn, setn, clk 
);

wire inum = ~inst[IMSB];
reg signed [DMSB:0] z;
wire signed [DMSB:0] x, y, nxt_z;
wire eq = ~|nxt_z;
wire lt = nxt_z[DMSB];
wire gt = ~|{eq,lt};

wire [1:0] src = inst[9:8];
assign x = 
	(src == 2'b11) ? rdata[DMSB:0] : 
	(src == 2'b01) ? addr[DMSB:0] : 
	(src == 2'b10) ? pc[DMSB:0] : 
	z;
assign y = inum ? inst[DMSB:0] : wdata[DMSB:0];
assign write = inum ? 1'b0 : inst[7];

wire jeq = inst[10];
wire jlt = inst[11];
wire jgt = inst[12];
wire jmp = |{jlt&&lt,jgt&&gt,jeq&&eq};

wire dst_wdata = inst[13];
wire dst_addr = inst[14];

alu #(
	. MSB (DMSB)
) u_alu(
	.z(nxt_z), 
	.sel_inv_z(inum ? 1'b0 : inst[6]), 
	.sel_rbo_z(inum ? 1'b0 : inst[5]), 
	.sel_shl_z(1'b0), 
	.sel_add(inum ? 1'b0 : inst[4]), 
	.sel_inv_x(inum ? 1'b1 : inst[3]), .sel_inv_y(inum ? 1'b0 : inst[2]), 
	.sel_zero_x(inum ? 1'b1 : inst[1]), .sel_zero_y(inum ? 1'b0 : inst[0]), 
	.x(x), .y(y) 
);

assign idle = (inst == {(IMSB+1){1'b0}}) || (pc == {(PMSB+1){1'b1}});

always@(negedge rstn or posedge clk) begin
	if(!rstn) z <= {(DMSB+1){1'b0}};
	else if(setn && ~idle) z <= nxt_z;
end

always@(negedge rstn or posedge clk) begin
	if(!rstn) wdata <= {(DMSB+1){1'b0}};
	else if(setn && ~idle) begin
		if(dst_wdata) wdata <= nxt_z;
	end
end

always@(negedge rstn or posedge clk) begin
	if(!rstn) addr <= {(AMSB+1){1'b0}};
	else if(setn && ~idle) begin
		if(dst_addr) addr <= nxt_z;
	end
end

always@(negedge rstn or posedge clk) begin
	if(!rstn) pc <= {(PMSB+1){1'b0}};
	else if(!setn) pc <= {(PMSB+1){1'b0}};
	else if(setn && ~idle) begin
		if(jmp) pc <= z;
		else pc <= pc + 1;
	end
end

endmodule



`timescale 1ns/1ps

module cpu_tb_1;

parameter IMSB = 15;
parameter PMSB = 7;
parameter AMSB = 7; 
parameter DMSB = 7;

reg rstn, setn, clk;

initial clk = 0;
always #1 clk = ~clk;

reg [255:0] in_file;
reg [255:0] out_file;
integer debug_fp, in_fp, out_fp;

reg [7:0] ram[0:(1<<AMSB)-1];
reg [15:0] rom[0:(1<<PMSB)-1];

reg loader_ram, loader_rom;
reg [AMSB:0] loader_addr;
reg [DMSB:0] loader_wdata;
reg [PMSB:0] loader_pc;
reg [IMSB:0] loader_inst;

wire write;
wire [DMSB:0] wdata;
wire [AMSB:0] addr;
wire [PMSB:0] pc;
wire [DMSB:0] rdata = ram[addr];
wire [IMSB:0] inst = rom[pc];
wire idle;

cpu #(
	.IMSB ( IMSB ), 
	.PMSB ( PMSB ), 
	.AMSB ( AMSB ), 
	.DMSB ( DMSB )
) u_cpu(
	.idle(idle), 
	.rdata(rdata), 
	.write(write), 
	.wdata(wdata), 
	.addr(addr), 
	.inst(inst), 
	.pc(pc), 
	.rstn(rstn), .setn(setn), .clk(clk) 
);

always@(negedge rstn or posedge clk) begin
	if(!rstn) begin
	end
	else if(loader_ram) begin
		ram[loader_addr] <= loader_wdata;
	end
	else if(loader_rom) begin
		rom[loader_pc] <= loader_inst;
	end
	else if(setn) begin
		if(write) ram[addr] <= wdata;
	end
end

reg [511:0] line;
initial line = 0;
task debug_line(input bit [PMSB:0] in_pc);
	reg [PMSB:0] debug_pc;
	reg [511:0] debug_line;
	reg [7:0] debug_line_len;
	reg [7:0] debug_line_char;
	begin
		debug_fp = $fopen("a.debug","r");
		$fscanf(debug_fp, "%s\n", in_file);
		$fscanf(debug_fp, "%s\n", out_file);
		while(!$feof(debug_fp)) begin
			$fscanf(debug_fp, "%c", debug_pc);
			$fscanf(debug_fp, "%c", debug_line_len);
			debug_line = 512'd0;
			repeat(debug_line_len) begin
				$fscanf(debug_fp, "%c", debug_line_char);
				debug_line = {debug_line[511-8:0],debug_line_char};
			end
			if(in_pc == debug_pc) line = debug_line;
		end
		$fclose(debug_fp);
	end
endtask

task load_ram;
	begin
		repeat(2) @(negedge clk); rstn = 1;
		loader_ram = 1;
		loader_addr = 0;
		$write("load ram\n");
		@(posedge clk);
		repeat(1<<(AMSB+1)) begin
			$fscanf(out_fp, "%c", loader_wdata);
			@(posedge clk);
			loader_addr = loader_addr + 1;
		end
		loader_ram = 0;
		repeat(2) @(negedge clk); rstn = 0;
	end
endtask

task load_rom;
	reg [7:0] pdata;
	begin
		repeat(2) @(negedge clk); rstn = 1;
		loader_rom = 1;
		loader_pc = 0;
		$write("load rom\n");
		@(posedge clk);
		repeat(1<<(PMSB+1)) begin
			$fscanf(out_fp, "%c", pdata);
			loader_inst = 16'h00ff & pdata;
			$fscanf(out_fp, "%c", pdata);
			loader_inst = loader_inst | ((16'h00ff & pdata) << 8);
			@(posedge clk);
			loader_pc = loader_pc + 1;
		end
		loader_rom = 0;
		repeat(2) @(negedge clk); rstn = 0;
	end
endtask

task print_cpu_state;
	$write("rdata = 0x%02x:%d:'%c', ", rdata, rdata, rdata);
	$write("wdata = 0x%02x:%d:'%c', ", wdata, wdata, wdata);
	$write("addr = 0x%02x:%d:'%c', ", addr, addr, addr);
	$write("pc = 0x%02x, ", pc);
	$write("inst = %016b, %04x, ", inst, inst);
	$write("%s\n", line);
endtask

reg [PMSB:0] cur_pc;
wire xor_pc = setn ? (pc ^ cur_pc) : (loader_pc ^ cur_pc);
always@(posedge xor_pc or posedge rstn) begin
	debug_line(setn ? pc : loader_pc);
	#0.1 cur_pc = setn ? pc : loader_pc;
end

task load_inst;
	begin
		$write("load inst\n");
		repeat(2) @(negedge clk); rstn = 1;
		repeat(2) @(negedge clk); setn = 1;
		do begin
			print_cpu_state;
			@(negedge clk);
		end while(!idle);
		repeat(2) @(negedge clk); setn = 0;
		repeat(2) @(negedge clk); rstn = 0;
	end
endtask

initial begin
	$dumpfile("a.fst");
	$dumpvars(0, cpu_tb_1);
	debug_fp = $fopen("a.debug","rb");
	$fscanf(debug_fp, "%s\n", in_file);
	$fscanf(debug_fp, "%s\n", out_file);
	$fclose(debug_fp);
	in_fp = $fopen(in_file,"r");
	out_fp = $fopen(out_file,"rb");
	rstn = 0;
	setn = 0;
	cur_pc = 0;
	loader_ram = 0;
	loader_addr = 0;
	loader_wdata = 0;
	loader_rom = 0;
	loader_pc = 0;
	loader_inst = 0;
	load_ram;
	load_rom;
	repeat(1) load_inst;
	$fclose(in_fp);
	$fclose(out_fp);
	$finish;
end

endmodule

