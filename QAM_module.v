
module QAM (
input clk,rst,Data_in_valid,ifft_Ready,
input [2:0] M_ary,
input [15:0] Data_in_QAM,
output reg QAM_Ready, mapping_valid,
output reg [31:0] QAM_I,QAM_Q

);

reg [15:0] Binary_Data; 
wire  [15: 0]   binary;
reg signed [5:0] I ;
reg signed [5:0] Q ;
reg finished;
integer log2_M, square_root_M;
reg [10:0] row;
reg [10:0]column ;
reg [1:0] state, next_state;

parameter IDLE =2'b00;
parameter CALC = 2'b01;
parameter END = 2'b10;
parameter SEND = 2'b11;


always @(M_ary) begin
case (M_ary)
3'b000:    begin  square_root_M = 2;   log2_M = 2; end      // 4-QAM
3'b001:    begin  square_root_M = 4;   log2_M = 4; end     // 16-QAM
3'b010:    begin  square_root_M = 8;   log2_M = 6; end    // 64-QAM
3'b011:    begin  square_root_M = 16;  log2_M = 8; end   //256-QAM
3'b100:    begin  square_root_M = 32;  log2_M = 10; end  //1024-QAM
default:   begin  square_root_M = 32;  log2_M = 10; end  //1024-QAM
endcase
end

assign  binary[15]     =       Data_in_QAM[15];
 
generate
genvar  i;
    for(i=0;i<15;i=i+1) begin:b2g
        assign  binary[i]     =       Data_in_QAM[i]^binary[i+1];  
    end
endgenerate

always @ (posedge clk)
begin
                Binary_Data = binary;
                row = Binary_Data/square_root_M;
                column = Binary_Data % square_root_M; 
                Q = {(-(2*(row+1)-1-square_root_M))}; 
                if ((row)%2==0)  begin  I= (-(2*(column+1)-1-square_root_M)); end 
                else begin  I= (2*(column+1)-1-square_root_M);end 
                finished = 1'b1;
end

always @(*)
begin
    case (state)
    IDLE:begin
            if (Data_in_valid == 1) next_state = CALC;
            else next_state = IDLE;
         end
    CALC:begin
            if (finished == 1) next_state = END;
            else next_state = CALC;
         end
    END:begin
            if (ifft_Ready == 1) next_state = SEND;
            else next_state = END;
         end
    SEND:begin
            if (ifft_Ready == 0) next_state = IDLE;
            else next_state = SEND;
         end
    endcase
end

always @(posedge clk or negedge rst)
begin
    if (!rst) state <= IDLE;
    else state <= next_state; 
end

always @(*)
begin
    case (state)
    IDLE:begin
            QAM_Ready = 1'b1;
            QAM_Q = 0;
            QAM_I = 0;
            mapping_valid = 1'b0;
         end
    CALC:begin
            QAM_Ready = 1'b0;
            QAM_Q = Q;
            QAM_I = I;
            mapping_valid = 1'b0;
         end
    END:begin
            QAM_Ready = 1'b0;
            QAM_Q = Q;
            QAM_I = I;
            mapping_valid = 1'b1;
         end
    SEND:begin
            QAM_Ready = 1'b0;
            QAM_Q = Q;
            QAM_I = I;
            mapping_valid = 1'b1;
         end
    endcase
end
endmodule
