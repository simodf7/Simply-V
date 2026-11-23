#!/bin/bash
# Author: Simone Di Fraia <sim.difraia@studenti.unina.it>
# Description:
# This script

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
IP_NAME=$( basename $(dirname $( realpath ${BASH_SOURCE[0]} ) ))

# Create rtl dir
IP_DIR=$(pwd -P)
RTL_DIR=${IP_DIR}/rtl
mkdir -p ${RTL_DIR} 

# Create tcl dir 
TCL_DIR=${RTL_DIR}/tcl 
mkdir -p ${TCL_DIR}

# Create tool dir
VX_TOOLDIR=${RTL_DIR}/tools
mkdir -p ${VX_TOOLDIR}

PRJ_DIR=vx_subsys_prj

printf "${YELLOW}IP_DIR: ${IP_DIR}${NC}\n"
printf "${YELLOW}TCL_DIR: ${TCL_DIR}${NC}\n"
printf "${YELLOW}RTL_DIR: ${RTL_DIR}${NC}\n"
printf "${YELLOW}PRJ_DIR: ${PRJ_DIR}${NC}\n"


# Check dependecies 
. /etc/os-release
printf "${YELLOW}[FETCH_SOURCES $IP_NAME] Detected ${PRETTY_NAME}${NC}\n"

missing=0 

# Required packages
for pkg in python3 libstdc++6; do
    printf "${YELLOW}[FETCH_SOURCES $IP_NAME] Checking $pkg:"
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed" ; then 
      printf "${GREEN}Found${NC}\n" 
    else 
      printf "${RED}Missing: (sudo apt install $pkg)${NC}\n"; missing=1;
    fi 
done

[ $missing -eq 0 ] || { printf "${RED}[FETCH_SOURCES $IP_NAME] Failed - Missing dependencies${NC}\n";  exit 1; }


# Clone Vortex Repo (branch for Simply-V)  
GIT_URL=https://github.com/simodf7/vortex.git
#GIT_URL=file:///home/simo/tesi/vortex
GIT_BRANCH=simply-v
CLONE_DIR=${RTL_DIR}/vortex
BOARD_DIR=hw/syn/xilinx/zcu102


cd ${RTL_DIR}; 
printf "${YELLOW}[FETCH_SOURCES $IP_NAME] Cloning source repository${NC}\n"
git clone ${GIT_URL} -b ${GIT_BRANCH} --depth 1 ${CLONE_DIR}
cd ${CLONE_DIR};

mkdir build 
cd build
../configure --xlen=64 --tooldir=${VX_TOOLDIR}
./ci/toolchain_install.sh --verilator 
source ./ci/toolchain_env.sh 

# This copies all rtl files and rtl list (define and include) in rtl/sources.txt 
make -C ${BOARD_DIR} gen-sources \
      CONFIG_JSON=${IP_DIR}/assets/simplyv.json \
      GEN_SRC_DIR=${RTL_DIR}/src \
      GEN_SRC_LIST=${RTL_DIR}/sources.txt 


# Copying all the necessary files into RTL dir
cd ${IP_DIR}; 
cp -r ${CLONE_DIR}/${BOARD_DIR}/ip_repo/ ${RTL_DIR}/
cp ${CLONE_DIR}/${BOARD_DIR}/tcl/vortex_subsystem_bd.tcl ${TCL_DIR} 
cp ${CLONE_DIR}/${BOARD_DIR}/tcl/import_ip.tcl ${TCL_DIR} 
cp ${CLONE_DIR}/hw/scripts/parse_vcs_list.tcl ${TCL_DIR}
cp ${CLONE_DIR}/hw/scripts/xilinx_ip_gen.tcl ${TCL_DIR}
cp ${CLONE_DIR}/hw/scripts/xilinx_async_bram_patch.tcl ${RTL_DIR}
cp assets/vortex_post_synth.tcl ${RTL_DIR}

cd ${RTL_DIR};

CONFIG_FILE=${XILINX_ROOT}/make/config.mk
export MBUS_ID_WIDTH=$(grep -E '^MBUS_ID_WIDTH' ${CONFIG_FILE} | awk '{print $NF}')
export MAIN_CLOCK_FREQ_MHZ=$(grep -E '^MAIN_CLOCK_FREQ_MHZ' ${CONFIG_FILE} | awk '{print $NF}')
vivado -mode batch -source ${IP_DIR}/assets/build_vortex_subsys.tcl 

cd ${IP_DIR}; 
# Clean 
rm -rf ${TCL_DIR} 
rm -rf ${CLONE_DIR}
rm -rf ${RTL_DIR}/${PRJ_DIR}
rm -rf ${VX_TOOLDIR} 
rm -rf ${RTL_DIR}/vivado*.log ${RTL_DIR}/vivado*.jou ${RTL_DIR}/.Xil

# Info
printf "${GREEN}[FETCH_SOURCES $IP_NAME] Completed${NC}\n"
