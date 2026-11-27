// Author: Simone Di Fraia <sim.difraia@studenti.unina.it>
// Description: Top level wrapper for Vortex GPGPU 
//
//              It has the following sub-architecture:
/*
                                                                         ADDR: MBUS_ADDR_WIDTH                              +-------------------+
               ADDR: MBUS_ADDR_WIDTH        +-----------------------+    DATA: 32                                           |                   |
               DATA: MBUS_DATA_WIDTH        | axi_dwidth_converter  |                                                       |                   |
    +--------+                      ------> |      (64 -> 32)       |-----                                   ADDR: 13       |                   |
    |        |                     | DW:64  +-----------------------+    |                                   DATA: 32       |                   |
    |        |                     |                                     |       +----------------------+    addr[12:0]     |                   |
    |        | MBUS_to_VORTEX      |                                     |       |                      |                   |                   |
    |        | ---------------------                                     |-----> | xlnx_axi4_to_axilite |------------------>|                   |
    |        |                     |                                     |       |                      |  s_vortex_axilite |                   |
    |   M    |                     |                                     |       +----------------------+                   |      Vortex       |
    |   B    |                     | DW:32                               |                                                  |     Subsystem     |
    |   U    |                      --------------------------------------                                                  |                   |
    |   S    |                                                                                                              |                   |
    |        |                                                                                                              |                   |
    |        |                                                                                                              |                   |
    |        |                                                                                                              |                   |
    |        |                                                                                                              |                   |
    |        | VORTEX_to_MBUS                                 +----------------------------+                 m_vortex_axi   |                   |
    |        | <----------------------------------------------|    axi_dwidth_converter    | <------------------------------|                   |
    |        |  ADDR: MBUS_ADDR_WIDTH                         |  (512 -> MBUS_DATA_WIDTH)  |                                |                   |
    +--------+  DATA: MBUS_DATA_WIDTH                         +----------------------------+                ADDR: 64        |                   |
                                                                                                            DATA: 512       +-------------------+
                                                                                                                                             
*/


// Import headers
`include "simplyv_mem.svh"
`include "simplyv_axi.svh"

module custom_top_wrapper #(
    parameter int unsigned LOCAL_AXI_DATA_WIDTH = 64,
    parameter int unsigned LOCAL_AXI_ADDR_WIDTH = 64,
    parameter int unsigned LOCAL_AXI_ID_WIDTH   = 5
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
    `DEFINE_AXI_MASTER_PORTS(m, LOCAL_AXI_DATA_WIDTH, LOCAL_AXI_ADDR_WIDTH, LOCAL_AXI_ID_WIDTH),

    // AXI Slave Interfaces
    `DEFINE_AXI_SLAVE_PORTS(s, LOCAL_AXI_DATA_WIDTH, LOCAL_AXI_ADDR_WIDTH, LOCAL_AXI_ID_WIDTH)
);

    //////////////////
    // Declarations //
    //////////////////

    // VORTEX AXI-lite Slave Path

    //// vx_dwidth_64_to_32_u -> vx_axi4_to_axilite_u
    localparam int unsigned CTRL_DATA_WIDTH = 32;
    localparam int unsigned CTRL_ADDR_WIDTH = LOCAL_AXI_ADDR_WIDTH;
    localparam int unsigned CTRL_ID_WIDTH = LOCAL_AXI_ID_WIDTH; 
    `DECLARE_AXI_BUS(to_prot_conv, CTRL_DATA_WIDTH, CTRL_ADDR_WIDTH, CTRL_ID_WIDTH);

    //// vx_axi4_to_axilite_u -> vortex_sys_u 
    localparam int unsigned LITE_DATA_WIDTH = CTRL_DATA_WIDTH; 
    localparam int unsigned LITE_ADDR_WIDTH = 13; 
    `DECLARE_AXILITE_BUS(to_s_vortex, LITE_DATA_WIDTH, LITE_ADDR_WIDTH);

    // VORTEX AXI4 Master Path 
   
    //// custom_vortex_u -> vx_dwidth_from512_u
    localparam int unsigned VX_DATA_WIDTH = 512;
    localparam int unsigned VX_ADDR_WIDTH = 64;
    localparam int unsigned VX_ID_WIDTH = MBUS_ID_WIDTH; // Must match axi_id_width of Vortex Subsystem
    `DECLARE_AXI_BUS(from_m_vortex, VX_DATA_WIDTH, VX_ADDR_WIDTH, VX_ID_WIDTH);


    /////////////
    // Modules //
    /////////////

    // Use a Dwidth converter if System XLEN is 64-bits wide.
    generate
    if ( LOCAL_AXI_DATA_WIDTH == 64 ) begin : gen_dwidth_conv
       vx_dwidth_64_to_32 vx_dwidth_64_to_32_u (
            .s_axi_aclk     ( clk_i                         ),
            .s_axi_aresetn  ( rst_ni                        ),

            // Slave from MBUS (64 bit)
            .s_axi_awid     ( s_axi_awid                  ),
            .s_axi_awaddr   ( s_axi_awaddr                ),
            .s_axi_awlen    ( s_axi_awlen                 ),
            .s_axi_awsize   ( s_axi_awsize                ),
            .s_axi_awburst  ( s_axi_awburst               ),
            .s_axi_awlock   ( s_axi_awlock                ),
            .s_axi_awcache  ( s_axi_awcache               ),
            .s_axi_awprot   ( s_axi_awprot                ),
            .s_axi_awregion ( s_axi_awregion              ),
            .s_axi_awqos    ( s_axi_awqos                 ),
            .s_axi_awvalid  ( s_axi_awvalid               ),
            .s_axi_awready  ( s_axi_awready               ),
            .s_axi_wdata    ( s_axi_wdata                 ),
            .s_axi_wstrb    ( s_axi_wstrb                 ),
            .s_axi_wlast    ( s_axi_wlast                 ),
            .s_axi_wvalid   ( s_axi_wvalid                ),
            .s_axi_wready   ( s_axi_wready                ),
            .s_axi_bid      ( s_axi_bid                   ),
            .s_axi_bresp    ( s_axi_bresp                 ),
            .s_axi_bvalid   ( s_axi_bvalid                ),
            .s_axi_bready   ( s_axi_bready                ),
            .s_axi_arid     ( s_axi_arid                  ),
            .s_axi_araddr   ( s_axi_araddr                ),
            .s_axi_arlen    ( s_axi_arlen                 ),
            .s_axi_arsize   ( s_axi_arsize                ),
            .s_axi_arburst  ( s_axi_arburst               ),
            .s_axi_arlock   ( s_axi_arlock                ),
            .s_axi_arcache  ( s_axi_arcache               ),
            .s_axi_arprot   ( s_axi_arprot                ),
            .s_axi_arregion ( s_axi_arregion              ),
            .s_axi_arqos    ( s_axi_arqos                 ),
            .s_axi_arvalid  ( s_axi_arvalid               ),
            .s_axi_arready  ( s_axi_arready               ),
            .s_axi_rid      ( s_axi_rid                   ),
            .s_axi_rdata    ( s_axi_rdata                 ),
            .s_axi_rresp    ( s_axi_rresp                 ),
            .s_axi_rlast    ( s_axi_rlast                 ),
            .s_axi_rvalid   ( s_axi_rvalid                ),
            .s_axi_rready   ( s_axi_rready                ),
            
            // Master to protocol converter (32 bit)
            // NOTE: the downsizer has no master-side IDs
            .m_axi_awaddr   ( to_prot_conv_axi_awaddr            ),
            .m_axi_awlen    ( to_prot_conv_axi_awlen             ),
            .m_axi_awsize   ( to_prot_conv_axi_awsize            ),
            .m_axi_awburst  ( to_prot_conv_axi_awburst           ),
            .m_axi_awlock   ( to_prot_conv_axi_awlock            ),
            .m_axi_awcache  ( to_prot_conv_axi_awcache           ),
            .m_axi_awprot   ( to_prot_conv_axi_awprot            ),
            .m_axi_awregion ( to_prot_conv_axi_awregion          ),
            .m_axi_awqos    ( to_prot_conv_axi_awqos             ),
            .m_axi_awvalid  ( to_prot_conv_axi_awvalid           ),
            .m_axi_awready  ( to_prot_conv_axi_awready           ),
            .m_axi_wdata    ( to_prot_conv_axi_wdata             ),
            .m_axi_wstrb    ( to_prot_conv_axi_wstrb             ),
            .m_axi_wlast    ( to_prot_conv_axi_wlast             ),
            .m_axi_wvalid   ( to_prot_conv_axi_wvalid            ),
            .m_axi_wready   ( to_prot_conv_axi_wready            ),
            .m_axi_bresp    ( to_prot_conv_axi_bresp             ),
            .m_axi_bvalid   ( to_prot_conv_axi_bvalid            ),
            .m_axi_bready   ( to_prot_conv_axi_bready            ),
            .m_axi_araddr   ( to_prot_conv_axi_araddr            ),
            .m_axi_arlen    ( to_prot_conv_axi_arlen             ),
            .m_axi_arsize   ( to_prot_conv_axi_arsize            ),
            .m_axi_arburst  ( to_prot_conv_axi_arburst           ),
            .m_axi_arlock   ( to_prot_conv_axi_arlock            ),
            .m_axi_arcache  ( to_prot_conv_axi_arcache           ),
            .m_axi_arprot   ( to_prot_conv_axi_arprot            ),
            .m_axi_arregion ( to_prot_conv_axi_arregion          ),
            .m_axi_arqos    ( to_prot_conv_axi_arqos             ),
            .m_axi_arvalid  ( to_prot_conv_axi_arvalid           ),
            .m_axi_arready  ( to_prot_conv_axi_arready           ),
            .m_axi_rdata    ( to_prot_conv_axi_rdata             ),
            .m_axi_rresp    ( to_prot_conv_axi_rresp             ),
            .m_axi_rlast    ( to_prot_conv_axi_rlast             ),
            .m_axi_rvalid   ( to_prot_conv_axi_rvalid            ),
            .m_axi_rready   ( to_prot_conv_axi_rready            )
        );

        // Downsizer output has no IDs: single ID towards the protocol converter
        assign to_prot_conv_axi_awid = '0;
        assign to_prot_conv_axi_arid = '0;

    end : gen_dwidth_conv
    else begin : no_dwidth_conv

        // Pass through (XLEN == 32: MBUS is already 32 bit)
         `ASSIGN_AXI_BUS(to_prot_conv, S_VORTEX)

    end : no_dwidth_conv
    endgenerate
    
    // convert from AXI4 to AXI-Lite
    vx_axi4_to_axilite  vx_axi4_to_axilite_u (
          .aclk           ( clk_i                ),
          .aresetn        ( rst_ni               ),

          // Slave interface (AXI4)
          .s_axi_awid     ( to_prot_conv_axi_awid     ),
          .s_axi_awaddr   ( to_prot_conv_axi_awaddr   ),
          .s_axi_awlen    ( to_prot_conv_axi_awlen    ),
          .s_axi_awsize   ( to_prot_conv_axi_awsize   ),
          .s_axi_awburst  ( to_prot_conv_axi_awburst  ),
          .s_axi_awlock   ( to_prot_conv_axi_awlock   ),
          .s_axi_awcache  ( to_prot_conv_axi_awcache  ),
          .s_axi_awprot   ( to_prot_conv_axi_awprot   ),
          .s_axi_awregion ( to_prot_conv_axi_awregion ),
          .s_axi_awqos    ( to_prot_conv_axi_awqos    ),
          .s_axi_awvalid  ( to_prot_conv_axi_awvalid  ),
          .s_axi_awready  ( to_prot_conv_axi_awready  ),
          .s_axi_wdata    ( to_prot_conv_axi_wdata    ),
          .s_axi_wstrb    ( to_prot_conv_axi_wstrb    ),
          .s_axi_wlast    ( to_prot_conv_axi_wlast    ),
          .s_axi_wvalid   ( to_prot_conv_axi_wvalid   ),
          .s_axi_wready   ( to_prot_conv_axi_wready   ),
          .s_axi_bid      ( to_prot_conv_axi_bid      ),
          .s_axi_bresp    ( to_prot_conv_axi_bresp    ),
          .s_axi_bvalid   ( to_prot_conv_axi_bvalid   ),
          .s_axi_bready   ( to_prot_conv_axi_bready   ),
          .s_axi_arid     ( to_prot_conv_axi_arid     ),
          .s_axi_araddr   ( to_prot_conv_axi_araddr   ),
          .s_axi_arlen    ( to_prot_conv_axi_arlen    ),
          .s_axi_arsize   ( to_prot_conv_axi_arsize   ),
          .s_axi_arburst  ( to_prot_conv_axi_arburst  ),
          .s_axi_arlock   ( to_prot_conv_axi_arlock   ),
          .s_axi_arcache  ( to_prot_conv_axi_arcache  ),
          .s_axi_arprot   ( to_prot_conv_axi_arprot   ),
          .s_axi_arregion ( to_prot_conv_axi_arregion ),
          .s_axi_arqos    ( to_prot_conv_axi_arqos    ),
          .s_axi_arvalid  ( to_prot_conv_axi_arvalid  ),
          .s_axi_arready  ( to_prot_conv_axi_arready  ),
          .s_axi_rid      ( to_prot_conv_axi_rid      ),
          .s_axi_rdata    ( to_prot_conv_axi_rdata    ),
          .s_axi_rresp    ( to_prot_conv_axi_rresp    ),
          .s_axi_rlast    ( to_prot_conv_axi_rlast    ),
          .s_axi_rvalid   ( to_prot_conv_axi_rvalid   ),
          .s_axi_rready   ( to_prot_conv_axi_rready   ),
                                                    
          // Master interface (AXI-Lite)
          .m_axi_awaddr   ( to_s_vortex_axilite_awaddr    ),
          .m_axi_awprot   ( to_s_vortex_axilite_awprot    ),
          .m_axi_awvalid  ( to_s_vortex_axilite_awvalid   ),
          .m_axi_awready  ( to_s_vortex_axilite_awready   ),
          .m_axi_wdata    ( to_s_vortex_axilite_wdata     ),
          .m_axi_wstrb    ( to_s_vortex_axilite_wstrb     ),
          .m_axi_wvalid   ( to_s_vortex_axilite_wvalid    ),
          .m_axi_wready   ( to_s_vortex_axilite_wready    ),
          .m_axi_bresp    ( to_s_vortex_axilite_bresp     ),
          .m_axi_bvalid   ( to_s_vortex_axilite_bvalid    ),
          .m_axi_bready   ( to_s_vortex_axilite_bready    ),
          .m_axi_araddr   ( to_s_vortex_axilite_araddr    ),
          .m_axi_arprot   ( to_s_vortex_axilite_arprot    ),
          .m_axi_arvalid  ( to_s_vortex_axilite_arvalid   ),
          .m_axi_arready  ( to_s_vortex_axilite_arready   ),
          .m_axi_rdata    ( to_s_vortex_axilite_rdata     ),
          .m_axi_rresp    ( to_s_vortex_axilite_rresp     ),
          .m_axi_rvalid   ( to_s_vortex_axilite_rvalid    ),
          .m_axi_rready   ( to_s_vortex_axilite_rready    )
      );



    assign from_m_vortex_axi_awregion = '0;
    assign from_m_vortex_axi_arregion = '0; 

    // Vortex Subsystem top
    vortex_sys vortex_sys_u(
          .aclk    (clk_i),  
          .aresetn (rst_ni), 
          .uart_tx (uart_tx_o), 
          // AXI master
          .M_AXI_VORTEX_araddr( from_m_vortex_axi_araddr ),
          .M_AXI_VORTEX_arburst( from_m_vortex_axi_arburst ),
          .M_AXI_VORTEX_arcache( from_m_vortex_axi_arcache ),
          .M_AXI_VORTEX_arid( from_m_vortex_axi_arid ),
          .M_AXI_VORTEX_arlen( from_m_vortex_axi_arlen ),
          .M_AXI_VORTEX_arlock( from_m_vortex_axi_arlock ),
          .M_AXI_VORTEX_arprot( from_m_vortex_axi_arprot ),
          .M_AXI_VORTEX_arqos( from_m_vortex_axi_arqos ),
          .M_AXI_VORTEX_arready( from_m_vortex_axi_arready ),
          .M_AXI_VORTEX_arsize( from_m_vortex_axi_arsize ),
          .M_AXI_VORTEX_arvalid( from_m_vortex_axi_arvalid ),
          .M_AXI_VORTEX_awaddr( from_m_vortex_axi_awaddr ),
          .M_AXI_VORTEX_awburst( from_m_vortex_axi_awburst ),
          .M_AXI_VORTEX_awcache( from_m_vortex_axi_awcache ),
          .M_AXI_VORTEX_awid( from_m_vortex_axi_awid ),
          .M_AXI_VORTEX_awlen( from_m_vortex_axi_awlen ),
          .M_AXI_VORTEX_awlock( from_m_vortex_axi_awlock ),
          .M_AXI_VORTEX_awprot( from_m_vortex_axi_awprot ),
          .M_AXI_VORTEX_awqos( from_m_vortex_axi_awqos ),
          .M_AXI_VORTEX_awready( from_m_vortex_axi_awready ),
          .M_AXI_VORTEX_awsize( from_m_vortex_axi_awsize ),
          .M_AXI_VORTEX_awvalid( from_m_vortex_axi_awvalid ),
          .M_AXI_VORTEX_bid( from_m_vortex_axi_bid ),
          .M_AXI_VORTEX_bready( from_m_vortex_axi_bready ),
          .M_AXI_VORTEX_bresp( from_m_vortex_axi_bresp ),
          .M_AXI_VORTEX_bvalid( from_m_vortex_axi_bvalid ),
          .M_AXI_VORTEX_rdata( from_m_vortex_axi_rdata ),
          .M_AXI_VORTEX_rid( from_m_vortex_axi_rid ),
          .M_AXI_VORTEX_rlast( from_m_vortex_axi_rlast ),
          .M_AXI_VORTEX_rready( from_m_vortex_axi_rready ),
          .M_AXI_VORTEX_rresp( from_m_vortex_axi_rresp ),
          .M_AXI_VORTEX_rvalid( from_m_vortex_axi_rvalid ),
          .M_AXI_VORTEX_wdata( from_m_vortex_axi_wdata ),
          .M_AXI_VORTEX_wlast( from_m_vortex_axi_wlast ),
          .M_AXI_VORTEX_wready( from_m_vortex_axi_wready ),
          .M_AXI_VORTEX_wstrb( from_m_vortex_axi_wstrb ),
          .M_AXI_VORTEX_wvalid( from_m_vortex_axi_wvalid ),
          // AXI-lite slave
          .S_AXI_VORTEX_araddr( to_s_vortex_axilite_araddr ),
          .S_AXI_VORTEX_arprot( to_s_vortex_axilite_arprot ),
          .S_AXI_VORTEX_arready( to_s_vortex_axilite_arready ),
          .S_AXI_VORTEX_arvalid( to_s_vortex_axilite_arvalid ),
          .S_AXI_VORTEX_awaddr( to_s_vortex_axilite_awaddr ),
          .S_AXI_VORTEX_awprot( to_s_vortex_axilite_awprot ),
          .S_AXI_VORTEX_awready( to_s_vortex_axilite_awready ),
          .S_AXI_VORTEX_awvalid( to_s_vortex_axilite_awvalid ),
          .S_AXI_VORTEX_bready( to_s_vortex_axilite_bready ),
          .S_AXI_VORTEX_bresp( to_s_vortex_axilite_bresp ),
          .S_AXI_VORTEX_bvalid( to_s_vortex_axilite_bvalid ),
          .S_AXI_VORTEX_rdata( to_s_vortex_axilite_rdata ),
          .S_AXI_VORTEX_rready( to_s_vortex_axilite_rready ),
          .S_AXI_VORTEX_rresp( to_s_vortex_axilite_rresp ),
          .S_AXI_VORTEX_rvalid( to_s_vortex_axilite_rvalid ),
          .S_AXI_VORTEX_wdata( to_s_vortex_axilite_wdata ),
          .S_AXI_VORTEX_wready( to_s_vortex_axilite_wready ),
          .S_AXI_VORTEX_wstrb( to_s_vortex_axilite_wstrb ),
          .S_AXI_VORTEX_wvalid( to_s_vortex_axilite_wvalid )
    ); 


    
    vx_dwidth_from512 vx_dwidth_from512_u (
        .s_axi_aclk     ( clk_i                                    ),
        .s_axi_aresetn  ( rst_ni                                   ),

        // Slave from Vortex (512 bit, 64-bit address clipped to MBUS_ADDR_WIDTH)
        .s_axi_awid     ( from_m_vortex_axi_awid                               ),
        .s_axi_awaddr   ( from_m_vortex_axi_awaddr[MBUS_ADDR_WIDTH-1:0]        ),
        .s_axi_awlen    ( from_m_vortex_axi_awlen                              ),
        .s_axi_awsize   ( from_m_vortex_axi_awsize                             ),
        .s_axi_awburst  ( from_m_vortex_axi_awburst                            ),
        .s_axi_awlock   ( from_m_vortex_axi_awlock                             ),
        .s_axi_awcache  ( from_m_vortex_axi_awcache                            ),
        .s_axi_awprot   ( from_m_vortex_axi_awprot                             ),
        .s_axi_awregion ( from_m_vortex_axi_awregion                           ),
        .s_axi_awqos    ( from_m_vortex_axi_awqos                              ),
        .s_axi_awvalid  ( from_m_vortex_axi_awvalid                            ),
        .s_axi_awready  ( from_m_vortex_axi_awready                            ),
        .s_axi_wdata    ( from_m_vortex_axi_wdata                              ),
        .s_axi_wstrb    ( from_m_vortex_axi_wstrb                              ),
        .s_axi_wlast    ( from_m_vortex_axi_wlast                              ),
        .s_axi_wvalid   ( from_m_vortex_axi_wvalid                             ),
        .s_axi_wready   ( from_m_vortex_axi_wready                             ),
        .s_axi_bid      ( from_m_vortex_axi_bid                                ),
        .s_axi_bresp    ( from_m_vortex_axi_bresp                              ),
        .s_axi_bvalid   ( from_m_vortex_axi_bvalid                             ),
        .s_axi_bready   ( from_m_vortex_axi_bready                             ),
        .s_axi_arid     ( from_m_vortex_axi_arid                               ),
        .s_axi_araddr   ( from_m_vortex_axi_araddr[MBUS_ADDR_WIDTH-1:0]        ),
        .s_axi_arlen    ( from_m_vortex_axi_arlen                              ),
        .s_axi_arsize   ( from_m_vortex_axi_arsize                             ),
        .s_axi_arburst  ( from_m_vortex_axi_arburst                            ),
        .s_axi_arlock   ( from_m_vortex_axi_arlock                             ),
        .s_axi_arcache  ( from_m_vortex_axi_arcache                            ),
        .s_axi_arprot   ( from_m_vortex_axi_arprot                             ),
        .s_axi_arregion ( from_m_vortex_axi_arregion                           ),
        .s_axi_arqos    ( from_m_vortex_axi_arqos                              ),
        .s_axi_arvalid  ( from_m_vortex_axi_arvalid                            ),
        .s_axi_arready  ( from_m_vortex_axi_arready                            ),
        .s_axi_rid      ( from_m_vortex_axi_rid                                ),
        .s_axi_rdata    ( from_m_vortex_axi_rdata                              ),
        .s_axi_rresp    ( from_m_vortex_axi_rresp                              ),
        .s_axi_rlast    ( from_m_vortex_axi_rlast                              ),
        .s_axi_rvalid   ( from_m_vortex_axi_rvalid                             ),
        .s_axi_rready   ( from_m_vortex_axi_rready                             ),
        // Master to MBUS (MBUS_DATA_WIDTH)
        // NOTE: the downsizer has no master-side IDs
        .m_axi_awaddr   ( m_axi_awaddr                           ),
        .m_axi_awlen    ( m_axi_awlen                            ),
        .m_axi_awsize   ( m_axi_awsize                           ),
        .m_axi_awburst  ( m_axi_awburst                          ),
        .m_axi_awlock   ( m_axi_awlock                           ),
        .m_axi_awcache  ( m_axi_awcache                          ),
        .m_axi_awprot   ( m_axi_awprot                           ),
        .m_axi_awregion ( m_axi_awregion                         ),
        .m_axi_awqos    ( m_axi_awqos                            ),
        .m_axi_awvalid  ( m_axi_awvalid                          ),
        .m_axi_awready  ( m_axi_awready                          ),
        .m_axi_wdata    ( m_axi_wdata                            ),
        .m_axi_wstrb    ( m_axi_wstrb                            ),
        .m_axi_wlast    ( m_axi_wlast                            ),
        .m_axi_wvalid   ( m_axi_wvalid                           ),
        .m_axi_wready   ( m_axi_wready                           ),
        .m_axi_bresp    ( m_axi_bresp                            ),
        .m_axi_bvalid   ( m_axi_bvalid                           ),
        .m_axi_bready   ( m_axi_bready                           ),
        .m_axi_araddr   ( m_axi_araddr                           ),
        .m_axi_arlen    ( m_axi_arlen                            ),
        .m_axi_arsize   ( m_axi_arsize                           ),
        .m_axi_arburst  ( m_axi_arburst                          ),
        .m_axi_arlock   ( m_axi_arlock                           ),
        .m_axi_arcache  ( m_axi_arcache                          ),
        .m_axi_arprot   ( m_axi_arprot                           ),
        .m_axi_arregion ( m_axi_arregion                         ),
        .m_axi_arqos    ( m_axi_arqos                            ),
        .m_axi_arvalid  ( m_axi_arvalid                          ),
        .m_axi_arready  ( m_axi_arready                          ),
        .m_axi_rdata    ( m_axi_rdata                            ),
        .m_axi_rresp    ( m_axi_rresp                            ),
        .m_axi_rlast    ( m_axi_rlast                            ),
        .m_axi_rvalid   ( m_axi_rvalid                           ),
        .m_axi_rready   ( m_axi_rready                           )
    );

    // Downsizer output has no IDs: single ID towards the MBUS
    // (bid/rid from the MBUS are not needed)
    assign m_axi_awid = '0;
    assign m_axi_arid = '0;


endmodule : custom_top_wrapper
