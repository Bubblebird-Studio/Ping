@group(0) @binding(0) var<storage, read> buffer_input_rgba: array<float>;
@group(0) @binding(1) var<storage, read_write> buffer_output_r: array<float>;
@group(0) @binding(2) var<storage, read_write> buffer_output_g: array<float>;
@group(0) @binding(3) var<storage, read_write> buffer_output_b: array<float>;
@group(0) @binding(4) var<storage, read_write> buffer_output_a: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;


@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let info_input_rgba = BindingInfo(uint(buffer_input_rgba[0]), buffer_input_rgba[1] != 0.0);

  let index = get_index(coord, resolution);

  buffer_output_r[index] = buffer_input_rgba[index * info_input_rgba.stride + 0];
  buffer_output_g[index] = buffer_input_rgba[index * info_input_rgba.stride + 1];
  buffer_output_b[index] = buffer_input_rgba[index * info_input_rgba.stride + 2];
  buffer_output_a[index] = buffer_input_rgba[index * info_input_rgba.stride + 3];
}