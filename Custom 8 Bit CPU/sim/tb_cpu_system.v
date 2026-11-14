`timescale 1ns/1ps

module tb_cpu_system;
    reg clk = 1'b0;
    reg reset = 1'b1;
    wire [7:0] output_data;
    wire output_valid;
    wire halted;

    always #5 clk = ~clk;

    cpu_system #(
        .INIT_FILE("program.hex")
    ) dut (
        .clk(clk),
        .reset(reset),
        .output_data(output_data),
        .output_valid(output_valid),
        .halted(halted)
    );

    initial begin
        $display("Starting 8-bit CPU simulation...");
        repeat (2) @(posedge clk);
        reset = 1'b0;

        repeat (100) begin
            @(posedge clk);
            if (output_valid)
                $display("CPU OUTPUT: %0d (0x%02h)", output_data, output_data);
            if (halted) begin
                $display("CPU halted.");
                $finish;
            end
        end

        $display("ERROR: timeout waiting for HLT.");
        $finish;
    end
endmodule
