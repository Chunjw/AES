module AES(
	input 			i_Clk	,
	input 			i_Reset	,
	input 			i_Start	,
	input 			i_Dec	,
	input [127:0] 	i_Data	,
	input [127:0] 	i_Key	,
	
	output [127:0] 	o_Data	,
	output 			o_fDone	,
	output 			o_fBusy
	);

//register
	reg	[127:0]	n_data, c_data	;
	reg	[127:0]	n_key, c_key	;
	reg	[127:0]	roundkey		;
	reg	[  1:0] n_state, c_state;
	reg	[  3:0] n_round, c_round;
	reg [ 31:0] rotation_in		;
	reg [  7:0] Rcon			;
	
	
	
	//wire encryption
	wire [127:0] sbox_in,		sbox_out			;
	wire [  7:0] s_box[15:0][15:0]					;
	wire [  7:0] inv_s_box[15:0][15:0]				;
	wire [127:0] shiftrow_in, 	shiftrow_out		;
	wire [127:0] mixcolumn_in, 	mixcolumn_out		;
	wire [127:0] addkey_in, 	addkey_out			;								
	
	//wire decryption
	wire [127:0] inv_sbox_in							;
	wire [127:0] inv_sbox_out							;
	wire [127:0] inv_shiftrow_in, 	inv_shiftrow_out	;
	wire [127:0] inv_mixcolumn_in, 	inv_mixcolumn_out	;
	wire [127:0] inv_addkey_in, 	inv_addkey_out		;
	
	//wire key 
	wire [31:0] rotation_out	;
	wire [31:0] key_sbox_in		;
	wire [31:0] key_sbox_out	;
	wire [31:0] use_for_key		;
	
	
	//patameter
	parameter	IDLE = 2'b00, KEY = 2'b10, ROUND = 2'b01, END = 2'b11;
	
	assign o_fDone 	= (c_state == END ) 					? 1 : 0;
	assign o_fBusy 	= (c_state == ROUND || c_state == KEY) 	? 1 : 0;
	assign o_Data 	= (c_state == END) 						? c_data : 0;
	
	//FlipFlop
	always @(posedge i_Clk or negedge i_Reset)	begin
		if(!i_Reset)	begin
			c_state = IDLE;
			c_round = 0;
			c_data 	= 0;
			c_key 	= 0;
		end
		else	begin
			c_state	= n_state;
			c_round	= n_round;
			c_data 	= n_data;
			c_key 	= n_key	;
		end
	end
	
	
	always @(*)	begin
		n_round = 0;
		case(c_state)
			KEY : begin
				if(c_round	==	4'd9)	n_round	= c_round;
				else					n_round = c_round + 1;
			end
			ROUND :	begin
				if(!i_Dec)				n_round	= c_round + 1;
				else					n_round	= c_round - 1;
			end
		endcase
	end
	
	
	always @(*)	begin
		n_state	= c_state;
		case(c_state)
			IDLE 	: begin
				if(i_Start)	begin
					if(!i_Dec)							n_state	= ROUND;
					else								n_state	= KEY;
				end
			end
			KEY		: if(c_round == 4'd9) 				n_state	= ROUND; 
			ROUND 	: begin
				if (!i_Dec & c_round == 4'd9)			n_state = END; 
				else if (i_Dec & c_round == 4'd0)		n_state = END; 
			end
			END 	: 									n_state = IDLE;
		endcase
	end
	
	
	//////////////////////////////////////// encryption text operation ////////////////////////////////////////////////////////////////
	always @(*)	begin
		n_data = c_data;
		case(c_state)
			IDLE 	: if(!i_Dec)				n_data = i_Data ^ i_Key;
			KEY	 	: if(c_round == 4'd9)		n_data = i_Data ^ roundkey;
			ROUND 	: begin
				if(!i_Dec)	n_data = addkey_out;
				else	begin
					if(c_round	==	0)			n_data = inv_addkey_out; 
					else						n_data = inv_mixcolumn_out;
				end
			end
		endcase
	end
	
	assign sbox_in = c_data;
	//DATA sbox0 (sbox_in[127:0], sbox_out[127:0]);
	assign sbox_out = {	{s_box[sbox_in[123:120]][sbox_in[127:124]], s_box[sbox_in[115:112]][sbox_in[119:116]], s_box[sbox_in[107:104]][sbox_in[111:108]], s_box[sbox_in[ 99: 96]][sbox_in[103:100]]},
	                  	{s_box[sbox_in[ 91: 88]][sbox_in[ 95: 92]], s_box[sbox_in[ 83: 80]][sbox_in[ 87: 84]], s_box[sbox_in[ 75: 72]][sbox_in[ 79: 76]], s_box[sbox_in[ 67: 64]][sbox_in[ 71: 68]]},
	                  	{s_box[sbox_in[ 59: 56]][sbox_in[ 63: 60]], s_box[sbox_in[ 51: 48]][sbox_in[ 55: 52]], s_box[sbox_in[ 43: 40]][sbox_in[ 47: 44]], s_box[sbox_in[ 35: 32]][sbox_in[ 39: 36]]},
	                  	{s_box[sbox_in[ 27: 24]][sbox_in[ 31: 28]], s_box[sbox_in[ 19: 16]][sbox_in[ 23: 20]], s_box[sbox_in[ 11:  8]][sbox_in[ 15: 12]], s_box[sbox_in[  3:  0]][sbox_in[  7:  4]]}};
	
	
	assign shiftrow_in = sbox_out;
	assign shiftrow_out = {	shiftrow_in[127:120], shiftrow_in[ 87: 80], shiftrow_in[ 47: 40], shiftrow_in[  7: 0],
							shiftrow_in[ 95: 88], shiftrow_in[ 55: 48], shiftrow_in[ 15:  8], shiftrow_in[103:96],
							shiftrow_in[ 63: 56], shiftrow_in[ 23: 16], shiftrow_in[111:104], shiftrow_in[ 71:64],
							shiftrow_in[ 31: 24], shiftrow_in[119:112], shiftrow_in[ 79: 72], shiftrow_in[ 39:32]};
		
	assign mixcolumn_in = shiftrow_out;
	MixColumns	mix0 (mixcolumn_in[127:96], mixcolumn_out[127:96]);
	MixColumns	mix1 (mixcolumn_in[ 95:64], mixcolumn_out[ 95:64]);
	MixColumns	mix2 (mixcolumn_in[ 63:32], mixcolumn_out[ 63:32]);
	MixColumns	mix3 (mixcolumn_in[ 31: 0], mixcolumn_out[ 31: 0]);
	
	assign addkey_in = (c_round == 4'd9) ? shiftrow_out : mixcolumn_out;
	assign addkey_out = addkey_in ^ roundkey;
	
	////////////////////////////////////////////////decruption text operation///////////////////////////////////////////////////////////
	
	assign inv_sbox_in = c_data;
	//InvSBOX inv_sbox0 (inv_sbox_in[127:0], inv_sbox_out[127:0]);
	assign inv_sbox_out = {	{inv_s_box[sbox_in[123:120]][sbox_in[127:124]], inv_s_box[sbox_in[115:112]][sbox_in[119:116]], inv_s_box[sbox_in[107:104]][sbox_in[111:108]], inv_s_box[sbox_in[ 99: 96]][sbox_in[103:100]]},
	             			{inv_s_box[sbox_in[ 91: 88]][sbox_in[ 95: 92]], inv_s_box[sbox_in[ 83: 80]][sbox_in[ 87: 84]], inv_s_box[sbox_in[ 75: 72]][sbox_in[ 79: 76]], inv_s_box[sbox_in[ 67: 64]][sbox_in[ 71: 68]]},
	              			{inv_s_box[sbox_in[ 59: 56]][sbox_in[ 63: 60]], inv_s_box[sbox_in[ 51: 48]][sbox_in[ 55: 52]], inv_s_box[sbox_in[ 43: 40]][sbox_in[ 47: 44]], inv_s_box[sbox_in[ 35: 32]][sbox_in[ 39: 36]]},
	              			{inv_s_box[sbox_in[ 27: 24]][sbox_in[ 31: 28]], inv_s_box[sbox_in[ 19: 16]][sbox_in[ 23: 20]], inv_s_box[sbox_in[ 11:  8]][sbox_in[ 15: 12]], inv_s_box[sbox_in[  3:  0]][sbox_in[  7:  4]]}};
	
	assign inv_shiftrow_in = inv_sbox_out;
	assign inv_shiftrow_out	= {inv_shiftrow_in[127:120], inv_shiftrow_in[ 23: 16], inv_shiftrow_in[ 47: 40], inv_shiftrow_in[ 71: 64],
							   inv_shiftrow_in[ 95: 88], inv_shiftrow_in[119:112], inv_shiftrow_in[ 15:  8], inv_shiftrow_in[ 39: 32],
							   inv_shiftrow_in[ 63: 56], inv_shiftrow_in[ 87: 80], inv_shiftrow_in[111:104], inv_shiftrow_in[  7:  0],
							   inv_shiftrow_in[ 31: 24], inv_shiftrow_in[ 55: 48], inv_shiftrow_in[ 79: 72], inv_shiftrow_in[103:96]};
	
	assign inv_addkey_in = inv_shiftrow_out;
	assign inv_addkey_out = inv_addkey_in ^ c_key;
		
	assign inv_mixcolumn_in = inv_addkey_out;
	InvMixColumns inv_mix0 (inv_mixcolumn_in[127:96], inv_mixcolumn_out[127:96]);
	InvMixColumns inv_mix1 (inv_mixcolumn_in[ 95:64], inv_mixcolumn_out[ 95:64]);
	InvMixColumns inv_mix2 (inv_mixcolumn_in[ 63:32], inv_mixcolumn_out[ 63:32]);
	InvMixColumns inv_mix3 (inv_mixcolumn_in[ 31: 0], inv_mixcolumn_out[ 31: 0]);
	
	///////////////////////////////////////////////key generation operation/////////////////////////////////////////////////
	
	always @(*)	begin
		rotation_in = c_key[31:0];
		if(i_Dec && c_state == ROUND )	rotation_in = c_key[63:32] ^ c_key[31:0];
	end
	
	assign	rotation_out = {rotation_in[23:0], rotation_in[31:24]};  	
	
	assign key_sbox_in = rotation_out;
	/*SBOX key_sbox0 (key_sbox_in[31:24], key_sbox_out[31:24]);
	SBOX key_sbox1 (key_sbox_in[23:16], key_sbox_out[23:16]);
	SBOX key_sbox2 (key_sbox_in[15: 8], key_sbox_out[15: 8]);
	SBOX key_sbox3 (key_sbox_in[ 7: 0], key_sbox_out[ 7: 0]);*/
	
	assign key_sbox_out = {{s_box[key_sbox_in[ 27: 24]][key_sbox_in[ 31: 28]], s_box[key_sbox_in[ 19: 16]][key_sbox_in[ 23: 20]], s_box[key_sbox_in[ 11:  8]][key_sbox_in[ 15: 12]], s_box[key_sbox_in[  3:  0]][key_sbox_in[  7:  4]]}};
	
	//roundkey//
	always @(*)	begin
		n_key = roundkey;
		case(c_state)
			IDLE : n_key = i_Key;
			KEY	: if(c_round == 9)	n_key = c_key; 
			endcase
	end

//	assign use_for_key = {(key_sbox_out[31:24] ^ Rcon), key_sbox_out[23:0]};
	
	always @(*)	begin
		roundkey[127:96] = {(key_sbox_out[31:24] ^ Rcon), key_sbox_out[23:0]} ^ c_key[127:96];	
//		roundkey[127:96] = use_for_key										  ^ c_key[127:96];	
		roundkey[ 95:64] = roundkey[127:96]   								  ^ c_key[ 95:64];
		roundkey[ 63:32] = roundkey[ 95:64]   								  ^ c_key[ 63:32];
		roundkey[ 31: 0] = roundkey[ 63:32]  							   	  ^ c_key[ 31: 0];	
		case(c_state)
			ROUND : begin	
				if(i_Dec)	begin
					roundkey[127:96] = {(key_sbox_out[31:24] ^ Rcon), key_sbox_out[23:0]} ^ c_key[127:96];
//					roundkey[127:96] = use_for_key									  ^ c_key[127:96];	
					roundkey[ 95:64] = c_key[127:96]   								  ^ c_key[ 95:64];
					roundkey[ 63:32] = c_key[ 95:64]   								  ^ c_key[ 63:32];
					roundkey[ 31: 0] = c_key[ 63:32]   								  ^ c_key[ 31: 0];
				end
			end
		endcase
	end
	
	always @(*)	begin
		Rcon = 0;
		case(c_round)
			0	:	Rcon	=	8'b00000001;
			1	:	Rcon	=	8'b00000010;
			2	:	Rcon	=	8'b00000100;
			3	:	Rcon	=	8'b00001000;
			4	:	Rcon	=	8'b00010000;
			5	:	Rcon	=	8'b00100000;
			6	:	Rcon	=	8'b01000000;
			7	:	Rcon	=	8'b10000000;
			8	:	Rcon	=	8'b00011011;
			9	:	Rcon	=	8'b00110110;
		endcase
		case(c_state)
			ROUND :	begin
				if(i_Dec)	begin
					case(c_round)
						1	:	Rcon	=	8'b00000001;
						2	:	Rcon	=	8'b00000010;
						3	:	Rcon	=	8'b00000100;
						4	:	Rcon	=	8'b00001000;
						5	:	Rcon	=	8'b00010000;
						6	:	Rcon	=	8'b00100000;
						7	:	Rcon	=	8'b01000000;
						8	:	Rcon	=	8'b10000000;
						9	:	Rcon	=	8'b00011011;
					endcase
				end
			end
		endcase
	end
/*	always @(*)	begin
		roundkey[119:96] = key_sbox_out[23:0] ^ c_key[119:96];	
		roundkey[ 95:64] = roundkey[127:96]   ^ c_key[ 95:64];
		roundkey[ 63:32] = roundkey[ 95:64]   ^ c_key[ 63:32];
		roundkey[ 31: 0] = roundkey[ 63:32]   ^ c_key[ 31: 0];
		case(c_state)	
			ROUND : begin
				if(i_Dec)	begin
					roundkey[119:96] = key_sbox_out[23:0] ^ c_key[119:96];	
					roundkey[ 95:64] = c_key[127:96]      ^ c_key[ 95:64];
					roundkey[ 63:32] = c_key[ 95:64]      ^ c_key[ 63:32];
					roundkey[ 31: 0] = c_key[ 63:32]      ^ c_key[ 31: 0];
				end
			end
		endcase
	end
		
	
	always @(*)	begin
		roundkey[127:120] = 0;
		case(c_round)
						0 :	roundkey[127:120] =	key_sbox_out[31:24] ^ 8'h01 ^ c_key[127:120];
						1 :	roundkey[127:120] =	key_sbox_out[31:24] ^ 8'h02 ^ c_key[127:120];
						2 :	roundkey[127:120] =	key_sbox_out[31:24] ^ 8'h04 ^ c_key[127:120];
						3 :	roundkey[127:120] =	key_sbox_out[31:24] ^ 8'h08 ^ c_key[127:120];
						4 :	roundkey[127:120] =	key_sbox_out[31:24] ^ 8'h10 ^ c_key[127:120];
						5 :	roundkey[127:120] =	key_sbox_out[31:24] ^ 8'h20 ^ c_key[127:120];
						6 :	roundkey[127:120] =	key_sbox_out[31:24] ^ 8'h40 ^ c_key[127:120];
						7 :	roundkey[127:120] =	key_sbox_out[31:24] ^ 8'h80 ^ c_key[127:120];
						8 :	roundkey[127:120] =	key_sbox_out[31:24] ^ 8'h1b ^ c_key[127:120];
						9 :	roundkey[127:120] =	key_sbox_out[31:24] ^ 8'h36 ^ c_key[127:120];
		endcase
		case(c_state)
			ROUND : begin
				if(i_Dec)	begin
					case(c_round)
						1 :	roundkey[127:120] =	key_sbox_out[31:24] ^ 8'h01 ^ c_key[127:120];
						2 :	roundkey[127:120] =	key_sbox_out[31:24] ^ 8'h02 ^ c_key[127:120];
						3 :	roundkey[127:120] =	key_sbox_out[31:24] ^ 8'h04 ^ c_key[127:120];
						4 :	roundkey[127:120] =	key_sbox_out[31:24] ^ 8'h08 ^ c_key[127:120];
						5 :	roundkey[127:120] =	key_sbox_out[31:24] ^ 8'h10 ^ c_key[127:120];
						6 :	roundkey[127:120] =	key_sbox_out[31:24] ^ 8'h20 ^ c_key[127:120];
						7 :	roundkey[127:120] =	key_sbox_out[31:24] ^ 8'h40 ^ c_key[127:120];
						8 :	roundkey[127:120] =	key_sbox_out[31:24] ^ 8'h80 ^ c_key[127:120];
						9 :	roundkey[127:120] =	key_sbox_out[31:24] ^ 8'h1b ^ c_key[127:120];
					endcase
				end
			end
		endcase
	end*/
	
	
	
	
	
	assign {s_box[0][ 0], s_box[1][ 0], s_box[2][ 0], s_box[3][ 0], s_box[4][ 0], s_box[5][ 0], s_box[6][ 0], s_box[7][ 0], s_box[8][ 0], s_box[9][ 0], s_box[10][ 0], s_box[11][ 0], s_box[12][ 0], s_box[13][ 0], s_box[14][ 0], s_box[15][ 0],
	         s_box[0][ 1], s_box[1][ 1], s_box[2][ 1], s_box[3][ 1], s_box[4][ 1], s_box[5][ 1], s_box[6][ 1], s_box[7][ 1], s_box[8][ 1], s_box[9][ 1], s_box[10][ 1], s_box[11][ 1], s_box[12][ 1], s_box[13][ 1], s_box[14][ 1], s_box[15][ 1],
	         s_box[0][ 2], s_box[1][ 2], s_box[2][ 2], s_box[3][ 2], s_box[4][ 2], s_box[5][ 2], s_box[6][ 2], s_box[7][ 2], s_box[8][ 2], s_box[9][ 2], s_box[10][ 2], s_box[11][ 2], s_box[12][ 2], s_box[13][ 2], s_box[14][ 2], s_box[15][ 2],
	         s_box[0][ 3], s_box[1][ 3], s_box[2][ 3], s_box[3][ 3], s_box[4][ 3], s_box[5][ 3], s_box[6][ 3], s_box[7][ 3], s_box[8][ 3], s_box[9][ 3], s_box[10][ 3], s_box[11][ 3], s_box[12][ 3], s_box[13][ 3], s_box[14][ 3], s_box[15][ 3],
	         s_box[0][ 4], s_box[1][ 4], s_box[2][ 4], s_box[3][ 4], s_box[4][ 4], s_box[5][ 4], s_box[6][ 4], s_box[7][ 4], s_box[8][ 4], s_box[9][ 4], s_box[10][ 4], s_box[11][ 4], s_box[12][ 4], s_box[13][ 4], s_box[14][ 4], s_box[15][ 4],
	         s_box[0][ 5], s_box[1][ 5], s_box[2][ 5], s_box[3][ 5], s_box[4][ 5], s_box[5][ 5], s_box[6][ 5], s_box[7][ 5], s_box[8][ 5], s_box[9][ 5], s_box[10][ 5], s_box[11][ 5], s_box[12][ 5], s_box[13][ 5], s_box[14][ 5], s_box[15][ 5],
	         s_box[0][ 6], s_box[1][ 6], s_box[2][ 6], s_box[3][ 6], s_box[4][ 6], s_box[5][ 6], s_box[6][ 6], s_box[7][ 6], s_box[8][ 6], s_box[9][ 6], s_box[10][ 6], s_box[11][ 6], s_box[12][ 6], s_box[13][ 6], s_box[14][ 6], s_box[15][ 6],
	         s_box[0][ 7], s_box[1][ 7], s_box[2][ 7], s_box[3][ 7], s_box[4][ 7], s_box[5][ 7], s_box[6][ 7], s_box[7][ 7], s_box[8][ 7], s_box[9][ 7], s_box[10][ 7], s_box[11][ 7], s_box[12][ 7], s_box[13][ 7], s_box[14][ 7], s_box[15][ 7],
	         s_box[0][ 8], s_box[1][ 8], s_box[2][ 8], s_box[3][ 8], s_box[4][ 8], s_box[5][ 8], s_box[6][ 8], s_box[7][ 8], s_box[8][ 8], s_box[9][ 8], s_box[10][ 8], s_box[11][ 8], s_box[12][ 8], s_box[13][ 8], s_box[14][ 8], s_box[15][ 8],
	         s_box[0][ 9], s_box[1][ 9], s_box[2][ 9], s_box[3][ 9], s_box[4][ 9], s_box[5][ 9], s_box[6][ 9], s_box[7][ 9], s_box[8][ 9], s_box[9][ 9], s_box[10][ 9], s_box[11][ 9], s_box[12][ 9], s_box[13][ 9], s_box[14][ 9], s_box[15][ 9],
	         s_box[0][10], s_box[1][10], s_box[2][10], s_box[3][10], s_box[4][10], s_box[5][10], s_box[6][10], s_box[7][10], s_box[8][10], s_box[9][10], s_box[10][10], s_box[11][10], s_box[12][10], s_box[13][10], s_box[14][10], s_box[15][10],
	         s_box[0][11], s_box[1][11], s_box[2][11], s_box[3][11], s_box[4][11], s_box[5][11], s_box[6][11], s_box[7][11], s_box[8][11], s_box[9][11], s_box[10][11], s_box[11][11], s_box[12][11], s_box[13][11], s_box[14][11], s_box[15][11],
	         s_box[0][12], s_box[1][12], s_box[2][12], s_box[3][12], s_box[4][12], s_box[5][12], s_box[6][12], s_box[7][12], s_box[8][12], s_box[9][12], s_box[10][12], s_box[11][12], s_box[12][12], s_box[13][12], s_box[14][12], s_box[15][12],
	         s_box[0][13], s_box[1][13], s_box[2][13], s_box[3][13], s_box[4][13], s_box[5][13], s_box[6][13], s_box[7][13], s_box[8][13], s_box[9][13], s_box[10][13], s_box[11][13], s_box[12][13], s_box[13][13], s_box[14][13], s_box[15][13],
	         s_box[0][14], s_box[1][14], s_box[2][14], s_box[3][14], s_box[4][14], s_box[5][14], s_box[6][14], s_box[7][14], s_box[8][14], s_box[9][14], s_box[10][14], s_box[11][14], s_box[12][14], s_box[13][14], s_box[14][14], s_box[15][14],
	         s_box[0][15], s_box[1][15], s_box[2][15], s_box[3][15], s_box[4][15], s_box[5][15], s_box[6][15], s_box[7][15], s_box[8][15], s_box[9][15], s_box[10][15], s_box[11][15], s_box[12][15], s_box[13][15], s_box[14][15], s_box[15][15]}
	         = {{ 8'h63, 8'h7c, 8'h77, 8'h7b, 8'hf2, 8'h6b, 8'h6f, 8'hc5, 8'h30, 8'h01, 8'h67, 8'h2b, 8'hfe, 8'hd7, 8'hab, 8'h76},
	            { 8'hca, 8'h82, 8'hc9, 8'h7d, 8'hfa, 8'h59, 8'h47, 8'hf0, 8'had, 8'hd4, 8'ha2, 8'haf, 8'h9c, 8'ha4, 8'h72, 8'hc0},
	            { 8'hb7, 8'hfd, 8'h93, 8'h26, 8'h36, 8'h3f, 8'hf7, 8'hcc, 8'h34, 8'ha5, 8'he5, 8'hf1, 8'h71, 8'hd8, 8'h31, 8'h15},
	            { 8'h04, 8'hc7, 8'h23, 8'hc3, 8'h18, 8'h96, 8'h05, 8'h9a, 8'h07, 8'h12, 8'h80, 8'he2, 8'heb, 8'h27, 8'hb2, 8'h75},
	            { 8'h09, 8'h83, 8'h2c, 8'h1a, 8'h1b, 8'h6e, 8'h5a, 8'ha0, 8'h52, 8'h3b, 8'hd6, 8'hb3, 8'h29, 8'he3, 8'h2f, 8'h84},
	            { 8'h53, 8'hd1, 8'h00, 8'hed, 8'h20, 8'hfc, 8'hb1, 8'h5b, 8'h6a, 8'hcb, 8'hbe, 8'h39, 8'h4a, 8'h4c, 8'h58, 8'hcf},
	            { 8'hd0, 8'hef, 8'haa, 8'hfb, 8'h43, 8'h4d, 8'h33, 8'h85, 8'h45, 8'hf9, 8'h02, 8'h7f, 8'h50, 8'h3c, 8'h9f, 8'ha8},
	            { 8'h51, 8'ha3, 8'h40, 8'h8f, 8'h92, 8'h9d, 8'h38, 8'hf5, 8'hbc, 8'hb6, 8'hda, 8'h21, 8'h10, 8'hff, 8'hf3, 8'hd2},
	            { 8'hcd, 8'h0c, 8'h13, 8'hec, 8'h5f, 8'h97, 8'h44, 8'h17, 8'hc4, 8'ha7, 8'h7e, 8'h3d, 8'h64, 8'h5d, 8'h19, 8'h73},
	            { 8'h60, 8'h81, 8'h4f, 8'hdc, 8'h22, 8'h2a, 8'h90, 8'h88, 8'h46, 8'hee, 8'hb8, 8'h14, 8'hde, 8'h5e, 8'h0b, 8'hdb},
	            { 8'he0, 8'h32, 8'h3a, 8'h0a, 8'h49, 8'h06, 8'h24, 8'h5c, 8'hc2, 8'hd3, 8'hac, 8'h62, 8'h91, 8'h95, 8'he4, 8'h79},
	            { 8'he7, 8'hc8, 8'h37, 8'h6d, 8'h8d, 8'hd5, 8'h4e, 8'ha9, 8'h6c, 8'h56, 8'hf4, 8'hea, 8'h65, 8'h7a, 8'hae, 8'h08},
	            { 8'hba, 8'h78, 8'h25, 8'h2e, 8'h1c, 8'ha6, 8'hb4, 8'hc6, 8'he8, 8'hdd, 8'h74, 8'h1f, 8'h4b, 8'hbd, 8'h8b, 8'h8a},
	            { 8'h70, 8'h3e, 8'hb5, 8'h66, 8'h48, 8'h03, 8'hf6, 8'h0e, 8'h61, 8'h35, 8'h57, 8'hb9, 8'h86, 8'hc1, 8'h1d, 8'h9e},
	            { 8'he1, 8'hf8, 8'h98, 8'h11, 8'h69, 8'hd9, 8'h8e, 8'h94, 8'h9b, 8'h1e, 8'h87, 8'he9, 8'hce, 8'h55, 8'h28, 8'hdf},
	            { 8'h8c, 8'ha1, 8'h89, 8'h0d, 8'hbf, 8'he6, 8'h42, 8'h68, 8'h41, 8'h99, 8'h2d, 8'h0f, 8'hb0, 8'h54, 8'hbb, 8'h16}};
	
	//INV - sboxOX
	assign {inv_s_box[0][ 0], inv_s_box[1][ 0], inv_s_box[2][ 0], inv_s_box[3][ 0], inv_s_box[4][ 0], inv_s_box[5][ 0], inv_s_box[6][ 0], inv_s_box[7][ 0], inv_s_box[8][ 0], inv_s_box[9][ 0], inv_s_box[10][ 0], inv_s_box[11][ 0], inv_s_box[12][ 0], inv_s_box[13][ 0], inv_s_box[14][ 0], inv_s_box[15][ 0],
	         inv_s_box[0][ 1], inv_s_box[1][ 1], inv_s_box[2][ 1], inv_s_box[3][ 1], inv_s_box[4][ 1], inv_s_box[5][ 1], inv_s_box[6][ 1], inv_s_box[7][ 1], inv_s_box[8][ 1], inv_s_box[9][ 1], inv_s_box[10][ 1], inv_s_box[11][ 1], inv_s_box[12][ 1], inv_s_box[13][ 1], inv_s_box[14][ 1], inv_s_box[15][ 1],
	         inv_s_box[0][ 2], inv_s_box[1][ 2], inv_s_box[2][ 2], inv_s_box[3][ 2], inv_s_box[4][ 2], inv_s_box[5][ 2], inv_s_box[6][ 2], inv_s_box[7][ 2], inv_s_box[8][ 2], inv_s_box[9][ 2], inv_s_box[10][ 2], inv_s_box[11][ 2], inv_s_box[12][ 2], inv_s_box[13][ 2], inv_s_box[14][ 2], inv_s_box[15][ 2],
	         inv_s_box[0][ 3], inv_s_box[1][ 3], inv_s_box[2][ 3], inv_s_box[3][ 3], inv_s_box[4][ 3], inv_s_box[5][ 3], inv_s_box[6][ 3], inv_s_box[7][ 3], inv_s_box[8][ 3], inv_s_box[9][ 3], inv_s_box[10][ 3], inv_s_box[11][ 3], inv_s_box[12][ 3], inv_s_box[13][ 3], inv_s_box[14][ 3], inv_s_box[15][ 3],
	         inv_s_box[0][ 4], inv_s_box[1][ 4], inv_s_box[2][ 4], inv_s_box[3][ 4], inv_s_box[4][ 4], inv_s_box[5][ 4], inv_s_box[6][ 4], inv_s_box[7][ 4], inv_s_box[8][ 4], inv_s_box[9][ 4], inv_s_box[10][ 4], inv_s_box[11][ 4], inv_s_box[12][ 4], inv_s_box[13][ 4], inv_s_box[14][ 4], inv_s_box[15][ 4],
	         inv_s_box[0][ 5], inv_s_box[1][ 5], inv_s_box[2][ 5], inv_s_box[3][ 5], inv_s_box[4][ 5], inv_s_box[5][ 5], inv_s_box[6][ 5], inv_s_box[7][ 5], inv_s_box[8][ 5], inv_s_box[9][ 5], inv_s_box[10][ 5], inv_s_box[11][ 5], inv_s_box[12][ 5], inv_s_box[13][ 5], inv_s_box[14][ 5], inv_s_box[15][ 5],
	         inv_s_box[0][ 6], inv_s_box[1][ 6], inv_s_box[2][ 6], inv_s_box[3][ 6], inv_s_box[4][ 6], inv_s_box[5][ 6], inv_s_box[6][ 6], inv_s_box[7][ 6], inv_s_box[8][ 6], inv_s_box[9][ 6], inv_s_box[10][ 6], inv_s_box[11][ 6], inv_s_box[12][ 6], inv_s_box[13][ 6], inv_s_box[14][ 6], inv_s_box[15][ 6],
	         inv_s_box[0][ 7], inv_s_box[1][ 7], inv_s_box[2][ 7], inv_s_box[3][ 7], inv_s_box[4][ 7], inv_s_box[5][ 7], inv_s_box[6][ 7], inv_s_box[7][ 7], inv_s_box[8][ 7], inv_s_box[9][ 7], inv_s_box[10][ 7], inv_s_box[11][ 7], inv_s_box[12][ 7], inv_s_box[13][ 7], inv_s_box[14][ 7], inv_s_box[15][ 7],
	         inv_s_box[0][ 8], inv_s_box[1][ 8], inv_s_box[2][ 8], inv_s_box[3][ 8], inv_s_box[4][ 8], inv_s_box[5][ 8], inv_s_box[6][ 8], inv_s_box[7][ 8], inv_s_box[8][ 8], inv_s_box[9][ 8], inv_s_box[10][ 8], inv_s_box[11][ 8], inv_s_box[12][ 8], inv_s_box[13][ 8], inv_s_box[14][ 8], inv_s_box[15][ 8],
	         inv_s_box[0][ 9], inv_s_box[1][ 9], inv_s_box[2][ 9], inv_s_box[3][ 9], inv_s_box[4][ 9], inv_s_box[5][ 9], inv_s_box[6][ 9], inv_s_box[7][ 9], inv_s_box[8][ 9], inv_s_box[9][ 9], inv_s_box[10][ 9], inv_s_box[11][ 9], inv_s_box[12][ 9], inv_s_box[13][ 9], inv_s_box[14][ 9], inv_s_box[15][ 9],
	         inv_s_box[0][10], inv_s_box[1][10], inv_s_box[2][10], inv_s_box[3][10], inv_s_box[4][10], inv_s_box[5][10], inv_s_box[6][10], inv_s_box[7][10], inv_s_box[8][10], inv_s_box[9][10], inv_s_box[10][10], inv_s_box[11][10], inv_s_box[12][10], inv_s_box[13][10], inv_s_box[14][10], inv_s_box[15][10],
	         inv_s_box[0][11], inv_s_box[1][11], inv_s_box[2][11], inv_s_box[3][11], inv_s_box[4][11], inv_s_box[5][11], inv_s_box[6][11], inv_s_box[7][11], inv_s_box[8][11], inv_s_box[9][11], inv_s_box[10][11], inv_s_box[11][11], inv_s_box[12][11], inv_s_box[13][11], inv_s_box[14][11], inv_s_box[15][11],
	         inv_s_box[0][12], inv_s_box[1][12], inv_s_box[2][12], inv_s_box[3][12], inv_s_box[4][12], inv_s_box[5][12], inv_s_box[6][12], inv_s_box[7][12], inv_s_box[8][12], inv_s_box[9][12], inv_s_box[10][12], inv_s_box[11][12], inv_s_box[12][12], inv_s_box[13][12], inv_s_box[14][12], inv_s_box[15][12],
	         inv_s_box[0][13], inv_s_box[1][13], inv_s_box[2][13], inv_s_box[3][13], inv_s_box[4][13], inv_s_box[5][13], inv_s_box[6][13], inv_s_box[7][13], inv_s_box[8][13], inv_s_box[9][13], inv_s_box[10][13], inv_s_box[11][13], inv_s_box[12][13], inv_s_box[13][13], inv_s_box[14][13], inv_s_box[15][13],
	         inv_s_box[0][14], inv_s_box[1][14], inv_s_box[2][14], inv_s_box[3][14], inv_s_box[4][14], inv_s_box[5][14], inv_s_box[6][14], inv_s_box[7][14], inv_s_box[8][14], inv_s_box[9][14], inv_s_box[10][14], inv_s_box[11][14], inv_s_box[12][14], inv_s_box[13][14], inv_s_box[14][14], inv_s_box[15][14],
	         inv_s_box[0][15], inv_s_box[1][15], inv_s_box[2][15], inv_s_box[3][15], inv_s_box[4][15], inv_s_box[5][15], inv_s_box[6][15], inv_s_box[7][15], inv_s_box[8][15], inv_s_box[9][15], inv_s_box[10][15], inv_s_box[11][15], inv_s_box[12][15], inv_s_box[13][15], inv_s_box[14][15], inv_s_box[15][15]}
	       = {{8'h52, 8'h09, 8'h6a, 8'hd5, 8'h30, 8'h36, 8'ha5, 8'h38, 8'hbf, 8'h40, 8'ha3, 8'h9e, 8'h81, 8'hf3, 8'hd7, 8'hfb},
	         {8'h7c, 8'he3, 8'h39, 8'h82, 8'h9b, 8'h2f, 8'hff, 8'h87, 8'h34, 8'h8e, 8'h43, 8'h44, 8'hc4, 8'hde, 8'he9, 8'hcb},
	         {8'h54, 8'h7b, 8'h94, 8'h32, 8'ha6, 8'hc2, 8'h23, 8'h3d, 8'hee, 8'h4c, 8'h95, 8'h0b, 8'h42, 8'hfa, 8'hc3, 8'h4e},
	         {8'h08, 8'h2e, 8'ha1, 8'h66, 8'h28, 8'hd9, 8'h24, 8'hb2, 8'h76, 8'h5b, 8'ha2, 8'h49, 8'h6d, 8'h8b, 8'hd1, 8'h25},
	         {8'h72, 8'hf8, 8'hf6, 8'h64, 8'h86, 8'h68, 8'h98, 8'h16, 8'hd4, 8'ha4, 8'h5c, 8'hcc, 8'h5d, 8'h65, 8'hb6, 8'h92},
	         {8'h6c, 8'h70, 8'h48, 8'h50, 8'hfd, 8'hed, 8'hb9, 8'hda, 8'h5e, 8'h15, 8'h46, 8'h57, 8'ha7, 8'h8d, 8'h9d, 8'h84},
	         {8'h90, 8'hd8, 8'hab, 8'h00, 8'h8c, 8'hbc, 8'hd3, 8'h0a, 8'hf7, 8'he4, 8'h58, 8'h05, 8'hb8, 8'hb3, 8'h45, 8'h06},
	         {8'hd0, 8'h2c, 8'h1e, 8'h8f, 8'hca, 8'h3f, 8'h0f, 8'h02, 8'hc1, 8'haf, 8'hbd, 8'h03, 8'h01, 8'h13, 8'h8a, 8'h6b},
	         {8'h3a, 8'h91, 8'h11, 8'h41, 8'h4f, 8'h67, 8'hdc, 8'hea, 8'h97, 8'hf2, 8'hcf, 8'hce, 8'hf0, 8'hb4, 8'he6, 8'h73},
	         {8'h96, 8'hac, 8'h74, 8'h22, 8'he7, 8'had, 8'h35, 8'h85, 8'he2, 8'hf9, 8'h37, 8'he8, 8'h1c, 8'h75, 8'hdf, 8'h6e},
	         {8'h47, 8'hf1, 8'h1a, 8'h71, 8'h1d, 8'h29, 8'hc5, 8'h89, 8'h6f, 8'hb7, 8'h62, 8'h0e, 8'haa, 8'h18, 8'hbe, 8'h1b},
	         {8'hfc, 8'h56, 8'h3e, 8'h4b, 8'hc6, 8'hd2, 8'h79, 8'h20, 8'h9a, 8'hdb, 8'hc0, 8'hfe, 8'h78, 8'hcd, 8'h5a, 8'hf4},
	         {8'h1f, 8'hdd, 8'ha8, 8'h33, 8'h88, 8'h07, 8'hc7, 8'h31, 8'hb1, 8'h12, 8'h10, 8'h59, 8'h27, 8'h80, 8'hec, 8'h5f},
	         {8'h60, 8'h51, 8'h7f, 8'ha9, 8'h19, 8'hb5, 8'h4a, 8'h0d, 8'h2d, 8'he5, 8'h7a, 8'h9f, 8'h93, 8'hc9, 8'h9c, 8'hef},
	         {8'ha0, 8'he0, 8'h3b, 8'h4d, 8'hae, 8'h2a, 8'hf5, 8'hb0, 8'hc8, 8'heb, 8'hbb, 8'h3c, 8'h83, 8'h53, 8'h99, 8'h61},
	         {8'h17, 8'h2b, 8'h04, 8'h7e, 8'hba, 8'h77, 8'hd6, 8'h26, 8'he1, 8'h69, 8'h14, 8'h63, 8'h55, 8'h21, 8'h0c, 8'h7d}};	


endmodule


