# CXL Trace Collector

This repo is a hardware framework for capturing physical memory access traces from CXL memory device. Built on a commodity FPGA platform acting as a CXL Type-3 memory device, it captures complete memory request streams including timestamps without introducing overhead.

## Architecture

The setup consists of two machines connected to a single FPGA:

1.  **Target Server (Host):** The machine running the workload. It connects to the FPGA via **CXL**.
2.  **Collection Server (Receiver):** A separate machine dedicated to storing the trace data. It connects to the FPGA via a separate PCIe link.

## 📂 Repository Structure

* **`rtl/`**: Hardware design files for the Intel Agilex 7 FPGA.
    * Can be dropped into the Intel Agilex 7 I-Series CXL Type 3 Design Example.
* **`sw/`**: Host-side software and utilities.
    * **`trace_controller`**: Runs on the Target Server to configure the FPGA CSRs via CXL.io.
    * **`trace_receiver`**: Runs on the Collection Server to drain the trace buffer via PCIe.
* **`distributed_collect.py`**: The main orchestration script that automates the tracing process across both machines.

## Usage

The system is controlled entirely from the **Target Server** using the `distributed_collect.py` script. This script starts the remote receiver, configures the FPGA, and launches your specific workload.

### Basic Syntax

```bash
sudo python3 distributed_collect.py [options] -- <target_workload_command>
