@group(0) @binding(0) var<storage, read> buffer_a: array<float>;
@group(0) @binding(1) var<storage, read> buffer_b: array<float>;
@group(0) @binding(2) var<storage, read_write> buffer_output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties {
  operation: float,
  a: float,
  b: float,
};

const OPERATION_ADD = 0;
const OPERATION_SUBTRACT = 1;
const OPERATION_MULTIPLY = 2;
const OPERATION_DIVIDE = 3;
const OPERATION_POWER = 4;
const OPERATION_LOG = 5;
const OPERATION_SQRT = 6;
const OPERATION_INVSQRT = 7;
const OPERATION_ABS = 8;
const OPERATION_EXP = 9;
const OPERATION_MIN = 10;
const OPERATION_MAX = 11;
const OPERATION_LESSTHAN = 12;
const OPERATION_GREATERTHAN = 13;
const OPERATION_SIGN = 14;
const OPERATION_ROUND = 15;
const OPERATION_FLOOR = 16;
const OPERATION_CEIL = 17;
const OPERATION_FRAC = 18;
const OPERATION_MOD = 19;
const OPERATION_SIN = 20;
const OPERATION_COS = 21;
const OPERATION_TAN = 22;
const OPERATION_ASIN = 23;
const OPERATION_ACOS = 24;
const OPERATION_ATAN = 25;
const OPERATION_ATAN2 = 26;
const OPERATION_SINH = 27;
const OPERATION_COSH = 28;
const OPERATION_TANH = 29;


@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let operation = uint(properties.operation);
  let info_a = BindingInfo(uint(buffer_a[0]), buffer_a[1] != 0.0);
  let info_b = BindingInfo(uint(buffer_b[0]), buffer_b[1] != 0.0);
  let info_output = BindingInfo(uint(buffer_output[0]), buffer_output[1] != 0.0);
  let index = get_index(coord, resolution);
  var a = float4(0.0, 0.0, 0.0, 0.0);
  var b = float4(0.0, 0.0, 0.0, 0.0);
  var result = float4(0.0, 0.0, 0.0, 1.0);
  
  for (var i = 0u; i < info_a.stride; i++) {
    a[i] = select(properties.a, buffer_a[index * info_a.stride + i], info_a.connected);
  }

  for (var i = 0u; i < info_b.stride; i++) {
    b[i] = select(properties.b, buffer_b[index * info_b.stride + i], info_b.connected);
  }

  if (operation == OPERATION_ADD)           { result = a + b; }
  if (operation == OPERATION_SUBTRACT)      { result = a - b; }
  if (operation == OPERATION_MULTIPLY)      { result = a * b; }
  if (operation == OPERATION_DIVIDE)        { result = a / b; }
  if (operation == OPERATION_POWER)         { result = pow(a, b); }
  if (operation == OPERATION_LOG)           { result = log(a); }
  if (operation == OPERATION_SQRT)          { result = sqrt(a); }
  if (operation == OPERATION_INVSQRT)       { result = inverseSqrt(a); }
  if (operation == OPERATION_ABS)           { result = abs(a); }
  if (operation == OPERATION_EXP)           { result = exp(a); }
  if (operation == OPERATION_MIN)           { result = min(a, b); }
  if (operation == OPERATION_MAX)           { result = max(a, b); }
  if (operation == OPERATION_LESSTHAN)      { result = float4(a < b); }
  if (operation == OPERATION_GREATERTHAN)   { result = float4(a > b); }
  if (operation == OPERATION_SIGN)          { result = sign(a); }
  if (operation == OPERATION_ROUND)         { result = round(a); }
  if (operation == OPERATION_FLOOR)         { result = floor(a); }
  if (operation == OPERATION_CEIL)          { result = ceil(a); }
  if (operation == OPERATION_FRAC)          { result = fract(a); }
  if (operation == OPERATION_MOD)           { result = a % b; }
  if (operation == OPERATION_SIN)           { result = sin(a); }
  if (operation == OPERATION_COS)           { result = cos(a); }
  if (operation == OPERATION_TAN)           { result = tan(a); }
  if (operation == OPERATION_ASIN)          { result = asin(a); }
  if (operation == OPERATION_ACOS)          { result = acos(a); }
  if (operation == OPERATION_ATAN)          { result = atan(a); }
  if (operation == OPERATION_ATAN2)         { result = atan2(a, b); }
  if (operation == OPERATION_SINH)          { result = sinh(a); }
  if (operation == OPERATION_COSH)          { result = cosh(a); }
  if (operation == OPERATION_TANH)          { result = tanh(a); }
  
  
  for (var i = 0u; i < info_output.stride; i++) {
    buffer_output[index * info_output.stride + i] = result[i];
  }
}