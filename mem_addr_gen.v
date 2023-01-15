module addr_gen_bg(
    input clk,
    input rst,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    output reg [16:0] pixel_addr_bg
);
    always @* begin
        if (0 <= h_cnt && h_cnt < 640 && 0 <= v_cnt && v_cnt < 480) begin
            pixel_addr_bg = (h_cnt >> 1) + 320 * (v_cnt >> 1);
        end else begin
            pixel_addr_bg = 0;
        end
    end

endmodule

module addr_gen_yellow(
    input clk_ke,
    input clk,
    input rst,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    input [2:0] collision_x,
    output reg [16:0] pixel_addr_yellow,
    output [2:0] yellow_x,
    output [9:0] yellow_y,
    output reg [5:0] yellow_score
);
    reg [9:0] position;
    reg [9:0] mask;

    assign yellow_x = 6;
    assign yellow_y = mask;

    always @* begin
        if (yellow_x * 80 <= h_cnt && h_cnt < (yellow_x + 1) * 80 && mask <= v_cnt && v_cnt < mask + 80) begin
            pixel_addr_yellow = (h_cnt + 80 * (v_cnt + position)) % 6400;
        end else begin
            pixel_addr_yellow = 0;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            position <= 0;
            mask <= 0;
            yellow_score <= 0;
        end else begin
            if (yellow_x == collision_x && mask + 80 >= 400) begin
                position <= 0;
                mask <= 0;
                yellow_score <= yellow_score + 1;
            end else begin
                position <= (position > 0) ? position - 1 : 79;
                mask <= (mask < 479) ? mask + 1 : 0;
                yellow_score <= yellow_score;
            end
        end
    end
endmodule

module addr_gen_orange(
    input clk_ke,
    input clk,
    input rst,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    input [2:0] collision_x,
    output reg [16:0] pixel_addr_orange,
    output [2:0] orange_x,
    output [9:0] orange_y,
    output reg [5:0] orange_score
);

    reg [9:0] position;
    reg [9:0] mask;

    wire clk_orange;
    clock_divider #(.n(20)) cd_b(.clk(clk_ke), .clk_div(clk_orange));

    assign orange_x = 3;
    assign orange_y = mask;

    always @* begin
        if (orange_x * 80 <= h_cnt && h_cnt < (orange_x + 1) * 80 && mask <= v_cnt && v_cnt < mask + 80) begin
            pixel_addr_orange = (h_cnt + 80 * (v_cnt + position)) % 6400;
        end else begin
            pixel_addr_orange = 0;
        end
    end

    always @ (posedge clk_orange or posedge rst) begin
        if (rst) begin
            position <= 0;
            mask <= 0;
            orange_score <= 0;
        end else begin
            if (orange_x == collision_x && mask + 80 >= 400) begin
                position <= 0;
                mask <= 0;
                orange_score <= orange_score + 2;
            end else begin
                position <= (position > 0) ? position - 1 : 79;
                mask <= (mask < 479) ? mask + 1 : 0;
                orange_score <= orange_score;
            end
        end
    end
endmodule

module addr_gen_green(
    input clk_ke,
    input clk,
    input rst,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    input [2:0] collision_x,
    output reg [16:0] pixel_addr_green,
    output [2:0] green_x,
    output [9:0] green_y,
    output reg [5:0] green_score
);

    reg [9:0] position;
    reg [9:0] mask;

    wire clk_green;
    clock_divider #(.n(19)) cd_b(.clk(clk_ke), .clk_div(clk_green));

    assign green_x = 1;
    assign green_y = mask;

    always @* begin
        if (green_x * 80 <= h_cnt && h_cnt < (green_x + 1) * 80 && mask <= v_cnt && v_cnt < mask + 80) begin
            pixel_addr_green = (h_cnt + 80 * (v_cnt + position)) % 6400;
        end else begin
            pixel_addr_green = 0;
        end
    end

    always @ (posedge clk_green or posedge rst) begin
        if (rst) begin
            position <= 0;
            mask <= 0;
            green_score <= 0;
        end else begin
            if (green_x == collision_x && mask + 80 >= 400) begin
                position <= 0;
                mask <= 0;
                green_score <= green_score + 3;
            end else begin
                position <= (position > 0) ? position - 1 : 79;
                mask <= (mask < 479) ? mask + 1 : 0;
                green_score <= green_score;
            end
        end
    end
endmodule

