@group(0) @binding(0) var<storage, read> buffer_input: array<float>;
@group(0) @binding(1) var<storage, read_write> buffer_output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;

@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let index = get_index(coord, resolution);
  let info_input = BindingInfo(uint(buffer_input[0]), buffer_input[1] != 0.0);
  let info_output = BindingInfo(uint(buffer_output[0]), buffer_output[1] != 0.0);
  
  if (info_input.stride != info_output.stride) { return; }
  
  if (info_input.stride == 1) {
    buffer_output[index] = buffer_input[index];
  }
  if (info_input.stride == 2) {
    let normalized = normalize(float2(
      buffer_input[index * 2 + 0],
      buffer_input[index * 2 + 1]
    ));
    buffer_output[index * 2 + 0] = normalized[0];
    buffer_output[index * 2 + 1] = normalized[1];
  }
  if (info_input.stride == 3) {
    let normalized = normalize(float3(
      buffer_input[index * 3 + 0],
      buffer_input[index * 3 + 1],
      buffer_input[index * 3 + 2]
    ));
    buffer_output[index * 3 + 0] = normalized[0];
    buffer_output[index * 3 + 1] = normalized[1];
    buffer_output[index * 3 + 2] = normalized[2];
  }
  if (info_input.stride == 4) {
    let normalized = normalize(float4(
      buffer_input[index * 4 + 0],
      buffer_input[index * 4 + 1],
      buffer_input[index * 4 + 2],
      buffer_input[index * 4 + 3],
    ));
    buffer_output[index * 4 + 0] = normalized[0];
    buffer_output[index * 4 + 1] = normalized[1];
    buffer_output[index * 4 + 2] = normalized[2];
    buffer_output[index * 4 + 3] = normalized[3];
  }
}