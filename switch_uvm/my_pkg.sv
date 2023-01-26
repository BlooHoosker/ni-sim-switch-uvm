package my_pkg;
  parameter NUM_OF_PORTS = 42;
  parameter PORT_ADDR_LENGTH = 32;
  parameter DATA_WIDTH = 64;

  // Sequence item
  `include "my_item.sv"
  // Scoreboard
  `include "my_scoreboard.sv"
  // Monitor
  `include "my_monitor.sv"

  `include "my_in_monitor.sv"
  // Driver
  `include "my_driver.sv"
  // Sequence
  `include "my_sequence.sv"
  // Sequencer
  `include "my_sequencer.sv"
  // Environment
  `include "my_env.sv"
  // Test
  `include "my_test.sv"
endpackage

