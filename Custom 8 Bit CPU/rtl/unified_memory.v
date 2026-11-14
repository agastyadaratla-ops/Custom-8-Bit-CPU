`timescale 1ns/1ps

module unified_memory #(
    parameter INIT_FILE = ""
) (
    input  wire       clk,
    input  wire [7:0] address,
    input  wire [7:0] write_data,
    input  wire       write_enable,
    output wire [7:0] read_data
);
    reg [7:0] memory [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 8'h00;

        if (INIT_FILE != "")
            $readmemh(INIT_FILE, memory);
    end

    // Asynchronous read, synchronous write.
    assign read_data = memory[address];

    always @(posedge clk) begin
        if (write_enable)
            memory[address] <= write_data;
    end
endmodule
