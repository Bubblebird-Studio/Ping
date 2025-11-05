@group(0) @binding(0) var<storage, read> buffer_input: array<float>;
@group(0) @binding(1) var<storage, read_write> buffer_output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;


// fn customFunction(coord: uint3, resolution: uint3, input: ptr<storage, array<float>, read_write>) -> float4 {
//   //let index = get_index(coord, resolution);
//   return float4(1.0, 1.0, 0.0, 1.0);
// }

@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let info_input = BindingInfo(uint(buffer_input[0]), buffer_input[1] != 0.0);

  let result = customFunction(coord, resolution, &buffer_input, info_input.stride);
  let index = get_index(coord, resolution);

  buffer_output[index * 4 + 0] = result.r;
  buffer_output[index * 4 + 1] = result.g;
  buffer_output[index * 4 + 2] = result.b;
  buffer_output[index * 4 + 3] = result.a;
}