
`timescale 1ns / 1ps

module tb_opennic_no_rx_filter #(
parameter DATA_WIDTH=512,
parameter NUM_CMAC_PORT = 2
)();

wire                        clk;
wire [NUM_CMAC_PORT-1:0]    cmac_clk;
wire                        axil_clk;
reg                         aresetn;
wire [31:0]                 shell_rst_done;
wire [31:0]                 user_rst_done;
wire                        rst_done;


reg [DATA_WIDTH-1:0]        s_axis_h2c_tdata;
reg                         s_axis_h2c_tvalid;
wire                        s_axis_h2c_tready;
reg                         s_axis_h2c_tlast;
reg [5:0]                   s_axis_h2c_tuser_mty;
reg [31:0]                  s_axis_h2c_tcrc;
reg [10:0]                  s_axis_h2c_tuser_qid;
reg [2:0]                   s_axis_h2c_tuser_port_id;
reg                         s_axis_h2c_tuser_error;
reg                         s_axis_h2c_tuser_zero_byte;
reg [31:0]                  s_axis_h2c_tuser;

wire [DATA_WIDTH-1:0]       m_axis_c2h_tdata;
wire                        m_axis_c2h_tvalid;
reg                         m_axis_c2h_tready;
wire                        m_axis_c2h_tlast;
wire [5:0]                  m_axis_c2h_mty;
wire [31:0]                 m_axis_c2h_tcrc;
wire [10:0]                 m_axis_c2h_ctrl_qid;
wire [2:0]                  m_axis_c2h_ctrl_port_id;
wire [6:0]                  m_axis_c2h_ctrl_ecc;
wire [15:0]                 m_axis_c2h_ctrl_len;
wire                        m_axis_c2h_ctrl_marker;
wire                        m_axis_c2h_ctrl_has_cmpt;

wire [NUM_CMAC_PORT-1:0][DATA_WIDTH-1:0]     m_axis_tx_tdata;
wire [NUM_CMAC_PORT-1:0][(DATA_WIDTH/8)-1:0] m_axis_tx_tkeep;
wire [NUM_CMAC_PORT-1:0]                     m_axis_tx_tuser;
wire [NUM_CMAC_PORT-1:0]                     m_axis_tx_tvalid;
reg  [NUM_CMAC_PORT-1:0]                     m_axis_tx_tready;
wire [NUM_CMAC_PORT-1:0]                     m_axis_tx_tlast;

reg [NUM_CMAC_PORT-1:0][DATA_WIDTH-1:0]      s_axis_rx_tdata;
reg [NUM_CMAC_PORT-1:0][(DATA_WIDTH/8)-1:0]  s_axis_rx_tkeep;
reg [NUM_CMAC_PORT-1:0]                      s_axis_rx_tuser_err;
reg [NUM_CMAC_PORT-1:0]                      s_axis_rx_tvalid;
reg [NUM_CMAC_PORT-1:0]                      s_axis_rx_tlast;


reg                         axil_awvalid;
reg [31:0]                  axil_awaddr;
wire                        axil_awready;
reg                         axil_wvalid;
reg [31:0]                  axil_wdata;
wire                        axil_wready;
wire                        axil_bvalid;
wire [1:0]                  axil_bresp;
reg                         axil_bready;
reg                         axil_arvalid;
reg [31:0]                  axil_araddr;
wire                        axil_arready;
wire                        axil_rvalid;
wire [31:0]                 axil_rdata;
wire [1:0]                  axil_rresp;
reg                         axil_rready;

logic [NUM_CMAC_PORT-1:0]   cmac_clock;

assign cmac_clock = cmac_clk;
assign rst_done = (&shell_rst_done) & (&user_rst_done);

// Output validation, define the target value you are looking for
// SUB EXPECTED OUTPUT
localparam logic [DATA_WIDTH-1:0] TARGET_VALUE_SUB = 512'h000000000100000002000000030000001a004c4d1a00e110d204dededede6f6f6f6f22de1140000001002e000045000801000081050403020100090000000000;
// ADD EXPECTED OUTPUT
localparam logic [DATA_WIDTH-1:0] TARGET_VALUE_ADD = 512'h000000000500000002000000030000000d00594d1a00e110d204dededede6f6f6f6f22de1140000001002e000045000801000081050403020100090000000000;
// STAGES EXPECTED OUTPUT
localparam logic [DATA_WIDTH-1:0] TARGET_VALUE_STAGES= 512'h00000000100000000c0000000400000001004c4d1a00e110d204dededede6f6f6f6f22de1140000001002e000045000801000081050403020100090000000000;

initial begin
    s_axis_h2c_tuser_error = 0;
    s_axis_h2c_tuser_zero_byte = 0;
    s_axis_h2c_tuser_port_id = 0;
    s_axis_rx_tuser_err = 0;
    
    axil_awvalid <= 0;
    axil_awaddr <= 0;
    axil_wvalid <= 0;
    axil_wdata <= 0;
    axil_bready <= 0;
    axil_arvalid <= 0;
    axil_araddr <= 0;
    axil_rready <= 0;
    
    aresetn = 1;
    @(clk == 1'b0);
    @(clk == 1'b1);
    aresetn = 0;
    @(posedge clk);
    aresetn = 1;
    @(rst_done == 1'b1);
    repeat(40)
        @(posedge clk);
    
    
    // H2C pipelines configuration:
    register_setup(32'h00001000, 32'h00000001);
    register_setup(32'h00002000, 32'h00020001);
    s_axis_h2c_tuser_qid = 0;
    configuration_h2c("calc_conf.txt", s_axis_h2c_tdata, s_axis_h2c_tvalid, m_axis_tx_tready[0], 
                                       s_axis_h2c_tlast, s_axis_h2c_tuser_mty, s_axis_h2c_tcrc,
                                       s_axis_h2c_tuser);
    s_axis_h2c_tuser_qid = 2;
    configuration_h2c("LongPipeline_conf.txt", s_axis_h2c_tdata, s_axis_h2c_tvalid, m_axis_tx_tready[1], 
                                               s_axis_h2c_tlast, s_axis_h2c_tuser_mty, s_axis_h2c_tcrc,
                                               s_axis_h2c_tuser);
    // C2H pipelines configuration:
    configuration_c2h("calc_conf_c2h.txt", cmac_clock[0], s_axis_rx_tdata[0], s_axis_rx_tvalid[0], 
                                           m_axis_c2h_tready, s_axis_rx_tlast[0], s_axis_rx_tkeep[0]);
    
    configuration_c2h("LongPipeline_conf_c2h.txt", cmac_clock[1], s_axis_rx_tdata[1], s_axis_rx_tvalid[1], 
                                                   m_axis_c2h_tready, s_axis_rx_tlast[1], s_axis_rx_tkeep[1]);
    
    
    s_axis_h2c_tuser_qid = 0;
    s_axis_h2c_tdata <= 512'h000000000000000002000000030000001a004c4d1a00e110d204dededede6f6f6f6f22de1140000001002e000045000801000081050403020100090000000000;
    s_axis_h2c_tuser_mty <= 6'b000000;
    s_axis_h2c_tvalid <= 1'b1;
    s_axis_h2c_tlast <= 1'b1;
    @(posedge clk);
    s_axis_h2c_tvalid <= 1'b0;
    s_axis_h2c_tlast <= 1'b0;
    // Check result
    @(posedge m_axis_tx_tvalid[0])
    if (m_axis_tx_tdata[0] == TARGET_VALUE_SUB) begin 
        $display ("SUB TEST PASSED"); 
    end else begin
        $display ("SUB TEST FAILED");
        $display("%h", m_axis_tx_tdata[0]);
        @(posedge clk);
        $finish(0);
    end
    
    // some time has passed   
    repeat(100)
        @(posedge clk);
    s_axis_h2c_tdata <= 512'h000000000000000002000000030000000d00594d1a00e110d204dededede6f6f6f6f22de1140000001002e000045000801000081050403020100090000000000;
    s_axis_h2c_tuser_mty <= 6'b000000;
    s_axis_h2c_tvalid <= 1'b1;
    s_axis_h2c_tlast <= 1'b1;
    @(posedge clk);
    s_axis_h2c_tvalid <= 1'b0;
    s_axis_h2c_tlast <= 1'b0;
    // Check result
    @(posedge m_axis_tx_tvalid[0])
    if (m_axis_tx_tdata[0] == TARGET_VALUE_ADD) begin 
        $display ("ADD TEST PASSED"); 
    end else begin
        $display ("ADD TEST FAILED");
        $display("%h", m_axis_tx_tdata[0]);
        @(posedge clk);
        $finish(0);
    end
    
    
    // some time has passed   
    repeat(100)
        @(posedge clk);
    s_axis_h2c_tuser_qid = 2;
    s_axis_h2c_tdata <= 512'h0000000028000000020000000000000001004c4d1a00e110d204dededede6f6f6f6f22de1140000001002e000045000801000081050403020100090000000000;	
    s_axis_h2c_tuser_mty <= 6'b000000;
    s_axis_h2c_tvalid <= 1'b1;
    s_axis_h2c_tlast <= 1'b1;
    @(posedge clk);
    s_axis_h2c_tvalid <= 1'b0;
    s_axis_h2c_tlast <= 1'b0;
    // Check result
    @(posedge m_axis_tx_tvalid[1])
    if (m_axis_tx_tdata[1] == TARGET_VALUE_STAGES) begin
        $display ("STAGES TEST PASSED");
    end else begin
        $display ("STAGES TEST FAILED");
        $display("%h", m_axis_tx_tdata[1]);
        @(posedge clk);
        $finish(0);
    end
    
    // some time has passed   
    repeat(100)
        @(posedge cmac_clock[0]);
    s_axis_rx_tdata[0] <= 512'h000000000000000002000000030000001a004c4d1a00e110d204dededede6f6f6f6f22de1140000001002e000045000801000081050403020100090000000000;
    s_axis_rx_tkeep[0] <= 64'hffffffffffffffff;
    s_axis_rx_tvalid[0] <= 1'b1;
    s_axis_rx_tlast[0] <= 1'b1;
    @(posedge cmac_clock[0]);
    s_axis_rx_tvalid[0] <= 1'b0;
    s_axis_rx_tlast[0] <= 1'b0;
    // Check result
    @(posedge m_axis_c2h_tvalid)
    if (m_axis_c2h_tdata == TARGET_VALUE_SUB) begin 
        $display ("SUB TEST PASSED"); 
    end else begin
        $display ("SUB TEST FAILED");
        $display("%h", m_axis_c2h_tdata);
        @(posedge cmac_clock[0]);
        $finish(0);
    end
    
    // some time has passed   
    repeat(100)
        @(posedge cmac_clock[0]);
    s_axis_rx_tdata[0] <= 512'h000000000000000002000000030000000d00594d1a00e110d204dededede6f6f6f6f22de1140000001002e000045000801000081050403020100090000000000;
    s_axis_rx_tkeep[0] <= 64'hffffffffffffffff;
    s_axis_rx_tvalid[0] <= 1'b1;
    s_axis_rx_tlast[0] <= 1'b1;
    @(posedge cmac_clock[0]);
    s_axis_rx_tvalid[0] <= 1'b0;
    s_axis_rx_tlast[0] <= 1'b0;
    // Check result
    @(posedge m_axis_c2h_tvalid)
    if (m_axis_c2h_tdata[511:368] == TARGET_VALUE_ADD[511:368]) begin 
        $display ("ADD TEST PASSED"); 
    end else begin
        $display ("ADD TEST FAILED");
        $display("%h", m_axis_c2h_tdata);
        @(posedge cmac_clock[0]);
        $finish(0);
    end
    
    // some time has passed   
    repeat(100)
        @(posedge cmac_clock[1]);
    s_axis_rx_tdata[1] <= 512'h0000000028000000020000000000000001004c4d1a00e110d204dededede6f6f6f6f22de1140000001002e000045000801000081050403020100090000000000;	
    s_axis_rx_tkeep[1] <= 64'hffffffffffffffff;
    s_axis_rx_tvalid[1] <= 1'b1;
    s_axis_rx_tlast[1] <= 1'b1;
    @(posedge cmac_clock[1]);
    s_axis_rx_tvalid[1] <= 1'b0;
    s_axis_rx_tlast[1] <= 1'b0;
    // Check result
    @(posedge m_axis_c2h_tvalid)
    if (m_axis_c2h_tdata == TARGET_VALUE_STAGES) begin
        $display ("STAGES TEST PASSED");
    end else begin
        $display ("STAGES TEST FAILED");
        $display("%h", m_axis_c2h_tdata);
        @(posedge cmac_clock[1]);
        $finish(0);
    end
    $finish(0);
    @(posedge cmac_clock[1]);
end


// Tasks:
task automatic configuration_h2c(input string             file_name,
                                 ref reg [DATA_WIDTH-1:0] s_axis_tdata,
                                 ref reg                  s_axis_tvalid,
                                 ref reg                  m_axis_tready,
                                 ref reg                  s_axis_tlast,
                                 ref reg [5:0]            s_axis_tuser_mty,
                                 ref reg [31:0]           s_axis_tcrc,
                                 ref reg [31:0]           s_axis_tuser);
int fd;
begin
    repeat(40)
        @(posedge clk);
    s_axis_tcrc = 32'b0;
    m_axis_tready = 1'b1;
    s_axis_tuser = 32'h0000004A;
    s_axis_tvalid = 1'b0;
    s_axis_tlast = 1'b0;
    repeat(3)
        @(posedge clk);
    
    fd = $fopen(file_name, "r");
    while(!$feof(fd))
    begin
        $fscanf(fd, "%h\n%b\n", s_axis_tdata, s_axis_tuser_mty);
        s_axis_tvalid = 1'b1;
        if(s_axis_tuser_mty != 6'b000000)
        begin
            s_axis_tlast = 1'b1;
            $fscanf(fd, "%b\n\n", s_axis_tcrc);
            @(posedge clk);
            s_axis_tvalid = 1'b0;
            s_axis_tlast = 1'b0;
            repeat(30)
                @(posedge clk);
        end
        else
        begin
            s_axis_tlast = 1'b0;
            @(posedge clk);
        end
    end
    $fclose(fd);
end
endtask


task automatic configuration_c2h(input string                 file_name,
                                 ref logic                    t_clk,
                                 ref reg [DATA_WIDTH-1:0]     s_axis_tdata,
                                 ref reg                      s_axis_tvalid,
                                 ref reg                      m_axis_tready,
                                 ref reg                      s_axis_tlast,
                                 ref reg [(DATA_WIDTH/8)-1:0] s_axis_tkeep);
int fd;
begin
    repeat(40)
        @(posedge t_clk);
    m_axis_tready = 1'b1;
    s_axis_tvalid = 1'b0;
    s_axis_tlast = 1'b0;
    repeat(3)
        @(posedge t_clk);
    
    fd = $fopen(file_name, "r");
    while(!$feof(fd))
    begin
        $fscanf(fd, "%h\n%h\n", s_axis_tdata, s_axis_tkeep);
        s_axis_tvalid = 1'b1;
        if(s_axis_tkeep != 64'hffffffffffffffff)
        begin
            s_axis_tlast = 1'b1;
            @(posedge t_clk);
            s_axis_tvalid = 1'b0;
            s_axis_tlast = 1'b0;
            repeat(30)
                @(posedge t_clk);
        end
        else
        begin
            s_axis_tlast = 1'b0;
            @(posedge t_clk);
        end
    end
    $fclose(fd);
end
endtask


task register_setup(input [31:0] reg_addr, reg_val);
begin
    // set register for qdma with axi4 lite     
    axil_awvalid <= 1'b1;
    axil_awaddr <= reg_addr;
    axil_wvalid <= 1'b1;
    axil_wdata <= reg_val;
    axil_bready <= 1'b1;
    @(axil_awready == 1'b1);
    @(posedge axil_clk);
    axil_awvalid <= 1'b0;
    @(axil_wready == 1'b1);
    @(posedge axil_clk);
    axil_wvalid <= 1'b0;
    axil_awaddr <= 32'h00000000;
    axil_wdata <= 32'h00000000;
    axil_bready <= 1'b0;
    @(axil_bvalid == 1'b1);
end
endtask



// module instantiation 

open_nic_shell #(
.NUM_PHYS_FUNC(2),
.NUM_CMAC_PORT(2)
)
open_nic_shell_ins
(
	.axis_aclk(clk),                // axis qdma clk
	.cmac_clk(cmac_clk),            // axis cmac clk
	.axil_aclk(axil_clk),           // axil clk
	.powerup_rstn(aresetn),
	.shell_rst_done(shell_rst_done),
	.user_rst_done(user_rst_done),

	// input Slave AXI Stream
	.s_axis_qdma_h2c_sim_tdata(s_axis_h2c_tdata),
	.s_axis_qdma_h2c_sim_tvalid(s_axis_h2c_tvalid),
	.s_axis_qdma_h2c_sim_tready(s_axis_h2c_tready),
	.s_axis_qdma_h2c_sim_tlast(s_axis_h2c_tlast),
	.s_axis_qdma_h2c_sim_tuser_err(s_axis_h2c_tuser_error),
	.s_axis_qdma_h2c_sim_tuser_zero_byte(s_axis_h2c_tuser_zero_byte),
	.s_axis_qdma_h2c_sim_tuser_mty(s_axis_h2c_tuser_mty),
	.s_axis_qdma_h2c_sim_tuser_mdata(s_axis_h2c_tuser),
	.s_axis_qdma_h2c_sim_tuser_qid(s_axis_h2c_tuser_qid),
	.s_axis_qdma_h2c_sim_tuser_port_id(s_axis_h2c_tuser_port_id),
	.s_axis_qdma_h2c_sim_tcrc(s_axis_h2c_tcrc),
	
	.m_axis_qdma_c2h_sim_tdata(m_axis_c2h_tdata),
	.m_axis_qdma_c2h_sim_tvalid(m_axis_c2h_tvalid),
	.m_axis_qdma_c2h_sim_tready(m_axis_c2h_tready),
	.m_axis_qdma_c2h_sim_tlast(m_axis_c2h_tlast),
	.m_axis_qdma_c2h_sim_ctrl_marker(m_axis_c2h_ctrl_marker),
	.m_axis_qdma_c2h_sim_ctrl_port_id(m_axis_c2h_ctrl_port_id),
	.m_axis_qdma_c2h_sim_ctrl_ecc(m_axis_c2h_ctrl_ecc),
	.m_axis_qdma_c2h_sim_ctrl_len(m_axis_c2h_ctrl_len),
	.m_axis_qdma_c2h_sim_ctrl_qid(m_axis_c2h_ctrl_qid),
	.m_axis_qdma_c2h_sim_ctrl_has_cmpt(m_axis_c2h_ctrl_has_cmpt),
	.m_axis_qdma_c2h_sim_mty(m_axis_c2h_mty),
	.m_axis_qdma_c2h_sim_tcrc(m_axis_c2h_tcrc),

	// output Master AXI Stream
	.m_axis_cmac_tx_sim_tdata(m_axis_tx_tdata),
	.m_axis_cmac_tx_sim_tkeep(m_axis_tx_tkeep),
	.m_axis_cmac_tx_sim_tvalid(m_axis_tx_tvalid),
	.m_axis_cmac_tx_sim_tuser_err(m_axis_tx_tuser),
	.m_axis_cmac_tx_sim_tready(m_axis_tx_tready),
	.m_axis_cmac_tx_sim_tlast(m_axis_tx_tlast),
	
	.s_axis_cmac_rx_sim_tdata(s_axis_rx_tdata),
	.s_axis_cmac_rx_sim_tkeep(s_axis_rx_tkeep),
	.s_axis_cmac_rx_sim_tvalid(s_axis_rx_tvalid),
	.s_axis_cmac_rx_sim_tuser_err(s_axis_rx_tuser_err),
	.s_axis_cmac_rx_sim_tlast(s_axis_rx_tlast),
	
	.s_axil_sim_awvalid(axil_awvalid),
	.s_axil_sim_awaddr(axil_awaddr),
	.s_axil_sim_awready(axil_awready),
	.s_axil_sim_wvalid(axil_wvalid),
	.s_axil_sim_wdata(axil_wdata),
	.s_axil_sim_wready(axil_wready),
	.s_axil_sim_bvalid(axil_bvalid),
	.s_axil_sim_bresp(axil_bresp),
	.s_axil_sim_bready(axil_bready),
	.s_axil_sim_arvalid(axil_arvalid),
	.s_axil_sim_araddr(axil_araddr),
	.s_axil_sim_arready(axil_arready),
	.s_axil_sim_rvalid(axil_rvalid),
	.s_axil_sim_rdata(axil_rdata),
	.s_axil_sim_rresp(axil_rresp),
	.s_axil_sim_rready(axil_rready)
);

endmodule
