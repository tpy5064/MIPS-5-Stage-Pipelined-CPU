`timescale 1ns / 1ps

module programCounter(    //Program Counter from Lecture #14
        
        input stallSig,
        input clk,
        input rst,
        output reg[31:0] pc

    );
    
    parameter increment = 32'd4;
    
    initial
    begin
        pc = 0;
    end
    
    always @(posedge clk)
    begin
        if(stallSig == 0)
        pc <= pc + increment;
                
    end

endmodule

module instructionMemory(
        
        input[31:0] currentPC,
        output reg[31:0] instrOut

    );
    
    integer pc;
    reg[31:0] instrMemory [0:255];

    
    initial
    
        begin
            /*                  
            instrMemory[100] = 32'b100011_00001_00010_0000000000000000; //lw $v0, 0($at)
            instrMemory[104] = 32'b100011_00001_00011_0000000000000100; //lw $v1, 4($at)     
            instrMemory[108] = 32'b100011_00001_00100_0000000000001000; //lw $a0, 8($at)   
            instrMemory[112] = 32'b100011_00001_00101_0000000000001100; //lw $a1, 12($at)
            instrMemory[116] = 32'b000000_00010_01010_00110_00000_100000; //add $a2, $v0, $t2 
            */
            
            instrMemory[100] = 32'b000000_00001_00010_00011_00000_100000; //add $3, $1, $2
            instrMemory[104] = 32'b000000_01001_00011_00100_00000_100010; //sub $4, $9, $3
            instrMemory[108] = 32'b000000_00011_01001_00101_00000_100101; //or  $5, $3, $9
            instrMemory[112] = 32'b000000_00011_01001_00110_00000_100110; //xor $6, $3, $9
            instrMemory[116] = 32'b000000_00011_01001_00111_00000_100100; //and $7, $3, $9
            
        end
        
        always@(*) //Outputs new instruction when PC updates.
        begin
            pc = currentPC;
            instrOut = instrMemory[pc];
        end
    
    
endmodule
 

module IF_ID(
    
    input stallSig,
    input clk,
    input[31:0] instruction,
    output reg[5:0] opcode,
    output reg[4:0] rs,
    output reg[4:0] rt,
    output reg[4:0] rd,
    output reg[5:0] funct,
    output reg[15:0] immediate
 
 );
 
        
    //Extracting the instructions, breaking down 32 bits.
    always@(posedge clk) 
    begin
        if(stallSig == 0)
        begin
        opcode <= {instruction[31], instruction[30], instruction[29], instruction[28], instruction[27], instruction[26]};
        rs <= {instruction[25], instruction[24], instruction[23], instruction[22], instruction[21]};
        rt <= {instruction[20], instruction[19], instruction[18], instruction[17], instruction[16]};
        rd <= {instruction[15], instruction[14], instruction[13], instruction[12], instruction[11]};
        funct <= {instruction[5], instruction[4], instruction[3], instruction[2], instruction[1], instruction[0]};
        
        immediate <= {instruction[15], instruction[14], instruction[13], instruction[12], 
                      instruction[11], instruction[10], instruction[9], instruction[8], 
                      instruction[7], instruction[6], instruction[5], instruction[4], 
                      instruction[3], instruction[2], instruction[1], instruction[0]};
                      
        end
        
    end       
           
endmodule


module controlUnit(
        
        input clk,
        input[5:0] op,
        input[5:0] func,
        input[4:0] rs,
        input[4:0] rt,
        input[4:0] ern,
        input[4:0] mrn,
        output reg writeReg,
               reg m2reg,
               reg writeMem,
               reg aluSource,  
               reg aluImmediate,
               reg regrt,
               reg[3:0] aluControl,
               reg[1:0] aluOp,
               reg stallSig     
               
);

        integer rType = 0
                ,addi = 0 
                ,andi = 0
                ,ori = 0
                ,xori = 0
                ,lw = 0
                ,sw = 0
                ,beq = 0;
                
        initial begin
        stallSig = 0;
        end

        always@(*)
        begin 
            if(mrn == rs || ern == rs || mrn == rt || ern == rt)
            stallSig = 1;
            else stallSig = 0;
            
            if(stallSig == 0)
            begin
                case(op)  //Determining type of operation
                    6'b000000 : rType = 1;
                    6'b001000 : addi = 1;
                    6'b001100 : andi = 1;
                    6'b001101 : ori = 1;
                    6'b001110 : xori = 1;
                    6'b100011 : lw = 1;
                    6'b101011 : sw = 1;
                    6'b101011 : beq = 1;   
                    default   : begin
                                   rType = 0;
                                   addi = 0;
                                   andi = 0;
                                   ori  = 0;
                                   xori = 0;
                                   lw = 0;
                                   sw = 0;
                                   beq = 0;
                                end                  
                endcase
                
                //Determining output of control unit
                assign writeReg = rType | lw;
                assign regrt = rType;
                assign m2reg = lw;
                assign writeMem = sw;
                if(sw | lw == 1) assign aluSource = 1;
                else if(sw | lw == 0) assign aluSource = 0;
                assign aluImmediate = addi | andi | ori | xori;
                
                if(rType == 1) assign aluSource = 0;
                
                end
                
                //Setting ALU Control
                if(aluSource == 1)
                    begin
                        aluControl = 4'b0010; //either lw or sw will trigger this
                        aluOp = 2'b00;
                    end
                else if(beq == 1)
                    begin
                        aluControl = 4'b0110;  //Check for equality, equivalent to sub
                        aluOp = 2'b01;
                    end
                else if(rType == 1)
                    case(func)  //Inspecting funct input to distinguish R-format
                        6'b100000 : begin 
                                        aluControl = 4'b0010; //add
                                        aluOp = 2'b10;
                                    end
                        6'b100010 : begin
                                        aluControl = 4'b0110; //sub
                                        aluOp = 2'b10;
                                    end
                        6'b100100 : begin
                                        aluControl = 4'b0000; //and
                                        aluOp = 2'b10;
                                    end
                        6'b100101 : begin
                                        aluControl = 4'b0001; //or
                                        aluOp = 2'b10;
                                    end
                        6'b100110 : begin
                                        aluControl = 4'b1010; //xor
                                        aluOp = 2'b10;
                                    end
                        default   : begin
                                        aluControl = 0;
                                        aluOp = 0;    
                                    end
                        endcase
        end          
endmodule

module regRtMux(
    
    input stallSig,
    input clk,
    input rst,
    input regRt,
    input[4:0] rd,
    input[4:0] rt,
    output reg[4:0] muxOut

);

    always@(*)
    begin
        if(stallSig == 0)
        begin
        
            if(regRt == 1) muxOut <= rd;    
            else if(regRt == 0) muxOut <= rt;
            
        end
        
        else if (stallSig == 1) muxOut <= 'bx;
     
    end

endmodule




module signExtender(

    input clk,
    input[15:0] imm,
    output reg[31:0] ext

);

    always@(*)
    begin  //Sign extension, examines MSB of immediate field and extend accordingly.
        if(imm[15] == 1) ext[31:16] = 16'b1111111111111111;
        else if(imm[15] == 0) ext[31:16] = 16'b0000000000000000;
        ext[15:0] = imm;
    end

endmodule





module ID_EX(
    
    input stall,
    input clk,
    input rst,
    input aluSrc,
    input[31:0] pc,
    input writeReg,
    input m2reg,
    input writeMem,
    input[3:0] aluControl,  
    input aluImmediate,
    input regrt,
    input[4:0] muxIn,
    input[31:0] readDataOne,
    input[31:0] readDataTwo,
    input[31:0] immIn,
    input[1:0] aluOpIn,
    
    output reg[31:0] pcOut,
    output reg writeRegOut,
    output reg m2regOut,
    output reg writeMemOut,
    output reg[3:0] aluControlOut,  
    output reg aluImmediateOut,
    output reg regrtOut,
    output reg[4:0] muxOut,
    output reg[31:0] readDataOneOut,
    output reg[31:0] readDataTwoOut,
    output reg[31:0] immOut,
    output reg[1:0] aluOpOut,
    output reg aluSrcOut,
    output reg[4:0] ern
   
);
    
    always@(posedge clk, posedge rst)
    begin
        if(stall == 0)
        begin
            pcOut <= pc;
            writeRegOut <= writeReg;
            m2regOut <= m2reg;
            writeMemOut <= writeMem;
            aluControlOut <= aluControl;
            aluImmediateOut <= aluImmediate;
            regrtOut <= regrt;
            muxOut <= muxIn;
            readDataOneOut <= readDataOne;
            readDataTwoOut <= readDataTwo;
            immOut <= immIn;  
            aluOpOut <= aluOpIn;
            aluSrcOut <= aluSrc;
            ern <= muxIn;
        end
        else if(stall == 1) 
        begin
            pcOut <= pcOut + 0;
            writeRegOut <= 'bx;
            m2regOut <= 'bx;
            writeMemOut <= 'bx;
            aluControlOut <= 'bx;
            aluImmediateOut <= 'bx;
            regrtOut <= 'bx;
            muxOut <= 'bx;
            readDataOneOut <= 'bx;
            readDataTwoOut <= 'bx;
            immOut <= 'bx;    
            aluOpOut <= 'bx;  
            aluSrcOut <= 'bx; 
            ern <= 'bx;
        end   
    end
endmodule

module aluMux(
    
    input stallSig,
    input clk, 
    input reset, 
    input aluSrc,
    input[31:0] imm,
    input[31:0] registerIn,
    output reg[31:0] muxOutput

);

    always@(posedge clk)
    begin
        
        //if(stallSig == 0) begin
        
        if(aluSrc == 1) muxOutput <= imm;
        else if(aluSrc == 0) muxOutput <= registerIn;

        //end
        
        //else if(stallSig == 1) muxOutput <= 'bx;        
        
    end
endmodule



module ALU (
    
    input[3:0] aluControl,
    input[31:0] registerIn,
    input[31:0] muxIn,  
    output reg[31:0] aluOut

);
    reg[32:0] tmp;
    always@(*)
    begin
    
        aluOut <= 'b0;
    
        case(aluControl)
        
            4'b0010 : tmp <= registerIn + muxIn;
            4'b0110 : tmp <= registerIn - muxIn;
            4'b0001 : tmp <= registerIn | muxIn;
            4'b1010 : tmp <= registerIn ^ muxIn;
            4'b0000 : tmp <= registerIn & muxIn;
            default : tmp <= 'bx;
        endcase       
        
        if(aluControl == 4'b0110 && registerIn < muxIn)
        begin
            aluOut <= (~tmp[31:0] + 1) >> 5;
        end
        else aluOut <= tmp[31:0];
        
    end

endmodule


module EX_MEM(
    
    input clk,
    input rst,
    input wreg,
    input m2reg,
    input wmem,
    input[4:0] regRtMux,
    input[31:0] aluIn,
    input[31:0] readRegTwo,
    
    output reg wregOut,
    output reg m2regOut,
    output reg wmemOut,
    output reg[4:0] regRtMuxOut,
    output reg[31:0] aluInOut,
    output reg[31:0] readRegTwoOut,
    output reg[4:0] mrn

);
    
    always@(posedge clk)
    begin
        wregOut <= wreg;
        m2regOut <= m2reg;
        wmemOut <= wmem;
        regRtMuxOut <= regRtMux;
        aluInOut <= aluIn;
        readRegTwoOut <= readRegTwo;
        mrn <= regRtMux;
    end
endmodule

module dataMem(

    input wmem,
    input[31:0] aluIn,
    input[31:0] readRegTwo,
    
    output reg[31:0] dataOut

);

    integer i;
    reg[31:0] memory [0:127];
    
    
    initial  // Set all memory to 0
    begin
        for(i = 40; i < 128; i = i + 4)
        memory[i] = 32'b0;
        
        memory[0] = 32'hA00000AA; 
        memory[4] = 32'h10000011; 
        memory[8] = 32'h20000022;
        memory[12] = 32'h30000033;
        memory[16] = 32'h40000044;
        memory[20] = 32'h50000055;
        memory[24] = 32'h60000066;
        memory[28] = 32'h70000077;
        memory[32] = 32'h80000088;
        memory[36] = 32'h90000099;
        
    end
    
    always@(*)
    begin
    
    dataOut <= memory[aluIn];
       
    if(wmem == 1) memory[aluIn] <= readRegTwo;
       
    end
    
endmodule

module MEM_WB(
    
    input clk,
    input wreg,
    input m2reg,
    input[4:0] regRtMux,
    input[31:0] alu,
    input[31:0] dataMem,
    
    output reg wregOut,
    output reg m2regOut,
    output reg[4:0] regRtOut,
    output reg[31:0] aluOut,
    output reg[31:0] dataMemOut

);

    always@(posedge clk)
    begin
        wregOut <= wreg;
        m2regOut <= m2reg;
        regRtOut <= regRtMux;
        aluOut <= alu;
        dataMemOut <= dataMem;      
    end
endmodule

module WBMux(
    
    input m2reg,
    input[31:0] alu,
    input[31:0] dataMem,
    
    output reg[31:0] WBData


);

    always@(*) begin
        if(m2reg == 1) WBData = dataMem;
        else if(m2reg == 0) WBData = alu;
    end

endmodule

module regFile(
    
    input clk,
    input rst,
    input writeReg,
    input[4:0] rs,
    input[4:0] rt,
    input[4:0] rd,
    input[31:0] dataMemIn,
    output reg[31:0] readDataOne,
    output reg[31:0] readDataTwo

);
    integer i;
    reg[31:0] registers [0:31];
    
    
    initial  // Set all registers to 0
    begin
        
        registers[0] = 32'h00000000;
        registers[1] = 32'hA00000AA; 
        registers[2] = 32'h10000011; 
        registers[3] = 32'h20000022;
        registers[4] = 32'h30000033;
        registers[5] = 32'h40000044;
        registers[6] = 32'h50000055;
        registers[7] = 32'h60000066;
        registers[8] = 32'h70000077;
        registers[9] = 32'h80000088;
        registers[10] = 32'h90000099;
        
    end
    
    always@(*)
    begin
        
        if(writeReg == 1) registers[rd] <= dataMemIn;

        readDataOne <= registers[rs];
        readDataTwo <= registers[rt];
            
    end

endmodule
