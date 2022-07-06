/*
 * NOTE: the code in this file has been normalised into "Factorio Normal Form"
 * so that it can be implemented directly in Factorio Circuit Network logic
 *
 * see the file 'train_balancer.sv' for the more readable original
 * SystemVerilog code, OR see the file 'train_balancer_compiled.sv' for a
 * version that can be transliterated directly into Factorio Combinators
 *
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
  input [INT:0] precision, // P
  output [INT:0] trains_limit // L
);
  reg [INT:0] average_percentage_stored;
  assign average_percentage_stored = total_percentage_stored / number_of_stations;
  reg [INT:0] ideal_trains_to_send, trains_to_send;
  reg [INT:0] free_space, trains_for_free_space;
  assign free_space = MAX_STOREABLE - units_accounted;
  assign trains_for_free_space = free_space / UNITS_IN_TRAIN_LOAD;
  reg [INT:0] percentage_deficit, units_deficit, trains_for_deficit, clipped_trains_for_deficit;
  assign percentage_deficit = average_percentage_stored - percentage_stored;
  reg [INT:0] t3;
  assign t3 = percentage_deficit * MAX_STOREABLE;
  assign units_deficit = t3 / precision;
  assign trains_for_deficit = units_deficit / UNITS_IN_TRAIN_LOAD;
  reg [INT:0] t4;
  assign t4 = trains_for_deficit == 0 ? 1 : 0;
  assign clipped_trains_for_deficit = trains_for_deficit + t4; // temporary clipped_trains_for_deficit not needed due to free summing
  reg [INT:0] t5, t6;
  assign t5 = trains_for_free_space <= clipped_trains_for_deficit ? trains_for_free_space : 0;
  assign t6 = clipped_trains_for_deficit < trains_for_free_space ? clipped_trains_for_deficit : 0;
  assign ideal_trains_to_send = t5 + t6; // might not need temporaries due to free summing
  reg [INT:0] t7, t8;
  assign t7 = ideal_trains_to_send <= QUEUE_LENGTH ? ideal_trains_to_send : 0;
  assign t8 = QUEUE_LENGTH < ideal_trains_to_send ? QUEUE_LENGTH : 0;
  assign trains_to_send = t7 + t8; // might not need temporaries due to free summing
  assign trains_limit = average_percentage_stored >= percentage_stored ? trains_to_send : 0;
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
    .units_accounted(units_accounted)
  );
  get_percentage_stored #(MAX_STOREABLE, INT) ps_getter(
    .units_accounted(units_accounted),
    .precision(precision),
    .percentage_stored(percentage_stored)
  );
  reg [INT:0] percentage_actually_stored;
  get_percentage_stored #(MAX_STOREABLE, INT) psa_getter(
    .units_accounted(units_at_this_station),
    .precision(precision),
    .percentage_stored(percentage_actually_stored)
  );
  get_trains_limit #(QUEUE_LENGTH, MAX_STOREABLE, UNITS_IN_TRAIN_LOAD, INT) tl_getter(
    .units_accounted(units_accounted),
    .percentage_stored(percentage_actually_stored),
    .total_percentage_stored(total_percentage_stored),
    .number_of_stations(number_of_stations),
    .precision(precision),
    .trains_limit(trains_limit)
  );
endmodule
