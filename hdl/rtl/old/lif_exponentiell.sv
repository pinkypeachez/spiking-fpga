// Modell von CUBA-LIF mit 2 Zustandsvariablen:
// 1) v_mem: Membranpotential (akkumuliert & zerfaellt exponentiell jeden Zeitschritt)
// 2) Current ( zerfaellt exponentiell & wird mit Input_current von der Synapse summiert)
// exponentieller Zerfall wird mit den Bitshifts statt Multiplikation mit dem Zerfallsfaktor modelliert

module lif_neuron
#(
//Qi.f
    parameter INT_BITS = 2, //inklusive Vorzeichenbit
    parameter FRAC_BITS = 14,
    parameter int V_TH_RAW = 1 << FRAC_BITS // Default Threshold = 1        
)
(   
    input  logic                                   enable,
    input logic                                    clk,
    input logic signed [INT_BITS+FRAC_BITS-1 :0]   input_current, 
    output logic                                   spike
);
    
    localparam int WIDTH = INT_BITS + FRAC_BITS;
    
    // LIF Neuron Konstanten
    localparam signed [WIDTH-1:0] V_RESET = '0;
    localparam signed [WIDTH-1:0] V_TH =  V_TH_RAW;   

    // Zerfall:  Membranzeitkonstante (tau_mem)
    localparam int V_DECAY_SHIFT_1 = 4;
    localparam int V_DECAY_SHIFT_2 = 5;

    // Zerfall: Synapsenzeitkonstante (tau_syn)
    localparam int I_DECAY_SHIFT_1 = 1;
    localparam int I_DECAY_SHIFT_2 = 3;
    localparam int I_DECAY_SHIFT_3 = 5;
    
    // overflow Schutz Konstanten (Saettigung)
    localparam logic signed [WIDTH-1:0] MAX = {1'b0, {(WIDTH-1){1'b1}}};
    localparam logic signed [WIDTH-1:0] MIN = {1'b1, {(WIDTH-1){1'b0}}}; 
    
    // ZUSTANDSVARIABLEN
    logic signed [WIDTH-1:0] v_mem = '0;  //  Membranpotential
    logic signed [WIDTH-1:0] i_syn = '0;   //Current [CUBA LIF: exponentieller Zerfall von Current]     
    
    // KOmbinatorik
    logic signed [WIDTH-1:0] i_decayed, i_next;
    logic signed [WIDTH-1:0] v_decayed, v_next; // updated Membranpotential
    
    logic [0:0] intern_spike;
    assign intern_spike = (v_next >= V_TH);
    
    // 1. Neuron Dynamics (State Variable Update - Membranpotential v_mem --> v_next wird BERECHNET)
    always_comb begin
     //  i_decayed =  i_syn - (i_syn >>> I_DECAY_SHIFT_1) -  (i_syn >>> I_DECAY_SHIFT_2) - (i_syn >>> I_DECAY_SHIFT_3);
     //  i_next = input_current + i_decayed;
       
       // Saettigung bei Overflow 
     //  if ((input_current[WIDTH-1] == input_current[WIDTH-1]) && (input_current[WIDTH-1] != v_next[WIDTH-1])) begin 
     //      if (input_current[WIDTH-1] == 1'b1 ) i_next = MIN; //overflow negativ
     //      else  i_next = MAX;   //overflow positiv
     //  end
       
       v_decayed = v_mem -  (v_mem >>> V_DECAY_SHIFT_1) -  (v_mem >>> V_DECAY_SHIFT_2);
       
     // Integration: Vmem_decayed + Iext
     // v_next =  v_decayed + i_next;
       v_next =  v_decayed + input_current;
     
     // Saettigung bei Overflow 
       if ((v_decayed[WIDTH-1] == input_current[WIDTH-1]) && (v_decayed[WIDTH-1] != v_next[WIDTH-1])) begin 
           if (input_current[WIDTH-1] == 1'b1 ) v_next = MIN; //overflow negativ
           else  v_next = MAX;   //overflow positiv
       end
       
     end
       

    always_ff @(posedge clk) begin
     if (enable) begin
       // i_syn <= i_next;
        v_mem <= intern_spike ? V_RESET : v_next;
        spike <= intern_spike;
     end else
        spike <= 1'b0;
    end
    
    
    
   

endmodule