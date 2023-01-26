// Code your design here
`default_nettype none

module memory #(parameter NUM_OF_PORTS = 10, parameter PORT_ADDR_LENGTH = 8)(
  input wire clk,
  input wire reset,
  input wire wr_en,
  input wire [PORT_ADDR_LENGTH-1:0] port_address,
  input wire [$clog2(NUM_OF_PORTS)-1:0] port_index,
  output wire found_port,
  output reg [$clog2(NUM_OF_PORTS)-1:0] found_port_index
);
  
reg [PORT_ADDR_LENGTH-1:0] memory_reg [NUM_OF_PORTS-1:0];
reg addr_exists;

// Memory register process
integer n;
always @(posedge clk)
begin
  if (reset)
    for (n=0;n<NUM_OF_PORTS;n=n+1)
    begin
      memory_reg[n]= {PORT_ADDR_LENGTH{1'b0}};
    end
  else if (wr_en && !addr_exists)
    memory_reg[port_index] <= port_address;
end

// Check if address already exists inside address memory
integer i;
always @(*)
begin
  addr_exists = 1'b0;
  found_port_index = 0;
  for (i = 0; i < NUM_OF_PORTS; i=i+1)
  begin
    if ((memory_reg[i] == port_address) && (port_address != {PORT_ADDR_LENGTH{1'b0}})) begin
      addr_exists = 1'b1;
      found_port_index = i;
    end
  end
end

assign found_port = addr_exists;

endmodule

module switch #(parameter NUM_OF_PORTS = 10, PORT_ADDR_LENGTH = 8, DATA_WIDTH = 8)(
    input wire clk,
    input wire reset,
    input wire [$clog2(NUM_OF_PORTS)-1:0] mem_port_index,
    input wire [PORT_ADDR_LENGTH-1:0] port_address,
    input wire mem_write,
    input wire [DATA_WIDTH-1:0] packet_data,
    input wire packet_send_req,

    output reg packet_finished,
    output reg [NUM_OF_PORTS-1:0] port_req,
    output reg [NUM_OF_PORTS*DATA_WIDTH-1:0] port_data,
    input wire [NUM_OF_PORTS-1:0] port_received
  );

  wire [NUM_OF_PORTS*PORT_ADDR_LENGTH-1:0] memory_data_i;
  wire [PORT_ADDR_LENGTH-1:0] port_address_i;
  wire addr_exist_i;

  // State encodings
  reg [2:0] curr_state;
  parameter [2:0]
            IDLE    = 3'b001,
            REQ     = 3'b010,
            FOUND   = 3'b100;

  wire wr_en_i;
  wire [$clog2(NUM_OF_PORTS)-1:0] curr_port_i;
  wire found_port_i;

  assign wr_en_i = (mem_write && (curr_state == IDLE));

memory #(.NUM_OF_PORTS(NUM_OF_PORTS), .PORT_ADDR_LENGTH(PORT_ADDR_LENGTH)) i_memory (
           .clk(clk),
           .reset(reset),
           .wr_en(wr_en_i),
           .port_address(port_address),
           .port_index(mem_port_index),
      .found_port(found_port_i),
           .found_port_index(curr_port_i)
         );

  // State transitions
  always @(posedge clk)
  begin
    if (reset)
      curr_state <= IDLE;
    else begin
        case (curr_state)
          IDLE:
            if (packet_send_req)
              curr_state <= REQ;
            else
              curr_state <= IDLE;
          REQ:
            if (found_port_i)
              curr_state <= FOUND;
            else
              curr_state <= IDLE;
          FOUND: begin
            if (port_received[curr_port_i])
              curr_state <= IDLE;
            else
              curr_state <= FOUND;
          end
          default:
            curr_state <= IDLE;
        endcase
     end
  end

  always @(*)
  begin
      packet_finished <= 1'b0;
      port_req <= {NUM_OF_PORTS{1'b0}};
      port_data <= {(NUM_OF_PORTS*DATA_WIDTH){1'b0}};
      case (curr_state)
          IDLE: begin
              
          end
          REQ: begin
            if (!found_port_i)
              packet_finished <= 1'b1;
          end
          FOUND: begin
              if (port_received[curr_port_i])
                packet_finished <= 1'b1;
              else begin
                port_req[curr_port_i] <= 1'b1;
                port_data[curr_port_i*DATA_WIDTH +: DATA_WIDTH] <= packet_data;
              end
          end
      endcase
  end
endmodule