#include <stdio.h>
#include <string.h>

#define AMSB 7 
#define DMSB 7 
#define PMSB 7 
#define IMSB 15 

#define new_string(__len) (char*)malloc(sizeof(char)*(__len+1));

/*char* bstr(short b){
	char* buf = new_string(17);
	short b1 = b;
	int k;
	for(k = 0; k <= 31; k++){
		if(b1 & 0x8000) buf[k] = '1';
		else buf[k] = '0';
		b1 = b1 << 1;
	}
	buf[16] = '\0';
	return buf;
}*/

char* line_cdr(char* matcher, char* buf){ 
	char* b = new_string(strlen(buf));
	b = strstr(buf, matcher); 
	return b;
}

char* line_car(char* matcher, char* buf){
	char* b = new_string(strlen(buf));
	char* m = line_cdr(matcher, buf);
	if(m != NULL){
		int len = m - buf;
		b[len] = '\0';
		strncpy(b, buf, len);
		return b;
	}
	else return m;
}

char* macro[(1<<(DMSB+1))]; char* macro_body[(1<<(DMSB+1))]; int macro_len = 0;

char* get_macro_body(char* name){
	char* b;
	for(int k=0; k < macro_len; k++){
		if(strcmp(name, macro[k]) == 0){
			b = macro_body[k];
		}
	}
	return b;
}

char* line_expand_macro(char* line){
	char* b0 = new_string((strlen(line)<<2));
	char* b = new_string(strlen(line));
	strcpy(b0, line);
	strcpy(b, line);
	char* line0 = new_string(strlen(line));
	do{
		b = line_cdr("macro ", b);
		if(b != NULL){
			b = line_cdr(" ", b);
			while(b[0] == ' ' || b[0] == '	') b++;
			line0 = line_car(".", b);
			if(line0 != NULL){
				char* body = get_macro_body(line0);
				char* p0 = strstr(b0, "macro ");
				char* p1 = strstr(p0, ".")+1;
				size_t len = strlen(body) + strlen(p1) + 1;
				char* b2 = new_string(len);
				strcpy(b2, body);
				b2[strlen(b2)] = '\0';
				strcat(b2, p1);
				memcpy(p0-1, b2, len-1);
				free(b2);
			}
			b = line_cdr(".", b);
		}
	}while(line0 != NULL && b != NULL);
	if(strcmp(b0, line) == 0) return line;
	else return line_expand_macro(b0);
}

char* byte[(1<<(AMSB+1))]; unsigned char byte_addr[(1<<(AMSB+1))]; int byte_len = 0;

unsigned char get_byte_addr(char* name){
	unsigned char a = -1;
	for(int k=0; k < byte_len; k++){
		if(strcmp(name, byte[k]) == 0){
			a = byte_addr[k];
		}
	}
	return a;
}

char* begin[(1<<(PMSB+1))]; unsigned char begin_pc[(1<<(PMSB+1))]; int begin_len = 0;

unsigned char get_begin_pc(char* name){
	unsigned char a = -1;
	for(int k=0; k < begin_len; k++){
		if(strcmp(name, begin[k]) == 0){
			a = begin_pc[k];
		}
	}
	return a;
}

unsigned char ram[(1<<(AMSB+1))];
unsigned short rom[(1<<(PMSB+1))];

