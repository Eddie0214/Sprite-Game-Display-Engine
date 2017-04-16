module SGDE ( ready, done, clk, reset, sprite, start, type, X, Y, SR_CEN, SR_A, SR_Q, FB_CEN, FB_WEN, FB_A, FB_D, FB_Q);

input clk, reset, sprite, start;
input [1:0] type;
input [5:0] X, Y;
input [12:0] SR_Q;
input [11:0] FB_Q;
output ready, done;
output SR_CEN, FB_CEN, FB_WEN;
output reg [8:0] SR_A;
output reg[11:0] FB_A, FB_D;
////////////////////////////////////////////
reg		done;
reg 	[2:0] 	PS, NS;
reg		[4:0] 	counter;
reg		[6:0] 	counter2;
///////////y,x information////////////
reg		[4:0] 	flowercounter, othercounter;
reg		[11:0] 	y_x_register [0:18]; //man=19 
reg		[11:0]	y_x_man, yx;
reg		[18:0]	other_type; //remember it's candy or ghost
reg		[5:0]	a;
reg		[1:0]  	lhd;
reg		type_reg, match;
wire	[11:0]	mb		[0:19];
wire	[11:0]	FB_address		;
/////////////man boundry////////////////////////////////////////
assign	mb[0] =y_x_man+12'b000000_000010, mb[1] =y_x_man+12'b000000_000011, mb[2] =y_x_man+12'b000000_000100, mb[3] =y_x_man+12'b000000_000101; 
assign	mb[4] =y_x_man+12'b000001_000001, mb[5] =y_x_man+12'b000001_000110;
assign	mb[6] =y_x_man+12'b000010_000000, mb[7] =y_x_man+12'b000010_000111;
assign	mb[8] =y_x_man+12'b000011_000000, mb[9] =y_x_man+12'b000011_000111;
assign	mb[10]=y_x_man+12'b000100_000000, mb[11]=y_x_man+12'b000100_000111;
assign	mb[12]=y_x_man+12'b000101_000000, mb[13]=y_x_man+12'b000101_000111;
assign	mb[14]=y_x_man+12'b000110_000001, mb[15]=y_x_man+12'b000110_000110;
assign	mb[16]=y_x_man+12'b000111_000010, mb[17]=y_x_man+12'b000111_000011, mb[18]=y_x_man+12'b000111_000100, mb[19]=y_x_man+12'b000111_000101;
//////////////////
assign	FB_address[11:6] =yx[11:6]+a;
assign	FB_address[5:0]	 =yx[5:0]+counter2[2:0];
assign	ready=1, SR_CEN=0, FB_WEN=0, FB_CEN=0;
////////catch type and (Y,X)////////////////////////
always@(posedge clk )begin
if(reset)begin
flowercounter<=5'd18;
othercounter<=5'd0;
end
else if(sprite)	begin
								case(type)
									2'b00: 	y_x_man<={Y,X};
									2'b01:	begin
											y_x_register[othercounter] <= {Y,X}; //type=1 -> candy,    type=0 -> ghost 
											other_type[othercounter]<=0;
											othercounter<=othercounter+5'd1;
											end
									2'b10:	begin
											y_x_register[othercounter] <= {Y,X}; 
											other_type[othercounter]<=1;
											othercounter<=othercounter+5'd1;
											end
									2'b11:	begin
											y_x_register[flowercounter]<={Y,X};
											flowercounter<=flowercounter-5'd1;
											end					
								endcase
				end
