`timescale 1ns/1ps

module cpu_system #(
    parameter INIT_FILE = "program.hex"
) (
    input  wire       clk,
    input  wire       reset,
    output wire [7:0] output_data,
    output wire       output_valid,
    output wire       halted
);
    wire [7:0] memory_address;
    wire [7:0] memory_write_data;
    wire [7:0] memory_read_data;
    wire       memory_write_enable;

    cpu_core processor (
        .clk(clk),
        .reset(reset),
        .mem_address(memory_address),
        .mem_write_data(memory_write_data),
        .mem_write_enable(memory_write_enable),
        .mem_read_data(memory_read_data),
        .output_data(output_data),
        .output_valid(output_valid),
        .halted(halted)
    );

    unified_memory #(
        .INIT_FILE(INIT_FILE)
    ) shared_memory (
        .clk(clk),
        .address(memory_address),
        .write_data(memory_write_data),
        .write_enable(memory_write_enable),
        .read_data(memory_read_data)
    );
endmodule
