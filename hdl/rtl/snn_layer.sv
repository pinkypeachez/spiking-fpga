module snn_layer
#(
   // Architektur
   parameter N_PRE = 4, N_POST = 1,  
  
  // Leaky Integrate and Fire Modul Parameter
  // Bitbreite Vmem (Membranpotential)
    parameter INT_BITS = 2, //inklusive Vorzeichenbit
    parameter FRAC_BITS = 14,
  // Threshold
    parameter int V_TH_RAW = 1 << FRAC_BITS, // Default Threshold = 1
    
  // Synapse Parameter
    parameter int W_W = 8,
    parameter int W_FRAC = 7,
    parameter I_W = 16, //inklusive Vorzeichenbit
    parameter I_FRAC = 14
)
(
   input logic          enable,
   input logic          clk,
   input logic [N_PRE-1:0]    spikes_in,
   output logic [N_POST-1:0]         spike_out // direkt als Bitvector --> Input in die naechste Schicht
    );
    
    localparam int WIDTH = INT_BITS + FRAC_BITS;
    
    
    // VERBINDUNG: Synapse -> LIF
    logic signed [WIDTH-1:0] synaptic_current;
    
     synapse #(
        .N_PRE (N_PRE),
        .N_POST (N_POST),
        .W_W (W_W),
        .W_FRAC (W_FRAC),
        .I_W (I_W),
        .I_FRAC (I_FRAC)
    ) test_synapse (
        .bitvector     (spikes_in),
        .output_current (synaptic_current)
    );
 
    for (genvar post = 0; post < N_POST; post++) begin : g_lif
     lif_neuron lif (
      .clk(clk), .enable(enable),
      .input_current(synaptic_current[post]),
      .spike(spike_out[post]));
    end 
    
endmodule
