@group(0) @binding(0) var<storage, read> buffer_edge1: array<float>;
@group(0) @binding(1) var<storage, read> buffer_edge2: array<float>;
@group(0) @binding(2) var<storage, read> buffer_input: array<float>;
@group(0) @binding(3) var<storage, read_write> buffer_output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties {
  edge1: float,
  edge2: float,
  input: float,
};

@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let info_edge1 = BindingInfo(uint(buffer_edge1[0]), buffer_edge1[1] != 0.0);
  let info_edge2 = BindingInfo(uint(buffer_edge2[0]), buffer_edge2[1] != 0.0);
  let info_input = BindingInfo(uint(buffer_input[0]), buffer_input[1] != 0.0);
  let info_output = BindingInfo(uint(buffer_output[0]), buffer_output[1] != 0.0);

  let index = get_index(coord, resolution);

  for (var i = 0u; i < info_input.stride; i++) {
    let edge1 = select(properties.edge1, buffer_edge1[index * info_edge1.stride + i], info_edge1.connected);
    let edge2 = select(properties.edge2, buffer_edge2[index * info_edge2.stride + i], info_edge2.connected);
    let input = select(properties.input, buffer_input[index * info_input.stride + i], info_input.connected);
    buffer_output[index * info_input.stride + i] = smoothstep(edge1, edge2, input);
  }
}