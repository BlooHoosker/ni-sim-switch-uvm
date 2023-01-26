interface if_in (input logic clk, input logic reset); // deklarace rozhrani typu SERIAL
  logic [$clog2(my_pkg::NUM_OF_PORTS)-1:0] mem_port_index;
  logic [my_pkg::PORT_ADDR_LENGTH-1:0] port_address;
  logic mem_write;

  logic [my_pkg::DATA_WIDTH-1:0] packet_data;
  logic packet_send_req;
  logic packet_finished;
endinterface