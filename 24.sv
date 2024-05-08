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


module filo #(
	parameter DMSB = 7, 
	parameter AMSB = 2
)(
	output full, empty, 
	input push, pop, 
	output reg [DMSB:0] q, 
	input [DMSB:0] d, 
	input rstn, setn, clk 
);

reg [AMSB:0] a;
assign full = a == {(AMSB+1){1'b1}};
assign empty = a == {(AMSB+1){1'b0}};
reg [DMSB:0] r[0:((1<<(AMSB+1))-1)];
wire [AMSB:0] pop_a = a - {{AMSB{1'b0}}, 1'b1};
wire [AMSB:0] a0 = a ^ (a>>1);
wire [AMSB:0] a1 = pop_a ^ (pop_a>>1);
always@(negedge rstn or posedge clk) begin
	if(!rstn) begin
		a <= {(AMSB+1){1'b0}};
		q <= {(DMSB+1){1'b0}};
	end
	else if(setn) begin
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
	input rstn, setn, clk 
);

wire inum = ~inst[IMSB];
wire signed [DMSB:0] z;
wire signed [DMSB:0] x, y, nxt_z;
wire eq = ~|nxt_z;
wire lt = nxt_z[DMSB];
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
	. MSB (DMSB)
) u_alu(
	.z(nxt_z), 
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
	.q(z), 
	.d(nxt_z), 
	.rstn(rstn), .setn(setn && ~idle), .clk(clk) 
);

always@(negedge rstn or posedge clk) begin
	if(!rstn) begin
		wdata <= {(DMSB+1){1'b0}};
		write <= 1'b0;
	end
	else if(setn && ~idle) begin
		if(nxt_write) begin
			wdata <= nxt_z;
			write <= 1'b1;
		end
		else write <= 1'b0;
	end
end

always@(negedge rstn or posedge clk) begin
	if(!rstn) begin
		addr <= {(AMSB+1){1'b0}};
		sel <= 1'b0;
	end
	else if(setn && ~idle) begin
		if(nxt_sel) begin
			if(!nxt_write) addr <= nxt_z;
			sel <= 1'b1;
		end
		else sel <= 1'b0;
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




/*

# SAED_Lib/32-28nm_EDK 

# dc_shell 
analyze -format verilog ../rtl/24.sv
elaborate -update cpu
create_clock -period 125 [get_ports clk]
compile_ultra -scan
set_dft_configuration -fix_clock enable
create_port -direction "in" test_si
set_dft_signal -port test_si -type scandatain
create_port -direction "out" test_so
set_dft_signal -port test_so -type scandataout
#create_port -direction "in" test_se
set_dft_signal -view spec -port test_se -type scanenable
set_dft_signal -view spec -port clk -type testdata
create_test_protocol -infer_clock -infer_asynch 
preview_dft
dft_drc
insert_dft
write -format verilog -hierarchy -output ../dc/cpu_mapped.v
write_test_protocol -output ../dc/cpu_mapped.spf
write_sdc ../dc/cpu_mapped.sdc
report_timing
report_area

# tmax -shell 
read_netlist ../dc/cpu_mapped.v 
read_netlist ../lib/saed32nm_hvt.v -library 
run_build_model cpu
run_drc ../dc/cpu_mapped.spf
set_faults -model stuck
add_faults -all
set_atpg -merge high -verbose -abort_limit 256 -coverage 100 -decision random
run_atpg
set_faults -summary verbose
set_faults -report collapsed
report_summaries
write_faults cpu_faults.rpt -all -replace
write_patterns ../atpg/cpu_patterns.stil -format stil -replace

# icc_shell
set top_entry cpu
sh rm -rfv ../icc/${top_entry}.mw
create_mw_lib -technology $tf -mw_reference_library $ref_lib ../icc/${top_entry}.mw
open_mw_lib ../icc/${top_entry}.mw
read_verilog -top ${top_entry} ../dc/${top_entry}_mapped.v
uniquify_fp_mw_cel
current_design ${top_entry}
link
set_operating_conditions \
	-min_library saed32hvt_ss0p7vn40c -min ss0p7vn40c \
	-max_library saed32hvt_ff1p16v125c -max ff1p16v125c 
read_sdc ../icc/${top_entry}_mapped.sdc
create_clock -period 125 [get_ports clk]
set_tlu_plus_files \
-max_tluplus $max_tluplus \
-min_tluplus $min_tluplus \
-tech2itf_map $tech2itf_map
check_tlu_plus_files
create_floorplan \
	-control_type "aspect_ratio" \
	-core_aspect_ratio 1.0 \
	-core_utilization 0.8 \
	-row_core_ratio 1 \
	-start_first_row \
	-flip_first_row \
	-left_io2core 0.1 \
	-bottom_io2core 0.1 \
	-right_io2core 0.1 \
	-top_io2core 0.1
derive_pg_connection \
	-power_net VDD -power_pin VDD \
	-ground_net VSS -ground_pin VSS
derive_pg_connection \
	-power_net VDD -power_pin VDD \
	-ground_net VSS -ground_pin VSS
set_separate_process_options -placement false
place_opt -effort high -congestion -area_recovery
create_fp_placement -congestion_driven -effort high -timing_driven
preroute_standard_cells \
	-nets {VDD VSS} \
	-connet horizontal \
	-do_not_route_over_macros \
	-remove_floating_pieces
derive_pg_connection \
	-power_net VDD -power_pin VDD 
	-ground_net VSS -ground_pin VSS
derive_pg_connection \
	-power_net VDD -ground_net VSS -tie 
verify_pg_nets
derive_pg_connection \
	-power_net DVDD -power_pin DVDD \
	-ground_net DVSS -ground_pin DVSS
derive_pg_connection \
	-power_net DVDD -ground_net DVSS -tie
connect_tie_cells \
	-objects [get_cells -hierarchical *] \
	-obj_type cell_inst \
	-tie_high_lib_cell TIEH_HVT -tie_low_lib_cell TIEL_HVT \
	-max_fanout 5
legalize_placement -incremental
verify_pg_nets
set_route
source $antenna
route_opt -effort high -area_recovery -optimize_wire_via
insert_stdcell_filler \
	-cell_with_metal $fillers \
	-cell_without_metal $fillers \
	-randomize \
	-dont_respect_hard_placement_blockage \
	-dont_respect_soft_placement_blockage \
	-connect_to_power {VDD} \
	-connect_to_ground {VSS}
derive_pg_connection \
	-power_net VDD -power_pin VDD \
	-ground_net VSS -ground_pin VSS
verify_pg_nets
verify_route
verify_zrt_route
verify_lvs -max_error 1000
route_zrt_detail -incremental true -initial_drc_from_input true
verify_lvs -check_short_locator -check_open_locator
change_names -rules verilog -hierarchy
define_name_rules MI -case_insensitive 
change_names -rules MI -hierarchy -verbose
define_name_rules NET_PORT -equal_ports_nets 
change_names -rules NET_PORT -hierarchy -verbose
write_verilog \
	-no_corner_pad_cells \
	-no_pad_filler_cells -no_core_filler_cells \
	-force_no_output_references \
	-verilog_file ../icc/${top_entry}_routed.v
set write_sdc_output_lumped_net_capacitance false
set write_sdc_output_net_resistance false
extract_rc -coupling_cap
update_timing
write_parasitics -output ../icc/${top_entry}_routed.spef
write_sdf ../icc/${top_entry}_routed.sdf
write_sdc ../icc/${top_entry}_routed.sdc
set_write_stream_options \
	-child_depth 255 \
	-map_layer $ref_map \
	-keep_data_type \
	-max_name_length 255 \
	-output_net_name_as_property 1 \
	-output_instance_name_as_property 1 \
	-output_pin {geometry text}
write_stream -cells ${top_entry} -format gds ../icc/${top_entry}.gds


 */



`timescale 10ns/1ps

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

reg [7:0] ram[0:(1<<(AMSB+1))-1];
reg [15:0] rom[0:(1<<(PMSB+1))-1];

reg loader_ram, loader_rom;
reg [AMSB:0] loader_addr;
reg [DMSB:0] loader_wdata;
reg [PMSB:0] loader_pc;
reg [IMSB:0] loader_inst;

wire write, sel;
wire [DMSB:0] wdata;
wire [AMSB:0] addr;
wire [PMSB:0] pc;
reg [DMSB:0] rdata;
reg [IMSB:0] inst;
wire idle;

cpu #(
	.IMSB ( IMSB ), 
	.PMSB ( PMSB ), 
	.AMSB ( AMSB ), 
	.DMSB ( DMSB )
) u_cpu(
	.idle(idle), 
	.write(write), .sel(sel), 
	.rdata(rdata), .wdata(wdata), 
	.addr(addr), 
	.inst(inst), 
	.pc(pc), 
	.rstn(rstn), .setn(setn), .clk(clk) 
);

always@(negedge rstn or posedge clk) begin
	if(!rstn) begin
		rdata = 0;
		inst = 0;
	end
	else begin
		fork
		begin
			//#0.1;
			fork
			if(sel) rdata = ram[addr];
			inst = rom[pc];
			join
		end
		begin
			fork
			if(loader_ram) ram[loader_addr] = loader_wdata;
			if(loader_rom) rom[loader_pc] = loader_inst;
			if(sel && write) ram[addr] = wdata;
			join
		end
		join
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
			loader_inst = {(DMSB+1){1'b1}} & pdata;
			$fscanf(out_fp, "%c", pdata);
			loader_inst = loader_inst | (({(DMSB+1){1'b1}} & pdata) << (IMSB-DMSB));
			@(posedge clk);
			loader_pc = loader_pc + 1;
		end
		loader_rom = 0;
		repeat(2) @(negedge clk); rstn = 0;
	end
endtask

task print_cpu_state;
	$write("rdata = 0x%02x, ", rdata);
	$write("wdata = 0x%02x, ", wdata);
	$write("addr = 0x%02x, ", addr);
	$write("pc = 0x%02x, ", pc);
	$write("inst = %016b, %04x, ", inst, inst);
	$write("%s\n", line);
endtask

reg [IMSB:0] cur_inst;
wire xor_inst = setn ? (inst != cur_inst) : (loader_inst != cur_inst);
always@(posedge xor_inst or posedge rstn) begin
	debug_line(setn ? pc : loader_pc);
	#0.1 cur_inst = setn ? inst : loader_inst;
end

task load_inst;
	begin
		$write("load inst\n");
		repeat(2) @(posedge clk); rstn = 1;
		repeat(2) @(posedge clk); setn = 1;
		do begin
			print_cpu_state;
			@(posedge clk);
		end while(!idle);
		repeat(2) @(posedge clk); setn = 0;
		repeat(2) @(posedge clk); rstn = 0;
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



module dsm (
	output sdo, 
	input signed [15:0] din, 
	input rstn, setn, ock, uck 
);

reg [15:0] undersampled_din;
reg [15:0] sigma;
wire [15:0] delta = sdo ? 
	((sigma == 16'hffff) ? 16'h8000 : 16'h0001) : 
	((sigma == 16'h0000) ? 16'h8000 : 16'hffff);
assign sdo = undersampled_din > sigma;

always@(negedge rstn or posedge uck) begin
	if(!rstn) undersampled_din <= 16'h8000;
	else if(setn) undersampled_din <= 16'h8000 + din;
end

always@(negedge rstn or posedge ock) begin
	if(!rstn) sigma <= 16'h8000;
	else if(setn) sigma <= (sigma - undersampled_din) + delta;
end

endmodule
