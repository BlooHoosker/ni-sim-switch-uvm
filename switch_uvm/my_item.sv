`timescale 1ns/10ps

`include "uvm_macros.svh"

// import knihovny UVM
import uvm_pkg::*;

class my_item extends uvm_sequence_item;

  // deklarace jednotlivych polozek
  rand bit [my_pkg::PORT_ADDR_LENGTH-1:0] addr;
  rand bit [my_pkg::DATA_WIDTH-1:0] data;

  rand bit writeMemOp;
  rand integer portIndex;
  
  // omezeni nahodnych hodnot
  constraint constraint_addr {
    addr inside {[0:my_pkg::NUM_OF_PORTS-1]};
    portIndex inside {[0:my_pkg::NUM_OF_PORTS-1]};
    writeMemOp dist {1'b0 := 2, 1'b1 := 1};
  }
  
  // registrace tridy a vsech polozek do factory (dulezite! - musi byt pro kazdou polozku)
  `uvm_object_utils_begin(my_item)
    `uvm_field_int(addr, UVM_DEFAULT)
    `uvm_field_int(data, UVM_DEFAULT)
    `uvm_field_int(writeMemOp, UVM_DEFAULT)
    `uvm_field_int(portIndex, UVM_DEFAULT) // pro promennou typu bit se take pouziva uvm_field_int
  `uvm_object_utils_end
  
  // konstruktor
  function new (string name = "my_item");
    super.new(name);
    assert(this.randomize());
  endfunction

endclass
