alu_x.macro alu zero_y, inv_y
alu_y.macro alu zero_x, inv_x
alu_+.macro alu add
alu_x-1.macro macro alu_+., zero_y, inv_y
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
* fibonacci
for_load.begin
	byte k. dst a.
	inum 8. dst a, d.
.end
* b = a; a = c;
shift.begin
	byte a. dst a.
	byte a. dst a.
	macro alu_y..
	byte b. dst a.
	macro alu_x.. dst a, d.
	byte c. dst a.
	byte c. dst a.
	macro alu_y..
	byte a. dst a.
	macro alu_y.. dst a, d.
.end
* c = a + b;
add.begin
	byte a. dst a.
	byte a. dst a.
	macro alu_y..
	byte b. dst a.
	byte b. dst a.
	macro alu_+..
	byte c. dst a.
	macro alu_x.. dst a, d.
.end
* k--; 
count.begin
	byte k. dst a.
	byte k. dst a.
	macro alu_y.. dst d.
	begin for_done.
	src d. macro alu_x.. jmp eq lt.
	byte k. dst a.
	macro alu_x-1.. dst a, d.
	begin shift.
	src d. macro alu_x.. jmp eq, lt, gt.
.end
for_done.begin
	byte c. dst a.
	byte c. dst a.
.end
.endtext
