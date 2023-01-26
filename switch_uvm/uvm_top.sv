`timescale 1ns/10ps

// import knihovny UVM
import uvm_pkg::*;

`include "my_pkg.sv"
import my_pkg::*;

// lze presunout do konfiguracniho souboru
`include "if_out.sv"
`include "if_in.sv"
`include "top.sv"

module uvm_top;

  // deklarace clk a reset
  bit T_CLK, T_RST; // lze pouzit logic, ale zbytecne

  // generovani hodin
  always
    #5 T_CLK = ~T_CLK;

  // generovani resetu (muze byt soucasti sekvenci)
  initial begin
    T_RST <= 1'b0;
    T_CLK <= 1'b1;
    #1 T_RST <= 1'b1;
    #21 T_RST <= 1'b0;
  end

  // instance vsech rozhrani DUT
  if_out inst_if_out[my_pkg::NUM_OF_PORTS-1:0] (
    .clk(T_CLK),
    .reset(T_RST)
  );

  if_in inst_if_in (
    .clk(T_CLK),
    .reset(T_RST)
    );

  // instance DUT
  top _dut (
    .clk(T_CLK),
    .reset(T_RST),
    .interface_input(inst_if_in),
    .interface_output(inst_if_out)
  );

  // preposlani referenci na rozhrani do testovaciho prostredi
  // HINT Array cannot be indexed by dynamic variable in module -> use generate loop
  for(genvar i = 0; i < my_pkg::NUM_OF_PORTS; i++)
  initial begin
    uvm_config_db#(virtual if_out)::set(uvm_root::get(), "*", $sformatf("inst_if_out[%0d]",i), inst_if_out[i]);
  end

  initial begin
    uvm_config_db#(virtual if_in)::set(uvm_root::get(), "*", "inst_if_in", inst_if_in);

    // spusteni testu
    run_test("my_test");
  end

  // nepovinne - ulozeni prubehu signalu do souboru typu .vcd
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end


endmodule
