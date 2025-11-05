@group(0) @binding(0) var<storage, read> buffer_scale: array<float>;
@group(0) @binding(1) var<storage, read_write> buffer_output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties {
  scale: float,
  min: float,
  max: float,
};

@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let info_scale = BindingInfo(uint(buffer_scale[0]), buffer_scale[1] != 0.0);
  let index = get_index(coord, resolution);
  let u = float(coord.x) / float(resolution.x);
  let v = float(coord.y) / float(resolution.y);
  let scale = select(properties.scale, buffer_scale[index], info_scale.connected);

  buffer_output[index] = remap(saturate((floor(u / scale) + floor(v / scale)) % 2.0), 0.0, 1.0, properties.min, properties.max);
}