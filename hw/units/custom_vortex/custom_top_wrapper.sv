// Author: Simone Di Fraia <sim.difraia@studenti.unina.it>
// Description: Top level wrapper for Vortex GPGPU 

// Import headers
`include "simplyv_mem.svh"
`include "simplyv_axi.svh"

module custom_top_wrapper # (

    //////////////////////////////////////
    //  Add here IP-related parameters  //
    //////////////////////////////////////
    // AXI master parameters
    localparam LOCAL_AXI_DATA_WIDTH     = 512,
    localparam LOCAL_AXI_ADDR_WIDTH     = 64,
    localparam LOCAL_AXI_ID_WIDTH       = 32,
    // AXI-lite slave parameters
    localparam LOCAL_AXILITE_DATA_WIDTH = 32,
    localparam LOCAL_AXILITE_ADDR_WIDTH = 13

) (

    ///////////////////////////////////
    //  Add here IP-related signals  //
    ///////////////////////////////////

    input  logic        clk_i,
    input  logic        rst_ni,
	  output logic        uart_tx_o,

    ////////////////////////////
    //  Bus Array Interfaces  //
    ////////////////////////////

    // AXI Master Interfaces
    `DEFINE_AXI_MASTER_PORTS(m_vortex, LOCAL_AXI_DATA_WIDTH, LOCAL_AXI_ADDR_WIDTH, LOCAL_AXI_ID_WIDTH),

    // AXI Slave Interfaces
    `DEFINE_AXILITE_SLAVE_PORTS(s_vortex, LOCAL_AXILITE_DATA_WIDTH, LOCAL_AXILITE_ADDR_WIDTH)
);

    assign m_vortex_axi_awregion = '0;
    assign m_vortex_axi_arregion = '0; 

    // Vortex Subsystem top
    vortex_sys vortex_sys_u(
          .aclk    (clk_i),  
          .aresetn (rst_ni), 
          .uart_tx (uart_tx_0), 
          // AXI master
          .M_AXI_VORTEX_araddr(m_vortex_axi_awradd),
          .M_AXI_VORTEX_arburst(m_vortex_axi_arburst),
          .M_AXI_VORTEX_arcache(m_vortex_axi_arcache),
          .M_AXI_VORTEX_arid(m_vortex_axi_arid),
          .M_AXI_VORTEX_arlen(m_vortex_axi_arlen),
          .M_AXI_VORTEX_arlock(m_vortex_axi_arlock),
          .M_AXI_VORTEX_arprot(m_vortex_axi_arprot),
          .M_AXI_VORTEX_arqos(m_vortex_axi_arqos),
          .M_AXI_VORTEX_arready(m_vortex_axi_arready),
          .M_AXI_VORTEX_arsize(m_vortex_axi_arsize),
          .M_AXI_VORTEX_arvalid(m_vortex_axi_arvalid),
          .M_AXI_VORTEX_awaddr(m_vortex_axi_awaddr),
          .M_AXI_VORTEX_awburst(m_vortex_axi_awburst),
          .M_AXI_VORTEX_awcache(m_vortex_axi_awcache),
          .M_AXI_VORTEX_awid(m_vortex_axi_awid),
          .M_AXI_VORTEX_awlen(m_vortex_axi_awlen),
          .M_AXI_VORTEX_awlock(m_vortex_axi_awlock),
          .M_AXI_VORTEX_awprot(m_vortex_axi_awprot),
          .M_AXI_VORTEX_awqos(m_vortex_axi_awqos),
          .M_AXI_VORTEX_awready(m_vortex_axi_awready),
          .M_AXI_VORTEX_awsize(m_vortex_axi_awsize),
          .M_AXI_VORTEX_awvalid(m_vortex_axi_awvalid),
          .M_AXI_VORTEX_bid(m_vortex_axi_bid),
          .M_AXI_VORTEX_bready(m_vortex_axi_bready),
          .M_AXI_VORTEX_bresp(m_vortex_axi_bresp),
          .M_AXI_VORTEX_bvalid(m_vortex_axi_bvalid),
          .M_AXI_VORTEX_rdata(m_vortex_axi_rdata),
          .M_AXI_VORTEX_rid(m_vortex_axi_rid),
          .M_AXI_VORTEX_rlast(m_vortex_axi_rlast),
          .M_AXI_VORTEX_rready(m_vortex_axi_rready),
          .M_AXI_VORTEX_rresp(m_vortex_axi_rresp),
          .M_AXI_VORTEX_rvalid(m_vortex_axi_rvalid),
          .M_AXI_VORTEX_wdata(m_vortex_axi_wdata),
          .M_AXI_VORTEX_wlast(m_vortex_axi_wlast),
          .M_AXI_VORTEX_wready(m_vortex_axi_wready),
          .M_AXI_VORTEX_wstrb(m_vortex_axi_wstrb),
          .M_AXI_VORTEX_wvalid(m_vortex_axi_wvalid),
          // AXI-lite slave
          .S_AXI_VORTEX_araddr(s_vortex_axilite_araddr),
          .S_AXI_VORTEX_arprot(s_vortex_axilite_arprot),
          .S_AXI_VORTEX_arready(s_vortex_axilite_arready),
          .S_AXI_VORTEX_arvalid(s_vortex_axilite_arvalid),
          .S_AXI_VORTEX_awaddr(s_vortex_axilite_awaddr),
          .S_AXI_VORTEX_awprot(s_vortex_axilite_awprot),
          .S_AXI_VORTEX_awready(s_vortex_axilite_awready),
          .S_AXI_VORTEX_awvalid(s_vortex_axilite_awvalid),
          .S_AXI_VORTEX_bready(s_vortex_axilite_bready),
          .S_AXI_VORTEX_bresp(s_vortex_axilite_bresp),
          .S_AXI_VORTEX_bvalid(s_vortex_axilite_bvalid),
          .S_AXI_VORTEX_rdata(s_vortex_axilite_rdata),
          .S_AXI_VORTEX_rready(s_vortex_axilite_rready),
          .S_AXI_VORTEX_rresp(s_vortex_axilite_rresp),
          .S_AXI_VORTEX_rvalid(s_vortex_axilite_rvalid),
          .S_AXI_VORTEX_wdata(s_vortex_axilite_wdata),
          .S_AXI_VORTEX_wready(s_vortex_axilite_wready),
          .S_AXI_VORTEX_wstrb(s_vortex_axilite_wstrb),
          .S_AXI_VORTEX_wvalid(s_vortex_axilite_wvalid)
    ); 
    


endmodule : custom_top_wrapper
