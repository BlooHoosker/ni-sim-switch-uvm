`timescale 1ns/10ps

`include "uvm_macros.svh"

// import knihovny UVM
import uvm_pkg::*;

class my_monitor extends uvm_monitor;

  // registrace do factory
  `uvm_component_utils(my_monitor)
  
  // deklarace rozhrani DUT
  virtual if_out inst_if_out;
  
  // deklarace objektu pro ukladani transakce
  my_pkg::my_item inst_collected_item;
  
  // port pro odesilani (nejen) do scoreboardu
  uvm_analysis_port #(my_pkg::my_item) inst_collected_item_port;

  // promenna, do ktere se ulozi poradove cislo portu, ke ktere je pripojen konkretni objekt teto tridy
  int monitor_index;
  
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
    // nejprve index - poradove cislo portu
    if(!uvm_config_db#(int)::get(this, "", "monitor_index", monitor_index))
      `uvm_fatal("NOPAR", {"Missing monitor_index: ", get_full_name(), ".monitor_index"})    
    // pote rozhrani dle poradoveho cisla portu
    if(!uvm_config_db#(virtual if_out)::get(this, "", $sformatf("inst_if_out[%0d]", monitor_index), inst_if_out))
      `uvm_fatal("NOVIF", {"Missing inst_if_out: ", get_full_name(), ".inst_if_out"})
  endfunction
  
  // faze run - vlakno, ktere zajisti prevod prijem paketu od prepinace, prevod na transakci a odeslani na kontrolu
  virtual task run_phase(uvm_phase phase);

    // inicializace
    inst_if_out.port_received <= 1'b0;

    // nekonecna smycka
    forever begin
      // cekani na udalost, ktera znaci platnost dat na sbernici
      @(posedge inst_if_out.port_req);
      // vytvoreni noveho objektu transakce
      inst_collected_item = my_pkg::my_item::type_id::create("inst_collected_item", this);
      // nastaveni polozek
      inst_collected_item.data = inst_if_out.port_data;

      // chvile cekani - pro DUT se tvari jako doba, po kterou prijemce paket zpracovava
      @(posedge inst_if_out.clk);
      // potvrzeni pro DUT, ze paket byl prijat
      inst_if_out.port_received <= 1'b1;
      // cekani a ukonceni potvrzovacho signalu
      @(posedge inst_if_out.clk);
      inst_if_out.port_received <= 1'b0;
      
      // odeslani analytickym portem
      inst_collected_item_port.write(inst_collected_item);
    end
  endtask

endclass
