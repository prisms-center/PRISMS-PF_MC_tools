# Makefile for installing only the mcpf dispatcher script

INSTALL_DIR := $(HOME)/.local/bin
SCRIPT_NAME := mcpf

.PHONY: install uninstall

install:
	@mkdir -p $(INSTALL_DIR)
	@ln -sf $(CURDIR)/$(SCRIPT_NAME) $(INSTALL_DIR)/$(SCRIPT_NAME)
	@echo "✅ Installed '$(SCRIPT_NAME)' to $(INSTALL_DIR)"

uninstall:
	@rm -f $(INSTALL_DIR)/$(SCRIPT_NAME)
	@echo "🗑️  Uninstalled '$(SCRIPT_NAME)' from $(INSTALL_DIR)"


