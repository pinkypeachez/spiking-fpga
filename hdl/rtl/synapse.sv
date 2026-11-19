// V.November; 4 zu 1 Architektur (aber theoretisch erweiterbar auf K zu N)
// noch voll parallel aber parametrisiert

module synapse
#(
  parameter N_PRE = 4, N_POST = 1,
  parameter W_W = 8, W_FRAC = 7,
  parameter I_W = 16, //inklusive Vorzeichenbit
  parameter I_FRAC = 14
)
(
   input logic unsigned [N_PRE-1:0]          bitvector,
   output logic signed [I_W-1 :0]            output_current [N_POST]
    );
    
    localparam int format_shift = (I_FRAC - (W_FRAC)); // Q1.7 -> Q2.14
    
    // Weight matrix
    // TODO: das funktioniert praktisch nur fuer 4 zu 1, weight matrix ueber $readmemh laden!!!
    logic signed [W_W-1:0] weight_matrix [N_PRE*N_POST] = '{
      8'sb0_0110011,  
      8'sb0_0100111, 
      8'sb0_1110111, 
      8'sb0_0100011
};

    always_comb 
     for (int post = 0; post < N_POST; post++) begin
       output_current[post] = '0;
       for (int pre = 0; pre < N_PRE; pre++) 
        if (bitvector[pre]) 
          output_current[post] +=  I_W'(weight_matrix[pre*N_POST + post]) <<< format_shift;    
    end

    
endmodule
