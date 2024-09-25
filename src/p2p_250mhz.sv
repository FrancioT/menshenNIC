// *************************************************************************
//
// Copyright 2020 Xilinx, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// *************************************************************************
`include "open_nic_shell_macros.vh"
`include "../menshen/rmt_wrapper.sv"
`timescale 1ns/1ps
module p2p_250mhz #(
  parameter int NUM_QDMA = 1,
  parameter int NUM_INTF = 1,
  parameter int PIPE_SIZE[4] = {5, 16, 32, 10}
) (
  input        [NUM_INTF*2-1:0] s_axil_awvalid,
  input     [32*NUM_INTF*2-1:0] s_axil_awaddr,
  output       [NUM_INTF*2-1:0] s_axil_awready,
  input        [NUM_INTF*2-1:0] s_axil_wvalid,
  input     [32*NUM_INTF*2-1:0] s_axil_wdata,
  output       [NUM_INTF*2-1:0] s_axil_wready,
  output       [NUM_INTF*2-1:0] s_axil_bvalid,
  output     [2*NUM_INTF*2-1:0] s_axil_bresp,
  input        [NUM_INTF*2-1:0] s_axil_bready,
  input        [NUM_INTF*2-1:0] s_axil_arvalid,
  input     [32*NUM_INTF*2-1:0] s_axil_araddr,
  output       [NUM_INTF*2-1:0] s_axil_arready,
  output       [NUM_INTF*2-1:0] s_axil_rvalid,
  output    [32*NUM_INTF*2-1:0] s_axil_rdata,
  output     [2*NUM_INTF*2-1:0] s_axil_rresp,
  input        [NUM_INTF*2-1:0] s_axil_rready,

  input      [NUM_INTF*NUM_QDMA-1:0] s_axis_qdma_h2c_tvalid,
  input  [512*NUM_INTF*NUM_QDMA-1:0] s_axis_qdma_h2c_tdata,
  input   [64*NUM_INTF*NUM_QDMA-1:0] s_axis_qdma_h2c_tkeep,
  input      [NUM_INTF*NUM_QDMA-1:0] s_axis_qdma_h2c_tlast,
  input   [16*NUM_INTF*NUM_QDMA-1:0] s_axis_qdma_h2c_tuser_size,
  input   [16*NUM_INTF*NUM_QDMA-1:0] s_axis_qdma_h2c_tuser_src,
  input   [16*NUM_INTF*NUM_QDMA-1:0] s_axis_qdma_h2c_tuser_dst,
  output reg [NUM_INTF*NUM_QDMA-1:0] s_axis_qdma_h2c_tready,

  output     [NUM_INTF*NUM_QDMA-1:0] m_axis_qdma_c2h_tvalid,
  output [512*NUM_INTF*NUM_QDMA-1:0] m_axis_qdma_c2h_tdata,
  output  [64*NUM_INTF*NUM_QDMA-1:0] m_axis_qdma_c2h_tkeep,
  output     [NUM_INTF*NUM_QDMA-1:0] m_axis_qdma_c2h_tlast,
  output  [16*NUM_INTF*NUM_QDMA-1:0] m_axis_qdma_c2h_tuser_size,
  output  [16*NUM_INTF*NUM_QDMA-1:0] m_axis_qdma_c2h_tuser_src,
  output  [16*NUM_INTF*NUM_QDMA-1:0] m_axis_qdma_c2h_tuser_dst,
  input      [NUM_INTF*NUM_QDMA-1:0] m_axis_qdma_c2h_tready,

  output     [NUM_INTF-1:0] m_axis_adap_tx_250mhz_tvalid,
  output [512*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tdata,
  output  [64*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tkeep,
  output     [NUM_INTF-1:0] m_axis_adap_tx_250mhz_tlast,
  output  [16*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tuser_size,
  output  [16*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tuser_src,
  output  [16*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tuser_dst,
  input      [NUM_INTF-1:0] m_axis_adap_tx_250mhz_tready,

  input      [NUM_INTF-1:0] s_axis_adap_rx_250mhz_tvalid,
  input  [512*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tdata,
  input   [64*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tkeep,
  input      [NUM_INTF-1:0] s_axis_adap_rx_250mhz_tlast,
  input   [16*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tuser_size,
  input   [16*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tuser_src,
  input   [16*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tuser_dst,
  output     [NUM_INTF-1:0] s_axis_adap_rx_250mhz_tready,

  input                     mod_rstn,
  output                    mod_rst_done,

  input                     axil_aclk,

`ifdef __au55n__
  input                     ref_clk_100mhz,
