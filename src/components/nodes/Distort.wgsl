@group(0) @binding(0) var<storage, read> buffer_uvw: array<float>;
@group(0) @binding(1) var<storage, read> buffer_input: array<float>;
@group(0) @binding(2) var<storage, read_write> buffer_output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties {
  input: float,
  bilinear_sampling: float,
};

@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let info_uvw = BindingInfo(uint(buffer_uvw[0]), buffer_uvw[1] != 0.0);
  let info_input = BindingInfo(uint(buffer_input[0]), buffer_input[1] != 0.0);
  let info_output = BindingInfo(uint(buffer_output[0]), buffer_output[1] != 0.0);

  let bilinear_sampling = uint(properties.bilinear_sampling) != 0u;
  let index = get_index(coord, resolution);

  if (info_uvw.connected) {
    let distort_uvw = float3(fmod(buffer_uvw[index * 3 + 0], 1.0), fmod(buffer_uvw[index * 3 + 1], 1.0), fmod(buffer_uvw[index * 3 + 2], 1.0));
    
    for (var i = 0u; i < info_input.stride; i++) {
      if (bilinear_sampling) {
        buffer_output[index * info_input.stride + i] = select(0.0, sample_buffer(&buffer_input, resolution, distort_uvw, info_input.stride, i), info_input.connected);
      } else {
        let distort_coord = uint3(distort_uvw * float3(resolution));
        let distort_index = get_index(distort_coord, resolution);
        buffer_output[index * info_input.stride + i] = select(0.0, buffer_input[distort_index * info_input.stride + i], info_input.connected);
      }
    }
  } else {
    for (var i = 0u; i < info_input.stride; i++) {
      buffer_output[index * info_input.stride + i] = buffer_input[index * info_input.stride + i];
    }
  }
}