@group(0) @binding(0) var<storage, read_write> buffer_output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties {
  size: float4,
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

  let d = abs(pos) - properties.size.xyz * dimensionality;
  let sdf = length(max(d, float3(0.0))) + min(max(d.x, max(d.y, d.z)), 0.0);
  //buffer_output[index] = select(0.0, 1.0, abs(pos.x) <= properties.size.x && abs(pos.y) <= properties.size.y && abs(pos.z) <= properties.size.z);
  buffer_output[index] = 1.0 - saturate(smoothstep(-properties.feather * 0.5, properties.feather * 0.5, sdf));
}