`elsif __au55c__
  input                     ref_clk_100mhz,
`elsif __au50__
  input                     ref_clk_100mhz,
`elsif __au280__
  input                     ref_clk_100mhz,
`endif
  input                     axis_aclk
);

  wire axil_aresetn;

  // Reset is clocked by the 125MHz AXI-Lite clock
  generic_reset #(
    .NUM_INPUT_CLK  (1),
    .RESET_DURATION (100)
  ) reset_inst (
    .mod_rstn     (mod_rstn),
    .mod_rst_done (mod_rst_done),
    .clk          (axil_aclk),
    .rstn         (axil_aresetn)
  );

  generate if (NUM_QDMA <= 1) begin
    axi_lite_slave #(
      .REG_ADDR_W (12),
      .REG_PREFIX (16'hB000)
    ) reg_inst (
      .s_axil_awvalid (s_axil_awvalid),
      .s_axil_awaddr  (s_axil_awaddr),
      .s_axil_awready (s_axil_awready),
      .s_axil_wvalid  (s_axil_wvalid),
      .s_axil_wdata   (s_axil_wdata),
      .s_axil_wready  (s_axil_wready),
      .s_axil_bvalid  (s_axil_bvalid),
      .s_axil_bresp   (s_axil_bresp),
      .s_axil_bready  (s_axil_bready),
      .s_axil_arvalid (s_axil_arvalid),
      .s_axil_araddr  (s_axil_araddr),
      .s_axil_arready (s_axil_arready),
      .s_axil_rvalid  (s_axil_rvalid),
      .s_axil_rdata   (s_axil_rdata),
      .s_axil_rresp   (s_axil_rresp),
      .s_axil_rready  (s_axil_rready),

      .aclk           (axil_aclk),
      .aresetn        (axil_aresetn)
    );
  end
  endgenerate

  generate for (genvar i = 0; i < NUM_INTF; i++) begin
    wire          [16*3-1:0] axis_adap_tx_250mhz_tuser;
    wire          [16*3-1:0] axis_adap_rx_250mhz_tuser;
    wire          [16*3*NUM_QDMA-1:0] axis_qdma_c2h_tuser;

    assign axis_adap_rx_250mhz_tuser[0+:16]                 = s_axis_adap_rx_250mhz_tuser_size[`getvec(16, i)];
    assign axis_adap_rx_250mhz_tuser[16+:16]                = s_axis_adap_rx_250mhz_tuser_src[`getvec(16, i)];
    assign axis_adap_rx_250mhz_tuser[32+:16]                = s_axis_adap_rx_250mhz_tuser_dst[`getvec(16, i)];

    assign m_axis_adap_tx_250mhz_tuser_size[`getvec(16, i)] = axis_adap_tx_250mhz_tuser[0+:16];
    assign m_axis_adap_tx_250mhz_tuser_src[`getvec(16, i)]  = axis_adap_tx_250mhz_tuser[16+:16];
    assign m_axis_adap_tx_250mhz_tuser_dst[`getvec(16, i)]  = 16'h1 << (6 + i);

    if (NUM_QDMA > 1) begin
      wire      [NUM_QDMA-1:0] axis_qdma_h2c_tvalid;
      wire  [512*NUM_QDMA-1:0] axis_qdma_h2c_tdata;
      wire   [64*NUM_QDMA-1:0] axis_qdma_h2c_tkeep;
      wire      [NUM_QDMA-1:0] axis_qdma_h2c_tlast;
      wire [16*3*NUM_QDMA-1:0] axis_qdma_h2c_tuser;
      wire      [NUM_QDMA-1:0] axis_qdma_h2c_tready;

      wire      [NUM_QDMA-1:0] axis_qdma_c2h_tvalid;
      wire  [512*NUM_QDMA-1:0] axis_qdma_c2h_tdata;
      wire   [64*NUM_QDMA-1:0] axis_qdma_c2h_tkeep;
      wire      [NUM_QDMA-1:0] axis_qdma_c2h_tlast;
      wire      [NUM_QDMA-1:0] axis_qdma_c2h_tready;

      for (genvar ii = 0; ii < NUM_QDMA; ii++) begin
        assign axis_qdma_h2c_tvalid[ii]                 = s_axis_qdma_h2c_tvalid[2*ii+i];
        assign axis_qdma_h2c_tdata[`getvec(512, ii)]    = s_axis_qdma_h2c_tdata[`getvec(512, 2*ii+i)];
        assign axis_qdma_h2c_tkeep[`getvec(64, ii)]     = s_axis_qdma_h2c_tkeep[`getvec(64, 2*ii+i)];
        assign axis_qdma_h2c_tlast[ii]                  = s_axis_qdma_h2c_tlast[2*ii+i];
        assign axis_qdma_h2c_tuser[`getvec(16, 3*ii)]   = s_axis_qdma_h2c_tuser_size[`getvec(16, 2*ii+i)];
        assign axis_qdma_h2c_tuser[`getvec(16, 3*ii+1)] = s_axis_qdma_h2c_tuser_src[`getvec(16, 2*ii+i)];
        assign axis_qdma_h2c_tuser[`getvec(16, 3*ii+2)] = s_axis_qdma_h2c_tuser_dst[`getvec(16, 2*ii+i)];
        assign s_axis_qdma_h2c_tready[2*ii+i]           = axis_qdma_h2c_tready[ii];

        assign m_axis_qdma_c2h_tvalid[2*ii+i]                  = axis_qdma_c2h_tvalid[ii];
        assign m_axis_qdma_c2h_tdata[`getvec(512, 2*ii+i)]     = axis_qdma_c2h_tdata[`getvec(512, ii)];
        assign m_axis_qdma_c2h_tkeep[`getvec(64, 2*ii+i)]      = axis_qdma_c2h_tkeep[`getvec(64, ii)];
        assign m_axis_qdma_c2h_tlast[2*ii+i]                   = axis_qdma_c2h_tlast[ii];
        assign m_axis_qdma_c2h_tuser_size[`getvec(16, 2*ii+i)] = axis_qdma_c2h_tuser[`getvec(16, 3*ii)];
        assign m_axis_qdma_c2h_tuser_src[`getvec(16, 2*ii+i)]  = axis_qdma_c2h_tuser[`getvec(16, 3*ii+1)];
        assign m_axis_qdma_c2h_tuser_dst[`getvec(16, 2*ii+i)]  = axis_qdma_c2h_tuser[`getvec(16, 3*ii+2)];
        assign axis_qdma_c2h_tready[ii]                        = m_axis_qdma_c2h_tready[2*ii+i];
      end

      box_250mhz_egress_axi_switch box_250mhz_egress_axi_switch_inst (
        .aclk                (axis_aclk),
        .aresetn             (axil_aresetn),
        .s_axis_tvalid       (axis_qdma_h2c_tvalid),
        .s_axis_tready       (axis_qdma_h2c_tready),
        .s_axis_tdata        (axis_qdma_h2c_tdata),
        .s_axis_tkeep        (axis_qdma_h2c_tkeep),
        .s_axis_tlast        (axis_qdma_h2c_tlast),
        .s_axis_tuser        (axis_qdma_h2c_tuser),
        .m_axis_tvalid       (m_axis_adap_tx_250mhz_tvalid[i]),
        .m_axis_tready       (m_axis_adap_tx_250mhz_tready[i]),
        .m_axis_tdata        (m_axis_adap_tx_250mhz_tdata[`getvec(512, i)]),
        .m_axis_tkeep        (m_axis_adap_tx_250mhz_tkeep[`getvec(64, i)]),
        .m_axis_tlast        (m_axis_adap_tx_250mhz_tlast[i]),
        .m_axis_tuser        (axis_adap_tx_250mhz_tuser),
        .s_axi_ctrl_aclk     (axil_aclk),
        .s_axi_ctrl_aresetn  (axil_aresetn),
        .s_axi_ctrl_awvalid  (s_axil_awvalid[2*i+1]),
        .s_axi_ctrl_awready  (s_axil_awready[2*i+1]),
        .s_axi_ctrl_awaddr   (s_axil_awaddr[`getvec(32, 2*i+1)]),
        .s_axi_ctrl_wvalid   (s_axil_wvalid[2*i+1]),
        .s_axi_ctrl_wready   (s_axil_wready[2*i+1]),
        .s_axi_ctrl_wdata    (s_axil_wdata[`getvec(32, 2*i+1)]),
        .s_axi_ctrl_bvalid   (s_axil_bvalid[2*i+1]),
        .s_axi_ctrl_bready   (s_axil_bready[2*i+1]),
        .s_axi_ctrl_bresp    (s_axil_bresp[`getvec(2, 2*i+1)]),
        .s_axi_ctrl_arvalid  (s_axil_arvalid[2*i+1]),
        .s_axi_ctrl_arready  (s_axil_arready[2*i+1]),
        .s_axi_ctrl_araddr   (s_axil_araddr[`getvec(32, 2*i+1)]),
        .s_axi_ctrl_rvalid   (s_axil_rvalid[2*i+1]),
        .s_axi_ctrl_rready   (s_axil_rready[2*i+1]),
        .s_axi_ctrl_rdata    (s_axil_rdata[`getvec(32, 2*i+1)]),
        .s_axi_ctrl_rresp    (s_axil_rresp[`getvec(2, 2*i+1)])
      );

      box_250mhz_ingress_axi_switch box_250mhz_ingress_axi_switch_inst (
        .aclk                (axis_aclk),
        .aresetn             (axil_aresetn),
        .s_axis_tvalid       (s_axis_adap_rx_250mhz_tvalid[i]),
        .s_axis_tready       (s_axis_adap_rx_250mhz_tready[i]),
        .s_axis_tdata        (s_axis_adap_rx_250mhz_tdata[`getvec(512, i)]),
        .s_axis_tkeep        (s_axis_adap_rx_250mhz_tkeep[`getvec(64, i)]),
        .s_axis_tlast        (s_axis_adap_rx_250mhz_tlast[i]),
        .s_axis_tuser        (axis_adap_rx_250mhz_tuser),
        .m_axis_tvalid       (axis_qdma_c2h_tvalid),
        .m_axis_tready       (axis_qdma_c2h_tready),
        .m_axis_tdata        (axis_qdma_c2h_tdata),
        .m_axis_tkeep        (axis_qdma_c2h_tkeep),
        .m_axis_tlast        (axis_qdma_c2h_tlast),
        .m_axis_tuser        (axis_qdma_c2h_tuser),
        .s_axi_ctrl_aclk     (axil_aclk),
        .s_axi_ctrl_aresetn  (axil_aresetn),
        .s_axi_ctrl_awvalid  (s_axil_awvalid[2*i]),
        .s_axi_ctrl_awready  (s_axil_awready[2*i]),
        .s_axi_ctrl_awaddr   (s_axil_awaddr[`getvec(32, 2*i)]),
        .s_axi_ctrl_wvalid   (s_axil_wvalid[2*i]),
        .s_axi_ctrl_wready   (s_axil_wready[2*i]),
        .s_axi_ctrl_wdata    (s_axil_wdata[`getvec(32, 2*i)]),
        .s_axi_ctrl_bvalid   (s_axil_bvalid[2*i]),
        .s_axi_ctrl_bready   (s_axil_bready[2*i]),
        .s_axi_ctrl_bresp    (s_axil_bresp[`getvec(2, 2*i)]),
        .s_axi_ctrl_arvalid  (s_axil_arvalid[2*i]),
        .s_axi_ctrl_arready  (s_axil_arready[2*i]),
        .s_axi_ctrl_araddr   (s_axil_araddr[`getvec(32, 2*i)]),
        .s_axi_ctrl_rvalid   (s_axil_rvalid[2*i]),
        .s_axi_ctrl_rready   (s_axil_rready[2*i]),
        .s_axi_ctrl_rdata    (s_axil_rdata[`getvec(32, 2*i)]),
        .s_axi_ctrl_rresp    (s_axil_rresp[`getvec(2, 2*i)])
      );
    end
    else begin
      wire [47:0]  axis_qdma_h2c_tuser;
      wire [511:0] rx_bridge_axis_tdata;   // rx and tx bridges connect the axis_stream_packet_buffers to their corresponding pipeline
      wire [63:0]  rx_bridge_axis_tkeep;
      wire [47:0]  rx_bridge_axis_tuser;
      wire         rx_bridge_axis_tvalid;
      reg          rx_bridge_axis_tready;
      wire         rx_bridge_axis_tlast;
      wire [511:0] rx_drop_channel;
      reg [511:0]  rx_axis_tdata;          // those registers are used to connect the rx pipeline to either rx-adapter or h2c (in case we are configuring the rx pipeline)
      reg [63:0]   rx_axis_tkeep;
      reg [47:0]   rx_axis_tuser;
      reg          rx_axis_tvalid;
      wire         rx_axis_tready;
      reg          rx_axis_tlast;
      
      wire [511:0] tx_bridge_axis_tdata;
      wire [63:0]  tx_bridge_axis_tkeep;
      wire [47:0]  tx_bridge_axis_tuser;
      wire         tx_bridge_axis_tvalid;
      wire         tx_bridge_axis_tready;
      wire         tx_bridge_axis_tlast;
      wire [511:0] tx_drop_channel; 
      wire         tx_axis_tready;
      
      reg drop_rx;

      assign axis_qdma_h2c_tuser[0+:16]                       = s_axis_qdma_h2c_tuser_size[`getvec(16, i)];
      assign axis_qdma_h2c_tuser[16+:16]                      = s_axis_qdma_h2c_tuser_src[`getvec(16, i)];
      assign axis_qdma_h2c_tuser[32+:16]                      = s_axis_qdma_h2c_tuser_dst[`getvec(16, i)];

      assign m_axis_qdma_c2h_tuser_size[`getvec(16, i)]       = axis_qdma_c2h_tuser[0+:16];
      assign m_axis_qdma_c2h_tuser_src[`getvec(16, i)]        = axis_qdma_c2h_tuser[16+:16];
      assign m_axis_qdma_c2h_tuser_dst[`getvec(16, i)]        = 16'h1 << i;

      // menshen pipeline in tx (from qdma to cmac)
      assign tx_drop_channel = s_axis_qdma_h2c_tdata[`getvec(512, i)];
      
      // this buffer is used as a filter for the configuration packets reguarding the rx pipeline (which will be redirected to it) 
      axi_stream_packet_buffer #( .TUSER_W(48)) tx_config_filter(
        .s_axis_tdata(s_axis_qdma_h2c_tdata[`getvec(512, i)]),
        .s_axis_tkeep(s_axis_qdma_h2c_tkeep[`getvec(64, i)]),
        .s_axis_tuser(axis_qdma_h2c_tuser),
        .s_axis_tvalid(s_axis_qdma_h2c_tvalid[i]),
        .s_axis_tready(tx_axis_tready),
        .s_axis_tlast(s_axis_qdma_h2c_tlast[i]),
        .s_axis_tid(),
        .s_axis_tdest(),

        .drop((tx_drop_channel[335:320] == 16'hf2f1) && s_axis_qdma_h2c_tuser_dst[15] == 1),
        .drop_busy(),

        .m_axis_tdata(tx_bridge_axis_tdata),
        .m_axis_tkeep(tx_bridge_axis_tkeep),
        .m_axis_tuser(tx_bridge_axis_tuser),
        .m_axis_tvalid(tx_bridge_axis_tvalid),
        .m_axis_tready(tx_bridge_axis_tready),
        .m_axis_tlast(tx_bridge_axis_tlast),
        .m_axis_tid(),
        .m_axis_tdest(),
        .m_axis_tuser_size(),

        .s_aclk(axis_aclk),
        .s_aresetn(axil_aresetn),
        .m_aclk(axis_aclk)
      	
      );
      
      rmt_wrapper #( .NUM_OF_STAGES(PIPE_SIZE[i])) tx_ppl_inst (
        .clk(axis_aclk),		// axis clk
        .aresetn(axil_aresetn),	

        // input Slave AXI Stream
        .s_axis_tdata(tx_bridge_axis_tdata),
        .s_axis_tkeep(tx_bridge_axis_tkeep),
        .s_axis_tuser(tx_bridge_axis_tuser),
        .s_axis_tvalid(tx_bridge_axis_tvalid),
        .s_axis_tready(tx_bridge_axis_tready),
        .s_axis_tlast(tx_bridge_axis_tlast),

        // output Master AXI Stream
        .m_axis_tdata(m_axis_adap_tx_250mhz_tdata[`getvec(512, i)]),
        .m_axis_tkeep(m_axis_adap_tx_250mhz_tkeep[`getvec(64, i)]),
        .m_axis_tuser(axis_adap_tx_250mhz_tuser),
        .m_axis_tvalid(m_axis_adap_tx_250mhz_tvalid[i]),
        .m_axis_tready(m_axis_adap_tx_250mhz_tready[i]),
        .m_axis_tlast(m_axis_adap_tx_250mhz_tlast[i])
      );


      // menshen pipeline in rx (from cmac to qdma)
      assign rx_drop_channel = s_axis_adap_rx_250mhz_tdata[`getvec(512, i)];
      
      // this buffer is used as a filter for the configuration packets arriving from the ethernet
      axi_stream_packet_buffer #( .TUSER_W(48)) rx_config_filter(
        .s_axis_tdata(s_axis_adap_rx_250mhz_tdata[`getvec(512, i)]),
        .s_axis_tkeep(s_axis_adap_rx_250mhz_tkeep[`getvec(64, i)]),
        .s_axis_tuser(axis_adap_rx_250mhz_tuser),
        .s_axis_tvalid(s_axis_adap_rx_250mhz_tvalid[i]),
        .s_axis_tready(s_axis_adap_rx_250mhz_tready[i]),
        .s_axis_tlast(s_axis_adap_rx_250mhz_tlast[i]),
        .s_axis_tid(),
        .s_axis_tdest(),

        .drop((rx_drop_channel[335:320] == 16'hf2f1) || (drop_rx && s_axis_adap_rx_250mhz_tlast[i])),
        .drop_busy(),

        .m_axis_tdata(rx_bridge_axis_tdata),
        .m_axis_tkeep(rx_bridge_axis_tkeep),
        .m_axis_tuser(rx_bridge_axis_tuser),
        .m_axis_tvalid(rx_bridge_axis_tvalid),
        .m_axis_tready(rx_bridge_axis_tready),
        .m_axis_tlast(rx_bridge_axis_tlast),
        .m_axis_tid(),
        .m_axis_tdest(),
        .m_axis_tuser_size(),

        .s_aclk(axis_aclk),
        .s_aresetn(axil_aresetn),
        .m_aclk(axis_aclk)
      	
      );
      
      // multiplexer used to connect the rx pipeline to either rx-adapter or h2c (in case we are configuring the rx pipeline)
      always_comb
      begin
        if(s_axis_qdma_h2c_tuser_dst[15] == 1 && s_axis_qdma_h2c_tuser_dst[14] == i)
        begin
          rx_axis_tdata =  s_axis_qdma_h2c_tdata[`getvec(512, i)];
          rx_axis_tkeep =  s_axis_qdma_h2c_tkeep[`getvec(64, i)];
          rx_axis_tuser =  axis_qdma_h2c_tuser;
          rx_axis_tvalid = s_axis_qdma_h2c_tvalid[i];
          rx_axis_tlast =  s_axis_qdma_h2c_tlast[i];
          s_axis_qdma_h2c_tready[i] = rx_axis_tready;
          rx_bridge_axis_tready = 1;
          drop_rx = 1;
        end
        else
        begin
          rx_axis_tdata =  rx_bridge_axis_tdata;
          rx_axis_tkeep =  rx_bridge_axis_tkeep;
          rx_axis_tuser =  rx_bridge_axis_tuser;
          rx_axis_tvalid = rx_bridge_axis_tvalid;
          rx_axis_tlast =  rx_bridge_axis_tlast;
          s_axis_qdma_h2c_tready[i] = tx_axis_tready;
          rx_bridge_axis_tready = rx_axis_tready;
          drop_rx = 0;
        end
      end

      rmt_wrapper #( .NUM_OF_STAGES(PIPE_SIZE[i])) rx_ppl_inst (
        .clk(axis_aclk),		// axis clk
        .aresetn(axil_aresetn),	

        // input Slave AXI Stream
        .s_axis_tdata(rx_axis_tdata),
        .s_axis_tkeep(rx_axis_tkeep),
        .s_axis_tuser(rx_axis_tuser),
        .s_axis_tvalid(rx_axis_tvalid),
        .s_axis_tready(rx_axis_tready),
        .s_axis_tlast(rx_axis_tlast),

        // output Master AXI Stream
        .m_axis_tdata(m_axis_qdma_c2h_tdata[`getvec(512, i)]),
        .m_axis_tkeep(m_axis_qdma_c2h_tkeep[`getvec(64, i)]),
        .m_axis_tuser(axis_qdma_c2h_tuser),
        .m_axis_tvalid(m_axis_qdma_c2h_tvalid[i]),
        .m_axis_tready(m_axis_qdma_c2h_tready[i]),
        .m_axis_tlast(m_axis_qdma_c2h_tlast[i])
      );
    end
  end
  endgenerate

endmodule: p2p_250mhz
