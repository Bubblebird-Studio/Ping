@group(0) @binding(0) var<storage, read> buffer_input: array<float>;
@group(0) @binding(1) var<storage, read> buffer_min: array<float>;
@group(0) @binding(2) var<storage, read> buffer_max: array<float>;
@group(0) @binding(5) var<storage, read_write> output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties {
  min: float,
  max: float,
};


@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let index = get_index(coord, resolution);

  let info_input = BindingInfo(uint(buffer_input[0]), buffer_input[1] != 0.0);
  let info_min =   BindingInfo(uint(buffer_min[0]), buffer_min[1] != 0.0);
  let info_max =   BindingInfo(uint(buffer_max[0]), buffer_max[1] != 0.0);

  for (var i = 0u; i < info_input.stride; i++) {
    let value = buffer_input[index * info_input.stride + i];
    let min = select(properties.min, buffer_min[index * info_min.stride + i], info_min.connected);
    let max = select(properties.max, buffer_max[index * info_max.stride + i], info_max.connected);

    output[index * info_input.stride + i] = clamp(value, min, max);
  }
}