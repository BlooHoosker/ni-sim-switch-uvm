`timescale 1ns/10ps

`include "uvm_macros.svh"

// import knihovny UVM
import uvm_pkg::*;

class my_test extends uvm_test;

  // registrace do factory
  `uvm_component_utils(my_test)
  
  // deklarace prostredi a sekvence
  my_pkg::my_env env;
  my_pkg::my_sequence seq;
  
  // konstruktor
  function new (string name = "my_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  // faze build
  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    // vytvoreni prostredi a sekvence
    env = my_pkg::my_env::type_id::create("env", this); // konstruktory komponent potrebuji referenci nadrazene komponenty
  endfunction
  
  // faze run
  task run_phase (uvm_phase phase);
    uvm_objection objection;
    super.run_phase(phase);

    // moznost nastaveni casu, ktery dobehne jeste potom, co vsechny komponenty stahly sve namitky (tj. umoznily konec testu)
    //phase.phase_done.set_drain_time(this, 100ns);

    // nekonecna smycka, ktera spousti stale stejnou sekvenci bez namitek - rizeni ukonceni testu je ciste v rezii scoreboardu
    forever begin
      //`uvm_info(get_type_name(), $sformatf("Test: Run: create sequence"), UVM_LOW)
      // vytvor objekt sequence
      seq = my_pkg::my_sequence::type_id::create("seq", this);

      //`uvm_info(get_type_name(), $sformatf("Test: Run: start sequence"), UVM_LOW)
      // zahaj sekvenci - tj. vygeneruj nahodne hodnoty v polozkach objektu tridy my_item a posli objekt pres driver na DUT
      seq.start(env.inst_sequencer);
    end

  endtask
  
  // volitelne - vypis topologie testu a konfiguracni databaze
  uvm_table_printer printer; // deklarace objektu pro formatovany vypis
  
  // faze end of elaboration - debugovaci vypisy mezi sestavenim testovaciho prostredi a zahajenim testu - lze zakomentovat pro mene ukecany vypis
  virtual function void end_of_elaboration_phase (uvm_phase phase);
    // vypis topologie testu
    `uvm_info(get_type_name(), $sformatf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
    // vypis konfiguracni databaze
    uvm_config_db #(int)::dump();
  endfunction

endclass
