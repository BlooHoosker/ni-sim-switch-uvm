// Code your testbench here
// or browse Examples
`default_nettype none
`define NUM_PORTS 10
`define PORT_ADDR_LEN 8
`define D_WIDTH 8

module test;
  reg  clk;
  reg  reset;
  reg  [$clog2(`NUM_PORTS)-1:0] mem_port_index;
  reg [`PORT_ADDR_LEN-1:0] port_address;
  reg mem_write;
  reg [`D_WIDTH-1:0] packet_data;
  reg packet_sent_req;
  
  wire packet_finished;
  wire [`NUM_PORTS-1:0] port_req;
  wire [`NUM_PORTS*`D_WIDTH-1:0] port_data;
  reg  [`NUM_PORTS-1:0] port_received;
  
  switch #(.NUM_OF_PORTS(`NUM_PORTS), .PORT_ADDR_LENGTH(`PORT_ADDR_LEN), .DATA_WIDTH(`D_WIDTH)) i_switch ( 
    .clk(clk),
    .reset(reset),
    .mem_port_index(mem_port_index),
    .port_address(port_address), 
    .mem_write(mem_write),
    .packet_data(packet_data),
    .packet_send_req(packet_sent_req),
  
    .packet_finished(packet_finished),
    .port_req(port_req),
    .port_data(port_data),
    .port_received(port_received)
  );
    
  always 
  begin
    #5 clk <= 1'b0;
    #5 clk <= 1'b1;
  end
  
  reg [`PORT_ADDR_LEN-1:0] addr_mirror [`NUM_PORTS-1:0];
  reg send_active;
  integer found_port;
  integer j;
  task sendPacketStart(
    input integer addr, 
    input [`D_WIDTH-1:0] packet
  ); begin
    $display("========== Sending packet ==========");
    $display("Address: %0d", addr);
    $display("Data (hexa): %0h", packet);
    port_received = {`NUM_PORTS{1'b0}};
    send_active = 1'b1;
    found_port = -1;
    for (j = 0; j < `NUM_PORTS; j = j+1) begin
      if (addr_mirror[j] == addr) begin
        found_port = j;
      end
    end
    
    $display("Found port by address: %0d", found_port);
    
    @(posedge clk);  
    port_address <= addr;
    packet_data <= packet;
    packet_sent_req <= 1'b1;
    @(posedge clk);
    packet_sent_req <= 1'b0;
  end endtask
  
  task sendPacketEnd(
      input [`D_WIDTH-1:0] packet
    ); begin
    #20
    // If port isn't found in address_mirror it means it shouldnt be in switch memory either
    if (found_port == -1) begin
      // Checking if all req and data signals are 0
      for (j = 0; j < `NUM_PORTS; j = j+1) begin
        if (port_req[j])
          $display("ERROR: Port req %0d at 1", j);
        
        if (port_data[j*`D_WIDTH +: `D_WIDTH] != 0) 
          $display("ERROR: Data at port %0d", j);
      end
    // If port is found in address_mirror it means it should be in switch memory as well
    end else begin
      // Check if switch gives port req on correct index
      if (!port_req[found_port])
        $display("ERROR: No port req on port %0d", found_port);
        
      if (port_data[found_port*`D_WIDTH +: `D_WIDTH] != packet)
        $display("ERROR: Data %0h being sent don't match packet %0h", port_data[found_port*`D_WIDTH +: `D_WIDTH], packet);
      
      // Set port req to 1 on wrong index
      @(posedge clk);  
      if (found_port == 0) 
        port_received[found_port+1] <= 1'b1;
      else if (found_port > 0) 
        port_received[found_port-1] <= 1'b1;
      
      // Check if switch responds to port_req on wrong index
      if (packet_finished)
        $display("ERROR: Packet finished on wrong port %0d", found_port); 
      @(posedge clk);  
      
      // Set port req to 1 on correct index
      port_received[found_port] <= 1'b1;  
      @(posedge clk);  
      
      // Check if switch responds to port_req on correct index
      if (!packet_finished)
        $display("ERROR: Packet not finished on correct port %0d", found_port); 
        
      port_received[found_port] <= 1'b0;  
      @(posedge clk);  
      
    end
    
    send_active = 1'b0;
    $display("========== Finished sending packet ==========");
  end endtask
  
  reg addr_exists;
  reg [`PORT_ADDR_LEN-1:0] port_address_tmp;
  integer i;
  task writeAddr(
    input integer port,
    input integer addr
  ); begin
    $display("========== Writing address ==========");
    $display("Address: %0d", addr);
    $display("Port: %0d", port);
    addr_exists = 1'b0;
    port_address_tmp <= port_address;
    for (i = 0; i < `NUM_PORTS; i = i+1) begin
      if (addr_mirror[i] == addr) begin
        addr_exists = 1'b1;
      end
    end
    
    @(posedge clk);
    mem_port_index <= port;
    port_address <= addr;
    
    @(posedge clk);
    mem_write <= 1'b1;
    if (!send_active && addr != 0 && !addr_exists)
      addr_mirror[port] <= addr;
      
    @(posedge clk);
    mem_write <= 1'b0;
    $display("========== Finished writing address ==========");
    port_address <= port_address_tmp;
    mem_port_index <= {$clog2(`NUM_PORTS){1'b0}};
    @(posedge clk);
  end endtask
  
  initial
  begin
    //$dumpfile("dump.vcd");
    //$dumpvars(1, test);
    
    // Initialize variables
    reset = 1'b1;
    mem_port_index = {$clog2(`NUM_PORTS){1'b0}};
    port_address = {`PORT_ADDR_LEN{1'b0}};
    mem_write = 1'b0;
    packet_data = {`D_WIDTH{1'b0}};
    packet_sent_req = 1'b0;
    port_received = {`NUM_PORTS{1'b0}};
    send_active = 0;
    
    #100
    // Release reset
    reset <= 1'b0;
    @(posedge clk);
    
    // Write address 42 to port 3
    writeAddr(3, 42);
    
    // Send packet at address 42. This address should be saved already
    sendPacketStart(42, 69);
    sendPacketEnd(69);  
    
    // Send packet to non existing address
    sendPacketStart(69, 69);
    sendPacketEnd(69); 
    
    // Write duplicate address to different port
    writeAddr(4, 42);
    #10
    // Rewrite address of one of the duplicates
    // If duplicate address was allowed, port 4 would have address 42 now
    writeAddr(3, 13);
    #10
    
    // Send packet to address 42
    sendPacketStart(42, 69);
    sendPacketEnd(69); 
    
    // Send packet to existing address 69
    sendPacketStart(13, 69);
    // Write address 69 to port 5 while transfer is in process
    writeAddr(5, 69);
    sendPacketEnd(69); 
    
    // Test if address 69 is in memory (it shouldn't be)
    sendPacketStart(69, 69);
    sendPacketEnd(69); 
     
    #100
    $finish;
  end

endmodule