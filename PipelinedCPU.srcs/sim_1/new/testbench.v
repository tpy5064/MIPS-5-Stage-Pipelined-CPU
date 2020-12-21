`timescale 1ns / 1ps

module testbench();
    
    reg clock, rst_t;
    wire[31:0] pc_t;
    wire[31:0] instruction_t;
    wire[5:0] opcode_t, funct_t;
    wire[4:0] rs_t, rt_t, rd_t;
    wire[15:0] imm_t;
    wire writeReg_t, m2reg_t, writeMem_t, aluSource_t, aluImmediate_t, regrt_t;
    wire[3:0] aluControl_t;
    wire[1:0] aluOp_t;  
    wire[4:0] muxOut_t;
    wire[31:0] readDataOne_t, readDataTwo_t, extendedAdd_t;
    wire[31:0] aluMuxOut_t;
    
    
    //ID_EX Outs
    wire[31:0] pcOut_IDEX;
    wire writeRegOut_IDEX, m2regOut_IDEX, writeMemOut_IDEX, aluImmediateOut_IDEX, regrtOut_IDEX, aluSourceOut_IDEX;
    wire[4:0] muxOut_IDEX;
    wire[31:0] readDataOneOut_IDEX;
    wire[31:0] readDataTwoOut_IDEX;
    wire[31:0] immOut_IDEX;
    wire[3:0] aluControlOut_IDEX;
    wire[1:0] aluOpOut_IDEX;
    
    //ALU Outs
    wire[31:0] aluOut_t;
    
    //Data Memory Outs
    wire[31:0] dataMemOut_t;
    
    //EX_MEM Outs
    wire wregOut_EXMEM, w2regOut_EXMEM, wmemOut_EXMEM;
    wire[4:0] regRtMuxOut_EXMEM;
    wire[31:0] aluOut_EXMEM;
    wire[31:0] readRegTwoOut_EXMEM;
    
    //MEM_WB Outs
    wire wregOut_MEMWB, m2regOut_MEMWB;
    wire[4:0] regRtMuxOut_MEMWB;
    wire[31:0] aluOut_MEMWB;
    wire[31:0] dataMemOut_MEMWB;
    
    //MEM_WB Mux Outs
    wire[31:0] memWBMuxOut;
    
    //Stall related Outs
    wire stallSig;
    wire[4:0] ern;
    wire[4:0] mrn;
    
    
    
    programCounter uut_pc(stallSig, clock, rst_t, pc_t);
    
    instructionMemory uut_IM(pc_t, instruction_t);
    
    IF_ID uut_ifid(stallSig, clock, instruction_t, opcode_t, rs_t, rt_t, rd_t, funct_t, imm_t);
    
    controlUnit uut_CU(clock, opcode_t, funct_t, rs_t, rt_t, ern, mrn, writeReg_t, m2reg_t, writeMem_t, aluSource_t, 
                       aluImmediate_t, regrt_t, aluControl_t, aluOp_t, stallSig);
                       
    regRtMux uut_regrtmux(stallSig, clock, rst_t, regrt_t, rd_t, rt_t, muxOut_t);
    
    regFile uut_regs(clock, rst_t, wregOut_MEMWB, rs_t, rt_t, regRtMuxOut_MEMWB, memWBMuxOut, readDataOne_t, readDataTwo_t);
    
    signExtender uut_se(clock, imm_t, extendedAdd_t);
    
    ID_EX uut_idex(stallSig, clock, rst_t, aluSource_t, pc_t, writeReg_t, m2reg_t, writeMem_t, aluControl_t, 
                           aluImmediate_t, regrt_t, muxOut_t, readDataOne_t, readDataTwo_t, extendedAdd_t,aluOp_t,
                           pcOut_IDEX, writeRegOut_IDEX, m2regOut_IDEX, writeMemOut_IDEX, 
                           aluControlOut_IDEX, aluImmediateOut_IDEX, regrtOut_IDEX, muxOut_IDEX,
                           readDataOneOut_IDEX, readDataTwoOut_IDEX, immOut_IDEX, aluOpOut_IDEX, aluSourceOut_IDEX, ern);
                           
    aluMux uut_alum(stallSig, clock, rst_t, aluSourceOut_IDEX, immOut_IDEX, readDataTwo_t, aluMuxOut_t);
    
    ALU uut_alu(aluControlOut_IDEX, readDataOneOut_IDEX, aluMuxOut_t, aluOut_t);
    
    EX_MEM uut_exmem(clock, rst_t, writeRegOut_IDEX, m2regOut_IDEX, writeMemOut_IDEX, muxOut_IDEX, aluOut_t, readDataTwoOut_IDEX,
                     wregOut_EXMEM, w2regOut_EXMEM, wmemOut_EXMEM, regRtMuxOut_EXMEM, aluOut_EXMEM, readRegTwoOut_EXMEM, mrn);
                     
    dataMem uut_datmem(wmemOut_EXMEM, aluOut_EXMEM, readRegTwoOut_EXMEM, dataMemOut_t);
    
    MEM_WB uut_memwb(clock, wregOut_EXMEM, w2regOut_EXMEM, regRtMuxOut_EXMEM, aluOut_EXMEM, dataMemOut_t, 
                     wregOut_MEMWB, m2regOut_MEMWB, regRtMuxOut_MEMWB, aluOut_MEMWB, dataMemOut_MEMWB);
                     
    WBMux uut_wbmux(m2regOut_MEMWB, aluOut_MEMWB, dataMemOut_MEMWB, memWBMuxOut);
    
    initial
    begin
        rst_t = 0;
        clock = 0;
    end
    
    always
    begin
        clock = ~clock;
        #15;
    end
    
endmodule
