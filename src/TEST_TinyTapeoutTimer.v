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
    .reset(~rst_n),
    .resistance_output(uo_out)
);

endmodule

//Module to control functionality of RC time to resistance calculator
module top(step_set, step_input, clk, reset, resistance_output);

    //Inputs will be clk, reset and the step_input produced by RC circuit
    input clk;
    input reset;
    input step_input;
    
    //Outputs will be resistance value and step_set signal to excite RC circuit
    output wire [7:0] resistance_output;
    output step_set;

    //Wires and Registers to store values of overflow and counter
    wire [23:0] counter;
    wire overflow;

    reg step_set_reg = 1'b0;
    reg overflow_reg = 1'b0;
    reg counter_reg = 24'd0;
    reg resistance_output_reg = 8'd0;
    reg [7:0] Capacitance = 8'd100; //Fixed capacitance value of 100pF for calculation

    // Instantiate the timer module
    timer main_timer(
        .step_set(step_set),
        .step_input(step_input),
        .clk(clk),
        .reset(reset),
        .timer_output(counter),
        .overflow(overflow)
    );

    //On each clock cycle
    always @(posedge clk or posedge reset) begin

        //If reset is high, reset overflow, step_set and counter
        if (reset) begin
            overflow_reg <= 1'b0;
            step_set_reg = 1'b0;
            counter_reg <= 24'd0;
        end 
        
        //Else set step_set high to start timer and excite RC circuit
        else begin
            step_set_reg = 1'b1;

            //If overflow occurs set overflow to high to be sent out
            if (overflow) begin
                overflow_reg <= 1'b1;
            end

            //When step_input is high, RC circuit has charged, so set step_set low to start discharging circuit
            if (step_input) begin
                step_set_reg = 1'b0;

                //Conver counter to time
                counter_reg <= counter/50;

                //Calculate resistance using R = t / (C * ln(2))
                resistance_output_reg <= counter/(Capacitance*$ln(2));
                
            end
        end
    end

    assign step_set = step_set_reg;
    assign resistance_output = resistance_output_reg;
    assign overflow = overflow_reg;

    
endmodule

module timer(step_set, step_input, clk, reset, timer_output, overflow);

    input clk;
    input reset;
    input step_input;
    input step_set;

    output wire [23:0] timer_output;
    output wire overflow;

    reg [23:0] counter = 24'd0;
    reg timer_stop = 1'b0;
    reg overflow_reg = 1'b0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 24'd0;
            timer_stop <= 1'b0;
            overflow_reg <= 1'b0;
        end 
        else if (step_set && !timer_stop) begin
            counter <= counter + 1;
            if (counter == 24'hFFFFFF) begin
                counter <= 24'd0;
                overflow_reg <= 1'b1;
            end
            else if (step_input == 1'b1) begin
                timer_stop <= 1'b1;
            end
        end
    end

    assign timer_output = counter;
    assign overflow = overflow_reg;

endmodule