module addr_gen_bug(
    input clk_ke,
    input clk,
    input rst,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    input [2:0] collision_x,
    output reg [16:0] pixel_addr_bug,
    output reg [2:0] bug_x,
    output reg [9:0] bug_y,
    output reg [5:0] bug_score
);
    reg [9:0] position;
    
    wire clk_bug;
    clock_divider #(.n(20)) cd_b(.clk(clk_ke), .clk_div(clk_bug));

    wire [2:0] bug_x_next;
    LFSR (.clk(clk_ke), .rst(rst), .random(bug_x_next));

    always @* begin
        if (bug_x * 80 <= h_cnt && h_cnt < (bug_x + 1) * 80 && bug_y <= v_cnt && v_cnt < bug_y + 80) begin
            pixel_addr_bug = (h_cnt + 80 * (v_cnt + position)) % 6400;
        end else begin
            pixel_addr_bug = 0;
        end
    end

    always @ (posedge clk_bug or posedge rst) begin
        if (rst) begin
            position <= 0;
            bug_x <= 0;
            bug_y <= 0;
            bug_score <= 0;
        end else begin
            if (bug_x == collision_x && bug_y + 80 >= 400) begin
                position <= 0;
                bug_x <= bug_x_next;
                bug_y <= 0;
                bug_score <= bug_score + 3;
            end else begin
                position <= (position > 0) ? position - 1 : 79;
                if (bug_y < 476) begin
                    bug_x <= bug_x;
                    bug_y <= bug_y + 1;
                end else begin
                    bug_x <= bug_x_next;
                    bug_y <= 0;
                end
                bug_score <= bug_score;
            end
        end
    end
endmodule

module addr_gen_farmer(
    input clk_ke,
    input clk,
    input rst,
    input [9:0] h_cnt,
    input [9:0] v_cnt,

    input [3:0] key_num,
    input [511:0] key_down,
    input [8:0] last_change,   // last pressing keycode
    input been_ready,

    output reg [16:0] pixel_addr_farmer,
    output reg [2:0] farmer_x
);
    parameter press_left = 4'd2;
    parameter press_right = 4'd3;
    parameter press_invalid = 4'd4;

    reg [2:0] farmer_x_next;

    always @* begin
        if (farmer_x * 80 <= h_cnt && h_cnt < (farmer_x + 1) * 80 && 400 <= v_cnt && v_cnt < 480)
            pixel_addr_farmer = (h_cnt + 80 * (v_cnt - 400));
        else
            pixel_addr_farmer = 0;
    end

    // update key_num to farmer_x
    always @(posedge clk_ke or posedge rst) begin
        if (rst)
            farmer_x <= 2;
        else
            farmer_x <= farmer_x_next;
    end

    always @* begin
        if (been_ready && key_down[last_change] == 1) begin
            if (key_num != press_invalid) begin
                if (key_num == press_left && farmer_x > 0)
                    farmer_x_next = farmer_x - 1;
                else if (key_num == press_right && farmer_x < 7)
                    farmer_x_next = farmer_x + 1;
                else
                    farmer_x_next = farmer_x;
            end else
                farmer_x_next = farmer_x;
        end else
            farmer_x_next = farmer_x;
    end

endmodule

module mem_addr_gen(
    input clk_ke,
    input clk,
    input rst,
    input [9:0] h_cnt,
    input [9:0] v_cnt,

    input [3:0] key_num,
    input [511:0] key_down,
    input [8:0] last_change,   // last pressing keycode
    input been_ready,

    output [16:0] pixel_addr_bg,
    output [16:0] pixel_addr_bug,
    output [16:0] pixel_addr_farmer,
    output [16:0] pixel_addr_green,
    output [16:0] pixel_addr_orange,
    output [16:0] pixel_addr_yellow,

    output [2:0] bug_x,
    output [2:0] farmer_x,
    output [2:0] green_x,
    output [2:0] orange_x,
    output [2:0] yellow_x,

    output [9:0] bug_y,
    output [9:0] farmer_y,
    output [9:0] green_y,
    output [9:0] orange_y,
    output [9:0] yellow_y,

    output [5:0] score_pos,
    output [5:0] score_neg
);

    wire [5:0] bug_score, green_score, orange_score, yellow_score;
    assign score_pos = green_score + orange_score + yellow_score;
    assign score_neg = bug_score;

    addr_gen_bg a0(
        .clk(clk),
        .rst(rst),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr_bg(pixel_addr_bg)
    );

    addr_gen_bug a1(
        .clk_ke(clk_ke),
        .clk(clk),
        .rst(rst),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr_bug(pixel_addr_bug),
        .bug_x(bug_x),
        .bug_y(bug_y),
        .collision_x(farmer_x),
        .bug_score(bug_score)
    );

    addr_gen_farmer a2(
        .clk_ke(clk_ke),
        .clk(clk),
        .rst(rst),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr_farmer(pixel_addr_farmer),
        .farmer_x(farmer_x),

        .key_down(key_down),
        .last_change(last_change),
        .been_ready(been_ready),
        .key_num(key_num)
    );

    addr_gen_green a3(
        .clk_ke(clk_ke),
        .clk(clk),
        .rst(rst),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr_green(pixel_addr_green),
        .green_x(green_x),
        .green_y(green_y),
        .collision_x(farmer_x),
        .green_score(green_score)
    );

    addr_gen_orange a4(
        .clk_ke(clk_ke),
        .clk(clk),
        .rst(rst),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr_orange(pixel_addr_orange),
        .orange_x(orange_x),
        .orange_y(orange_y),
        .collision_x(farmer_x),
        .orange_score(orange_score)
    );

    addr_gen_yellow a5(
        .clk_ke(clk_ke),
        .clk(clk),
        .rst(rst),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr_yellow(pixel_addr_yellow),
        .yellow_x(yellow_x),
        .yellow_y(yellow_y),
        .collision_x(farmer_x),
        .yellow_score(yellow_score)
    );

endmodule