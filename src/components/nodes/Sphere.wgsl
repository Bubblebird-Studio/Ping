@group(0) @binding(0) var<storage, read_write> buffer_output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties {
  radius: float,
  feather: float,
};

@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));
  let dimensionality = float3(select(0.0, 1.0, resolution.x > 1), select(0.0, 1.0, resolution.y > 1), select(0.0, 1.0, resolution.z > 1));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let index = get_index(coord, resolution);
  let uvw = float3(coord) / float3(resolution);
  let pos = uvw * 2.0 - dimensionality;

  let sdf = length(pos) - properties.radius;

  buffer_output[index] = 1.0 - saturate(smoothstep(-properties.feather * 0.5, properties.feather * 0.5, sdf));
}