@group(0) @binding(0) var<storage, read_write> buffer_output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties {
  color: float4
};


@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let index = get_index(coord, resolution);

  buffer_output[index * 4 + 0] = properties.color.r;
  buffer_output[index * 4 + 1] = properties.color.g;
  buffer_output[index * 4 + 2] = properties.color.b;
  buffer_output[index * 4 + 3] = properties.color.a;
}