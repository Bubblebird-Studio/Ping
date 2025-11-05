@group(0) @binding(0) var<storage, read> buffer_input: array<float>;
@group(0) @binding(1) var<storage, read_write> buffer_output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;

@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let index = get_index(coord, resolution);
  let info_input = BindingInfo(uint(buffer_input[0]), buffer_input[1] != 0.0);

  if (info_input.stride == 1) {
    buffer_output[index] = length(buffer_input[index]);
  }
  if (info_input.stride == 2) {
    buffer_output[index] = length(float2(
      buffer_input[index * 2 + 0],
      buffer_input[index * 2 + 1]
    ));
  }
  if (info_input.stride == 3) {
    buffer_output[index] = length(float3(
      buffer_input[index * 3 + 0],
      buffer_input[index * 3 + 1],
      buffer_input[index * 3 + 2]
    ));
  }
  if (info_input.stride == 4) {
    buffer_output[index] = length(float4(
      buffer_input[index * 4 + 0],
      buffer_input[index * 4 + 1],
      buffer_input[index * 4 + 2],
      buffer_input[index * 4 + 3],
    ));
  }
}