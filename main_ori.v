module main(
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

    // parameter Init = 3'b000;
    // parameter Set = 3'b001;
    // parameter Game = 3'b010;
    // parameter Win = 3'd3;
    // parameter Lose = 3'd4;
    parameter Init = 2'b00;
    parameter Set = 2'b01;
    parameter Game = 2'b10;

    parameter press_left = 4'd2;
    parameter press_right = 4'd3;
    parameter press_invalid = 4'd4;

    // h's range for different branches
    // parameter [9:0] branch [0:7] = {10'd0, 10'd80, 10'd160, 10'd240, 10'd320, 10'd400, 10'd480, 10'd560};
    
    // general signals
    reg [1:0] state, state_next;
    reg [6:0] cnt, cnt_next, score, score_next;   // display on 7-segment

    // clock
    wire clk_7segment, clk_2, clk_21, clk_led;
    clock_divider #(.n(14)) cd0(.clk(clk), .clk_div(clk_7seg));
    clock_divider #(.n(2))  cd1(.clk(clk), .clk_div(clk_2));
    clock_divider #(.n(21)) cd2(.clk(clk), .clk_div(clk_21));
    clock_divider #(.n(24)) cd3(.clk(clk), .clk_div(clk_led));

    // pushbuttons
    wire db_rst, _rst;
    debounce d0(.clk(clk), .pb(rst), .pb_debounced(db_rst));
    onepulse o0(.clk(clk), .pb_debounced(db_rst), .pb_1pulse(_rst));
    wire db_start, _start;
    debounce d2(.clk(clk), .pb(start), .pb_debounced(db_start));
    onepulse o2(.clk(clk), .pb_debounced(db_start), .pb_1pulse(_start));

    // keyoard signals
    reg [3:0] key_num;  // trans keycode (last_change) to corresponding decimal
    wire [511:0] key_down;
    wire [8:0] last_change;   // last pressing keycode
    wire been_ready;

    parameter [8:0] key_code [0:1] = {
		9'b0_0001_1100,   // A -> 1C; left
		9'b0_0010_0011    // D -> 23; right
    };

    KeyboardDecoder key_de(
        .key_down(key_down),
		.last_change(last_change),
		.key_valid(been_ready),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(_rst),
		.clk(clk)
    );

    always @* begin
        case (last_change)
            key_code[0]: key_num = press_left;
            key_code[1]: key_num = press_right;
            default    : key_num = press_invalid;
        endcase
    end

        // !!!
    // vga signals
    wire [11:0] data;
    wire [16:0] pixel_addr_bg, pixel_addr_bug, pixel_addr_farmer, pixel_addr_green, pixel_addr_orange, pixel_addr_yellow;
    // wire [13:0] pixel_addr_bug;
    wire [11:0] pixel_bg, pixel_farmer, pixel_bug, pixel_green, pixel_orange, pixel_yellow;
    wire show_bg, show_farmer, show_bug, show_green, show_orange, show_yellow;
    wire valid;
    wire [9:0] h_cnt, v_cnt;

    reg [2:0] farmer_pos;  // 7~0

    always @* begin
        {vgaRed, vgaGreen, vgaBlue} = pixel_bug;
    end

    mem_addr_gen m(
        .clk(clk_21),
        .rst(_rst),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        // .pixel_addr_bg(pixel_addr_bg),
        // .pixel_addr_farmer(pixel_addr_farmer),
        .pixel_addr_bug(pixel_addr_bug),
        // .pixel_addr_green(pixel_addr_green),
        // .pixel_addr_orange(pixel_addr_orange),
        // .pixel_addr_yellow(pixel_addr_yellow),
        // .show_bg(show_bg),
        // .show_farmer(show_farmer),
        .show_bug(show_bug)
        // .show_green(show_green)
        // .show_orange(show_orange),
        // .show_yellow(show_yellow)
    );

    // bg

    // blk_mem_gen_0 b0(
    //     .clka(clk_2),
    //     .wea(0),
    //     .addra(pixel_addr_bg),
    //     .dina(data[11:0]),
    //     .douta(pixel_bg)
    // );


    // blk_mem_gen_1 b1(
    //     .clka(clk_2),
    //     .wea(0),
    //     .addra(pixel_addr_bug),
    //     .dina(data[11:0]),
    //     .douta(pixel_bug)
    // );

    // blk_mem_gen_2 b2(
    //     .clka(clk_2),
    //     .wea(0),
    //     .addra(pixel_addr_farmer),
    //     .dina(data[11:0]),
    //     .douta(pixel_farmer)
    // );


    // blk_mem_gen_3 b3(
    //     .clka(clk_2),
    //     .wea(0),
    //     .addra(pixel_addr_green),
    //     .dina(data[11:0]),
    //     .douta(pixel_green)
    // );


    // blk_mem_gen_4 b4(
    //     .clka(clk_2),
    //     .wea(0),
    //     .addra(pixel_addr_orange),
    //     .dina(data[11:0]),
    //     .douta(pixel_orange)
    // );

    // blk_mem_gen_5 b5(
    //     .clka(clk_2),
    //     .wea(0),
    //     .addra(pixel_addr_yellow),
    //     .dina(data[11:0]),
    //     .douta(pixel_yellow)
    // );

    // vga_controller v(
    //     .pclk(clk_2),
    //     .reset(_rst),
    //     .hsync(hsync),
    //     .vsync(vsync),
    //     .valid(valid),
    //     .h_cnt(h_cnt),
    //     .v_cnt(v_cnt)
    // );

    // state transition
    always @(posedge clk_2 or posedge _rst) begin
        if (_rst) begin
            state <= Init;
        end else begin
            state <= state_next;
        end
    end

    // led
    reg [15:0] LED_next;
    always @(posedge clk_led) begin
        case (state)
            Init: LED <= {16{1'b1}};
            // Set: LED <= (LED == {16{1'b0}}) ? 16'b0101_0101_0101_0101 : ~LED;
            // set farmer pos
            Game: begin
                LED = {16{1'b0}};
                LED[farmer_pos] = 1;
            end
            // (Win || Lose): LED <= LED_next;
        endcase
    end

    always @* begin
        // if (state == Win || state == Lose) begin
        //     if (LED == 16'b0101_0101_0101_0101 || LED == 16'b1010_1010_1010_1010 || LED == {16{1'b0}})
        //         LED_next = {16{1'b1}};
        //     else if (LED[0] == 1)
                LED_next = LED >> 1;
        end
    // end

    // 7 segment
    reg [3:0] display;
    reg [3:0] digit_0, digit_1, digit_2, digit_3;

    always @* begin
        case (state)
            Init: begin
                {digit_3, digit_2, digit_1, digit_0} = {4'd8, 4'd8, 4'd8, 4'd8};
                state_next = Game;
            end
            Game: begin
                {digit_3, digit_2, digit_1, digit_0} = {4'd3, 4'd3, 4'd3, 4'd3};
                state_next = Game;
            end
            default: begin
                {digit_3, digit_2, digit_1, digit_0} = {4'd2, 4'd3, 4'd3, 4'd3};
                state_next = Init;
            end
            // (Win || Lose): {digit_3, digit_2, digit_1, digit_0} = {4'd10, 4'd10, 4'd10, 4'd10};
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
            // dash
            4'd10: DISPLAY = 7'b011_1111;
            default: DISPLAY = 7'b111_1111;
        endcase
    end

endmodule


