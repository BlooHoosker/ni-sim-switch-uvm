`timescale 1ns/10ps

`include "uvm_macros.svh"

// import knihovny UVM
import uvm_pkg::*;

class my_in_monitor extends uvm_monitor;

  // registrace do factory
  `uvm_component_utils(my_in_monitor)
  
  // deklarace rozhrani DUT
  virtual if_in inst_if_in;

  // deklarace objektu pro ukladani transakce
  my_pkg::my_item inst_collected_item;
  
  // port pro odesilani (nejen) do scoreboardu
  uvm_analysis_port #(my_pkg::my_item) inst_collected_item_port;
  
  // konstruktor
  function new (string name = "my_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  // faze build
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // vytvoreni portu pro odesilani (muze byt i v konstruktoru)
    inst_collected_item_port = new("inst_collected_item_port", this);

    // vyzvednuti reference na rozhrani DUT z databaze
    if(!uvm_config_db#(virtual if_in)::get(this, "", "inst_if_in", inst_if_in))
      `uvm_fatal("NOVIF", {"Missing inst_if_in: ", get_full_name(), ".inst_if_in"})
  endfunction
  
  // faze run - vlakno, ktere zajisti odposlech vstupniho rozhrani, prevod na transakci a odeslani na kontrolu
  virtual task run_phase(uvm_phase phase);
    fork
      monitor_send_packet(phase);
    join_none

    fork
      monitor_mem_write(phase);
    join_none
  endtask


  task monitor_send_packet(uvm_phase phase);
    // nekonecna smycka
    forever begin
      // cekani na udalost, ktera znaci platnost dat na sbernici
      @(posedge inst_if_in.packet_finished);
      // vytvoreni noveho objektu transakce
      inst_collected_item = my_pkg::my_item::type_id::create("inst_collected_item", this);
      // nastaveni polozek
      inst_collected_item.writeMemOp = 1'b0;
      inst_collected_item.addr = inst_if_in.port_address;
      inst_collected_item.data = inst_if_in.packet_data;
      // odeslani analytickym portem
      inst_collected_item_port.write(inst_collected_item);
    end
  endtask

  task monitor_mem_write(uvm_phase phase);
  // nekonecna smycka
  forever begin
    // cekani na udalost, ktera znaci platnost dat na sbernici
    @(posedge inst_if_in.mem_write);
    // vytvoreni noveho objektu transakce
    inst_collected_item = my_pkg::my_item::type_id::create("inst_collected_item", this);
    inst_collected_item.writeMemOp = 1'b1;
    inst_collected_item.portIndex = inst_if_in.mem_port_index;
    inst_collected_item.addr = inst_if_in.port_address;
    
    @(negedge inst_if_in.mem_write);
    // odeslani analytickym portem
    inst_collected_item_port.write(inst_collected_item);
  end
endtask

endclass
