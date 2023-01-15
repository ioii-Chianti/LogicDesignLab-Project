module LFSR (
    input clk,
    input rst,
    output reg [2:0] random
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            random[2:0] <= 3'b101;
        else
            random <= {random[1] ^ random[0], random[2:1]};
    end

endmodule