module addr_gen_bg(
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    output [16:0] pixel_addr_bg
);
    assign pixel_addr_bg = (h_cnt >> 1) + 320 * (v_cnt >> 1);
endmodule

module addr_gen_yellow(
    input clk_100MHz,
    input clk,
    input rst,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    input [2:0] collision_x,
    output reg [16:0] pixel_addr_yellow,
    output reg [2:0] x,
    output reg [9:0] y,
    output reg [5:0] score
);
    // speed: clock(21), score: +1, initial x: 6

    reg [9:0] position;
    wire [2:0] x_next;
    LFSR (.clk(clk_100MHz), .rst(rst), .random(x_next));

    always @* begin
        if (x * 80 <= h_cnt && h_cnt < (x + 1) * 80 && y <= v_cnt && v_cnt < y + 80)
            pixel_addr_yellow = (h_cnt + 80 * (v_cnt + position)) % 6400;
        else
            pixel_addr_yellow = 0;
        
    end

    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            position <= 0;
            x <= 6;
            y <= 0;
            score <= 0;
        end else begin
            if (x == collision_x && y + 80 >= 400) begin
                position <= 0;
                x <= x_next;
                y <= 0;
                score <= score + 1;
            end else begin
                position <= (position > 0) ? position - 1 : 79;
                if (y < 476) begin
                    x <= x;
                    y <= y + 1;
                end else begin
                    x <= x_next;
                    y <= 0;
                end
                score <= score;
            end
        end
    end
endmodule

module addr_gen_orange(
    input clk_100MHz,
    input clk,
    input rst,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    input [2:0] collision_x,
    output reg [16:0] pixel_addr_orange,
    output reg [2:0] x,
    output reg [9:0] y,
    output reg [5:0] score
);
    // speed: clock(20), score: +2, initial x: 3

    reg [9:0] position;
    wire clk_orange;
    clock_divider #(.n(20)) cd_b(.clk(clk_100MHz), .clk_div(clk_orange));

    wire [2:0] x_next;
    LFSR (.clk(clk_100MHz), .rst(rst), .random(x_next));

    always @* begin
        if (x * 80 <= h_cnt && h_cnt < (x + 1) * 80 && y <= v_cnt && v_cnt < y + 80)
            pixel_addr_orange = (h_cnt + 80 * (v_cnt + position)) % 6400;
        else
            pixel_addr_orange = 0;
        
    end

    always @ (posedge clk_orange or posedge rst) begin
        if (rst) begin
            position <= 0;
            x <= 3;
            y <= 0;
            score <= 0;
        end else begin
            if (x == collision_x && y + 80 >= 400) begin
                position <= 0;
                x <= x_next;
                y <= 0;
                score <= score + 2;
            end else begin
                position <= (position > 0) ? position - 1 : 79;
                if (y < 476) begin
                    x <= x;
                    y <= y + 1;
                end else begin
                    x <= x_next;
                    y <= 0;
                end
                score <= score;
            end
        end
    end
endmodule

module addr_gen_green(
    input clk_100MHz,
    input clk,
    input rst,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    input [2:0] collision_x,
    output reg [16:0] pixel_addr_green,
    output reg [2:0] x,
    output reg [9:0] y,
    output reg [5:0] score
);
    // speed: clock(19), score: +3, initial x: 1

    reg [9:0] position;
    wire clk_green;
    clock_divider #(.n(19)) cd_b(.clk(clk_100MHz), .clk_div(clk_green));

    wire [2:0] x_next;
    LFSR (.clk(clk_100MHz), .rst(rst), .random(x_next));

    always @* begin
        if (x * 80 <= h_cnt && h_cnt < (x + 1) * 80 && y <= v_cnt && v_cnt < y + 80)
            pixel_addr_green = (h_cnt + 80 * (v_cnt + position)) % 6400;
        else
            pixel_addr_green = 0;
        
    end

    always @ (posedge clk_green or posedge rst) begin
        if (rst) begin
            position <= 0;
            x <= 1;
            y <= 0;
            score <= 0;
        end else begin
            if (x == collision_x && y + 80 >= 400) begin
                position <= 0;
                x <= x_next;
                y <= 0;
                score <= score + 3;
            end else begin
                position <= (position > 0) ? position - 1 : 79;
                if (y < 476) begin
                    x <= x;
                    y <= y + 1;
                end else begin
                    x <= x_next;
                    y <= 0;
                end
                score <= score;
            end
        end
    end
