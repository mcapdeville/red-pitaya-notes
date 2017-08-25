set display_name {sha256 bitcoin miner}

set core [ipx::current_core]

set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core
set_property VENDOR {mcapdeville} $core
set_property VENDOR_DISPLAY_NAME {Marc CAPDEVILLE} $core
set_property COMPANY_URL {https://github.com/mcapdeville/red-pitaya-notes} $core

core_parameter DEPTH {UNROLL DEPTH} {How many to unroll loops as power of 2 (0 to 5)}
