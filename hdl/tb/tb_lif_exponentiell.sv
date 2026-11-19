`timescale 1ns/1ps

module testbench;

      logic clk = 0;
      logic t_spike;
      logic signed [15:0] input_current = '0;
      
      // Testszenarien
      typedef enum logic [2:0] { 
        IDLE          = 3'b000,
        MEM_ZERFALL     = 3'b001, 
        I_ZERFALL     = 3'b010,
        OVERFLOW_UP      = 3'b011,
        OVERFLOW_DOWN      = 3'b100
      } test_state_enum;
      
      test_state_enum current_state = IDLE;
      
      //LIF Neuron DUT Instanz
      // schema: <Modulname> <Instanzname> ( .<Port des Moduls>(<Signal hier>), ... );
      lif_neuron lif_dut ( .clk (clk),
                   .input_current (input_current),
                   .spike (t_spike));
                   
      always #5 clk = ~clk; //5ns  warten -> clock invertieren -> usw
       
   
      // Input an Falling Edge (da Vmem auf Rising Edge gespeichert wird - um Racing Conditions zu vermeiden)
      task automatic inject_current(input test_state_enum state, input logic signed [15:0] value);
            
            @(negedge clk);
            current_state = state;
            input_current = value;
            #1;
  
      endtask
         
      //Vergleich gegen v_mem  
      task automatic check_vmem(input string check_name, input logic signed [15:0] expected_value);
            if (lif_dut.v_next !== expected_value)
              $error("%s: v_next = %0d, erwartet %0d",  check_name, lif_dut.v_next, expected_value);
            else
              $display("%s: OK",  check_name);
      endtask
      
      //Vergleich gegen i_syn  
      task automatic check_isyn(input string check_name, input logic signed [15:0] expected_value);
            if (lif_dut.i_next !== expected_value)
              $error("%s: i_next = %0d, erwartet %0d",  check_name, lif_dut.i_next, expected_value);
            else
              $display("%s: OK",  check_name);
      endtask
      
         
      initial begin
            // Check 1: exponentieller Zerfall
            // Input_current wird das erste Mal eingegeben, anschliessend zerfaellt Membranpotential 
            inject_current(MEM_ZERFALL, 576);          // v_mem: 0 --> v_mem = 576
            check_vmem("Vmem nach dem Update ", 576);
            check_isyn("Synapse (Zerfall + input_current)", 576);
            
            // Es wird KEIN Input gegeben, Membranpotential zerfaellt
            inject_current(MEM_ZERFALL, 0);             // v_mem = 576 --> v_mem: 576 - (576>>>4) - (576>>>5) = 522
            check_vmem("Vmem nach dem Update  ", 720);
            check_isyn("Synapse (Zerfall + input_current)", 198);
            
             // Check 2: overflow
            inject_current(OVERFLOW_UP, +32600);  // v_mem = (522 -> Zerfall)  + 16000 --> v_mem:
            check_vmem("Overflow up: ", 16'sb0111111111111111);
            check_isyn("Synapse (Zerfall + input_current)", 32669);
            
            inject_current(OVERFLOW_DOWN, -600);
            
            inject_current(OVERFLOW_DOWN, -32600);
            check_vmem("Overflow down: ", 19309);  // GAR KEIN OVERFLOW EIGENTLICH
            
            @(posedge clk);
            @(negedge clk);
            
   
            $finish;
      end
                  
                  
                  
endmodule                  