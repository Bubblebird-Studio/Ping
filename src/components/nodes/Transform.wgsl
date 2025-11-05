@group(0) @binding(0) var<storage, read> buffer_position: array<float>;
@group(0) @binding(1) var<storage, read> buffer_rotation: array<float>;
@group(0) @binding(2) var<storage, read> buffer_scale: array<float>;
@group(0) @binding(3) var<storage, read> buffer_input: array<float>;
@group(0) @binding(4) var<storage, read_write> buffer_output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties {
  position: float4,
  rotation: float4,
  scale: float4,
  input: float,
  bilinear_sampling: float,
};

@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let info_position = BindingInfo(uint(buffer_position[0]), buffer_position[1] != 0.0);
  let info_rotation = BindingInfo(uint(buffer_rotation[0]), buffer_rotation[1] != 0.0);
  let info_scale = BindingInfo(uint(buffer_scale[0]), buffer_scale[1] != 0.0);
  let info_input = BindingInfo(uint(buffer_input[0]), buffer_input[1] != 0.0);
  let info_output = BindingInfo(uint(buffer_output[0]), buffer_output[1] != 0.0);
  let index = get_index(coord, resolution);
  let bilinear_sampling = uint(properties.bilinear_sampling) != 0u;

  var position = float3(0.0);
  for (var i = 0u; i < info_position.stride; i++) {
    position[i] = select(properties.position[i], buffer_position[index * info_position.stride + i], info_position.connected);
  }

  var rotation = QUATERNION_IDENTITY;
  for (var i = 0u; i < info_rotation.stride; i++) {
    rotation[i] = select(properties.rotation[i], buffer_rotation[index * info_rotation.stride + i], info_rotation.connected);
  }

  var scale = float3(0.0);
  for (var i = 0u; i < info_scale.stride; i++) {
    scale[i] = select(properties.scale[i], buffer_scale[index * info_scale.stride + i], info_scale.connected);
  }

  var quaternion = QUATERNION_IDENTITY;
  quaternion = qmul(rotate_angle_axis(rotation.x / 360.0 * TAU, UP), quaternion);
  quaternion = qmul(rotate_angle_axis(rotation.y / 360.0 * TAU, LEFT), quaternion);
  quaternion = qmul(rotate_angle_axis(rotation.z / 360.0 * TAU, FORWARD), quaternion);

  var pos = float3(coord) / float3(resolution) * 2.0 - 1.0;
  pos = rotate_vector(pos, quaternion);
  pos += position;
  pos /= scale;

  var uvw = fmod3(pos * 0.5 + 0.5, float3(1.0));

  for (var i = 0u; i < info_output.stride; i++) {
    if (bilinear_sampling) {
      buffer_output[index * info_input.stride + i] = select(0.0, sample_buffer(&buffer_input, resolution, uvw, info_input.stride, i), info_input.connected);
    } else {
      let transformed_index = get_index(uint3(uvw * float3(resolution)), resolution);
      let input = select(properties.input, buffer_input[transformed_index * info_input.stride + i], info_input.connected);
      buffer_output[index * info_output.stride + i] = input;
    }
  }
}