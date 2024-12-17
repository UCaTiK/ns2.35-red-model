# Параметры
PARAM_SCRIPT = ./create_parameters.sh
PARAM_DIR = parameters
RESULT_DIR = result
FFT_DIR = 4fft
PROCESSING_DIR = processing
RED_DIR = $(PROCESSING_DIR)/red
PARSED_DIR = parsed
JOBS = 8  # Количество параллельных задач

.PHONY: params ns parse plot default

all: params ns parse plot
	@echo "Done. Check the '$(RESULT_DIR)' and '$(FFT_DIR)' directories for results."

params:
	@bash $(PARAM_SCRIPT)

ns:
	@echo "Running ns for all files in $(PARAM_DIR)..."
	@mkdir -p $(FFT_DIR)
	@counter=0; \
	for file in $(PARAM_DIR)/*; do \
		{ \
			echo "Running ns for $$file..."; \
			filename=$$(basename $$file); \
			ns red.tcl `cat $$file` > $(FFT_DIR)/$$filename; \
		} & \
		counter=$$((counter + 1)); \
		if [ $$counter -ge $(JOBS) ]; then wait; counter=0; fi; \
	done; \
	wait

parse:
	@echo "Running parse for all files in $(RED_DIR)..."
	@counter=0; \
	for file in $(RED_DIR)/*; do \
		{ \
			echo "Running parse for $$file..."; \
			filename=$$(basename $$file .tr); \
			part_name=$$(echo $$filename | sed 's/^red-queue_//') ; \
			./parse $$part_name; \
		} & \
		counter=$$((counter + 1)); \
		if [ $$counter -ge $(JOBS) ]; then wait; counter=0; fi; \
	done; \
	wait

plot:
	@echo "Running plot for all files in $(PARSED_DIR)..."
	@counter=0; \
	for file in $(PARSED_DIR)/inst/*; do \
		{ \
			echo "Running plot_queue and plot_avg_queue for $$file..."; \
			filename=$$(basename $$file .tr); \
			part_name=$$(echo $$filename | sed 's/^queue_inst_//') ; \
			./plot_queue $$part_name; \
			./plot_avg_queue $$part_name; \
		} & \
		counter=$$((counter + 1)); \
		if [ $$counter -ge $(JOBS) ]; then wait; counter=0; fi; \
	done; \
	wait

default:
	@echo "Processing ns without Qmin and Qmax parameters..."
	@mkdir -p $(FFT_DIR)
	ns red.tcl > $(FFT_DIR)/"default"; \
	./parse; \
	./plot_queue; \
	./plot_avg_queue; \

clean:
	@echo "Cleaning up..."
	rm -rf $(RESULT_DIR) $(FFT_DIR) $(PARAM_DIR) $(PROCESSING_DIR) $(PARSED_DIR)
	rm -f out.nam queue.pdf queue_avg.pdf *.tr