void mark0(FILE* debug_fp, FILE* in_fp){
	unsigned int pc = 0;
	unsigned int addr = 0;
	char data = 0;
	char line_st = 0;
	while(!feof(in_fp)){
		char* line = new_string((1<<(DMSB+1)));
		fgets(line, (1<<(DMSB+1))+1, in_fp);
		line[strlen(line)-1] = '\0';
		while(line[0] == ' ' || line[0] == '	') line++;
		//printf("mark0: %s\n", line);
		if(line[0] == '*'){ ; }
		else if((line[0] == '.') || (line[0] >= 33 && line[0] <= 126)){
			if(line_cdr(".macro", line) != NULL){ 
				//printf("mark0 .macro: %s\n", line);
				macro[macro_len] = new_string(strlen(line));
				strcpy(macro[macro_len], line_car(".", line));
				macro_body[macro_len] = new_string(strlen(line));
				strcpy(macro_body[macro_len], line_cdr(" ", line_cdr(".macro", line)));
				macro_len++;
			}
			else if(line_cdr(".data", line) != NULL){ 
				//printf("mark0 .data: %s\n", line);
				line_st--; 
				for(int k = 0; k < (1<<(AMSB+1)); k++) ram[k] = 0;
			}
			else if(line_cdr(".enddata", line) != NULL){ line_st++; }
			else if(line_cdr(".byte", line) != NULL){ 
				//printf("mark0 .byte: %s\n", line);
				line_st--; 
				byte[byte_len] = new_string(strlen(line));
				byte[byte_len] = line_car(".", line);
				byte_addr[byte_len] = addr;
				byte_len++;
			}
			else if(line_cdr(".endbyte", line) != NULL){ line_st++; }
			else if(line_cdr(".text", line) != NULL){ 
				//printf("mark0 .text: %s\n", line);
				line_st++; 
				for(int k = 0; k < (1<<(PMSB+1)); k++) rom[k] = 0;
			}
			else if(line_cdr(".endtext", line) != NULL){ line_st--; }
			else if(line_cdr(".begin", line) != NULL){ 
				//printf("mark0 .begin: %s\n", line);
				line_st++; 
				begin[begin_len] = new_string(strlen(line));
				begin[begin_len] = line_car(".", line);
				begin_pc[begin_len] = pc;
				begin_len++;
			}
			else if(line_cdr(".end", line) != NULL){ line_st--; }
			else if(line_st <= -2){
				char* line0 = new_string(strlen(line));
				char* line1 = new_string(strlen(line));
				do{
					line0 = line_car(",", line);
					line1 = line_cdr(",", line); if(line1 != NULL) line1++;
					if(line0 != NULL){
						while(line0[0] == ' ' || line0[0] == '	') line0++;
						addr++;
					}
					line = line_cdr(",", line); if(line != NULL) line++;
				}while((line0 != NULL) && (line1 != NULL));
				free(line0);
				free(line1);
			}
			else if(line_st >= 2){
				char* line0 = new_string(strlen(line));
				char* line1 = new_string(strlen(line));
				do{
					line0 = line_car(".", line);
					line1 = line_cdr(".", line); if(line1 != NULL) line1++;
					if(line0 != NULL){ ; }
					line = line_cdr(".", line); if(line != NULL) line++;
				}while((line0 != NULL) && (line1 != NULL));
				free(line0);
				free(line1);
				pc++;
			}
		}
		free(line);
	}
}

void write_debug_line(FILE* debug_fp, unsigned int pc, char* line){
	int len = strlen(line);
	fprintf(debug_fp, "%c", (char)pc);
	fprintf(debug_fp, "%c", (char)len);
	fprintf(debug_fp, "%s", line);
}

