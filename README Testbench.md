````verilog
`timescale 1ns/1ps
module tb_fifo_async;
  
  parameter Width =8, Depth =8, PTR_Width =$clog2(Depth);
  reg wclk, rclk, w_en, r_en, wrst_n, rrst_n;
  reg [Width-1 :0] data_in;
  wire [Width-1 :0] data_out;
  wire full,empty;
  integer i;
  
  reg [Width-1 :0] exp_data_q[$], exp_data;
  
  fifo_async #(Width, Depth, PTR_Width) DUT (wclk, rclk, wrst_n, rrst_n, w_en, r_en, data_in, data_out, full, empty);
  
  always #10 wclk = ~wclk;
  always #35 rclk = ~rclk;
  
  initial begin 
    wclk = 0; 
    w_en = 0; 
    wrst_n = 0; 
    data_in = 0;
    
    repeat(10)@(posedge wclk);
      wrst_n <= 1;
    
    repeat(2) begin
      for(i=0; i<30; i=i+1) begin
        @(posedge wclk && !full);
        w_en <= (i%2) ? 1'b0 : 1'b1;
        if(w_en ) begin
        data_in <= $urandom % 2**Width;
        exp_data_q.push_back(data_in);
      end
    end
    #50;
  end
  end
  
  initial begin
    rclk = 0;
    r_en = 0;
    rrst_n = 0;
    
    repeat(10)@(posedge rclk);
    rrst_n <= 1;
    
    repeat(2) begin
      for(i=0; i<30; i=i+1) begin
        @(posedge rclk && !empty);
        r_en <= (i%2) ? 1'b0 : 1'b1;
        if(r_en ) begin
        exp_data <= exp_data_q.pop_front();
          if( data_out!== exp_data) begin
            $error("Time=%0t, Comparison Failed, exp_data =%d, data_out=%d, data_in=%d",$time,exp_data,data_out,data_in);
          end else begin
            $display("Time=%0t, Comparison Pass, exp_data =%d, data_out=%d, data_in=%d",$time,exp_data,data_out,data_in);
          end
        end
      end
   #500;
  end
  
  $finish;
  end
    
    initial begin
      $dumpfile("dump.vcd");
      $dumpvars;
    end
endmodule
