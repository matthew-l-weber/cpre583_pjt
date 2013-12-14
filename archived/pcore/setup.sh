######################################################################
# Joseph Zambreno
# setup.sh - shell configuration for Modelsim/Xilinx/Altera labs
######################################################################

SDIR=`dirname "$BASH_SOURCE"`
CDIR=`readlink -f "$SDIR"`

export XLNX_VER=14.6
#export XLNX_VER=13.4
#export XLNX_VER=12.4
export ALTR_VER=11.0
export ARCH_VER=64
export VSIM_VER=10.1c
#export VSIM_VER=6.5c

printf "Setting up environment variables for %s-bit Xilinx tools, version %s..." $ARCH_VER $XLNX_VER 
source /remote/Xilinx/$XLNX_VER/settings$ARCH_VER.sh
printf "done.\n"

printf "Setting up path for %s-bit Modelsim tools, version %s..." $ARCH_VER $VSIM_VER
export PATH=$PATH:/remote/Modelsim/$VSIM_VER/modeltech/linux_x86_64/
printf "done.\n"

printf "Setting up environment variables for %s-bit Altera tools, version %s..." $ARCH_VER $ALTR_VER 
export PATH=$PATH:/remote/Altera/$ALTR_VER/quartus/bin
#export SOPC_KIT_NIOS2=/remote/Altera/$ALTR_VER/nios2eds
#export QUARTUS_ROOTDIR=/remote/Altera/$ALTR_VER/quartus
#export SOPC_BUILDER_PATH_81=/remote/Altera/$ALTR_VER/nios2eds+$SOPC_BUILDER_PATH_81
#unset GCC_EXEC_PREFIX
printf "done.\n"

printf "Setting up license file..."
export LM_LICENSE_FILE=2201@mitch.ece.iastate.edu:1717@io.ece.iastate.edu:27006@io.ece.iastate.edu
printf "done.\n"