endmodule

module addr_gen_bug(
    input clk_100MHz,
    input clk,
    input rst,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    input [2:0] collision_x,
    output reg [16:0] pixel_addr_bug,
    output reg [2:0] x,
    output reg [9:0] y,
    output reg [5:0] score
);
    // speed: clock(20), score: -3, initial x: 0

    reg [9:0] position;
    wire clk_bug;
    clock_divider #(.n(20)) cd_b(.clk(clk_100MHz), .clk_div(clk_bug));

    wire [2:0] x_next;
    LFSR (.clk(clk_100MHz), .rst(rst), .random(x_next));

    always @* begin
        if (x * 80 <= h_cnt && h_cnt < (x + 1) * 80 && y <= v_cnt && v_cnt < y + 80)
            pixel_addr_bug = (h_cnt + 80 * (v_cnt + position)) % 6400;
        else
            pixel_addr_bug = 0;
        
    end

    always @ (posedge clk_bug or posedge rst) begin
        if (rst) begin
            position <= 0;
            x <= 0;
            y <= 0;
            score <= 0;
        end else begin
            if (x == collision_x && y + 80 >= 400) begin
                position <= 0;
                x <= x_next;
                y <= 0;
                score <= score + 3;
            end else begin
                position <= (position > 0) ? position - 1 : 79;
                if (y < 476) begin
                    x <= x;
                    y <= y + 1;
                end else begin
                    x <= x_next;
                    y <= 0;
                end
                score <= score;
            end
        end
    end
endmodule

module addr_gen_farmer(
    input clk_100MHz,
    input clk,
    input rst,
    input [9:0] h_cnt,
    input [9:0] v_cnt,

    input [3:0] key_num,
    input [511:0] key_down,
    input [8:0] last_change,   // last pressing keycode
    input been_ready,

    output reg [16:0] pixel_addr_farmer,
    output reg [2:0] x
);
    parameter press_left = 4'd2;
    parameter press_right = 4'd3;
    parameter press_invalid = 4'd4;

    reg [2:0] x_next;

    always @* begin
        if (x * 80 <= h_cnt && h_cnt < (x + 1) * 80 && 400 <= v_cnt && v_cnt < 480)
            pixel_addr_farmer = (h_cnt + 80 * (v_cnt - 400));
        else
            pixel_addr_farmer = 0;
    end

    // update key_num to x
    always @(posedge clk_100MHz or posedge rst) begin
        if (rst)
            x <= 2;
        else
            x <= x_next;
    end

    always @* begin
        if (been_ready && key_down[last_change] == 1) begin
            if (key_num != press_invalid) begin
                if (key_num == press_left && x > 0)
                    x_next = x - 1;
                else if (key_num == press_right && x < 7)
                    x_next = x + 1;
                else
                    x_next = x;
            end else
                x_next = x;
        end else
            x_next = x;
    end
endmodule

module mem_addr_gen(
    input clk_100MHz,
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
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr_bg(pixel_addr_bg)
    );

    addr_gen_bug a1(
        .clk_100MHz(clk_100MHz),
        .clk(clk),
        .rst(rst),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr_bug(pixel_addr_bug),
        .x(bug_x),
        .y(bug_y),
        .collision_x(farmer_x),
        .score(bug_score)
    );

    addr_gen_farmer a2(
        .clk_100MHz(clk_100MHz),
        .clk(clk),
        .rst(rst),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr_farmer(pixel_addr_farmer),
        .x(farmer_x),

        .key_down(key_down),
        .last_change(last_change),
        .been_ready(been_ready),
        .key_num(key_num)
    );

    addr_gen_green a3(
        .clk_100MHz(clk_100MHz),
        .clk(clk),
        .rst(rst),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr_green(pixel_addr_green),
        .x(green_x),
        .y(green_y),
        .collision_x(farmer_x),
        .score(green_score)
    );

    addr_gen_orange a4(
        .clk_100MHz(clk_100MHz),
        .clk(clk),
        .rst(rst),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr_orange(pixel_addr_orange),
        .x(orange_x),
        .y(orange_y),
        .collision_x(farmer_x),
        .score(orange_score)
    );

    addr_gen_yellow a5(
        .clk_100MHz(clk_100MHz),
        .clk(clk),
        .rst(rst),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr_yellow(pixel_addr_yellow),
        .x(yellow_x),
        .y(yellow_y),
        .collision_x(farmer_x),
        .score(yellow_score)
    );
endmodule