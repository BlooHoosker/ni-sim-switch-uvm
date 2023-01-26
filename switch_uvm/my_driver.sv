`timescale 1ns/10ps

`include "uvm_macros.svh"

// import knihovny UVM
import uvm_pkg::*;

class my_driver extends uvm_driver #(my_pkg::my_item);
  // zakladni trida uvm_driver je parametrizovatelna
  // parametr je trida definujici transakci
  
  // registrace do factory
  `uvm_component_utils(my_driver)
  
  // deklarace rozhrani DUT
  virtual if_in inst_if_in;
  
  // konstruktor
  function new (string name = "my_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  // faze build
  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    // vyzvednuti reference na rozhrani DUT z databaze
    if (!uvm_config_db#(virtual if_in)::get(this, "", "inst_if_in", inst_if_in))
      `uvm_fatal("NOVIF", {"Missing inst_if_in: ", get_full_name(), ".inst_if_in"})
  endfunction
  
  // faze run
  task run_phase (uvm_phase phase);
    super.run_phase(phase);
  
    // inicializace
    inst_if_in.packet_send_req <= 1'b0;
    inst_if_in.port_address <= {my_pkg::PORT_ADDR_LENGTH{1'bz}};
    inst_if_in.packet_data <= {my_pkg::DATA_WIDTH{1'bz}};
    inst_if_in.mem_port_index <= {$clog2(my_pkg::NUM_OF_PORTS){1'bz}};
    inst_if_in.mem_write <= 1'b0;

    // cekani na reset
    @(posedge inst_if_in.reset);

    // nekonecna smycka
    forever begin

      while(inst_if_in.reset !== 1'b0) begin
        // pokud (dokud) je reset, tak podrzet vychozi hodnoty
        inst_if_in.packet_send_req <= 1'b0;
        inst_if_in.port_address <= {my_pkg::PORT_ADDR_LENGTH{1'bz}};
        inst_if_in.packet_data <= {my_pkg::DATA_WIDTH{1'bz}};
        inst_if_in.mem_port_index <= {$clog2(my_pkg::NUM_OF_PORTS){1'bz}};
        inst_if_in.mem_write <= 1'b0;
        @(posedge inst_if_in.clk);
      end

      // zadost o dalsi polozku ze sekvenceru
      seq_item_port.get_next_item(req);
      // buzeni DUT - zpravidla v samostatnem tasku, ale neni nutne
      drive_item(req);
      // ohlaseni dokonceni buzeni
      seq_item_port.item_done();

      // nechat viset hodnoty na sbernici az do dalsiho taktu hodin
      @(posedge inst_if_in.clk);

    end
  endtask
  
  task drive_item (my_pkg::my_item req);

      if (req.writeMemOp == 1'b1) begin
        inst_if_in.mem_port_index <= req.portIndex;
        inst_if_in.port_address <= req.addr;
        @(posedge inst_if_in.clk);
        inst_if_in.mem_write <= 1'b1;
        @(posedge inst_if_in.clk);
        inst_if_in.mem_write <= 1'b0;

        `uvm_info(get_type_name(), $sformatf("Driver: memory write: \n%s", req.sprint()), UVM_LOW);
      end else begin
        // nastaveni polozek (jednotlivych signalu) rozhrani DUT
        inst_if_in.packet_send_req <= 1'b1;
        inst_if_in.port_address <= req.addr;
        inst_if_in.packet_data <= req.data;
        
        // pockat na reakci DUT
        @(posedge inst_if_in.packet_finished);
        inst_if_in.packet_send_req <= 1'b0;

        // vypis hlasky na konzoli
        `uvm_info(get_type_name(), $sformatf("Driver: item sent: \n%s", req.sprint()), UVM_LOW);
      end

  endtask

endclass
