`timescale 1ns/1ps

module clock (
    clk,
    reset_n,
    second,
    minute,
    hour,
    sec_count
    );

    input clk, reset_n;

    output reg [5:0] second, minute;
    output reg [4:0] hour;
    output reg [27:0] sec_count; // 28-bit counter, 50MHz needs 26-bit Binary. Doing 27 just in case

    always @(posedge(clk) or posedge(reset_n)) begin

        if(reset_n == 1'b1) begin
            sec_count <= 0;
            second <= 0;
            hour <= 0;
            minute <= 0;

        end

        else if(clk == 1'b1) begin
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
    end
endmodule //clock
