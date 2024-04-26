
op1.macro alu rbo_z, shl_z, inv_x, inv_y, zero_x, zero_y
op2.macro macro op1., inv_z, add


.data 

a.byte
12, 45, -78, 
'a', -33, 'B', 
.endbyte

b.byte
"urmom", 
0x12, "shit", 
.endbyte

.enddata


.text 

* here is the comment 1
* here is the comment 2 

f1.begin 
	w. dst a, d. src_y m. src_x d. macro op1..
	dst a, d. src_y m. src_x a. alu rbo, shl, inv_x, inv_y, zero_x, zero_y. 
	dst a, d. src_y m. src_x p. macro op2.. 
	w. dst a, d. src_y m. src_x z. inst 123. 
	jmp eq, lt, gt. src_y m. begin f1. 
	w. dst a, d. src_y m. src_x inst. byte a. 
.end

.endtext 
