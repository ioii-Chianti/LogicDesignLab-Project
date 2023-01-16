module clock_divider #(parameter n = 25) (
    input clk,
    output clk_div
);
    reg [n-1:0] cnt = 0;
    wire [n-1:0] cnt_next;

    always @(posedge clk)
        cnt <= cnt_next;

    assign cnt_next = cnt + 1;
    assign clk_div = cnt[n-1];
endmodule


module debounce (
    input clk,
    input pb,
    output pb_debounced
);
    reg [3:0] shift;
    always @(posedge clk) begin
        shift[3:1] <= shift[2:0];
        shift[0] <= pb;
    end

    assign pb_debounced = (shift == 4'b1111) ? 1'b1 : 1'b0;
endmodule


module onepulse (
    input clk,
    input pb_debounced,
    output reg pb_1pulse
);
    reg pb_debounced_delay;

    always @(posedge clk) begin
        if (pb_debounced == 1'b1 & pb_debounced_delay == 1'b0)
            pb_1pulse <= 1'b1;
        else
            pb_1pulse <= 1'b0;
        pb_debounced_delay <= pb_debounced;
    end
endmodule


module KeyboardDecoder (
	output reg [511:0] key_down,
	output wire [8:0] last_change,
	output reg key_valid,
	inout wire PS2_DATA,
	inout wire PS2_CLK,
	input wire rst,
	input wire clk
);
    parameter [1:0] INIT			= 2'b00;
    parameter [1:0] WAIT_FOR_SIGNAL = 2'b01;
    parameter [1:0] GET_SIGNAL_DOWN = 2'b10;
    parameter [1:0] WAIT_RELEASE    = 2'b11;
    
	parameter [7:0] IS_INIT			= 8'hAA;
    parameter [7:0] IS_EXTEND		= 8'hE0;
    parameter [7:0] IS_BREAK		= 8'hF0;
    
    reg [9:0] key;		// key = {been_extend, been_break, key_in}
    reg [1:0] state;
    reg been_ready, been_extend, been_break;
    
    wire [7:0] key_in;
    wire is_extend;
    wire is_break;
    wire valid;
    wire err;
    
    wire [511:0] key_decode = 1 << last_change;
    assign last_change = {key[9], key[7:0]};
    
    KeyboardCtrl_0 inst (
		.key_in(key_in),
		.is_extend(is_extend),
		.is_break(is_break),
		.valid(valid),
		.err(err),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk)
	);

	onepulse op (
		.pb_1pulse(pulse_been_ready),
		.pb_debounced(been_ready),
		.clk(clk)
	);
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		state <= INIT;
    		been_ready  <= 1'b0;
    		been_extend <= 1'b0;
    		been_break  <= 1'b0;
    		key <= 10'b0_0_0000_0000;
    	end else begin
    		state <= state;
			been_ready  <= been_ready;
			been_extend <= (is_extend) ? 1'b1 : been_extend;
			been_break  <= (is_break ) ? 1'b1 : been_break;
			key <= key;
    		case (state)
    			INIT : begin
    					if (key_in == IS_INIT) begin
    						state <= WAIT_FOR_SIGNAL;
    						been_ready  <= 1'b0;
							been_extend <= 1'b0;
							been_break  <= 1'b0;
							key <= 10'b0_0_0000_0000;
    					end else begin
    						state <= INIT;
    					end
    				end
    			WAIT_FOR_SIGNAL : begin
    					if (valid == 0) begin
    						state <= WAIT_FOR_SIGNAL;
    						been_ready <= 1'b0;
    					end else begin
    						state <= GET_SIGNAL_DOWN;
    					end
    				end
    			GET_SIGNAL_DOWN : begin
						state <= WAIT_RELEASE;
						key <= {been_extend, been_break, key_in};
						been_ready  <= 1'b1;
    				end
    			WAIT_RELEASE : begin
    					if (valid == 1) begin
    						state <= WAIT_RELEASE;
    					end else begin
    						state <= WAIT_FOR_SIGNAL;
    						been_extend <= 1'b0;
    						been_break  <= 1'b0;
    					end
    				end
    			default : begin
    					state <= INIT;
						been_ready  <= 1'b0;
						been_extend <= 1'b0;
						been_break  <= 1'b0;
						key <= 10'b0_0_0000_0000;
    				end
    		endcase
    	end
    end
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		key_valid <= 1'b0;
    		key_down <= 511'b0;
    	end else if (key_decode[last_change] && pulse_been_ready) begin
    		key_valid <= 1'b1;
    		if (key[8] == 0) begin
    			key_down <= key_down | key_decode;
    		end else begin
    			key_down <= key_down & (~key_decode);
    		end
    	end else begin
    		key_valid <= 1'b0;
			key_down <= key_down;
    	end
    end

