@group(0) @binding(0) var<storage, read> buffer_a: array<float>;
@group(0) @binding(1) var<storage, read> buffer_b: array<float>;
@group(0) @binding(2) var<storage, read_write> buffer_c: array<float>;
@group(0) @binding(3) var<storage, read> buffer_d: array<float>;
@group(0) @binding(4) var<storage, read_write> buffer_e: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties {
  input: float,
};

@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let info_a = BindingInfo(uint(buffer_a[0]), buffer_a[1] != 0.0);
  let info_b = BindingInfo(uint(buffer_b[0]), buffer_b[1] != 0.0);
  let info_d = BindingInfo(uint(buffer_d[0]), buffer_d[1] != 0.0);

  let index = get_index(coord, resolution);

  for (var i = 0u; i < info_b.stride; i++) {
    buffer_c[index * info_b.stride + i] = buffer_b[index * info_b.stride + i];
  }

  for (var i = 0u; i < info_d.stride; i++) {
    buffer_e[index * info_d.stride + i] = buffer_d[index * info_d.stride + i];
  }
}