`include "switch_top.v"

module top (
        input wire clk,
        input wire reset,
        interface interface_input,
        interface interface_output[my_pkg::NUM_OF_PORTS-1:0]
    );

    logic packet_finished;
    logic [my_pkg::NUM_OF_PORTS-1:0] port_req;
    logic [my_pkg::NUM_OF_PORTS*my_pkg::DATA_WIDTH-1:0] port_data;
    logic [my_pkg::NUM_OF_PORTS-1:0] port_received;

    switch #(.NUM_OF_PORTS(my_pkg::NUM_OF_PORTS), .PORT_ADDR_LENGTH(my_pkg::PORT_ADDR_LENGTH), .DATA_WIDTH(my_pkg::DATA_WIDTH)) i_switch (
        .clk(clk),
        .reset(reset),
        .mem_port_index(interface_input.mem_port_index),
        .port_address(interface_input.port_address),
        .mem_write(interface_input.mem_write),
        .packet_data(interface_input.packet_data),
        .packet_send_req(interface_input.packet_send_req),
    
        .packet_finished(interface_input.packet_finished),
        .port_req(port_req),
        .port_data(port_data),
        .port_received(port_received)
    );

    for(genvar i = 0; i < my_pkg::NUM_OF_PORTS; i++) begin
        always@(*) begin
            interface_output[i].port_req <= port_req[i];
            interface_output[i].port_data <= port_data[i*my_pkg::DATA_WIDTH +: my_pkg::DATA_WIDTH];
            port_received[i] <= interface_output[i].port_received;
        end
    end

endmodule
    