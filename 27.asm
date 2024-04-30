alu_x.macro alu zero_y, inv_y
alu_y.macro alu zero_x, inv_x
alu_y-1.macro alu zero_x, inv_x, add
alu_+.macro alu add
.data
k.byte
-10,
.endbyte
c.byte
1,
.endbyte
a.byte
1,
.endbyte
b.byte
0,
.endbyte
.enddata
.text
fibonacci.begin
for_load.begin
	inum 8. dst d.
	byte k. dst a.
	dst w.
	begin for_loop. dst a.
.end
for_loop.begin
* b = a; a = c;
shift.begin
	byte a. dst a.
	src m. macro alu_x.. dst d.
	byte b. dst a.
	macro alu_y.. dst d, w.
	byte c. dst a.
	src m. macro alu_x.. dst d.
	byte a. dst a.
	macro alu_y.. dst d, w.
.end
* c = a + b;
add.begin
	byte a. dst a.
	src m. macro alu_x.. dst d.
	byte b. dst a.
	src m. macro alu_+.. dst d.
	byte c. dst a.
	macro alu_y.. dst d, w.
.end
* k--; 
count.begin
	byte k. dst a.
	src m. macro alu_x.. dst d.
	begin for_done. dst a.
	macro alu_y.. jmp eq lt. 
	byte k. dst a.
	macro alu_y-1.. dst d, w. 
	begin for_loop. dst a.
	jmp eq, lt, gt. 
.end
.end
for_done.begin
	byte c. dst a.
	src m. macro alu_x.. dst d.
.end
.end
.endtext
