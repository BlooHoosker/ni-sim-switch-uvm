interface if_out (input logic clk, input logic reset); // deklarace rozhrani typu SERIAL
    logic port_req;
    logic [my_pkg::DATA_WIDTH-1:0] port_data;
    logic port_received;
endinterface