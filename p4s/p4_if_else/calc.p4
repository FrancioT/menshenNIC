#include <core.p4>
#include <fpga.p4>

/*
 * Define the headers the program will recognize
 */

/*
 * Standard ethernet header 
 */
header ethernet_t {
        bit<48> eth_dst_addr;
        bit<48> eth_src_addr;
        bit<16> eth_ethertype;
}

header vlan_t {
        bit<16> vlan_id;
        bit<16> vlan_ethertype;
}

header ipv4_t {
        bit<4>  version;
        bit<4>  ihl;
        bit<8>  diffserv;
        bit<16> total_len;
        bit<16> identification;
        bit<3>  flags;
        bit<13> frag_offset;
        bit<8>  ttl;
        bit<8>  protocol;
        bit<16> ip_checksum;
        bit<32> ip_src_addr;
        bit<32> ip_dst_addr;
}

header udp_t {
        bit<16> udp_src_port;
        bit<16> udp_dst_port;
        bit<16> hdr_length;
        bit<16> udp_checksum;
}

header p4calc_t {
        bit<16> op;
        bit<32> operand_a;
        bit<32> operand_b;
        bit<32> res;
}

/*
 * All headers, used in the program needs to be assembed into a single struct.
 * We only need to declare the type, but there is no need to instantiate it,
 * because it is done "by the architecture", i.e. outside of P4 functions
 */
struct headers {
        ethernet_t      ethernet;
        vlan_t          vlan;
        ipv4_t          ipv4;
        udp_t           udp;
        p4calc_t        p4calc;
}

/*
 * All metadata, globally used in the program, also  needs to be assembed 
 * into a single struct. As in the case of the headers, we only need to 
 * declare the type, but there is no need to instantiate it,
 * because it is done "by the architecture", i.e. outside of P4 functions
 */
 
struct metadata {
        bit<128>  nothing;
        bit<1>    discard;
        bit<127>  still_nothing;
}

/*************************************************************************
 ***********************  P A R S E R  ***********************************
 *************************************************************************/
parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

        state start {
                packet.extract(hdr.ethernet);
                transition parse_vlan;
        }

        state parse_vlan {
                packet.extract(hdr.vlan);
                transition parse_ip;
        }

        state parse_ip {
                packet.extract(hdr.ipv4);
                transition parse_udp;
        }

        state parse_udp {
                packet.extract(hdr.udp);
                transition parse_custom;
        }
    
        state parse_custom {
                packet.extract(hdr.p4calc);
                transition accept;
        }
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) { 
    
    /*  METTERE L'IF ELSE ALL'INTERNO DELL'AZIONE NON FUNZIONA! (da errore a compilazione)
    action compute() {
            if(hdr.p4calc.res > 0)
                    if(hdr.p4calc.operand_a > 10)
                            hdr.p4calc.res = 100;
                else
                        hdr.p4calc.res = 50;
            else
                    if(hdr.p4calc.operand_b < 3)
                            hdr.p4calc.res = 101;
                    else
                        hdr.p4calc.res = 51;
    }*/
       
    action compute_1()
    {
            hdr.p4calc.res = 100;
    }
    
    action compute_2()
    {
            hdr.p4calc.res = 101;
    }
    
    action drop_pkt() {
        meta.discard = 1;
    }
    
    table middle_tab_1 {
        key = {
            hdr.p4calc.res        : exact;
        }
        actions = {
            compute_1;
            drop_pkt;
        }
        const default_action = compute_1();
        const entries = {
            0: drop_pkt();
            1: compute_1();
        }
    }
    table middle_tab_2 {
        key = {
            hdr.p4calc.res        : exact;
        }
        actions = {
            compute_2;
            drop_pkt;
        }
        const default_action = compute_2();
        const entries = {
            0: drop_pkt();
            1: compute_2();
        }
    }

    apply {
        if(hdr.p4calc.operand_a == 3)
                middle_tab_1.apply();
        else
                middle_tab_2.apply();
    }
}

/*************************************************************************
 ***********************  S W I T T C H **********************************
 *************************************************************************/

FpgaSwitch(
MyParser(),
MyIngress()
) main;