void encode0(FILE* debug_fp, FILE* in_fp, FILE* out_fp){
	unsigned int pc = 0;
	unsigned int addr = 0;
	char data = 0;
	char line_st = 0;
	unsigned short inst = 0;
	char inst_num;
	while(!feof(in_fp)){
		char* line = new_string((1<<(DMSB+1)));
		fgets(line, (1<<(DMSB+1))+1, in_fp);
		line[strlen(line)-1] = '\0';
		while(line[0] == ' ' || line[0] == '	') line++;
		//printf("encode0: %s\n", line);
		if(line[0] == '*'){
			write_debug_line(debug_fp, pc, line);
		}
		else if((line[0] == '.') || (line[0] >= 33 && line[0] <= 126)){
			write_debug_line(debug_fp, pc, line);
			if(line_cdr(".macro", line) != NULL){ 
				char* b = new_string(strlen(line));
				b = line_car(".", line);
				free(b);
			}
			else if(line_cdr(".data", line) != NULL){ line_st--; }
			else if(line_cdr(".enddata", line) != NULL){ line_st++; }
			else if(line_cdr(".byte", line) != NULL){ 
				line_st--; 
				char* b = new_string(strlen(line));
				b = line_car(".", line);
				free(b);
			}
			else if(line_cdr(".endbyte", line) != NULL){ line_st++; }
			else if(line_cdr(".text", line) != NULL){ line_st++; }
			else if(line_cdr(".endtext", line) != NULL){ line_st--; }
			else if(line_cdr(".begin", line) != NULL){ line_st++; }
			else if(line_cdr(".end", line) != NULL){ line_st--; }
			else if(line_st <= -2){
				char* line0 = new_string(strlen(line));
				char* line1 = new_string(strlen(line));
				do{
					line0 = line_car(",", line);
					line1 = line_cdr(",", line); if(line1 != NULL) line1++;
					if(line0 != NULL){
						while(line0[0] == ' ' || line0[0] == '	') line0++;
						if(line_cdr("\"", line0) != NULL){
							char* b = new_string(strlen(line));
							sscanf(line0, "\"%s\"", b);
							b[strlen(b)-1] = '\0';
							for(int k = 0; k < strlen(b); k++){
								ram[addr] = *(b+k);
								addr++;
							}
							free(b);
						}
						else if(line_cdr("'", line0) != NULL){
							sscanf(line0, "'%c'", &data);
							ram[addr] = data;
							addr++;
						}
						else if(line_cdr("0x", line0) != NULL){
							sscanf(line0, "0x%x", &data);
							ram[addr] = data;
							addr++;
						}
						else {
							sscanf(line0, "%d", &data);
							ram[addr] = data;
							addr++;
						}
					}
					line = line_cdr(",", line); if(line != NULL) line++;
				}while((line0 != NULL) && (line1 != NULL));
				free(line0);
				free(line1);
			}
			else if(line_st >= 2){
				//printf("macro: %s -> ", line);
				line = line_expand_macro(line);
				//printf("%s \n", line);
				char* line0 = new_string(strlen(line));
				char* line1 = new_string(strlen(line));
				inst = 0;
				inst = inst | (0x1<<IMSB);
				do{
					line0 = line_car(".", line);
					line1 = line_cdr(".", line); if(line1 != NULL) line1++;
					if(line0 != NULL){
						while(line0[0] == ' ' || line0[0] == '	') line0++;
						if(line_cdr("dst ", line0) != NULL){
							char* b = new_string(strlen(line0));
							b = line_cdr(" ", line0);
							if(line_cdr("d", b) != NULL) inst = inst | (0x1<<(IMSB-6));
							if(line_cdr("a", b) != NULL) inst = inst | (0x1<<(IMSB-7));
							//printf("dst: %s\n", bstr(inst));
							free(b);
						}
						else if(line_cdr("src ", line0) != NULL){
							char* b = new_string(strlen(line0));
							b = line_cdr(" ", line0);
							if(line_cdr("z", b) != NULL) inst = inst | (0x3<<(IMSB-5));
							else if(line_cdr("a", b) != NULL) inst = inst | (0x1<<(IMSB-5));
							else if(line_cdr("p", b) != NULL) inst = inst | (0x2<<(IMSB-5));
							else if(line_cdr("d", b) != NULL) inst = inst | (0x0<<(IMSB-5));
							else inst = inst | (0x0<<(IMSB-5));
							//printf("src: %s\n", bstr(inst));
							free(b);
						}
						else if(line_cdr("byte ", line0) != NULL){
							inst = inst & 0xff<<(IMSB-DMSB-1);
							char* b = new_string(strlen(line0));
							b = line_cdr(" ", line0);
							while(b[0] == ' ' || b[0] == '	') b++;
							inst_num = get_byte_addr(b);
							inst = inst | (((1<<(DMSB+1))-1) & inst_num);
							inst = inst & ~(0x1<<IMSB);
							//printf("byte: %x\n", inst);
							free(b);
						}
						else if(line_cdr("begin ", line0) != NULL){
							inst = inst & 0xff<<(IMSB-DMSB-1);
							char* b = new_string(strlen(line0));
							b = line_cdr(" ", line0);
							while(b[0] == ' ' || b[0] == '	') b++;
							inst_num = get_begin_pc(b);
							inst = inst | (((1<<(DMSB+1))-1) & inst_num);
							inst = inst & ~(0x1<<IMSB);
							//printf("begin: %x\n", inst);
							free(b);
						}
						else if(line_cdr("inum ", line0) != NULL){
							inst = inst & 0xff<<(IMSB-DMSB-1);
							char* b = new_string(strlen(line0));
							b = line_cdr(" ", line0);
							while(b[0] == ' ' || b[0] == '	') b++;
							if(b[0] == '\'') sscanf(b, "'%c'.", &inst_num);
							else sscanf(b, "%d.", &inst_num);
							inst = inst | (((1<<(DMSB+1))-1) & inst_num);
							inst = inst & ~(0x1<<IMSB);
							//printf("inum: %x\n", inst);
							free(b);
						}
						else if(line_cdr("alu ", line0) != NULL){
							char* b = new_string(strlen(line0));
							b = line_cdr(" ", line0);
							if(line_cdr("inv_z", b) != NULL) inst = inst | (0x1<<7);
							if(line_cdr("rbo_z", b) != NULL) inst = inst | (0x1<<6);
							if(line_cdr("shl_z", b) != NULL) inst = inst | (0x1<<5);
							if(line_cdr("add", b) != NULL) inst = inst | (0x1<<4);
							if(line_cdr("inv_x", b) != NULL) inst = inst | (0x1<<3);
							if(line_cdr("inv_y", b) != NULL) inst = inst | (0x1<<2);
							if(line_cdr("zero_x", b) != NULL) inst = inst | (0x1<<1);
							if(line_cdr("zero_y", b) != NULL) inst = inst | (0x1<<0);
							//printf("alu: %s\n", bstr(inst));
							free(b);
						}
						else if(line_cdr("jmp ", line0) != NULL){
							char* b = new_string(strlen(line0));
							b = line_cdr(" ", line0);
							if(line_cdr("eq", b) != NULL) inst = inst | (0x1<<(IMSB-3));
							if(line_cdr("lt", b) != NULL) inst = inst | (0x1<<(IMSB-2));
							if(line_cdr("gt", b) != NULL) inst = inst | (0x1<<(IMSB-1));
							//printf("jmp: %x\n", inst);
							free(b);
						}
					}
					line = line_cdr(".", line); if(line != NULL) line++;
				}while((line0 != NULL) || (line1 != NULL));
				free(line0);
				free(line1);
				rom[pc] = inst;
				pc++;
			}
		}
		free(line);
	}
	fwrite(&ram, sizeof(unsigned char), (1<<(AMSB+1)), out_fp);
	fwrite(&rom, sizeof(unsigned short), (1<<(PMSB+1)), out_fp);
}

