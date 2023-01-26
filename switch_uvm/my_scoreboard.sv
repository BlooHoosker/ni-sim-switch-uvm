`timescale 1ns/10ps

`include "uvm_macros.svh"

// import knihovny UVM
import uvm_pkg::*;

class my_scoreboard extends uvm_scoreboard;

  // registrace do factory
  `uvm_component_utils(my_scoreboard)

  // importy pro prijem z jednotlivych monitoru
  uvm_tlm_analysis_fifo #(my_pkg::my_item) inst_in_fifo;
  uvm_tlm_analysis_fifo #(my_pkg::my_item) inst_out_fifo[0:my_pkg::NUM_OF_PORTS-1];
  
  int coverage_done;
  int portsWrittenInto [0:my_pkg::NUM_OF_PORTS-1];
  logic [my_pkg::PORT_ADDR_LENGTH-1:0] addr_memory_mirror [my_pkg::NUM_OF_PORTS-1:0];

  // konstruktor
  function new (string name = "my_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    // sablona pocita, ze na pokryti staci 10 paketu, at uz jsou jakekoli
    coverage_done = 0;
    portsWrittenInto = '{default:0};
    for (int n = 0; n < my_pkg::NUM_OF_PORTS ; n=n+1)
    begin
      addr_memory_mirror[n] <= n;
    end
  endfunction

  // faze build
  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    // vytvoreni portu pro prijem (muze byt i v konstruktoru)
    inst_in_fifo = new("inst_in_fifo", this);
    
    for(int i = 0; i < my_pkg::NUM_OF_PORTS; i++) begin
      inst_out_fifo[i] = new($sformatf("inst_out_fifo[%0d]", i), this);
    end
  endfunction

  // faze run - vlakno, ktere bude vybirat data z jednotlivych monitoru
  task run_phase (uvm_phase phase);
    super.run_phase(phase);
    
    // zamezeni ukonceni testu, dokud neni splneno pokryti
    phase.raise_objection(this);
    
    // vytvoreni samostatnych vlaken - pro kazdy port jedno
    for(int i = 0; i < my_pkg::NUM_OF_PORTS; i++) begin
      fork
        int index = i;
        scoreboard_match(index, phase);
      join_none
    end

    fork
      scoreboard_addr_mem(phase);
    join_none

  endtask

  task scoreboard_match(int index, uvm_phase phase);
    // objekty, do kterych se budou ukladat data z monitoru
    my_pkg::my_item in_item;
    my_pkg::my_item out_item;
    int find_res[$];

    //`uvm_info(get_type_name(), $sformatf("Scoreboard: scoreboard_match: start - thread %0d", index), UVM_LOW)

    forever begin
      // blokujici cteni z vystupni fronty (vystupniho rozhrani)
      inst_out_fifo[index].get(out_item);
      // pokud prisla data z vystupniho portu, tak precti data ze vstupu (v sablone tam jina byt nemohou)
      inst_in_fifo.get(in_item);

      // v sablone jsou adresy stejne jako poradova cisla portu -> adresu jde tedy doplnit primo
      find_res = addr_memory_mirror.find_first_index with (item == in_item.addr);
      if (find_res.size() == 0) begin
        out_item.addr = in_item.addr;
        in_item.data = out_item.data;
      end else begin
        out_item.addr = addr_memory_mirror[index];
      end

      // porovnani
      if (in_item.addr != out_item.addr || in_item.data != out_item.data ) begin
        // panika
        `uvm_error(get_full_name(), $sformatf("Scoreboard: scoreboard_match - thread %0d : item mismatch\nin_item: \n%s\nout_item: \n%s", index, in_item.sprint(), out_item.sprint()))
      end else begin
        // ok
        //`uvm_info(get_full_name(), $sformatf("Scoreboard: scoreboard_match - thread %0d : item match\nin_item: \n%s\nout_item: \n%s", index, in_item.sprint(), out_item.sprint()), UVM_LOW)
      end

      // Zkontroluji zda bylo do kazdeho registru alespon jednou zapsano
      portsWrittenInto[index] += 1;
      coverage_done = 1;
      for(int i = 0; i < my_pkg::NUM_OF_PORTS; i++) begin
        if (portsWrittenInto[i] == 0) begin
          coverage_done = 0;
        end;
      end

      // pokud probehlo 10 paketu, tak konec testu (nic dalsiho neni potreba, staci stahnout namitku - objection)
      if (coverage_done) begin
        `uvm_info(get_full_name(), $sformatf("\n\nScoreboard: dummy coverage done -> finishing test.\n\n"), UVM_LOW)  
        phase.drop_objection(this);
      end
    end
  endtask

  task scoreboard_addr_mem(uvm_phase phase);
    my_pkg::my_item in_item;
    int find_res[$];

    forever begin
      if (inst_in_fifo.used() > 0) begin 
        inst_in_fifo.peek(in_item);
        if (in_item.writeMemOp == 1'b1) begin
          `uvm_info(get_full_name(), $sformatf("Getting write in item"), UVM_LOW)
          inst_in_fifo.get(in_item);
          find_res = addr_memory_mirror.find_first_index with (item == in_item.addr);
  
          if (find_res.size() == 0) begin
            addr_memory_mirror[in_item.portIndex] = in_item.addr;
          end
        end
      end
      #1;
    end

  endtask

  // funkce, do ktere lze vlozit vypis pokryti (i jinou zpravu) po skonceni testu
  function void report_phase(uvm_phase phase);
    //`uvm_info(get_full_name(), $sformatf("Dopadlo to vyborne, jsem jen trochu v soku..."), UVM_LOW)
  endfunction

endclass
