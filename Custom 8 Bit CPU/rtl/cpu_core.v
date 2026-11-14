`timescale 1ns/1ps

module cpu_core (
    input  wire       clk,
    input  wire       reset,

    // Shared Von Neumann memory interface.
    output reg  [7:0] mem_address,
    output wire [7:0] mem_write_data,
    output wire       mem_write_enable,
    input  wire [7:0] mem_read_data,

    // Simple output port.
    output reg  [7:0] output_data,
    output reg        output_valid,
    output reg        halted
);
    // Instruction opcodes.
    localparam OP_NOP = 8'h00;
    localparam OP_LDI = 8'h10;
    localparam OP_LDA = 8'h11;
    localparam OP_STA = 8'h12;
    localparam OP_ADD = 8'h20;
    localparam OP_SUB = 8'h21;
    localparam OP_AND = 8'h22;
    localparam OP_OR  = 8'h23;
    localparam OP_XOR = 8'h24;
    localparam OP_JMP = 8'h30;
    localparam OP_JZ  = 8'h31;
    localparam OP_JNZ = 8'h32;
    localparam OP_OUT = 8'h40;
    localparam OP_HLT = 8'hFF;

    localparam ALU_ADD = 3'd0;
    localparam ALU_SUB = 3'd1;
    localparam ALU_AND = 3'd2;
    localparam ALU_OR  = 3'd3;
    localparam ALU_XOR = 3'd4;

    localparam STATE_FETCH    = 3'd0;
    localparam STATE_DECODE   = 3'd1;
    localparam STATE_OPERAND  = 3'd2;
    localparam STATE_EXECUTE  = 3'd3;
    localparam STATE_HALTED   = 3'd4;

    reg [2:0] state;
    reg [7:0] pc;
    reg [7:0] instruction_register;
    reg [7:0] operand_register;
    reg [7:0] accumulator;
    reg       zero_flag;

    reg [2:0] alu_operation;
    wire [7:0] alu_result;
    wire       alu_zero;

    assign mem_write_data = accumulator;
    assign mem_write_enable =
        (state == STATE_EXECUTE) && (instruction_register == OP_STA);

    alu arithmetic_unit (
        .a(accumulator),
        .b(mem_read_data),
        .operation(alu_operation),
        .result(alu_result),
        .zero(alu_zero)
    );

    // One shared memory address bus is multiplexed between instruction
    // fetch, operand fetch, and data access.
    always @* begin
        mem_address = pc;

        case (state)
            STATE_EXECUTE: begin
                case (instruction_register)
                    OP_LDA, OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR, OP_STA:
                        mem_address = operand_register;
                    default:
                        mem_address = pc;
                endcase
            end
            default: mem_address = pc;
        endcase
    end

    // Select the ALU operation from the current instruction.
    always @* begin
        case (instruction_register)
            OP_SUB: alu_operation = ALU_SUB;
            OP_AND: alu_operation = ALU_AND;
            OP_OR:  alu_operation = ALU_OR;
            OP_XOR: alu_operation = ALU_XOR;
            default: alu_operation = ALU_ADD;
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state                <= STATE_FETCH;
            pc                   <= 8'h00;
            instruction_register <= OP_NOP;
            operand_register     <= 8'h00;
            accumulator           <= 8'h00;
            zero_flag             <= 1'b1;
            output_data           <= 8'h00;
            output_valid          <= 1'b0;
            halted                <= 1'b0;
        end else begin
            // output_valid is a one-cycle pulse.
            output_valid <= 1'b0;

            case (state)
                STATE_FETCH: begin
                    instruction_register <= mem_read_data;
                    pc <= pc + 8'd1;
                    state <= STATE_DECODE;
                end

                STATE_DECODE: begin
                    case (instruction_register)
                        OP_HLT: begin
                            halted <= 1'b1;
                            state <= STATE_HALTED;
                        end

                        OP_NOP: state <= STATE_FETCH;

                        OP_OUT: begin
                            output_data <= accumulator;
                            output_valid <= 1'b1;
                            state <= STATE_FETCH;
                        end

                        OP_LDI, OP_LDA, OP_STA,
                        OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR,
                        OP_JMP, OP_JZ, OP_JNZ: begin
                            state <= STATE_OPERAND;
                        end

                        default: state <= STATE_FETCH;
                    endcase
                end

                STATE_OPERAND: begin
                    operand_register <= mem_read_data;
                    pc <= pc + 8'd1;
                    state <= STATE_EXECUTE;
                end

                STATE_EXECUTE: begin
                    case (instruction_register)
                        OP_LDI: begin
                            accumulator <= operand_register;
                            zero_flag <= (operand_register == 8'h00);
                        end

                        OP_LDA: begin
                            accumulator <= mem_read_data;
                            zero_flag <= (mem_read_data == 8'h00);
                        end

                        OP_STA: begin
                            // Memory write occurs on this clock edge.
                        end

                        OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR: begin
                            accumulator <= alu_result;
                            zero_flag <= alu_zero;
                        end

                        OP_JMP: pc <= operand_register;
                        OP_JZ:  if (zero_flag)  pc <= operand_register;
                        OP_JNZ: if (!zero_flag) pc <= operand_register;

                        default: begin end
                    endcase
                    state <= STATE_FETCH;
                end

                STATE_HALTED: begin
                    halted <= 1'b1;
                    state <= STATE_HALTED;
                end

                default: state <= STATE_FETCH;
            endcase
        end
    end
endmodule
