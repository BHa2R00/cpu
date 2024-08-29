`timescale 10ns/1ps


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
	for(i=0;i<=MSB;i=i+1) assign z2_r[i] = z2[MSB-i];
endgenerate
wire signed [MSB:0] z3 = sel_rbo_z ? z2_r : z2;
wire signed [MSB:0] z4 = sel_inv_z ? ~z3 : z3;
assign z = z4;

endmodule


`ifdef SIM
module alu_tb;

reg clk;
parameter MSB = 7;
wire signed [MSB:0] z;
reg sel_inv_z;
reg sel_rbo_z;
reg sel_shl_z; 
reg sel_add;
reg sel_inv_x, sel_inv_y;
reg sel_zero_x, sel_zero_y;
reg signed [MSB:0] x, y;
reg check;
reg signed [MSB:0] z0;

alu #(
	.MSB(MSB)
) u_alu(
	.z(z), 
	.sel_inv_z(sel_inv_z), 
	.sel_rbo_z(sel_rbo_z), 
	.sel_shl_z(sel_shl_z), 
	.sel_add(sel_add), 
	.sel_inv_x(sel_inv_x), .sel_inv_y(sel_inv_y), 
	.sel_zero_x(sel_zero_x), .sel_zero_y(sel_zero_y), 
	.x(x), .y(y) 
);

always #1 clk = ~clk;
integer k;

