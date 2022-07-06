/*
 * NOTE: the code in this file has been normalised into "Factorio Normal Form"
 * so that it can be implemented directly in Factorio Circuit Network logic
 *
 * see the file 'train_balancer.sv' for the more readable original
 * SystemVerilog code
 * variables marked t0, t1, t2, etc... are "temporaries" intended for the
 * number signals to be used for them
 */
module get_units_accounted #(
  parameter UNITS_IN_TRAIN_LOAD = 8000, // W
  parameter INT = 31
) (
  input [INT:0] stopped_train_id, // T
  input [INT:0] train_count, // C
  input [INT:0] units_at_this_station, // U
  output [INT:0] units_accounted // A
);
  // trains en route = Z
  reg [INT:0] trains_en_route, units_accounted;
  reg [INT:0] t0;
  assign t0 = stopped_train_id != 0 ? 1 : 0;
  assign trains_en_route = train_count - t0;
  reg [INT:0] t1;
  assign t1 = trains_en_route * UNITS_IN_TRAIN_LOAD;
  assign units_accounted = units_at_this_station + t1;
endmodule

module get_percentage_stored #(
  parameter MAX_STOREABLE = 128000, // M
  parameter INT = 31
) (
  input [INT:0] units_accounted, // A
  input [INT:0] precision, // P
  output [INT:0] percentage_stored // S
);
  reg [INT:0] t2;
  assign t2 = units_accounted * precision;
  assign percentage_stored = t2 / MAX_STOREABLE;
endmodule

module get_trains_limit #(
  parameter QUEUE_LENGTH = 3, // Q
  parameter MAX_STOREABLE = 128000, // M
  parameter UNITS_IN_TRAIN_LOAD = 8000, // W
  parameter INT = 31
) (
  input [INT:0] units_accounted, // A
  input [INT:0] percentage_stored, // S
  input [INT:0] total_percentage_stored, // R
  input [INT:0] number_of_stations, // G
  input [INT:0] train_count, // C
  input [INT:0] precision, // P
  output [INT:0] trains_limit // L
);
  // B, D, E
  reg space_available, deserves_resupply, space_in_the_queue;
  reg [INT:0] t3;
  assign t3 = MAX_STOREABLE - units_accounted;
  reg t4;
  assign t4 = t3 >= UNITS_IN_TRAIN_LOAD;
  reg t5;
  assign t5 = units_accounted < MAX_STOREABLE;
  assign space_available = t5 && t4;
  reg [INT:0] t6;
  assign t6 = total_percentage_stored * precision;
  reg [INT:0] t7;
  assign t7 = t6 / number_of_stations;
  reg [INT:0] t8;
  assign t8 = t7 / precision;
  assign deserves_resupply = percentage_stored <= t8;
  assign space_in_the_queue = train_count < QUEUE_LENGTH;
  reg [INT:0] t9;
  // XXX: no temporary needed because Factorio signals sum implicitly when on same wire
  assign t9 = (space_available + deserves_resupply + space_in_the_queue) == 3 ? 1 : 0;
  assign trains_limit = train_count + t9;
endmodule

module dropoff_train_station #(
  parameter QUEUE_LENGTH = 3, // Q
  parameter MAX_STOREABLE = 128000, // M
  parameter UNITS_IN_TRAIN_LOAD = 8000, // W
  parameter INT = 31
) (
  input [INT:0] precision, // P
  input [INT:0] number_of_stations, // G
  input [INT:0] total_percentage_stored, // R
  input [INT:0] units_at_this_station, // U
  input [INT:0] train_count, // C
  input [INT:0] stopped_train_id, // T
  output [INT:0] percentage_stored, // S
  output [INT:0] trains_limit // L
);
  reg [INT:0] units_accounted; // Circuit A
  get_units_accounted #(UNITS_IN_TRAIN_LOAD, INT) ua_getter(
    .stopped_train_id(stopped_train_id),
    .train_count(train_count),
    .units_at_this_station(units_at_this_station),
    .stopped_train_contents(stopped_train_contents),
    .units_accounted(units_accounted)
  );
  get_percentage_stored #(MAX_STOREABLE, INT) ps_getter(
    .units_accounted(units_accounted),
    .precision(precision),
    .percentage_stored(percentage_stored)
  );
  get_trains_limit #(QUEUE_LENGTH, MAX_STOREABLE, UNITS_IN_TRAIN_LOAD, INT) tl_getter(
    .units_accounted(units_accounted),
    .percentage_stored(percentage_stored),
    .total_percentage_stored(total_percentage_stored),
    .number_of_stations(number_of_stations),
    .train_count(train_count),
    .precision(precision),
    .trains_limit(trains_limit)
  );
endmodule
