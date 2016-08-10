/* Copyright (c) 2012-2015 by the author(s)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * =============================================================================
 *
 * A verilated testbench for a simple systems with only one compute tile.
 *
 * Author(s):
 *   Stefan Wallentowitz <stefan.wallentowitz@tum.de>
 */

`include "dbg_config.vh"

import dii_package::dii_flit;

module tb_compute_tile(
`ifdef verilator
   input clk,
   input rst
`endif
   );

   parameter USE_DEBUG = 0;

   parameter NUM_CORES = 1;

   // NoC parameters
   parameter NOC_FLIT_DATA_WIDTH = 32;
   parameter NOC_FLIT_TYPE_WIDTH = 2;
   localparam NOC_FLIT_WIDTH = NOC_FLIT_DATA_WIDTH + NOC_FLIT_TYPE_WIDTH;

   parameter VCHANNELS = 3;

   logic rst_sys, rst_cpu;

`ifndef verilator
   reg clk;
   reg rst;
   reg cpu_stall;
`else
   logic cpu_stall;
   assign rst_sys = rst;
   assign rst_cpu = rst;
   assign cpu_stall = 0;
`endif

   reg [NOC_FLIT_WIDTH-1:0] noc_in_flit;
   reg [VCHANNELS-1:0] noc_in_valid;
   wire [VCHANNELS-1:0] noc_in_ready;
   wire [NOC_FLIT_WIDTH-1:0] noc_out_flit;
   wire [VCHANNELS-1:0] noc_out_valid;
   reg [VCHANNELS-1:0] noc_out_ready;

   genvar                                      i;
   generate
      if (USE_DEBUG == 0) begin
         wire [`DEBUG_TRACE_EXEC_WIDTH*NUM_CORES-1:0] trace_array [0:NUM_CORES-1];
         assign trace_array = u_compute_tile.trace;

         wire                                        trace_enable   [0:NUM_CORES-1] /*verilator public_flat_rd*/;
         wire [31:0]                                 trace_insn     [0:NUM_CORES-1] /*verilator public_flat_rd*/;
         wire [31:0]                                 trace_pc       [0:NUM_CORES-1] /*verilator public_flat_rd*/;
         wire                                        trace_wben     [0:NUM_CORES-1];
         wire [4:0]                                  trace_wbreg    [0:NUM_CORES-1];
         wire [31:0]                                 trace_wbdata   [0:NUM_CORES-1];
         wire [31:0]                                 trace_r3       [0:NUM_CORES-1] /*verilator public_flat_rd*/;

         wire [NUM_CORES-1:0]                         termination;

         for (i = 0; i < NUM_CORES; i++) begin
            assign trace_enable[i] = trace_array[i][`DEBUG_TRACE_EXEC_ENABLE_MSB:`DEBUG_TRACE_EXEC_ENABLE_LSB];
            assign trace_insn[i] = trace_array[i][`DEBUG_TRACE_EXEC_INSN_MSB:`DEBUG_TRACE_EXEC_INSN_LSB];
            assign trace_pc[i] = trace_array[i][`DEBUG_TRACE_EXEC_PC_MSB:`DEBUG_TRACE_EXEC_PC_LSB];
            assign trace_wben[i] = trace_array[i][`DEBUG_TRACE_EXEC_WBEN_MSB:`DEBUG_TRACE_EXEC_WBEN_LSB];
            assign trace_wbreg[i] = trace_array[i][`DEBUG_TRACE_EXEC_WBREG_MSB:`DEBUG_TRACE_EXEC_WBREG_LSB];
            assign trace_wbdata[i] = trace_array[i][`DEBUG_TRACE_EXEC_WBDATA_MSB:`DEBUG_TRACE_EXEC_WBDATA_LSB];

            r3_checker
              u_r3_checker(.clk(clk),
                           .valid(trace_enable[i]),
                           .we (trace_wben[i]),
                           .addr (trace_wbreg[i]),
                           .data (trace_wbdata[i]),
                           .r3 (trace_r3[i]));

            /* trace_monitor AUTO_TEMPLATE(
             .enable  (trace_enable[i]),
             .wb_pc   (trace_pc[i]),
             .wb_insn (trace_insn[i]),
             .r3      (trace_r3[i]),
             .supv    (),
             .termination  (termination[i]),
             .termination_all (termination),
             ); */
            trace_monitor
              #(.STDOUT_FILENAME({"stdout.",index2string(i)}),
                .TRACEFILE_FILENAME({"trace.",index2string(i)}),
                .ENABLE_TRACE(0),
                .ID(i),
                .TERM_CROSS_NUM(NUM_CORES))
            u_mon0(/*AUTOINST*/
                   // Outputs
                   .termination            (termination[i]),        // Templated
                   // Inputs
                   .clk                    (clk),
                   .enable                 (trace_enable[i]),       // Templated
                   .wb_pc                  (trace_pc[i]),           // Templated
                   .wb_insn                (trace_insn[i]),         // Templated
                   .r3                     (trace_r3[i]),           // Templated
                   .termination_all        (termination));          // Templated
         end // for (i = 0; i < NUM_CORES; i++)
      end else begin // if (USE_DEBUG == 0)
         glip_channel c_glip_in(.*);
         glip_channel c_glip_out(.*);

         dii_flit debug_ring_in;
         logic debug_ring_in_ready;
         dii_flit debug_ring_out;
         logic debug_ring_out_ready;

         logic com_rst, logic_rst;

         glip_tcp_toplevel
           u_glip
             (.*,
              .clk_io    (clk),
              .clk_logic (clk),
              .fifo_in   (c_glip_in),
              .fifo_out  (c_glip_out)
              );

         debug_interface
           #(.SYSTEMID    (1),
             .NUM_MODULES (0))
           u_debuginterface
             (.*,
              .sys_rst         (rst_sys),
              .cpu_rst         (rst_cpu),
              .glip_in         (c_glip_in),
              .glip_out        (c_glip_out),
              .debug_out       (debug_ring_in),
              .debug_out_ready (debug_ring_in_ready),
              .debug_in        (debug_ring_out),
              .debug_in_ready  (debug_ring_out_ready));

         assign debug_ring_out = debug_ring_in;
         assign debug_ring_in_ready = debug_ring_out_ready;
      end // else: !if(USE_DEBUG == 0)
   endgenerate

   compute_tile_dm
      #(.ID(0),
        .CORES(NUM_CORES),
        .MEM_SIZE(8*1024*1024), // 1 MB
        .MEM_FILE("ct.vmem"),
        .USE_DEBUG(USE_DEBUG))
      u_compute_tile(// Outputs
                     .noc_in_ready      (noc_in_ready[VCHANNELS-1:0]),
                     .noc_out_flit      (noc_out_flit[NOC_FLIT_WIDTH-1:0]),
                     .noc_out_valid     (noc_out_valid[VCHANNELS-1:0]),
                     // Inputs
                     .clk               (clk),
                     .rst_cpu           (rst_cpu),
                     .rst_sys           (rst_sys),
                     .noc_in_flit       (noc_in_flit[NOC_FLIT_WIDTH-1:0]),
                     .noc_in_valid      (noc_in_valid[VCHANNELS-1:0]),
                     .noc_out_ready     (noc_out_ready[VCHANNELS-1:0]));

`ifndef verilator
   initial begin
      clk = 1'b1;
      rst = 1'b1;
      noc_out_ready = {VCHANNELS{1'b1}};
      noc_in_valid = '0;
      cpu_stall = 0;
      #15;
      rst = 1'b0;
   end

   always clk = #1.25 ~clk;
`endif

   `include "optimsoc_functions.vh"
endmodule

// Local Variables:
// verilog-library-directories:("." "../../../../src/rtl/*/verilog")
// verilog-auto-inst-param-value: t
// End: