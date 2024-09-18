# Menshen port on the OpenNIC platform
This projects consists in the parameterization of the [Menshen](https://github.com/multitenancy-project/menshen) pipeline, an hardware library for an High-Speed Programmable Packet-Processing Pipeline, and the integration of multiple instances of different lenght (number of stages) in an AMD's [OpenNIC](https://github.com/Xilinx/open-nic-shell) platform, which is an open-source FPGA-based NIC.

You can read Menshen's paper and learn about the project [here](https://www.usenix.org/system/files/nsdi22-paper-wang_tao.pdf).

The integration consists in the development of an OpenNIC 250MHz user plugin box (see OpenNIC's architecture) that wraps Menshen's pipeline inside. The project also comes with the testbenches to verify that all of the pipeline features properly work.
## Directory structure
 ```sh
menshen-open-nic/
├── src/                        # OpenNIC user plugin template, accordingly patched for 
│                               # the architecture of Menshen
├── p4s/                        # Source files for our tests, written in the P4 language
├── tbs/                        # Unit tests for Menshen by itself
├── patch_files/                # diff patches for modifying the OpenNIC environment and the 
│                               # Xilinx cam IPs
├── open-nic-tbs/               # Tests the complete component
└── menshen-open-nic.sh         # Script for project generation
```
## Building
The build process consists on running a script that will clone the OpenNIC and Menshen repositories and patch the files necessary for building and testing the component on the OpenNIC platform.
1. Clone the repo and enter the folder you just cloned
   ```sh
   git clone https://github.com/FrancioT/menshenNIC.git && cd menshen-open-nic
   ```
2. We used [Xilinx Application 1151 CAM](https://www.xilinx.com/member/forms/download/design-license.html?cid=154257&filename=xapp1151_Param_CAM.zip). 
   After downloading it and placing it in the "menshen-open-nic/" folder, run the following commands:
   ```sh
   unzip xapp1151_Param_CAM.zip
   cp -r xapp1151_cam_v1_1/src/vhdl ./xilinx_cam
   patch -p0 --ignore-whitespace -i patch_files/cam.patch
   ```
3. Give to the script the necessary permissions
   ```sh
   chmod +x menshen-open-nic.sh
   ```
4. Run the script
   ```sh
   ./menshen-open-nic.sh
   ```
5. In order to include the component inside OpenNIC you will need to build with this command, using Vivado 2022.1
   ```sh
   cd path/to/menshen-open-nic/open-nic-shell/script
   vivado -mode tcl -source build.tcl -tclargs -board au55c -num_cmac_port 2 -num_phys_func 2 -user_plugin ../../src
   ```
## Sidenotes
The port has only been built and tested on an Alveo U55C board, therefore support on other Alveo boards isn't guaranteed.

In order to replicate the results obtained in this repository, use the same menshen and open-nic versions:
- for menshen checkout at the commit *fc968bf28626c8f8a610592749a8b2542f0c1f0f*
- for open-nic checkout at the commit *80777515c83cc04d8497522669aa82dd914d1e08*