end
////////////Read from ROM and Program Buffer////////////////////
always@(negedge clk or posedge reset)begin
if(reset)
PS<=4'd0;
else
PS<=NS;
end
always@(*)begin
case(PS)
3'd0:if(FB_A==12'd4095) 		NS=3'd1; 	else NS=3'd0;
3'd1:if(counter==flowercounter) NS=3'd3; 	else NS=3'd2;
3'd2:if(counter2==6'd63) 		NS=3'd1; 	else NS=3'd2;
3'd3:if(counter==othercounter)	NS=3'd5; 	else NS=3'd4;
3'd4:if(counter2==6'd63) 		NS=3'd3;	else NS=3'd4;
3'd5:							NS=3'd6;                
3'd6:if(counter2==6'd63) 		NS=3'd7;	else NS=3'd6;
3'd7:							NS=3'd7;
endcase
end
always@(negedge clk or posedge reset)begin
if(reset)begin
FB_A<=12'd0;
FB_D<=12'b1100_1111_0000;
counter2<=0;
counter<=5'd18;
done<=0;
a<=0;
end
else begin
		case(PS)
		////////////////background///////////////////////
		3'd0:FB_A<=FB_A+12'd1;
		//////////////////flower/////////////////////////	
		3'd1:begin
				if(counter==flowercounter)
				counter<=0;
				else
				counter<=counter-1;
				yx<=y_x_register[counter];
				SR_A<=9'd320;
				counter2<=6'd0;
				a<=0;
				
			end
		3'd2:begin
				counter2<=counter2+6'd1;
				SR_A<=SR_A+1;
				if(counter2[2:0]==3'b111)
				a<=a+1;
				if(SR_Q[0])begin
				FB_A<=FB_address;
				FB_D<=SR_Q[12:1];end
			end
		//////////////candy & ghost//////////////////////////////
		3'd3:begin 
				counter<=counter+1;
				yx<=y_x_register[counter];
				type_reg<=other_type[counter];
				SR_A<=(other_type[counter]==0)? 9'd192 : 9'd256;
				counter2<=0;
				a<=0;
				
			end
		3'd4:begin
				counter2<=counter2+6'd1;
				SR_A<=SR_A+1;
				if(counter2[2:0]==3'b111)
				a<=a+1;
				if(SR_Q[0])begin
				FB_A<=FB_address;
				FB_D<=SR_Q[12:1];end
			end
		//////////////man/////////////////////////////////	
		3'd5:begin
				case(lhd)
				2'b00:SR_A<=9'd0;//live
				2'b01:SR_A<=9'd128;//die
				2'b10:SR_A<=9'd64;//happy
				endcase
				yx<=y_x_man;
				counter2<=0;
				a<=0;
				
			end
		3'd6:begin
				counter2<=counter2+6'd1;
				SR_A<=SR_A+1;
				if(counter2[2:0]==3'b111)
				a<=a+1;
				if(SR_Q[0])begin
				FB_A<=FB_address;
				FB_D<=SR_Q[12:1];end
			end
		3'd7:	done<=1;
		endcase
end
end
/////////    live, happy or die???     ///////////////////////
always@(negedge clk or posedge reset)begin
if(reset)
	lhd<=2'b00;
else if(match==1)begin
			case(lhd)
		2'b00:	if(type_reg==0)	
					lhd<=2'b01;
				else if(type_reg==1)
					lhd<=2'b10;
		2'b01:	if(type_reg==1)
					lhd<=2'b10;
		2'b10:;
			endcase
end
end
always@(*)begin
if(PS==3'd4 && SR_Q[0])begin
case(FB_address)
mb[0]:	 match=1;
mb[1]:	 match=1;
mb[2]:   match=1;
mb[3]:   match=1;
mb[4]:   match=1;
mb[5]:   match=1;
mb[6]:   match=1;
mb[7]:   match=1;
mb[8]:   match=1;
mb[9]:   match=1;
mb[10]:  match=1;
mb[11]:  match=1;
mb[12]:  match=1;
mb[13]:  match=1;
mb[14]:  match=1;
mb[15]:  match=1;
mb[16]:  match=1;
mb[17]:  match=1;
mb[18]:  match=1;
mb[19]:  match=1;
default: match=0;
endcase
end
else
match=0;
end
endmodule

