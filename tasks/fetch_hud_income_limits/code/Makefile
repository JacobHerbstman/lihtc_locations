include ../../shared/code/shell_functions.make
.DEFAULT_GOAL := all
all: ../../../data_raw/hud_income_limits/2024/MTSP-Data-FY24.xlsx
include ../../shared/code/generic.make

../../../data_raw/hud_income_limits/2024/MTSP-Data-FY24.xlsx: | download_limits.R ../temp ../report
	$(R) download_limits.R
