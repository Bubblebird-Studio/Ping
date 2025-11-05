@group(0) @binding(0) var<storage, read_write> buffer_uvw: array<float>;
@group(0) @binding(1) var<storage, read_write> buffer_u: array<float>;
@group(0) @binding(2) var<storage, read_write> buffer_v: array<float>;
@group(0) @binding(3) var<storage, read_write> buffer_w: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;


@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let u = float(coord.x) / float(resolution.x);
  let v = float(coord.y) / float(resolution.y);
  let w = float(coord.z) / float(resolution.z);

  let index = get_index(coord, resolution);

  buffer_uvw[index * 3 + 0] = u;
  buffer_uvw[index * 3 + 1] = v;
  buffer_uvw[index * 3 + 2] = w;

  buffer_u[index] = u;
  buffer_v[index] = v;
  buffer_w[index] = w;
}