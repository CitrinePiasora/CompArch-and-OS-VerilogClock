`timescale 1ns/1ps

module clock (
    input clk, reset_n,
    input io0_down, io1_up, io2_setHour, io3_setMinute, io4_military, io5_stopwatch_enable, io6_stopwatch_run, io7_stopwatch_zero,
    output ad0_L1, ad1_L2, ad2_L3, ad3_L4,
    output io8_a, io9_b, io10_c, io11_d, io12_e, io13_f, ad4_g, ad5_dp);

    /*******CLOCK VARIABLES*******/
    reg [5:0] second; 
    reg [5:0] minute; // Minute Tracking
    reg [3:0] minute1; // First Digit for Minutes
    reg [3:0] minute2; // Second Digit for Minutes
    wire am_pm; 
    reg [4:0] hour; // 24-Hour Tracking
    reg [3:0] hour1; // First Digit for Hours
    reg [3:0] hour2; // Second Digit for Hours

    assign am_pm = (hour >= 12) ? 1 : 0; // 0 for am, 1 for pm

    /*******1-Sec Counter & Clock Operation*******/
    reg [27:0] sec_count; // 28-bit counter, 50MHz needs 26-bit Binary. Doing 27 just in case

    always @(posedge clk) begin

        if(!reset_n) begin
            sec_count <= 0;
            second <= 0;
            hour <= 0;
            minute <= 0;

        end

        else begin
            sec_count <= sec_count + 1;

            if (sec_count >= 99999999) begin // 1-Sec Counter, 100M due to using 100 MHz Clock
                second <= second + 1;
                sec_count <= 0;
            end

            if (second >= 60) begin // Add 1 to minute when second >= 60
                second <= 0;
                minute <= minute + 1;
            end

            if (minute >= 60) begin // Add 1 to hour when minute >= 60
                minute <= 0;
                hour <= hour + 1;
            end

            if (hour >= 24) begin // Reset hours to 0 when hour >= 24
                hour <= 0;
            end
        end

    /*******Setting Hours and Minutes*******/
        if (io2_setHour && sec_count == 99999999) begin

            if (io0_down) begin
                if (hour <= 0) hour <= 0;
                else hour <= hour - 1;
            end

            else if (io1_up) begin
                hour <= hour + 1;
            end

        end
          
          else if (io3_setMinute && sec_count == 99999999) begin

            if (io0_down) begin
                if (minute <= 0) minute <= 0;
                else minute <= minute - 1;
            end

            else if (io1_up) begin
                minute <= minute + 1;
            end

        end
    end
    
    /*******Clock Display Output*******/
    always @* begin
        /*******Military (24-Hour) Hour Display*******/
        if (io4_military) begin
            if (hour < 10) begin  // If before 10am, 00-09
                hour1 <= 0;
                hour2 <= hour;
            end
            
            else begin
                hour1 <= hour / 10;
                hour2 <= hour % 10;
            end
        end

        /*******AM PM HOUR DISPLAY FORMAT*******/
        else begin
            if (hour < 10) begin // If before 10am, 01-09
                hour1 <= 0;
                hour2 <= hour;    
            end 

            else if (hour >= 10 && hour <= 12) begin // If after/at 10am, 10-12
                hour1 <= 1;
                hour2 <= hour % 10;
            end

            else if (hour > 12 && hour < 22) begin // If after 12pm but before 10pm, 1pm-10pm
                hour1 <= 0;
                hour2 <= hour - 12;
            end

            else begin // From 10pm-12am
                hour1 <= 1;
                hour2 <= (hour - 12) % 10;
            end

        end

        /*******Minute Display*******/
        if (minute < 10) begin
            minute1 <= 0;
            minute2 <= minute;
        end

        else begin
            minute1 <= minute / 10;
            minute2 <= minute % 10;
        end
    end

    /*******Display Variables*******/
    reg [6:0] segments; // Output Segments
    reg dp; // Decimal Point
    reg [3:0] out_digit; // Output Data for Each Digit
    reg [3:0] led_enabled;

    assign {ad0_L1, ad1_L2, ad2_L3, ad3_L4} = led_enabled;
    assign {io8_a, io9_b, io10_c, io11_d, io12_e, io13_f, ad4_g} = segments;
    assign ad5_dp = dp;

    /*******Stopwatch Operation*******/
    reg [6:0] sw_minute; // 7-bit register to allow up to 99 minutes
    reg [5:0] sw_second; 
    reg [3:0] sw_minute1;
    reg [3:0] sw_minute2; 
    reg [3:0] sw_second1;
    reg [3:0] sw_second2;

    always @(posedge clk) begin
        if (io5_stopwatch_enable) begin
            if(io7_stopwatch_zero) begin
                sw_minute <= 0;
                sw_second <= 0;
            end

            else if (io6_stopwatch_run && sec_count == 99999999) begin
                sw_second <= sw_second + 1;
            end

            if (sw_second >= 60) begin
                sw_second <= 0;
                sw_minute <= sw_minute + 1;
            end

            if (sw_minute >= 100) begin
                sw_minute <= 0;
            end

            /*******Stopwatch Display Output*******/
            if (sw_minute < 10) begin
                sw_minute1 <= 0;
                sw_minute2 <= sw_minute;
            end
            
            else begin
                sw_minute1 <= sw_minute / 10;
                sw_minute2 <= sw_minute % 10;
            end
            
            if (sw_second < 10) begin
                sw_second1 <= 0;
                sw_second2 <= sw_second;
            end

            else begin
                sw_second1 <= sw_second / 10;
                sw_second2 <= sw_second % 10;
            end
        end
    end
     
     
     /*******Multiplexing Four Digits*******/
     
     reg [17:0] count; // 18-bit counter
     
     always @(posedge clk) begin
        count <= count + 1;
     end
     
     always @* begin
        /*******Normal Display*******/
        if (!io5_stopwatch_enable) begin
            case (count[17:16])
                2'b00: begin
                    out_digit <= hour1;
                    led_enabled <= 4'b1000;
                    dp = 1'b1;
                end
                2'b01: begin
                    out_digit <= hour2;
                    led_enabled <= 4'b1000;
                    dp = 1'b0;
                end
                2'b10: begin
                    if (sec_count < 50000000) begin // Blinking effect every half a second (because the clock is 100MHz)
                        out_digit <= minute1;
                        led_enabled <= 4'b0010;
                    end
                    else begin
                        led_enabled <= 4'b0000;
                    end
                    dp = 1'b1;
                end
                2'b11: begin
                    if (sec_count < 50000000) begin
                        out_digit <= minute2;
                        led_enabled <= 4'b0001;
                    end
                    else begin
                        led_enabled <= 4'b0000;
                    end
                    if (am_pm) dp <= 1'b0; // last decimal point is ON if it is PM
                    else dp <= 1'b1;
                end
            endcase
        end
        /*******Stopwatch Display*******/
        else begin
            case (count[17:16])
                2'b00: begin
                    out_digit <= sw_minute1;
                    led_enabled <= 4'b1000;
                    dp = 1'b1;
                end
                2'b01: begin
                    out_digit <= sw_minute2;
                    led_enabled <= 4'b0100;
                    dp = 1'b0;
                end
                2'b10: begin
                    out_digit <= sw_second1;
                    led_enabled <= 4'b0010;
                    dp = 1'b1;
                end
                2'b11: begin
                    out_digit <= sw_second2;
                    led_enabled <= 4'b0001;
                    dp = 1'b1;
                end
            endcase
        end
     end
     
     /*******7-Segment Display*******/
     always @* begin
        case(out_digit)
            4'b0000: segments = 7'b0000001;
            4'b0001: segments = 7'b1001111;
            4'b0010: segments = 7'b0010010;
            4'b0011: segments = 7'b0000110;
            4'b0100: segments = 7'b1001100;
            4'b0101: segments = 7'b0100100;
            4'b0110: segments = 7'b0100000;
            4'b0111: segments = 7'b0001111;
            4'b1000: segments = 7'b0000000;
            4'b1001: segments = 7'b0000100;
            4'b1010: segments = 7'b0001000;
            4'b1011: segments = 7'b1100000;
            4'b1100: segments = 7'b0110001;
            4'b1101: segments = 7'b1000010;
            4'b1110: segments = 7'b0110000;
            4'b1111: segments = 7'b0111000;
        endcase
    end
endmodule //clock