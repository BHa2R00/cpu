* common operators 
alu_x^y.macro alu
alu_x+y.macro alu add
alu_0.macro macro alu_x^y. zero_x
alu_0_1.macro macro alu_x^y. zero_y
alu_0_2.macro macro alu_x^y. zero_x, zero_y
alu_~x^y.macro macro alu_x^y. inv_x
alu_y.macro macro alu_x^y. inv_x, zero_x
alu_0_3.macro macro alu_x^y. inv_x, zero_y
alu_0_4.macro macro alu_x^y. inv_x, zero_x, zero_y
alu_x^~y.macro macro alu_x^y. inv_y
alu_0_5.macro macro alu_x^y. inv_y, zero_x
alu_x.macro macro alu_x^y. inv_y, zero_y
alu_0_6.macro macro alu_x^y. inv_y, zero_x, zero_y
alu_x~vy.macro macro alu_x^y. inv_x, inv_y



.data


a.byte
1,
.endbyte


b.byte
1,
.endbyte


c.byte
1,
.endbyte


.enddata



.text


main.begin
	macro alu_0_5.. w. dst a.
	inst 9. dst a.
	byte c. 
	macro alu_x~vy.. 
	begin f1.
	jmp eq.
.end

f1.begin
	begin main.
	jmp eq.
end


.endtext
