/*
 * COMPLETED COMPILED FACTORIO BUILD FOR train_balancer.sv
 *
 * IMPORTANT: REFER TO USAGE INSTRUCTIONS NEAR MODULE dropoff_train_station EXACTLY!
 *
 * NOTE: variables marked t0, t1, t2, etc... are "temporaries" intended for the
 * number signals to be used for them
 */
module get_a #(
  parameter W = 8000, // W
  parameter INT = 31
) (
  input [INT:0] t, // T
  input [INT:0] c, // C
  input [INT:0] u, // U
  output [INT:0] a // A
);
  // trains en route = Z
  reg [INT:0] z, a;
  reg [INT:0] t0;
  assign t0 = t != 0 ? 1 : 0;
  assign z = c - t0;
  reg [INT:0] t1;
  assign t1 = z * W;
  assign a = u + t1;
endmodule

module get_s #(
  parameter M = 128000, // M
  parameter INT = 31
) (
  input [INT:0] a, // A
  input [INT:0] p, // P
  output [INT:0] s // S
);
  reg [INT:0] t2;
  assign t2 = a * p;
  assign s = t2 / M;
endmodule

module get_l #(
  parameter Q = 3, // Q
  parameter M = 128000, // M
  parameter W = 8000, // W
  parameter INT = 31
) (
  input [INT:0] a, // A
  input [INT:0] s, // S
  input [INT:0] r, // R
  input [INT:0] g, // G
  input [INT:0] c, // C
  input [INT:0] p, // P
  output [INT:0] l // L
);
  // B, D, E but due to Factorio semantics, can coalesce into 1
  reg b, d, e;
  reg [INT:0] t3;
  assign t3 = M - a;
  reg t4;
  assign t4 = t3 >= W;
  reg t5;
  assign t5 = a < M;
  assign b = t5 && t4;
  reg [INT:0] t6;
  assign t6 = r * p;
  reg [INT:0] t7;
  assign t7 = t6 / g;
  reg [INT:0] t8;
  assign t8 = t7 / p;
  assign d = s <= t8;
  assign e = c < Q;
  reg [INT:0] t9;
  // XXX: no temporary needed because Factorio signals sum implicitly when on same wire
  assign t9 = (b + d + e) == 3 ? 1 : 0;
  assign l = c + t9;
endmodule

/*
 * USAGE INSTRUCTIONS *
 * Signals in constant combinator nearest the train stop:
 * - Q = maximum number of trains to send to station at once (queue length)
 * - M = maximum resources to store at this station
 *   (NOTE: there's a bug where station can be over-filled in some circumstances
 *          therefore, M should be set to the true maximum minus W)
 * - W = units per train load
 *
 * On GLOBAL network input/output line:
 * - convert IDENTITY on Green to G (number of stations)
 * - copy P on Green to P (precision)
 * - convert IDENTITY on Red to R (total percentage of resources)
 * - back-convert S to IDENTITY ON Red (this station's contribution to total percentage of resources)
 * - add constant combinator with IDENTITY = 1 on Green
 *
 * - Wire buffer chests to train stop on Green
 * - Take C, T and L from/to train stop as inputs/outputs to/from Green
 * - IDENTITY from this same Green network gets converted to U on same network
 */
module dropoff_train_station #(
  parameter Q = 3, // station config combinator
  parameter M = 128000, // station config combinator
  parameter W = 8000, // station config combinator
  parameter INT = 31
) (
  input [INT:0] p, // P network (green)
  input [INT:0] g, // G network (green)
  input [INT:0] r, // R network (red)
  input [INT:0] u, // U local via train stop
  input [INT:0] c, // C train stop
  input [INT:0] t, // T train stop
  output [INT:0] s, // S convert to network (red)
  output [INT:0] l // L train stop
);
  reg [INT:0] a; // Circuit A
  get_a #(W, INT) ua_getter(
    .t(t),
    .c(c),
    .u(u),
    .a(a)
  );
  get_s #(M, INT) ps_getter(
    .a(a),
    .p(p),
    .s(s)
  );
  get_l #(Q, M, W, INT) tl_getter(
    .a(a),
    .s(s),
    .r(r),
    .g(g),
    .c(c),
    .p(p),
    .l(l)
  );
endmodule
