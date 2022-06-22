module InvMixColumns(
	input	wire	[31:0]	i_Data,
	output	reg		[31:0]	o_Data
);

	wire 	[ 7:0]	Line1, Line2, Line3, Line4;
	reg		[ 7:0]	shift2_Line1, shift2_Line2, shift2_Line3, shift2_Line4, shift4_Line1, shift4_Line2, shift4_Line3, shift4_Line4, shift8_Line1, shift8_Line2, shift8_Line3, shift8_Line4;


	assign Line1 = i_Data[31:24];
	assign Line2 = i_Data[23:16];
	assign Line3 = i_Data[15: 8];
	assign Line4 = i_Data[ 7: 0];



	always@(*)
	begin
		if(Line1[7])
			shift2_Line1 = {Line1[6:0], 1'b0} ^ 8'h1B;	
		else	
			shift2_Line1 = {Line1[6:0], 1'b0};		
	end

	always@(*)
	begin
		if(Line2[7])
			shift2_Line2 = {Line2[6:0], 1'b0} ^ 8'h1B;	
		else	
			shift2_Line2 = {Line2[6:0], 1'b0};		
	end

	always@(*)
	begin
		if(Line3[7])
			shift2_Line3 = {Line3[6:0], 1'b0} ^ 8'h1B;	
		else	
			shift2_Line3 = {Line3[6:0], 1'b0};		
	end

	always@(*)
	begin
		if(Line4[7])
			shift2_Line4 = {Line4[6:0], 1'b0} ^ 8'h1B;	
		else	
			shift2_Line4 = {Line4[6:0], 1'b0};		
	end


	always@(*)
	begin
		if(shift2_Line1[7])
			shift4_Line1 = {shift2_Line1[6:0], 1'b0} ^ 8'h1B;	
		else		
			shift4_Line1 = {shift2_Line1[6:0], 1'b0};		
	end

	always@(*)
	begin
		if(shift2_Line2[7])
			shift4_Line2 = {shift2_Line2[6:0], 1'b0} ^ 8'h1B;	
		else		
			shift4_Line2 = {shift2_Line2[6:0], 1'b0};		
	end

	always@(*)
	begin
		if(shift2_Line3[7])
			shift4_Line3 = {shift2_Line3[6:0], 1'b0} ^ 8'h1B;	
		else		
			shift4_Line3 = {shift2_Line3[6:0], 1'b0};		
	end

	always@(*)
	begin
		if(shift2_Line4[7])
			shift4_Line4 = {shift2_Line4[6:0], 1'b0} ^ 8'h1B;	
		else		
			shift4_Line4 = {shift2_Line4[6:0], 1'b0};		
	end


	always@(*)
	begin
		if(shift4_Line1[7])
			shift8_Line1 = {shift4_Line1[6:0], 1'b0} ^ 8'h1B;	
		else		
			shift8_Line1 = {shift4_Line1[6:0], 1'b0};		
	end

	always@(*)
	begin
		if(shift4_Line2[7])
			shift8_Line2 = {shift4_Line2[6:0], 1'b0} ^ 8'h1B;	
		else		
			shift8_Line2 = {shift4_Line2[6:0], 1'b0};		
	end

	always@(*)
	begin
		if(shift4_Line3[7])	
			shift8_Line3 = {shift4_Line3[6:0], 1'b0} ^ 8'h1B;	
		else		
			shift8_Line3 = {shift4_Line3[6:0], 1'b0};		
	end

	always@(*)
	begin
		if(shift4_Line4[7])
			shift8_Line4 = {shift4_Line4[6:0], 1'b0} ^ 8'h1B;	
		else		
			shift8_Line4 = {shift4_Line4[6:0], 1'b0};		
	end




	always@(*)
	begin
		o_Data[31:24] = (shift8_Line1 ^ shift4_Line1 ^ shift2_Line1)	^	(shift8_Line2 ^ shift2_Line2 ^ Line2)			^	(shift8_Line3 ^ shift4_Line3 ^ Line3)			^	(shift8_Line4 ^ Line4)						;
		o_Data[23:16] = (shift8_Line1 ^ Line1)							^	(shift8_Line2 ^ shift4_Line2 ^ shift2_Line2)	^	(shift8_Line3 ^ shift2_Line3 ^ Line3)			^	(shift8_Line4 ^ shift4_Line4 ^ Line4)			;
		o_Data[15: 8] = (shift8_Line1 ^ shift4_Line1 ^ Line1)			^	(shift8_Line2 ^ Line2)							^	(shift8_Line3 ^ shift4_Line3 ^ shift2_Line3)	^	(shift8_Line4 ^ shift2_Line4 ^ Line4)		;	
		o_Data[ 7: 0] = (shift8_Line1 ^ shift2_Line1 ^ Line1)			^	(shift8_Line2 ^ shift4_Line2 ^ Line2)			^	(shift8_Line3 ^ Line3)							^	(shift8_Line4 ^ shift4_Line4 ^ shift2_Line4)	;
	end

endmodule
