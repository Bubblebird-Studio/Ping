@group(0) @binding(0) var<storage, read> buffer_input_r: array<float>;
@group(0) @binding(1) var<storage, read> buffer_input_g: array<float>;
@group(0) @binding(2) var<storage, read> buffer_input_b: array<float>;
@group(0) @binding(3) var<storage, read> buffer_input_a: array<float>;
@group(0) @binding(4) var<storage, read_write> buffer_output_rgba: array<float>;
@group(0) @binding(5) var<storage, read_write> buffer_output_rgb: array<float>;
@group(0) @binding(6) var<storage, read_write> buffer_output_rg: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties {
  r: float,
  g: float,
  b: float,
  a: float,
};


@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let info_input_r = BindingInfo(uint(buffer_input_r[0]), buffer_input_r[1] != 0.0);
  let info_input_g = BindingInfo(uint(buffer_input_g[0]), buffer_input_g[1] != 0.0);
  let info_input_b = BindingInfo(uint(buffer_input_b[0]), buffer_input_b[1] != 0.0);
  let info_input_a = BindingInfo(uint(buffer_input_a[0]), buffer_input_a[1] != 0.0);

  let index = get_index(coord, resolution);

  buffer_output_rgba[index * 4 + 0] = select(properties.r, buffer_input_r[index * info_input_r.stride + 0], info_input_r.connected);
  buffer_output_rgba[index * 4 + 1] = select(properties.g, buffer_input_g[index * info_input_g.stride + 0], info_input_g.connected);
  buffer_output_rgba[index * 4 + 2] = select(properties.b, buffer_input_b[index * info_input_b.stride + 0], info_input_b.connected);
  buffer_output_rgba[index * 4 + 3] = select(properties.a, buffer_input_a[index * info_input_a.stride + 0], info_input_a.connected);

  buffer_output_rgb[index * 3 + 0] = select(properties.r, buffer_input_r[index * info_input_r.stride + 0], info_input_r.connected);
  buffer_output_rgb[index * 3 + 1] = select(properties.g, buffer_input_g[index * info_input_g.stride + 0], info_input_g.connected);
  buffer_output_rgb[index * 3 + 2] = select(properties.b, buffer_input_b[index * info_input_b.stride + 0], info_input_b.connected);

  buffer_output_rg[index * 2 + 0] = select(properties.r, buffer_input_r[index * info_input_r.stride + 0], info_input_r.connected);
  buffer_output_rg[index * 2 + 1] = select(properties.g, buffer_input_g[index * info_input_g.stride + 0], info_input_g.connected);
}