endmodule


`timescale 1ns/1ps

module vga_controller (
    input wire pclk, reset,
    output wire hsync, vsync, valid,
    output wire [9:0]h_cnt,
    output wire [9:0]v_cnt
    );

    reg [9:0]pixel_cnt;
    reg [9:0]line_cnt;
    reg hsync_i,vsync_i;

    parameter HD = 640;
    parameter HF = 16;
    parameter HS = 96;
    parameter HB = 48;
    parameter HT = 800; 
    parameter VD = 480;
    parameter VF = 10;
    parameter VS = 2;
    parameter VB = 33;
    parameter VT = 525;
    parameter hsync_default = 1'b1;
    parameter vsync_default = 1'b1;

    always @(posedge pclk)
        if (reset)
            pixel_cnt <= 0;
        else
            if (pixel_cnt < (HT - 1))
                pixel_cnt <= pixel_cnt + 1;
            else
                pixel_cnt <= 0;

    always @(posedge pclk)
        if (reset)
            hsync_i <= hsync_default;
        else
            if ((pixel_cnt >= (HD + HF - 1)) && (pixel_cnt < (HD + HF + HS - 1)))
                hsync_i <= ~hsync_default;
            else
                hsync_i <= hsync_default; 

    always @(posedge pclk)
        if (reset)
            line_cnt <= 0;
        else
            if (pixel_cnt == (HT -1))
                if (line_cnt < (VT - 1))
                    line_cnt <= line_cnt + 1;
                else
                    line_cnt <= 0;

    always @(posedge pclk)
        if (reset)
            vsync_i <= vsync_default; 
        else if ((line_cnt >= (VD + VF - 1)) && (line_cnt < (VD + VF + VS - 1)))
            vsync_i <= ~vsync_default; 
        else
            vsync_i <= vsync_default; 

    assign hsync = hsync_i;
    assign vsync = vsync_i;
    assign valid = ((pixel_cnt < HD) && (line_cnt < VD));

    assign h_cnt = (pixel_cnt < HD) ? pixel_cnt : 10'd0;
    assign v_cnt = (line_cnt < VD) ? line_cnt : 10'd0;

endmodule


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


module main (
    input clk,
    input rst,
    input start,

    inout PS2_DATA,
    inout PS2_CLK,

    output reg [3:0] vgaRed,
    output reg [3:0] vgaGreen,
    output reg [3:0] vgaBlue,
    output hsync,
    output vsync,

    output reg [15:0] LED,
    output reg [3:0] DIGIT,
    output reg [6:0] DISPLAY
);

    // 1. preprocess pushbuttons
    wire db_start, _start;
    debounce d2(.clk(clk), .pb(start), .pb_debounced(db_start));
    onepulse o2(.clk(clk), .pb_debounced(db_start), .pb_1pulse(_start));

    // 2. States and next signals
    parameter Init = 2'd0;
    parameter Game = 2'd1;
    parameter Win = 2'd2;
    parameter Lose = 2'd3;
    reg [1:0] state, state_next;
    reg [5:0] score, score_next;   // display on 7-segment
    wire [5:0] score_pos, score_neg;   // collecting score from fruits
    // corresponding behaviors for key_num 
    parameter press_left = 4'd2;
    parameter press_right = 4'd3;
    parameter press_invalid = 4'd4;

    // 3. clocks
    wire clk_7segment, clk_2, clk_21, clk_led;
    clock_divider #(.n(14)) cd0 (.clk(clk), .clk_div(clk_7segment));
    clock_divider #(.n(2))  cd1 (.clk(clk), .clk_div(clk_2));   // memory used
    clock_divider #(.n(21)) cd2 (.clk(clk), .clk_div(clk_21));  // update fruits_y
    clock_divider #(.n(24)) cd3 (.clk(clk), .clk_div(clk_led));

    // 4. keyoard signals
    reg [3:0] key_num;  // trans keycode (last_change) to corresponding decimal
    wire [511:0] key_down;
    wire [8:0] last_change;   // last pressing keycode
    wire been_ready;

    parameter [8:0] key_code [0:1] = {
		9'b0_0001_1100,   // A -> 1C; left
		9'b0_0010_0011    // D -> 23; right
    };

    always @* begin
        case (last_change)
            key_code[0]: key_num = press_left;
            key_code[1]: key_num = press_right;
            default    : key_num = press_invalid;
        endcase
    end

    KeyboardDecoder key_de(
        .key_down(key_down),
		.last_change(last_change),
		.key_valid(been_ready),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk)
    );

    // 5. vga signals
    wire [16:0] pixel_addr_bg;
    wire [16:0] pixel_addr_bug;
    wire [16:0] pixel_addr_farmer;
    wire [16:0] pixel_addr_green;
    wire [16:0] pixel_addr_orange;
    wire [16:0] pixel_addr_yellow;

    wire [11:0] pixel_bg;
    wire [11:0] pixel_bug;
    wire [11:0] pixel_farmer;
    wire [11:0] pixel_green;
    wire [11:0] pixel_orange;
    wire [11:0] pixel_yellow;

    wire [2:0] bug_x, farmer_x, green_x, orange_x, yellow_x;
    wire [9:0] bug_y, green_y, orange_y, yellow_y;

    wire valid;
    wire [11:0] data;
    wire [9:0] h_cnt, v_cnt;

    // display Game
    always @* begin
        case (state)
            Init: begin
                {vgaRed, vgaGreen, vgaBlue} = pixel_bg;
            end
            Game: begin
                if (farmer_x * 80 <= h_cnt && h_cnt < (farmer_x + 1) * 80 && 400 <= v_cnt && v_cnt < 480)
                    {vgaRed, vgaGreen, vgaBlue} = pixel_farmer;
                else if (bug_x * 80 <= h_cnt && h_cnt < (bug_x + 1) * 80 && bug_y <= v_cnt && v_cnt < bug_y + 80)
                    {vgaRed, vgaGreen, vgaBlue} = pixel_bug;
                else if (green_x * 80 <= h_cnt && h_cnt < (green_x + 1) * 80 && green_y <= v_cnt && v_cnt < green_y + 80)
                    {vgaRed, vgaGreen, vgaBlue} = pixel_green;
                else if (orange_x * 80 <= h_cnt && h_cnt < (orange_x + 1) * 80 && orange_y <= v_cnt && v_cnt < orange_y + 80)
                    {vgaRed, vgaGreen, vgaBlue} = pixel_orange;
                else if (yellow_x * 80 <= h_cnt && h_cnt < (yellow_x + 1) * 80 && yellow_y <= v_cnt && v_cnt < yellow_y + 80)
                    {vgaRed, vgaGreen, vgaBlue} = pixel_yellow;
                else if (0 <= h_cnt && h_cnt < 640 && 0 <= v_cnt && v_cnt < 480)
                    {vgaRed, vgaGreen, vgaBlue} = {12{1'b0}};
            end
            Win: begin
                {vgaRed, vgaGreen, vgaBlue} = pixel_bg;
            end
            Lose: begin
                {vgaRed, vgaGreen, vgaBlue} = pixel_bg;
            end
        endcase
    end

    // 6. memory addr generator & block mem
    mem_addr_gen m(
        .clk_100MHz(clk),
        .clk(clk_21),
        .rst(rst),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),

        .pixel_addr_bg(pixel_addr_bg),
        .pixel_addr_bug(pixel_addr_bug),
        .pixel_addr_farmer(pixel_addr_farmer),
        .pixel_addr_green(pixel_addr_green),
        .pixel_addr_orange(pixel_addr_orange),
        .pixel_addr_yellow(pixel_addr_yellow),

        // (x, y) for display images
        .bug_x(bug_x),
        .farmer_x(farmer_x),
        .green_x(green_x),
        .orange_x(orange_x),
        .yellow_x(yellow_x),

        .bug_y(bug_y),
        .green_y(green_y),
        .orange_y(orange_y),
        .yellow_y(yellow_y),

        // key actions for moving farmer
        .key_down(key_down),
        .last_change(last_change),
        .been_ready(been_ready),
        .key_num(key_num),

        // collect all scores for state transition
        .score_pos(score_pos),
        .score_neg(score_neg)
    );

    blk_mem_gen_0 b0(
        .clka(clk_2),
        .wea(0),
        .addra(pixel_addr_bg),
        .dina(data[11:0]),
        .douta(pixel_bg)
    );

    blk_mem_gen_1 b1(
        .clka(clk_2),
        .wea(0),
        .addra(pixel_addr_bug),
        .dina(data[11:0]),
        .douta(pixel_bug)
    );

    blk_mem_gen_2 b2(
        .clka(clk_2),
        .wea(0),
        .addra(pixel_addr_farmer),
        .dina(data[11:0]),
        .douta(pixel_farmer)
    );

    blk_mem_gen_3 b3(
        .clka(clk_2),
        .wea(0),
        .addra(pixel_addr_green),
        .dina(data[11:0]),
        .douta(pixel_green)
    );

    blk_mem_gen_4 b4(
        .clka(clk_2),
        .wea(0),
        .addra(pixel_addr_orange),
        .dina(data[11:0]),
        .douta(pixel_orange)
    );

    blk_mem_gen_5 b5(
        .clka(clk_2),
        .wea(0),
        .addra(pixel_addr_yellow),
        .dina(data[11:0]),
        .douta(pixel_yellow)
    );

    vga_controller v(
        .pclk(clk_2),
        .reset(_rst),
        .hsync(hsync),
        .vsync(vsync),
        .valid(valid),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt)
    );

    // 7. Update states and score
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= Init;
            score <= 0;
        end else begin
            state <= state_next;
            score <= score_next;
        end
    end

    // 8. Update next states and score
    always @* begin
        case (state)
            Init: begin
                state_next = _start ? Game : Init;
                score_next = 0;
            end
            Game: begin
                if (score_pos - score_neg >= 30) begin
                    score_next = 0;
                    state_next = Win;
                end else if (score_pos - score_neg < 0) begin
                    score_next = 0;
                    state_next = Lose;
                end else begin
                    score_next = score_pos - score_neg;
                    state_next = Game;
                end
            end
            Win: begin
                score_next = 0;
                state_next = _start ? Init : Win;
            end
            Lose: begin
                score_next = 0;
                state_next = _start ? Init : Lose;
            end
        endcase
    end

    // 9. set LED
    always @(posedge clk_led) begin
        case (state)
            Init: LED <=  {16{1'b0}};
            Game: LED <= (LED == {16{1'b0}}) ? 16'b0101_0101_0101_0101 : ~LED;
            Win:  LED <= {{8{1'b1}}, {8{1'b0}}};
            Lose: LED <= {{8{1'b0}}, {8{1'b1}}};
        endcase
    end

    // 10. 7-segment
    reg [3:0] display;
    reg [3:0] digit_0, digit_1, digit_2, digit_3;

    always @* begin
        case (state)
            Init: begin   // ----
                digit_0 = 10;
                digit_1 = 10;
                digit_2 = 10;
                digit_3 = 10;
            end
            Game: begin   // score
                digit_0 = score % 10;
                digit_1 = score / 10;
                digit_2 = 15;
                digit_3 = 15;
            end
            Win: begin    // End
                digit_0 = 13;
                digit_1 = 12;
                digit_2 = 11;
                digit_3 = 15;
            end
            Lose: begin   // End
                digit_0 = 13;
                digit_1 = 12;
                digit_2 = 11;
                digit_3 = 15;
            end
        endcase
    end

    always @(posedge clk_7segment) begin
        case (DIGIT)
            4'b1110: begin
                display <= digit_1;
                DIGIT <= 4'b1101;
            end
            4'b1101: begin
                display <= digit_2;
                DIGIT <= 4'b1011;
            end
            4'b1011: begin
                display <= digit_3;
                DIGIT <= 4'b0111;
            end
            4'b0111: begin
                display <= digit_0;
                DIGIT <= 4'b1110;
            end
            default: begin
                display <= digit_0;
                DIGIT <= 4'b1110;
            end
        endcase
    end

    always @* begin
        case (display)
            // 0 ~ 9
            4'd0: DISPLAY = 7'b100_0000;
            4'd1: DISPLAY = 7'b111_1001;
            4'd2: DISPLAY = 7'b010_0100;
            4'd3: DISPLAY = 7'b011_0000;
            4'd4: DISPLAY = 7'b001_1001;
            4'd5: DISPLAY = 7'b001_0010;
            4'd6: DISPLAY = 7'b000_0010;
            4'd7: DISPLAY = 7'b111_1000;
            4'd8: DISPLAY = 7'b000_0000;
            4'd9: DISPLAY = 7'b001_0000;
            4'd10: DISPLAY = 7'b011_1111; // dash
            4'd11: DISPLAY = 7'b000_0110; // E
            4'd12: DISPLAY = 7'b010_1011; // n
            4'd13: DISPLAY = 7'b010_0001; // d
            default: DISPLAY = 7'b111_1111;
        endcase
    end
    
endmodule