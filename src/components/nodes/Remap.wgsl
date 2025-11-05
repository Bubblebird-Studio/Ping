@group(0) @binding(0) var<storage, read> buffer_input: array<float>;
@group(0) @binding(1) var<storage, read> buffer_from_min: array<float>;
@group(0) @binding(2) var<storage, read> buffer_from_max: array<float>;
@group(0) @binding(3) var<storage, read> buffer_to_min: array<float>;
@group(0) @binding(4) var<storage, read> buffer_to_max: array<float>;
@group(0) @binding(5) var<storage, read_write> output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties {
  fromMin: float,
  fromMax: float,
  toMin: float,
  toMax: float
};


@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let index = get_index(coord, resolution);

  let info_input =    BindingInfo(uint(buffer_input[0]), buffer_input[1] != 0.0);
  let info_from_min = BindingInfo(uint(buffer_from_min[0]), buffer_from_min[1] != 0.0);
  let info_from_max = BindingInfo(uint(buffer_from_max[0]), buffer_from_max[1] != 0.0);
  let info_to_min =   BindingInfo(uint(buffer_to_min[0]), buffer_to_min[1] != 0.0);
  let info_to_max =   BindingInfo(uint(buffer_to_max[0]), buffer_to_max[1] != 0.0);

  for (var i = 0u; i < info_input.stride; i++) {
    let value = buffer_input[index * info_input.stride + i];
    let fromMin = select(properties.fromMin, buffer_from_min[index * info_from_min.stride + i], info_from_min.connected);
    let fromMax = select(properties.fromMax, buffer_from_max[index * info_from_max.stride + i], info_from_max.connected);
    let toMin = select(properties.toMin, buffer_to_min[index * info_to_min.stride + i], info_to_min.connected);
    let toMax = select(properties.toMax, buffer_to_max[index * info_to_max.stride + i], info_to_max.connected);

    output[index * info_input.stride + i] = remap(value, fromMin, fromMax, toMin, toMax);
  }
}