initial begin
	`ifdef FST
	$dumpfile("a.fst");
	$dumpvars(0, alu_tb);
	`endif
	clk = 1'b0;
	check = 1'b1;
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b00000000;
		$write("op_x&y, ZAXY = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = x & y;
				repeat(1) @(posedge clk);
				$write(" x = %b, y = %b, z = %b, z0 = %b\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b00000010;
		$write("op_0, Z0 = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = 0;
				repeat(1) @(posedge clk);
				$write(" x = %b, y = %b, z = %b, z0 = %b\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b00000001;
		$write("op_0, Z0 = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = 0;
				repeat(1) @(posedge clk);
				$write(" x = %b, y = %b, z = %b, z0 = %b\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b00000011;
		$write("op_0, Z0 = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = 0;
				repeat(1) @(posedge clk);
				$write(" x = %b, y = %b, z = %b, z0 = %b\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b00001000;
		$write("op_(~x)&y, ZANXY = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = (~x) & y;
				repeat(1) @(posedge clk);
				$write(" x = %b, y = %b, z = %b, z0 = %b\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b00001010;
		$write("op_y, ZY = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = y;
				repeat(1) @(posedge clk);
				$write(" x = %b, y = %b, z = %b, z0 = %b\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b00001001;
		$write("op_0, Z0 = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = 0;
				repeat(1) @(posedge clk);
				$write(" x = %b, y = %b, z = %b, z0 = %b\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b00001011;
		$write("op_0, Z0 = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = 0;
				repeat(1) @(posedge clk);
				$write(" x = %b, y = %b, z = %b, z0 = %b\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b00000100;
		$write("op_x&(~y), ZAXNY = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = x & (~y);
				repeat(1) @(posedge clk);
				$write(" x = %b, y = %b, z = %b, z0 = %b\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b00000110;
		$write("op_0, Z0 = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = 0;
				repeat(1) @(posedge clk);
				$write(" x = %b, y = %b, z = %b, z0 = %b\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b00000101;
		$write("op_x, ZX = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = x;
				repeat(1) @(posedge clk);
				$write(" x = %b, y = %b, z = %b, z0 = %b\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b00000111;
		$write("op_0, Z0 = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = 0;
				repeat(1) @(posedge clk);
				$write(" x = %b, y = %b, z = %b, z0 = %b\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b00001100;
		$write("op_~(x|y), ZNOXY = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = ~(x | y);
				repeat(1) @(posedge clk);
				$write(" x = %b, y = %b, z = %b, z0 = %b\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b00010011;
		$write("op_0, Z0 = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = 0;
				repeat(1) @(posedge clk);
				$write(" x = %b, y = %b, z = %b, z0 = %b\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b10011111;
		$write("op_1, Z1 = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = 1;
				repeat(1) @(posedge clk);
				$write(" x = %d, y = %d, z = %d, z0 = %d\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b00010111;
		$write("op_-1, Z-1 = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = -1;
				repeat(1) @(posedge clk);
				$write(" x = %d, y = %d, z = %d, z0 = %d\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b00011011;
		$write("op_-1, Z-1 = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = -1;
				repeat(1) @(posedge clk);
				$write(" x = %d, y = %d, z = %d, z0 = %d\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b10010101;
		$write("op_-x, Z-X = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = 0-x;
				repeat(1) @(posedge clk);
				$write(" x = %d, y = %d, z = %d, z0 = %d\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b10011010;
		$write("op_-y, Z-Y = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = 0-y;
				repeat(1) @(posedge clk);
				$write(" x = %d, y = %d, z = %d, z0 = %d\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b10000101;
		$write("op_~x, ZX = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = ~x;
				repeat(1) @(posedge clk);
				$write(" x = %b, y = %b, z = %b, z0 = %b\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b10001010;
		$write("op_~y, ZY = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = ~y;
				repeat(1) @(posedge clk);
				$write(" x = %b, y = %b, z = %b, z0 = %b\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b10011101;
		$write("op_x+1, Z+X1 = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = x+1;
				repeat(1) @(posedge clk);
				$write(" x = %d, y = %d, z = %d, z0 = %d\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b00010101;
		$write("op_x-1, Z-X1 = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = x-1;
				repeat(1) @(posedge clk);
				$write(" x = %d, y = %d, z = %d, z0 = %d\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b10011110;
		$write("op_y+1, Z+Y1 = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = y+1;
				repeat(1) @(posedge clk);
				$write(" x = %d, y = %d, z = %d, z0 = %d\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b00011010;
		$write("op_y-1, Z-Y1 = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = y-1;
				repeat(1) @(posedge clk);
				$write(" x = %d, y = %d, z = %d, z0 = %d\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b00010000;
		$write("op_x+y, Z+XY = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = x + y;
				repeat(1) @(posedge clk);
				$write(" x = %d, y = %d, z = %d, z0 = %d\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b10011000;
		$write("op_x-y, Z-XY = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = x - y;
				repeat(1) @(posedge clk);
				$write(" x = %d, y = %d, z = %d, z0 = %d\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b10010100;
		$write("op_y-x, Z-YX = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = y - x;
				repeat(1) @(posedge clk);
				$write(" x = %d, y = %d, z = %d, z0 = %d\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b10010000;
		$write("op_-x-y-1, Z-1-XY = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = 0 - x - y - 1;
				repeat(1) @(posedge clk);
				$write(" x = %d, y = %d, z = %d, z0 = %d\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b00100101;
		$write("op_shl_x, ZSX = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = x<<1;
				repeat(1) @(posedge clk);
				$write(" x = %b, y = %b, z = %b, z0 = %b\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b00101010;
		$write("op_shl_y, ZSY = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				z0 = y<<1;
				repeat(1) @(posedge clk);
				$write(" x = %b, y = %b, z = %b, z0 = %b\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b01000101;
		$write("op_rbo_x, ZRX = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				for(k = 0; k<=MSB; k=k+1) z0[k] = x[MSB-k];
				repeat(1) @(posedge clk);
				$write(" x = %b, y = %b, z = %b, z0 = %b\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) begin
		{sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y} = 8'b01001010;
		$write("op_rbo_y, ZRY = %b\n", {sel_inv_z,sel_rbo_z,sel_shl_z,sel_add,sel_inv_x,sel_inv_y,sel_zero_x,sel_zero_y});
		repeat(10) begin
			if(check) begin
				x = $urandom_range(0,(1<<MSB)); 
				y = $urandom_range(0,(1<<MSB)); 
				for(k = 0; k<=MSB; k=k+1) z0[k] = y[MSB-k];
				repeat(1) @(posedge clk);
				$write(" x = %b, y = %b, z = %b, z0 = %b\n", x, y, z, z0);
				if(z != z0) check = 1'b0;
			end
		end
	end
	if(check) $write("pass\n"); else $write("fail\n");
	$finish;
end

endmodule
`endif


module filo #(
	parameter DMSB = 7, 
	parameter AMSB = 2
)(
	output full, empty, 
	input push, pop, 
	output reg [DMSB:0] q, 
	input [DMSB:0] d, 
	input rstb, setb, clk 
);

reg [AMSB:0] a;
assign full = a == {(AMSB+1){1'b1}};
assign empty = a == {(AMSB+1){1'b0}};
reg [DMSB:0] r[0:((1<<(AMSB+1))-1)];
wire [AMSB:0] pop_a = a - {{AMSB{1'b0}}, 1'b1};
wire [AMSB:0] a0 = a ^ (a>>1);
wire [AMSB:0] a1 = pop_a ^ (pop_a>>1);
always@(negedge rstb or posedge clk) begin
	if(~rstb) begin
		a <= {(AMSB+1){1'b0}};
		q <= {(DMSB+1){1'b0}};
	end
	else if(setb) begin
		case({push, pop})
			2'b11: q <= d;
			2'b10: begin
				if(!full) begin
					r[a0] <= q;
					a <= a + {{AMSB{1'b0}}, 1'b1};
					q <= d;
				end
			end
			2'b01: begin
				if(!empty) begin
					q <= r[a1];
					a <= a - {{AMSB{1'b0}}, 1'b1};
				end
			end
			default: begin
				a <= a;
				q <= q;
			end
		endcase
	end
end
endmodule


`ifdef SIM
module filo_tb;

parameter DMSB = 7;
parameter AMSB = 2;
wire full, empty;
reg push, pop;
wire [DMSB:0] q; 
reg [DMSB:0] d, d_diff;
reg rstb, setb, clk;
reg check;
integer i, j, k;

filo #(
	.DMSB(DMSB), 
	.AMSB(AMSB)
) u_filo(
	.full(full), .empty(empty), 
	.push(push), .pop(pop), 
	.q(q), 
	.d(d), 
	.rstb(rstb), .setb(setb), .clk(clk) 
);

always #1 clk = ~clk;

initial begin
	`ifdef FST
	$dumpfile("a.fst");
	$dumpvars(0, filo_tb);
	`endif
	rstb = 1'b0;
	setb = 1'b0;
	clk = 1'b0;
	check = 1'b1;
	push = 1'b0;
	pop = 1'b0;
	repeat(10) begin
		repeat(3) @(posedge clk); rstb = 1'b1;
		repeat(3) @(posedge clk); setb = 1'b1;
		repeat(10) begin
		if(check) begin
			repeat(3) @(posedge clk); #0.1;
			i = $urandom_range(0,(1<<(DMSB+1))-1);
			j = $urandom_range(0,(1<<(DMSB+1))-1);
			k = $urandom_range(3,(1<<(AMSB+1)));
			d = i;
			push = 1'b1;
			pop = 1'b0;
			$write("push \n");
			repeat(k) begin
				@(posedge clk); #0.1;
				if(~full) begin
					$write(" d = %d\n", d);
					d = d + j;
				end
				else push = 1'b0;
			end
			if(~full) d = d - j;
			push = 1'b0;
			pop = 1'b0;
			repeat(1) @(posedge clk); #0.1;
			push = 1'b0;
			pop = 1'b1;
			$write("pop \n");
			repeat(k) begin
				@(posedge clk); #0.1;
				if(~empty) begin
					d = d - j;
					$write(" d = %d, q = %d\n", d, q);
					if(check && (d != q)) check = 0;
				end
				else pop = 1'b0;
			end
			push = 1'b0;
			pop = 1'b0;
			repeat(3) @(posedge clk);
		end
		end
		repeat(3) @(posedge clk); setb = 1'b0;
		repeat(3) @(posedge clk); rstb = 1'b0;
	end
	if(check) $write("pass\n"); else $write("fail\n");
	$finish;
end

endmodule
`endif



module cpu #(
	parameter IMSB = 15, 
	parameter PMSB = 7, 
	parameter AMSB = 7, 
	parameter DMSB = 7 
)(
	output idle, 
	output reg sel, write, 
	input signed [DMSB:0] rdata, 
	output reg signed [DMSB:0] wdata, 
	output reg [AMSB:0] addr, 
	input [IMSB:0] inst, 
	output reg [PMSB:0] pc, 
	input init, 
	input rstb, setb, clk 
);

wire inum = ~inst[IMSB];
wire signed [DMSB:0] t, x, y, z;
wire eq = ~|z;
wire lt = z[DMSB];
wire gt = ~|{eq,lt};

wire [1:0] src = inst[(IMSB-4):(IMSB-5)];
assign x = 
	(src == 2'b11) ? z : 
	(src == 2'b01) ? addr[DMSB:0] : 
	(src == 2'b10) ? pc[DMSB:0] : 
	wdata[DMSB:0];
assign y = inum ? inst[DMSB:0] : rdata[DMSB:0];
wire nxt_sel = inst[IMSB-7];
wire nxt_write = inst[IMSB-6];

wire jeq = inst[IMSB-3];
wire jlt = inst[IMSB-2];
wire jgt = inst[IMSB-1];
wire jmp = |{(jlt && lt), (jgt && gt), (jeq && eq)};

alu #(
	.MSB(DMSB)
) u_alu(
	.z(z), 
	.sel_inv_z(inum ? 1'b0 : inst[7]), 
	.sel_rbo_z(inum ? 1'b0 : inst[6]), 
	.sel_shl_z(inum ? 1'b0 : inst[5]), 
	.sel_add(inum ? 1'b0 : inst[4]), 
	.sel_inv_x(inum ? 1'b1 : inst[3]), .sel_inv_y(inum ? 1'b0 : inst[2]), 
	.sel_zero_x(inum ? 1'b1 : inst[1]), .sel_zero_y(inum ? 1'b0 : inst[0]), 
	.x(x), .y(y) 
);

assign idle = (inst == {(IMSB+1){1'b0}}) || (pc == {(PMSB+1){1'b1}});

wire push = ~|{nxt_sel, nxt_write, jmp};
wire pop = src == 2'b11;

filo #(
	. DMSB (DMSB), 
	. AMSB (3)
) u_filo(
	.full(), .empty(), 
	.push(push), .pop(pop), 
	.q(t), 
	.d(z), 
	.rstb(rstb), .setb(setb && ~idle), .clk(clk) 
);

always@(negedge rstb or posedge clk) begin
	if(~rstb) begin
		wdata <= {(DMSB+1){1'b0}};
		write <= 1'b0;
	end
	else if(setb && ~idle) begin
		if(nxt_write) begin
			wdata <= z;
			write <= 1'b1;
		end
		else write <= 1'b0;
	end
end

always@(negedge rstb or posedge clk) begin
	if(~rstb) begin
		addr <= {(AMSB+1){1'b0}};
		sel <= 1'b0;
	end
	else if(setb && ~idle) begin
		if(nxt_sel) begin
			if(!nxt_write) addr <= z;
			sel <= 1'b1;
		end
		else sel <= 1'b0;
	end
end

always@(negedge rstb or posedge clk) begin
	if(~rstb) pc <= {(PMSB+1){1'b0}};
	else if(init) pc <= {(PMSB+1){1'b0}};
	else if(setb && ~idle) begin
		if(jmp) pc <= t;
		else pc <= pc + 1;
	end
end

endmodule



/*

# dc_shell 
analyze -format verilog 32.sv
elaborate -update cpu
create_port -direction in test_se
create_port -direction in test_si
create_port -direction out test_so
set_dft_signal -port test_se -type scanenable
set_dft_signal -port test_si -type scandatain
set_dft_signal -port test_so -type scandataout
set_dft_signal -port clk -type testdata
create_test_protocol -infer_clock -infer_asynch
set_case_analysis 0 test_se
create_clock -name clk -period 5 [get_ports clk] 
set_clock_gating_style -sequential_cell latch -control_point before -max_fanout 8 
set_clock_transition 0.1 clk
set_clock_uncertainty -setup 0.2 clk
set_clock_uncertainty -hold 0.2 clk
compile_ultra -scan -gate_clock
preview_dft
dft_drc
insert_dft

# upf 
upf_version 2.0
create_power_domain PD -include_scope 
create_supply_port GND -direction in 
create_supply_port VCC -direction in 
create_supply_net GND
create_supply_net VCC 
connect_supply_net GND -ports GND
connect_supply_net VCC -ports VCC
create_supply_set PD.primary -function {power VCC} -function {ground GND} -update 
add_power_state PD.primary -state on  {-supply_expr {power  == `{FULL_ON, 1.2} } -simstate NORMAL }
add_power_state PD.primary -state off {-supply_expr {power  == `{OFF} } -simstate CORRUPT }
add_power_state PD.primary -state gnd {-supply_expr {ground == `{FULL_ON, 0.0} } -simstate NORMAL }
create_pst PST -supplies { PD.primary.power PD.primary.ground }



 */
