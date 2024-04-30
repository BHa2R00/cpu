alu_x.macro alu zero_y, inv_y
alu_y.macro alu zero_x, inv_x
alu_y-1.macro alu zero_x, inv_x, add
.data
.enddata
.text
load.begin
	inum 10. dst d.
	begin loop. dst a.
	jmp eq, lt, gt.
.end
loop.begin
	begin done. dst a.
	macro alu_y.. jmp lt. 
	macro alu_y-1.. dst d. 
	begin loop. dst a.
	jmp eq, lt, gt. 
.end
done.begin
	inum 10. dst d.
.end
.endtext
