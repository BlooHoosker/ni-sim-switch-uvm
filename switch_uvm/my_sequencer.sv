`timescale 1ns/10ps

`include "uvm_macros.svh"

// import knihovny UVM
import uvm_pkg::*;

class my_sequencer extends uvm_sequencer #(my_pkg::my_item);
  // zakladni trida uvm_sequencer je parametrizovatelna
  // parametr je trida definujici transakci

  // registrace do factory
  `uvm_component_utils(my_sequencer)

  // konstruktor
  function new (string name = "my_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass
