// Author: Simone Di Fraia <sim.difraia@studenti.unina.it>
// Description: This module is a wrapper for Vortex GPGPU.
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


module vortex_wrapper # (
    // MBUS parameters
    parameter MBUS_ADDR_WIDTH = 32,
    parameter MBUS_DATA_WIDTH = 32,
    parameter MBUS_ID_WIDTH   = 5
) (
    // MBUS clock and reset
    input  logic MBUS_clk_i,
    input  logic MBUS_rstn_i,

    // Slave for control
    `DEFINE_AXI_SLAVE_PORTS(S_VORTEX, MBUS_DATA_WIDTH, MBUS_ADDR_WIDTH, MBUS_ID_WIDTH),

    // Master to MBUS
    `DEFINE_AXI_MASTER_PORTS(M_VORTEX, MBUS_DATA_WIDTH, MBUS_ADDR_WIDTH, MBUS_ID_WIDTH)

);

    //////////////////
    // Declarations //
    //////////////////

    // VORTEX AXI-lite Slave Path
    // axi_dwidth_conv_u -> xlnx_axi4_to_axilite_u
    localparam int unsigned CTRL_DATA_WIDTH = 32;
    localparam int unsigned CTRL_ADDR_WIDTH = 32; // NOTE: clips the MBUS address (the IP configuration leaves ADDR_WIDTH to default (32), but nevermind because Vortex only needs the least signifcant 13 bits)
    `DECLARE_AXI_BUS(to_prot_conv, CTRL_DATA_WIDTH, CTRL_ADDR_WIDTH, MBUS_ID_WIDTH);

    // xlnx_axi4_to_axilite_u -> custom_vortex_u 
    `DECLARE_AXILITE_BUS(to_s_vortex, CTRL_DATA_WIDTH, CTRL_ADDR_WIDTH);

    // VORTEX AXI4 Master Path 
    // custom_vortex_u -> axi_dwidth_conv_u
    localparam int unsigned VX_DATA_WIDTH = 512;
    localparam int unsigned VX_ADDR_WIDTH = 64;
    localparam int unsigned VX_ID_WIDTH = MBUS_ID_WIDTH; // Must match axi_id_width of Vortex Subsystem
    `DECLARE_AXI_BUS(from_m_vortex, VX_DATA_WIDTH, VX_ADDR_WIDTH, VX_ID_WIDTH);

    /////////////
    // Modules //
    /////////////
    
    // Use a Dwidth converter if System XLEN is 64-bits wide.
    generate
    if ( MBUS_DATA_WIDTH == 64 ) begin : gen_dwidth_conv
       xlnx_axi_dwidth_64_to_32_converter axi_dwidth_conv_u (
            .s_axi_aclk     ( MBUS_clk_i                         ),
            .s_axi_aresetn  ( MBUS_rstn_i                        ),
 
            // Slave from MBUS (64 bit)
            .s_axi_awid     ( S_VORTEX_axi_awid                  ),
            .s_axi_awaddr   ( S_VORTEX_axi_awaddr[CTRL_ADDR_WIDTH-1:0] ),
            .s_axi_awlen    ( S_VORTEX_axi_awlen                 ),
            .s_axi_awsize   ( S_VORTEX_axi_awsize                ),
            .s_axi_awburst  ( S_VORTEX_axi_awburst               ),
            .s_axi_awlock   ( S_VORTEX_axi_awlock                ),
            .s_axi_awcache  ( S_VORTEX_axi_awcache               ),
            .s_axi_awprot   ( S_VORTEX_axi_awprot                ),
            .s_axi_awregion ( S_VORTEX_axi_awregion              ),
            .s_axi_awqos    ( S_VORTEX_axi_awqos                 ),
            .s_axi_awvalid  ( S_VORTEX_axi_awvalid               ),
            .s_axi_awready  ( S_VORTEX_axi_awready               ),
            .s_axi_wdata    ( S_VORTEX_axi_wdata                 ),
            .s_axi_wstrb    ( S_VORTEX_axi_wstrb                 ),
            .s_axi_wlast    ( S_VORTEX_axi_wlast                 ),
            .s_axi_wvalid   ( S_VORTEX_axi_wvalid                ),
            .s_axi_wready   ( S_VORTEX_axi_wready                ),
            .s_axi_bid      ( S_VORTEX_axi_bid                   ),
            .s_axi_bresp    ( S_VORTEX_axi_bresp                 ),
            .s_axi_bvalid   ( S_VORTEX_axi_bvalid                ),
            .s_axi_bready   ( S_VORTEX_axi_bready                ),
            .s_axi_arid     ( S_VORTEX_axi_arid                  ),
            .s_axi_araddr   ( S_VORTEX_axi_araddr[CTRL_ADDR_WIDTH-1:0] ),
            .s_axi_arlen    ( S_VORTEX_axi_arlen                 ),
            .s_axi_arsize   ( S_VORTEX_axi_arsize                ),
            .s_axi_arburst  ( S_VORTEX_axi_arburst               ),
            .s_axi_arlock   ( S_VORTEX_axi_arlock                ),
            .s_axi_arcache  ( S_VORTEX_axi_arcache               ),
            .s_axi_arprot   ( S_VORTEX_axi_arprot                ),
            .s_axi_arregion ( S_VORTEX_axi_arregion              ),
            .s_axi_arqos    ( S_VORTEX_axi_arqos                 ),
            .s_axi_arvalid  ( S_VORTEX_axi_arvalid               ),
            .s_axi_arready  ( S_VORTEX_axi_arready               ),
            .s_axi_rid      ( S_VORTEX_axi_rid                   ),
            .s_axi_rdata    ( S_VORTEX_axi_rdata                 ),
            .s_axi_rresp    ( S_VORTEX_axi_rresp                 ),
            .s_axi_rlast    ( S_VORTEX_axi_rlast                 ),
            .s_axi_rvalid   ( S_VORTEX_axi_rvalid                ),
            .s_axi_rready   ( S_VORTEX_axi_rready                ),
 
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
    xlnx_axi4_to_axilite_d32_converter xlnx_axi4_to_axilite_u (
          .aclk           ( MBUS_clk_i                ),
          .aresetn        ( MBUS_rstn_i               ),
   
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


    // Vortex instance
     custom_vortex custom_vortex_u (
        .clk_i                      ( MBUS_clk_i                    ),
        .rst_ni                     ( MBUS_rstn_i                   ),
        .uart_tx_o                  (                               ), // Unconnected for now
 
        // AXI master (Vortex memory requests)
        .m_vortex_axi_awid          ( from_m_vortex_axi_awid               ),
        .m_vortex_axi_awaddr        ( from_m_vortex_axi_awaddr             ),
        .m_vortex_axi_awlen         ( from_m_vortex_axi_awlen              ),
        .m_vortex_axi_awsize        ( from_m_vortex_axi_awsize             ),
        .m_vortex_axi_awburst       ( from_m_vortex_axi_awburst            ),
        .m_vortex_axi_awlock        ( from_m_vortex_axi_awlock             ),
        .m_vortex_axi_awcache       ( from_m_vortex_axi_awcache            ),
        .m_vortex_axi_awprot        ( from_m_vortex_axi_awprot             ),
        .m_vortex_axi_awregion      ( from_m_vortex_axi_awregion           ),
        .m_vortex_axi_awqos         ( from_m_vortex_axi_awqos              ),
        .m_vortex_axi_awvalid       ( from_m_vortex_axi_awvalid            ),
        .m_vortex_axi_awready       ( from_m_vortex_axi_awready            ),
        .m_vortex_axi_wdata         ( from_m_vortex_axi_wdata              ),
        .m_vortex_axi_wstrb         ( from_m_vortex_axi_wstrb              ),
        .m_vortex_axi_wlast         ( from_m_vortex_axi_wlast              ),
        .m_vortex_axi_wvalid        ( from_m_vortex_axi_wvalid             ),
        .m_vortex_axi_wready        ( from_m_vortex_axi_wready             ),
        .m_vortex_axi_bid           ( from_m_vortex_axi_bid                ),
        .m_vortex_axi_bresp         ( from_m_vortex_axi_bresp              ),
        .m_vortex_axi_bvalid        ( from_m_vortex_axi_bvalid             ),
        .m_vortex_axi_bready        ( from_m_vortex_axi_bready             ),
        .m_vortex_axi_arid          ( from_m_vortex_axi_arid               ),
        .m_vortex_axi_araddr        ( from_m_vortex_axi_araddr             ),
        .m_vortex_axi_arlen         ( from_m_vortex_axi_arlen              ),
        .m_vortex_axi_arsize        ( from_m_vortex_axi_arsize             ),
        .m_vortex_axi_arburst       ( from_m_vortex_axi_arburst            ),
        .m_vortex_axi_arlock        ( from_m_vortex_axi_arlock             ),
        .m_vortex_axi_arcache       ( from_m_vortex_axi_arcache            ),
        .m_vortex_axi_arprot        ( from_m_vortex_axi_arprot             ),
        .m_vortex_axi_arregion      ( from_m_vortex_axi_arregion           ),
        .m_vortex_axi_arqos         ( from_m_vortex_axi_arqos              ),
        .m_vortex_axi_arvalid       ( from_m_vortex_axi_arvalid            ),
        .m_vortex_axi_arready       ( from_m_vortex_axi_arready            ),
        .m_vortex_axi_rid           ( from_m_vortex_axi_rid                ),
        .m_vortex_axi_rdata         ( from_m_vortex_axi_rdata              ),
        .m_vortex_axi_rresp         ( from_m_vortex_axi_rresp              ),
        .m_vortex_axi_rlast         ( from_m_vortex_axi_rlast              ),
        .m_vortex_axi_rvalid        ( from_m_vortex_axi_rvalid             ),
        .m_vortex_axi_rready        ( from_m_vortex_axi_rready             ),


        // AXI-Lite slave (VX console + DCR), 8 KB window: only addr[12:0]
        .s_vortex_axilite_awaddr    ( to_s_vortex_axilite_awaddr[12:0]  ),
        .s_vortex_axilite_awprot    ( to_s_vortex_axilite_awprot        ),
        .s_vortex_axilite_awvalid   ( to_s_vortex_axilite_awvalid       ),
        .s_vortex_axilite_awready   ( to_s_vortex_axilite_awready       ),
        .s_vortex_axilite_wdata     ( to_s_vortex_axilite_wdata         ),
        .s_vortex_axilite_wstrb     ( to_s_vortex_axilite_wstrb         ),
        .s_vortex_axilite_wvalid    ( to_s_vortex_axilite_wvalid        ),
        .s_vortex_axilite_wready    ( to_s_vortex_axilite_wready        ),
        .s_vortex_axilite_bresp     ( to_s_vortex_axilite_bresp         ),
        .s_vortex_axilite_bvalid    ( to_s_vortex_axilite_bvalid        ),
        .s_vortex_axilite_bready    ( to_s_vortex_axilite_bready        ),
        .s_vortex_axilite_araddr    ( to_s_vortex_axilite_araddr[12:0]  ),
        .s_vortex_axilite_arprot    ( to_s_vortex_axilite_arprot        ),
        .s_vortex_axilite_arvalid   ( to_s_vortex_axilite_arvalid       ),
        .s_vortex_axilite_arready   ( to_s_vortex_axilite_arready       ),
        .s_vortex_axilite_rdata     ( to_s_vortex_axilite_rdata         ),
        .s_vortex_axilite_rresp     ( to_s_vortex_axilite_rresp         ),
        .s_vortex_axilite_rvalid    ( to_s_vortex_axilite_rvalid        ),
        .s_vortex_axilite_rready    ( to_s_vortex_axilite_rready        )
 
    ); 


    // this is a new ip (now it's supported only on HPC profile) 
    xlnx_axi_dwidth_from512_converter_vx axi_dwidth_from512_conv_u (
        .s_axi_aclk     ( MBUS_clk_i                                    ),
        .s_axi_aresetn  ( MBUS_rstn_i                                   ),

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
        .m_axi_awaddr   ( M_VORTEX_axi_awaddr                           ),
        .m_axi_awlen    ( M_VORTEX_axi_awlen                            ),
        .m_axi_awsize   ( M_VORTEX_axi_awsize                           ),
        .m_axi_awburst  ( M_VORTEX_axi_awburst                          ),
        .m_axi_awlock   ( M_VORTEX_axi_awlock                           ),
        .m_axi_awcache  ( M_VORTEX_axi_awcache                          ),
        .m_axi_awprot   ( M_VORTEX_axi_awprot                           ),
        .m_axi_awregion ( M_VORTEX_axi_awregion                         ),
        .m_axi_awqos    ( M_VORTEX_axi_awqos                            ),
        .m_axi_awvalid  ( M_VORTEX_axi_awvalid                          ),
        .m_axi_awready  ( M_VORTEX_axi_awready                          ),
        .m_axi_wdata    ( M_VORTEX_axi_wdata                            ),
        .m_axi_wstrb    ( M_VORTEX_axi_wstrb                            ),
        .m_axi_wlast    ( M_VORTEX_axi_wlast                            ),
        .m_axi_wvalid   ( M_VORTEX_axi_wvalid                           ),
        .m_axi_wready   ( M_VORTEX_axi_wready                           ),
        .m_axi_bresp    ( M_VORTEX_axi_bresp                            ),
        .m_axi_bvalid   ( M_VORTEX_axi_bvalid                           ),
        .m_axi_bready   ( M_VORTEX_axi_bready                           ),
        .m_axi_araddr   ( M_VORTEX_axi_araddr                           ),
        .m_axi_arlen    ( M_VORTEX_axi_arlen                            ),
        .m_axi_arsize   ( M_VORTEX_axi_arsize                           ),
        .m_axi_arburst  ( M_VORTEX_axi_arburst                          ),
        .m_axi_arlock   ( M_VORTEX_axi_arlock                           ),
        .m_axi_arcache  ( M_VORTEX_axi_arcache                          ),
        .m_axi_arprot   ( M_VORTEX_axi_arprot                           ),
        .m_axi_arregion ( M_VORTEX_axi_arregion                         ),
        .m_axi_arqos    ( M_VORTEX_axi_arqos                            ),
        .m_axi_arvalid  ( M_VORTEX_axi_arvalid                          ),
        .m_axi_arready  ( M_VORTEX_axi_arready                          ),
        .m_axi_rdata    ( M_VORTEX_axi_rdata                            ),
        .m_axi_rresp    ( M_VORTEX_axi_rresp                            ),
        .m_axi_rlast    ( M_VORTEX_axi_rlast                            ),
        .m_axi_rvalid   ( M_VORTEX_axi_rvalid                           ),
        .m_axi_rready   ( M_VORTEX_axi_rready                           )
    );
 
    // Downsizer output has no IDs: single ID towards the MBUS
    // (bid/rid from the MBUS are not needed)
    assign M_VORTEX_axi_awid = '0;
    assign M_VORTEX_axi_arid = '0;
 


endmodule : vortex_wrapper
