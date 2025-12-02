module tt_um_rowantylerr_RC_TDC (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

top top_inst (
    .step_set(uio_out[0]),
    .step_input(ui_in[0]),
    .clk(clk),
    .reset(~rst_n)
);

assign uio_oe = 8'b11111111; // Set uio_out as outputs
assign uio_out[7:1] = 7'b0; // Only using 1st bit so keep rest driven to 0

// List all unused inputs to prevent warnings
    wire _unused = &{ena, uo_out, uio_in[7:0], ui_in[7:1], 1'b0};

endmodule

//Module to control functionality of RC time to resistance calculator
module top(step_set, step_input, clk, reset);

    //Inputs will be clk, reset and the step_input produced by RC circuit
    input clk;
    input reset;
    input step_input;
    
    //Outputs will be step_set signal to excite RC circuit
    output reg step_set = 1'b0;
	wire overflow;

	reg charging = 1'b0; //LED0
	reg discharging = 1'b0; //LED1

    //Wires and Registers
    wire [23:0] counter;
    wire discharge_finished;

    reg [23:0] calc_res = 24'd0;
    reg [7:0] Capacitance = 8'd10; //Fixed capacitance value of 10nF for calculation
    reg clear_timer = 1'b0;
    reg discharge_start = 1'b0;

    reg bcd_start = 1'b0;
    wire bcd_finished;
    wire [23:0] bcd_output;

    wire [7:0]seg1_wire;
    wire [7:0]seg2_wire;
    wire [7:0]seg3_wire;
    wire [7:0]seg4_wire;
    wire [7:0]seg5_wire;
    wire [7:0]seg6_wire;

    reg [3:0] digit1 = 1; reg [7:0] seg1 = 8'b10011111;
    reg [3:0] digit2 = 2; reg [7:0] seg2 = 8'b00100101;
    reg [3:0] digit3 = 3; reg [7:0] seg3 = 8'b00001101;
    reg [3:0] digit4 = 4; reg [7:0] seg4 = 8'b10011001;
    reg [3:0] digit5 = 5; reg [7:0] seg5 = 8'b01001001;
    reg [3:0] digit6 = 6; reg [7:0] seg6 = 8'b01000001;
    

    // Instantiate the timer module
    input_timer input_timer_inst(
        .step_set(step_set),
        .step_input(step_input),
        .clk(clk),
        .reset(reset),
        .timer_output(counter),
        .overflow(overflow),
        .clear(clear_timer)
    );

    discharge_timer discharge_timer_inst(
        .start(discharge_start),
        .clk(clk),
        .reset(reset),
        .counter(counter),
        .finished(discharge_finished),
        .clear(clear_timer)
    );

    seg7 seg7_1(
        .data_in(digit1),
        .display_out(seg1_wire),
        .AN()
    );

    seg7 seg7_2(
        .data_in(digit2),
        .display_out(seg2_wire),
        .AN()
    );

    seg7 seg7_3(
        .data_in(digit3),
        .display_out(seg3_wire),
        .AN()
    );

    seg7 seg7_4(
        .data_in(digit4),
        .display_out(seg4_wire),
        .AN()
    );

    seg7 seg7_5(
        .data_in(digit5),
        .display_out(seg5_wire),
        .AN()
    );

    seg7 seg7_6(
        .data_in(digit6),
        .display_out(seg6_wire),
        .AN()
    );

    Binary_to_BCD #(.INPUT_WIDTH(24), .DECIMAL_DIGITS(6)) bcd_converter(  
        .i_Clock(clk), 
        .i_Binary(calc_res),
        .i_Start(bcd_start),
        .o_BCD(bcd_output),
        .o_DV(bcd_finished)
    );

    //On each clock cycle
    always @(posedge clk) begin

        //If reset is high, reset overflow, step_set and counter
        if (reset) begin
            step_set = 1'b0;
            calc_res = 24'd0;
            charging = 1'b1;
				discharging = !charging;
        end 
        
        //Else set step_set high to start timer and excite RC circuit
        else if (charging) begin
            clear_timer = 1'b0;
            step_set = 1'b1;
            discharge_start = 1'b0;

            //If overflow occurs
            if (overflow) begin
					step_set = 1'b0;
					charging = 1'b0;
					discharging = !charging;
            end

            //When step_input is high, RC circuit has charged, so set step_set low to start discharging circuit
            if (step_input) begin
                step_set = 1'b0;
                charging = 1'b0;
					 discharging = !charging;

                // compute resistance using integer arithmetic into a wide register
                calc_res = calculate_resistance(counter, Capacitance);

                // start BCD conversion if result is non-zero
                if (calc_res != 24'd0) begin
                    bcd_start = 1'b1; //Start BCD conversion
                end

             end
        end

        else if (discharging) begin
            step_set = 1'b0;
            
            if (discharge_finished && !bcd_start) begin
                discharge_start = 1'b0;
                clear_timer = 1'b1; //Clear the timer for next measurement    
            end

            if (bcd_finished) begin
                bcd_start = 1'b0;
                {digit1, digit2, digit3, digit4, digit5, digit6} = bcd_output;
					 {seg1, seg2, seg3, seg4, seg5, seg6} = {seg1_wire, seg2_wire, seg3_wire, seg4_wire, seg5_wire, seg6_wire};
					 
            end

            //Check if timer has been cleared
            if (counter == 24'd0) begin
                charging = 1'b1;    //Set charging to true to start next measurement
					 discharging = !charging;
                clear_timer = 1'b0;
            end

            else begin
                discharge_start = 1'b1; //Start discharging the RC circuit
            end

        end

    end

// R = t / (C * ln(2))
//resistance = (time_value * 20) * (1/ln(2)) / capacitance (when using 50 MHz clock and capacitance given in nF)
function [23:0] calculate_resistance;
    input integer time_value;
    input integer capacitance;
    // Use Q16 fixed-point. CONST_Q16 = round(28.853900817779268 * 2^16)
    // 28.853900817779268 = 20 * (1/ln(2))
    reg [31:0] CONST_Q16;
    reg [63:0] prod;
    reg [63:0] down_shift;
    reg [63:0] result;
    integer cap;
    begin
        CONST_Q16 = 32'd1890952; // Q16 representation
        cap = (capacitance == 0) ? 1 : capacitance; // avoid divide by zero

        // wide multiply: time_value * CONST_Q16
        prod = $unsigned(time_value) * CONST_Q16;

        // shift down by 16 to convert from Q16 -> integer
        down_shift = prod >> 16;

        // divide by capacitance
        result = down_shift / cap;

        // clamp to 24 bits
        if (result > 24'hFFFFFF)
            calculate_resistance = 24'hFFFFFF;
        else
            calculate_resistance = result[23:0];
    end
endfunction

    
endmodule



