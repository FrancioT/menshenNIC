# MENSHEN
[ -d "menshen" ] && rm -rf "menshen"
[ -d "rmtv2" ] && rm -rf "rmtv2"
git clone https://github.com/multitenancy-project/menshen.git
mv menshen/lib_rmt/rmtv2/ rmtv2
mv menshen/lib_rmt/netfpga_fifo/fallthrough_small_fifo_v1_0_0/hdl/fallthrough_small_fifo.v rmtv2/
mv menshen/lib_rmt/netfpga_fifo/fallthrough_small_fifo_v1_0_0/hdl/small_fifo.v rmtv2/
rm rmtv2/rmt_wrapper.v
cp patch_files/rmt_wrapper.sv rmtv2/rmt_wrapper.sv
rm -rf menshen
mv rmtv2 menshen
cp patch_files/opennic_integration.tcl menshen/tcl/
cp tbs/tb_rmt_wrapper_calc.sv menshen/tb/
cp tbs/tb_rmt_wrapper_drop.sv menshen/tb/
cp tbs/tb_rmt_wrapper_if_else.sv menshen/tb/
cp tbs/tb_rmt_wrapper_modules.sv menshen/tb/
cp tbs/tb_rmt_wrapper_stages.sv menshen/tb/

# ON SHELL
[ -d "open-nic-shell" ] && rm -rf "open-nic-shell"
git clone https://github.com/Xilinx/open-nic-shell.git
patch open-nic-shell/script/build.tcl < patch_files/build.patch
patch open-nic-shell/src/open_nic_shell.sv < patch_files/open_nic_shell.patch
patch open-nic-shell/src/open_nic_shell_macros.vh < patch_files/open_nic_shell_macros.patch
filter_flag="rx_filter"
if [[ "$1" == "$filter_flag" ]];
then
        patch open-nic-shell/src/qdma_subsystem/qdma_subsystem.sv < patch_files/qdma_subsystem.patch
        patch open-nic-shell/src/qdma_subsystem/qdma_subsystem_function.sv < patch_files/qdma_subsystem_function.patch
        patch src/p2p_250mhz.sv < patch_files/p2p_250mhz.patch
fi
realpath open-nic-tbs
# ABS PATH PATCHES
OS_TYPE=$(uname)
case "$OS_TYPE" in
    Linux*)
        echo "Running on Linux"
        VAR=$(realpath open-nic-tbs)
		sed -i "s|{{VAR}}|${VAR}|g" "open-nic-shell/script/build.tcl"
		VAR=$(realpath .)
		sed -i "s|{{VAR}}|${VAR}|g" "menshen/tcl/opennic_integration.tcl"
        ;;

    Darwin*)
        echo "Running on macOS"
        VAR=$(realpath open-nic-tbs)
		sed -i "" "s|{{VAR}}|${VAR}|g" "open-nic-shell/script/build.tcl"
		VAR=$(realpath .)
		sed -i "" "s|{{VAR}}|${VAR}|g" "menshen/tcl/opennic_integration.tcl"
        ;;

    *)
        echo "Unknown operating system: $OS_TYPE"
        exit 1
        ;;
esac

echo "successful project gen"
