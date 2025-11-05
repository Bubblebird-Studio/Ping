@group(0) @binding(0) var<storage, read> buffer_a: array<float>;
@group(0) @binding(1) var<storage, read> buffer_b: array<float>;
@group(0) @binding(2) var<storage, read> buffer_x: array<float>;
@group(0) @binding(3) var<storage, read_write> buffer_output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties {
  a: float,
  b: float,
  x: float,
};

@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let info_a = BindingInfo(uint(buffer_a[0]), buffer_a[1] != 0.0);
  let info_b = BindingInfo(uint(buffer_b[0]), buffer_b[1] != 0.0);
  let info_x = BindingInfo(uint(buffer_x[0]), buffer_x[1] != 0.0);
  let info_output = BindingInfo(uint(buffer_output[0]), buffer_output[1] != 0.0);

  let index = get_index(coord, resolution);
  var a = float4(0.0);
  var b = float4(0.0);
  var x = float4(0.0);

  for (var i = 0u; i < info_a.stride; i++) {
    a[i] = select(float(properties.a), buffer_a[index * info_a.stride + i], info_a.connected);
  }

  for (var i = 0u; i < info_b.stride; i++) {
    b[i] = select(float(properties.b), buffer_b[index * info_b.stride + i], info_b.connected);
  }

  for (var i = 0u; i < info_x.stride; i++) {
    x[i] = select(float(properties.x), buffer_x[index * info_x.stride + i], info_x.connected);
  }

  for (var i = 0u; i < info_output.stride; i++) {
    buffer_output[index * info_output.stride + i] = mix(a[i], b[i], x[i]);
  }
}