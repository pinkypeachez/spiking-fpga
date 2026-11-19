// Erste Variante:  4 zu 1 Architektur, nur zum testen

module synapse
#(
  parameter NUMBER_NEURONS = 4,
  parameter WEIGHT = 8,
  parameter INT_BITS = 2, //inklusive Vorzeichenbit
  parameter FRAC_BITS = 14
)
(
   input logic unsigned [NUMBER_NEURONS-1:0]                bitvector,
   output logic signed [INT_BITS+FRAC_BITS-1 :0]            output_current
    );
    
    localparam int format_shift = (FRAC_BITS - (WEIGHT-1)); // Q1.7 -> Q2.14
       
 // TODO: Encoder statt N Leitungen 
    logic signed [WEIGHT-1:0] weight0 =8'b0_0110011;
    logic signed [WEIGHT-1:0] wire0 = WEIGHT'(weight0) <<< format_shift;  
    
    logic signed [WEIGHT-1:0] weight1 =8'b0_0100111;
    logic signed [WEIGHT-1:0] wire1 = WEIGHT'(weight1) <<< format_shift;  
    
    logic signed [WEIGHT-1:0] weight2 = 8'b0_1110111;
    logic signed [WEIGHT-1:0] wire2 = WEIGHT'(weight2) <<< format_shift;  
    
    logic signed [WEIGHT-1:0] weight3 = 8'b0_0100011;
    logic signed [WEIGHT-1:0] wire3  = WEIGHT'(weight3) <<< format_shift;  
    
    
    always_comb begin
    
    
      if (bitvector[0] == 1'b1)  wire0 = weight0;
      else wire0 = '0;
      
      if (bitvector[1] == 1'b1)  wire1 = weight1;
      else wire1 = '0;
      
      if (bitvector[2] == 1'b1)  wire2 = weight2;
      else wire2 = '0;
      
      if (bitvector[3] == 1'b1)  wire3 = weight3;
      else wire3 = '0;
      
      output_current =  wire0 + wire1 + wire2 + wire3;
    
    
    end

    
endmodule
