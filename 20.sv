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
	input signed [DMSB:0] rdata, 
	output write, 
	output reg signed [DMSB:0] wdata, 
	output reg [AMSB:0] addr, 
	input [IMSB:0] inst, 
	output reg [PMSB:0] pc, 
	input rstn, setn, clk 
);

reg signed [DMSB:0] z;
wire signed [DMSB:0] x, y, nxt_z;
wire [2:0] src_x = inst[8:6];
assign x = 
	(src_x == 3'b111) ? rdata[DMSB:0] : 
	(src_x == 3'b110) ? wdata[DMSB:0] : 
	(src_x == 3'b101) ? addr[DMSB:0] : 
	(src_x == 3'b100) ? inst[DMSB:0] : 
	(src_x == 3'b011) ? pc[DMSB:0] : 
	z;
wire [2:0] src_y = inst[11:9];
assign y = 
	(src_y == 3'b111) ? rdata[DMSB:0] : 
	(src_y == 3'b110) ? wdata[DMSB:0] : 
	(src_y == 3'b101) ? addr[DMSB:0] : 
	(src_y == 3'b100) ? inst[DMSB:0] : 
	(src_y == 3'b011) ? pc[DMSB:0] : 
	z;

wire dst_wdata = inst[12];
wire dst_addr = inst[13];
wire dst_pc = inst[14];
assign write = inst[15];

alu #(
	. MSB (DMSB)
) u_alu(
	.z(nxt_z), 
	.sel_rbo_z(inst[7]), 
	.sel_shl_z(inst[5]), 
	.sel_inv_z(inst[5]), 
	.sel_add(inst[4]), 
	.sel_inv_x(inst[3]), .sel_inv_y(inst[2]), 
	.sel_zero_x(inst[1]), .sel_zero_y(inst[0]), 
	.x(x), .y(y) 
);

always@(negedge rstn or posedge clk) begin
	if(!rstn) z <= {(DMSB+1){1'b0}};
	else if(setn) z <= nxt_z;
end

always@(negedge rstn or posedge clk) begin
	if(!rstn) wdata <= {(DMSB+1){1'b0}};
	else if(setn) begin
		if(dst_wdata) wdata <= nxt_z;
	end
end

always@(negedge rstn or posedge clk) begin
	if(!rstn) addr <= {(AMSB+1){1'b0}};
	else if(setn) begin
		if(dst_addr) addr <= nxt_z;
	end
end

always@(negedge rstn or posedge clk) begin
	if(!rstn) pc <= {(PMSB+1){1'b0}};
	else if(setn) begin
		if(dst_pc) pc <= nxt_z;
		else pc <= pc + 1;
	end
end

endmodule
