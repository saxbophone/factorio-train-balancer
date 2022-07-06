// SmartStations v1.0 -- Dropoff Station logic

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
  reg [INT:0] trains_en_route;
  assign trains_en_route = stopped_train_id == 0 ? train_count : train_count - 1;
  assign units_accounted = units_at_this_station + (trains_en_route * UNITS_IN_TRAIN_LOAD);
endmodule

module get_percentage_stored #(
  parameter MAX_STOREABLE = 128000, // M
  parameter INT = 31
) (
  input [INT:0] units_accounted, // A
  input [INT:0] precision, // P
  output [INT:0] percentage_stored // S
);
  assign percentage_stored = (units_accounted * precision) / MAX_STOREABLE;
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
  assign units_deficit = (percentage_deficit * MAX_STOREABLE) / precision;
  assign trains_for_deficit = units_deficit / UNITS_IN_TRAIN_LOAD;
  assign clipped_trains_for_deficit = trains_for_deficit > 0 ? trains_for_deficit : 1;
  assign ideal_trains_to_send = trains_for_free_space < clipped_trains_for_deficit ? trains_for_free_space : clipped_trains_for_deficit;
  assign trains_to_send = ideal_trains_to_send < QUEUE_LENGTH ? ideal_trains_to_send : QUEUE_LENGTH;
  assign trains_limit = percentage_stored > average_percentage_stored ? 0 : trains_to_send;
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
