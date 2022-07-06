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
  input [INT:0] train_count, // C
  input [INT:0] precision, // P
  output [INT:0] trains_limit // L
);
  reg space_available, deserves_resupply, space_in_the_queue;
  assign space_available = units_accounted < MAX_STOREABLE && (MAX_STOREABLE - units_accounted >= UNITS_IN_TRAIN_LOAD);
  assign deserves_resupply = percentage_stored <= (((total_percentage_stored * precision) / number_of_stations) / precision);
  assign space_in_the_queue = train_count < QUEUE_LENGTH;
  assign trains_limit = space_available && deserves_resupply && space_in_the_queue ? train_count + 1 : train_count;
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
