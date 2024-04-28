alu_x.macro alu zero_y, inv_y
.data
a.byte
"urmom!",
0xab, -3,
"Shit",' ',"abc",
.endbyte
.enddata
.text
main.begin
	inum 'R'. dst a, d. 
	inum 'C'. dst d. 
	inum 'L'. 
	inum 'A'. dst a. 
	inum 'r'. dst d. 
	inum 0x0a. dst a. 
	src z. macro alu_x.. dst w. 
	inum 'c'. dst d. 
.end
.endtext
