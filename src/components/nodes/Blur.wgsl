@group(0) @binding(0) var<storage, read> buffer_input: array<float>;
@group(0) @binding(1) var<storage, read> buffer_scale: array<float>;
@group(0) @binding(2) var<storage, read> buffer_sigma: array<float>;
@group(0) @binding(3) var<storage, read> buffer_samples: array<float>;
@group(0) @binding(4) var<storage, read_write> buffer_tmp: array<float>;
@group(0) @binding(5) var<storage, read_write> buffer_output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties {
  blur_type: f32,
  scale: f32,
  sigma: f32,
  samples: f32
};


fn gaussian(x: float, sigma: float) -> float {
  return exp(-0.5 * (x * x) / (sigma * sigma));
}

@compute @workgroup_size(8, 8, 8)
fn horizontal(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));
  let blur_type = int(properties.blur_type);

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let info_input = BindingInfo(uint(buffer_input[0]), buffer_input[1] != 0.0);
  let info_scale = BindingInfo(uint(buffer_scale[0]), buffer_scale[1] != 0.0);
  let info_sigma = BindingInfo(uint(buffer_sigma[0]), buffer_sigma[1] != 0.0);
  let info_samples = BindingInfo(uint(buffer_samples[0]), buffer_samples[1] != 0.0);
  let info_output = BindingInfo(uint(buffer_output[0]), buffer_output[1] != 0.0);

  let index = get_index(coord, resolution);
  let scale = select(float(properties.scale), buffer_scale[index], info_scale.connected);
  let sigma = select(float(properties.sigma), buffer_sigma[index], info_sigma.connected);
  let samples = min(select(uint(properties.samples), uint(buffer_samples[index]), info_samples.connected), 128u);

  var sum = float4(0.0);
  var weightSum = 0.0;

  for (var i = 0u; i < samples; i++) {
    let uvw = float3(coord) / float3(resolution);
    let n = float(i) / float(samples) * scale;
    let offset = float3(n, n, n) * float3(1, 0, 0);
    let weight = gaussian(n, sigma * scale);
    for (var n = 0u; n < info_input.stride; n++) {
      sum[n] += sample_buffer(&buffer_input, resolution, uvw + offset, info_input.stride, n) * weight;
      sum[n] += sample_buffer(&buffer_input, resolution, uvw - offset, info_input.stride, n) * weight;
    }
    weightSum += weight;
  }

  sum /= weightSum * 2.0;

  for (var n = 0u; n < info_input.stride; n++) {
    buffer_tmp[index * info_output.stride + n] = sum[n];
  }
}


@compute @workgroup_size(8, 8, 8)
fn vertical(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));
  let blur_type = int(properties.blur_type);

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let info_input = BindingInfo(uint(buffer_input[0]), buffer_input[1] != 0.0);
  let info_scale = BindingInfo(uint(buffer_scale[0]), buffer_scale[1] != 0.0);
  let info_sigma = BindingInfo(uint(buffer_sigma[0]), buffer_sigma[1] != 0.0);
  let info_samples = BindingInfo(uint(buffer_samples[0]), buffer_samples[1] != 0.0);
  let info_output = BindingInfo(uint(buffer_output[0]), buffer_output[1] != 0.0);

  let index = get_index(coord, resolution);
  let scale = select(float(properties.scale), buffer_scale[index], info_scale.connected);
  let sigma = select(float(properties.sigma), buffer_sigma[index], info_sigma.connected);
  let samples = min(select(uint(properties.samples), uint(buffer_samples[index]), info_samples.connected), 128u);

  var sum = float4(0.0);

  if (scale > 0) {
    var weightSum = 0.0;

    for (var i = 0u; i < samples; i++) {
      let uvw = float3(coord) / float3(resolution);
      let n = float(i) / float(samples) * scale;
      let offset = float3(n, n, n) * float3(0, 1, 0);
      let weight = gaussian(n, sigma * scale);
      for (var n = 0u; n < info_input.stride; n++) {
        sum[n] += sample_buffer_rw(&buffer_tmp, resolution, uvw + offset, info_input.stride, n) * weight;
        sum[n] += sample_buffer_rw(&buffer_tmp, resolution, uvw - offset, info_input.stride, n) * weight;
      }
      weightSum += weight;
    }
    sum /= weightSum * 2.0;
  } else {
    for (var n = 0u; n < info_input.stride; n++) {
      sum[n] = buffer_input[index * info_input.stride + n];
    }
  }

  for (var n = 0u; n < info_input.stride; n++) {
    buffer_output[index * info_output.stride + n] = sum[n];
  }
}