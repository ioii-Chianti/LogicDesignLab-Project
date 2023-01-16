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