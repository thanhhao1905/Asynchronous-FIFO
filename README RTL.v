module synchronous_2ff #(parameter Width = 3) (input clk, rst_n, 
                                               input [Width :0] d_in,
                                               output reg [Width :0] d_out);
  reg [Width :0] q;
  
  always@(posedge clk or negedge rst_n)
    
    if(!rst_n) begin
      q <= 0;
      d_out <= 0;
    end else begin
      q <= d_in;
      d_out <= q;
    end
endmodule


module write_pointer_handler #(parameter Width = 3) (input wclk, wrst_n, w_en,
                                                     input [Width:0] g_rptr_sync,
                                                     output reg full,
                                                     output reg [Width:0] b_wptr, g_wptr);
  reg [Width :0 ] b_wptr_next;
  reg [Width :0 ] g_wptr_next;
  wire wfull;
  
  always@(posedge wclk or negedge wrst_n)
    if(!wrst_n) begin
      b_wptr <= 0;
      g_wptr <= 0;
      full <= 0;
    end else begin
      
      b_wptr_next = b_wptr + (w_en && !full);
 	  g_wptr_next = ( b_wptr_next >> 1) ^ b_wptr_next;
      
      b_wptr <= b_wptr_next;
      g_wptr <= g_wptr_next;
      
      full <= wfull;
    end
  
  assign wfull = (g_wptr_next == {~g_rptr_sync[Width : Width-1],g_rptr_sync[Width-2 :0]});
  //assign wfull =(( g_wptr[Width] != g_rptr_sync[Width] ) && (g_wptr[Width-1 :0] == g_rptr_sync[Width-1 :0]));
endmodule
  


module read_pointer_handler #(parameter Width = 3) (input rclk, rrst_n, r_en,
                                                    input [Width :0] g_wptr_sync,
                                                    output reg empty,
                                                    output reg [Width :0] b_rptr, g_rptr);
  reg [Width :0] b_rptr_next;
  reg [Width :0] g_rptr_next;
  wire wempty;
  
  always @(posedge rclk or negedge rrst_n)
    if(!rrst_n) begin
      b_rptr <= 0;
      g_rptr <= 0;
      empty <= 1;
    end else begin
      
      b_rptr_next = b_rptr + (r_en && !empty);
      g_rptr_next = (b_rptr_next >> 1)^b_rptr_next;
      
      b_rptr <= b_rptr_next;
      g_rptr <= g_rptr_next;
      
       empty <= wempty;
    end
  assign wempty = g_wptr_sync == g_rptr;
endmodule

module fifo_memo #(parameter Width = 8, Depth =8, PTR_Width =$clog2(Depth))(input wclk, rclk, w_en, 
                                                                            r_en, full,empty,
                                                                            input[PTR_Width :0] b_wptr, 
                                                                            b_rptr,
                                                                            input[Width-1:0] data_in,
                                                                            output reg [Width-1:0] 
                                                                            data_out);
  reg [Width-1:0] fifo [0:Depth-1];
  
  always @(posedge wclk)
    if(w_en && !full)begin
      fifo[b_wptr[PTR_Width-1 :0]] <= data_in;
    end 
  
  always @(posedge rclk)
    if(r_en && !empty)begin
     data_out <= fifo[b_rptr[PTR_Width-1:0]];
    end
  
  //assign data_out = fifo[b_rptr[PTR_Width-1 :0]];
endmodule

module fifo_async #(parameter Width =8, Depth =8, PTR_Width =$clog2(Depth)) (input wclk, rclk, wrst_n, 
                                                                             rrst_n, w_en, r_en,
                                                                             input [Width-1 :0] data_in,
                                                                             output [Width-1:0]data_out,
                                                                             output full, empty);
  wire [PTR_Width : 0] g_wptr_sync,g_rptr_sync;
  wire [PTR_Width : 0] g_wptr, g_rptr;
  wire [PTR_Width : 0] b_wptr, b_rptr;
  
  //wire [PTR_Width-1 :0] waddr, raddr;
  
  synchronous_2ff # (PTR_Width) synchronous_write (wclk, wrst_n, g_rptr, g_rptr_sync);
  synchronous_2ff # (PTR_Width) synchronous_read (rclk, rrst_n, g_wptr, g_wptr_sync);
  
  write_pointer_handler # (PTR_Width) w_ptr_h (wclk, wrst_n, w_en, g_rptr_sync, full, b_wptr, g_wptr);
  read_pointer_handler # (PTR_Width) r_ptr_h (rclk, rrst_n, r_en, g_wptr_sync, empty, b_rptr, g_rptr);
  fifo_memo # (Width, Depth, PTR_Width) fifom (wclk, rclk, w_en, r_en, full, empty, b_wptr, b_rptr, data_in, data_out);
  
endmodule
