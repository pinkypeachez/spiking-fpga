// Delta LIF: nur eine Zustandsvariable
// 1) v_mem: Membranpotential (akkumuliert & zerfaellt exponentiell jeden Zeitschritt)

module lif_neuron
#(
//Qi.f
 parameter INT_BITS = 2, //inklusive Vorzeichenbit
 parameter FRAC_BITS = 14,
 parameter int V_TH_RAW = 1 << FRAC_BITS // Default Threshold = 1 
)
( 
 input logic clk,
 input logic signed [INT_BITS+FRAC_BITS-1 :0] input_current, 
 output logic spike
);
 
 localparam int WIDTH = INT_BITS + FRAC_BITS;
 
 // LIF Neuron Konstanten
 localparam signed [WIDTH-1:0] V_RESET = '0;
 localparam signed [WIDTH-1:0] V_TH = V_TH_RAW; 


 // erste Zustandsvariable: Membranpotential
// TODO: ueber Reset initialisieren (?????)
 logic signed [WIDTH-1:0] v_mem = '0;
 logic signed [WIDTH-1:0] v_next; // updated Membranpotential
 localparam int V_DECAY_SHIFT_1 = 4;
 localparam int V_DECAY_SHIFT_2 = 5;
 
 // zweite Zustandsvariable: Current [CUBA LIF: exponentieller Zerfall von Current] 
 localparam int I_DECAY_SHIFT_1 = 1;
 localparam int I_DECAY_SHIFT_2 = 3;
 localparam int I_DECAY_SHIFT_3 = 5;
 
 // overflow Schutz Konstanten (Saettigung)
 localparam logic signed [WIDTH-1:0] MAX = {1'b0, {(WIDTH-1){1'b1}}};

localparam logic signed [WIDTH-1:0] MIN = {1'b1, {(WIDTH-1){1'b0}}}; 
 
// Reine Verdrahtungen, verbrauchen keine Ressourcen!
 logic signed [WIDTH-1:0] v_decayed; // fuer das zwischenergebnis, fuers debugging
 logic signed [WIDTH-1:0] decay_1, decay_2;
 
 logic [0:0] intern_spike;
 assign intern_spike = (v_next >= V_TH);
 
 // 1. Neuron Dynamics (State Variable Update - Membranpotential v_mem --> v_next wird BERECHNET)
 always_comb begin
 // Exponentieller Zerfall wird durch 2 Bitshifts & 2 Substraktionen approximiert (statt Multiplikation mit einer Konstante)
 decay_1 = (v_mem >>> V_DECAY_SHIFT_1); // zerfall um 2^-4 = 1/16
 decay_2 = (v_mem >>> V_DECAY_SHIFT_2); // zerfall um 2^-5 = 1/32
 
 v_decayed = v_mem - decay_1 - decay_2;
 
 // Integration: Vmem_decayed + Iext
 v_next = v_decayed + input_current;
 
 // Saettigung bei Overflow 
 if ((v_decayed[WIDTH-1] == input_current[WIDTH-1]) && (v_decayed[WIDTH-1] != v_next[WIDTH-1])) begin 
 if (input_current[WIDTH-1] == 1'b1 ) v_next = MIN; //overflow negativ
 else v_next = MAX; //overflow positiv
 end
 
 end
 

always_ff @(posedge clk) begin
 v_mem <= intern_spike ? V_RESET : v_next;
 spike <= intern_spike;
end
 
 
 
 

endmodule