`timescale 1ns/10ps

`include "uvm_macros.svh"

// import knihovny UVM
import uvm_pkg::*;

class my_sequence extends uvm_sequence #(my_pkg::my_item);
  // zakladni trida uvm_sequence je parametrizovatelna
  // parametr je trida definujici transakci

  // registrace do factory
  `uvm_object_utils(my_sequence)

  // deklarace transakce
  my_pkg::my_item inst_item;

  // konstruktor
  function new(string name = "my_sequence");
    super.new(name);
  endfunction

  // telo sekvence
  virtual task body();
    // pro jednoduchou sekvenci lze pouzit makro uvm_do
    `uvm_do(inst_item)
  endtask

endclass