void asm0(char* debug_file, char* in_file, char* out_file){
	FILE* in_fp;
	FILE* out_fp;
	FILE* debug_fp;
	debug_fp = fopen(debug_file, "wb"); 
	in_fp = fopen(in_file, "r"); 
	fprintf(debug_fp, "%s\n", in_file);
	fprintf(debug_fp, "%s\n", out_file);
	mark0(debug_fp, in_fp); 
	fclose(in_fp);
	in_fp = fopen(in_file, "r"); out_fp = fopen(out_file, "wb");
	encode0(debug_fp, in_fp, out_fp); 
	fclose(out_fp); fclose(in_fp);
	fclose(debug_fp);
}

int main(int argc, char** argv){
	int i;
	char* out_file = "a.bin";
	char* asm0_file = "no input file";
	char* debug_file = "a.debug";
	for(i = 1; i < argc; i++){
		if(strcmp(argv[i], "-o") == 0){
			out_file = argv[i+1];
		}
		else if(strcmp(argv[i], "-asm0") == 0){
			asm0_file = argv[i+1];
		}
		else if(strcmp(argv[i], "-d") == 0){
			debug_file = argv[i+1];
		}
	}
	if(strcmp(asm0_file, "no input file") != 0){
		asm0(debug_file, asm0_file, out_file);
	}
	else {
		printf("-o <output_bin>, a.bin by default\n");
		printf("-asm0 <input_asm0>\n");
		printf("-d <debug_db>, a.debug by default\n");
	}
	return 0;
}
