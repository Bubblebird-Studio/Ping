@group(0) @binding(0) var<storage, read_write> buffer_output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties {
  seed: float,
  min: float,
  max: float,
};


@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let seed = uint(properties.seed);
  let index = get_index(coord, resolution);
  let noise = rand01(hash_int3(int3(int(hash_uint(coord.x + seed)), int(hash_uint(coord.y + seed)), int(hash_uint(coord.z + seed)))));

  buffer_output[index] = remap(noise, 0.0, 1.0, properties.min, properties.max);
}