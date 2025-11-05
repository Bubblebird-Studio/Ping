@group(0) @binding(0) var<storage, read> buffer_input: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties {
  euler_rotation: float4,
  resolution: float, // unused
  time: float,
  raymarchingSamples: float,
  bilinear_sampling: float,
  mode: float, // unused
  large: float, // unused
  fog: float,
  playing: float, // unused
};


struct Varyings {
  @builtin(position) position : float4,
  @location(0) uv : float2,
};


fn sampleInput(uvw: float3, resolution: uint3, info_input: BindingInfo, bilinear_sampling: bool) -> float4 {
  let coord = uint3(uvw * float3(resolution));
  let index = get_index(coord, resolution);
  var output = float4(0, 0, 0, 1.0);
  for (var i = 0u; i < info_input.stride; i++) {
    if (bilinear_sampling) {
      output[i] = saturate(select(0.0, sample_buffer(&buffer_input, resolution, uvw, info_input.stride, i), info_input.connected));
    } else {
      output[i] = saturate(select(0.0, buffer_input[index * info_input.stride + i], info_input.connected));
    }
  }
  return output;
}


fn intersectBox(ro: float3, rd: float3, bmin: float3, bmax: float3) -> float2 {
  let inv = 1.0 / rd;
  let t0 = (bmin - ro) * inv;
  let t1 = (bmax - ro) * inv;
  let tmin = max(max(min(t0.x, t1.x), min(t0.y, t1.y)), min(t0.z, t1.z));
  let tmax = min(min(max(t0.x, t1.x), max(t0.y, t1.y)), max(t0.z, t1.z));
  return float2(tmin, tmax); // hit if tmax >= max(tmin, 0)
}


@vertex
fn vertex(@builtin(vertex_index) i: uint) -> Varyings {
  var pos = array<float2, 6>(
    float2(-1.0, -1.0), float2(1.0, -1.0), float2(-1.0, 1.0),
    float2(-1.0, 1.0), float2(1.0, -1.0), float2(1.0, 1.0)
  );
  var output : Varyings;
  output.position = float4(pos[i], 0.0, 1.0);
  output.uv = 0.5 * (pos[i] + float2(1.0));
  output.uv = float2(output.uv.x, 1.0 - output.uv.y);
  return output;
}


@fragment
fn fragment(input: Varyings) -> @location(0) float4 {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));
  let bilinear_sampling = uint(properties.bilinear_sampling) != 0u;

  let info_input = BindingInfo(uint(buffer_input[0]), buffer_input[1] != 0.0);
  let background = float4(saturate((floor(input.uv.x * 8.0) + floor(input.uv.y * 8.0)) % 2.0 * 0.2 + 0.4));
  let output = sampleInput(float3(input.uv, properties.time), resolution, info_input, bilinear_sampling);
  
  return alpha_blend(output, background);
}

@fragment
fn fragmentVolume(input: Varyings) -> @location(0) float4 {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));
  let raymarchingSamples = uint(properties.raymarchingSamples);
  let bilinear_sampling = uint(properties.bilinear_sampling) != 0u;

  let info_input = BindingInfo(uint(buffer_input[0]), buffer_input[1] != 0.0);
  let background = float4(saturate((floor(input.uv.x * 8.0) + floor(input.uv.y * 8.0)) % 2.0 * 0.2 + 0.4));
  let fog_color = float4(1.0, 1.0, 1.0, 0.0);
  var output = float4(0, 0, 0, 0);

  var rotation = QUATERNION_IDENTITY;
  rotation = qmul(rotate_angle_axis(properties.euler_rotation.y, DOWN), rotation);
  rotation = qmul(rotate_angle_axis(properties.euler_rotation.x, RIGHT), rotation);

  let ray_origin = rotate_vector(float3(0.0, 0.0, -6), rotation);
  let ray_direction = rotate_vector(normalize(float3(input.uv * 2.0 - 1.0, 5.0)), rotation);

  let boxMin = float3(-1.0);
  let boxMax = float3(1.0);

  let tHit = intersectBox(ray_origin, ray_direction, boxMin, boxMax);
  let tEnter = max(tHit.x, 0.0) + 0.0001;
  let tExit  = tHit.y;

  if (tExit < tEnter) {
    return background;
  }
  
  let step_inc = 3.0 / float(raymarchingSamples);
  var step = tEnter;

  // raymarcher
  for (var s = 0u; s < raymarchingSamples; s++) {
    var ray_position = ray_origin + ray_direction * step;
    var jitter = rand01(hash_float3(ray_position) + s);
    step += step_inc * (jitter * 0.8 + 0.6);

    var sample = sampleInput(ray_position * 0.5 + 0.5, resolution, info_input, bilinear_sampling);
    sample = float4(mix(sample.rgb, fog_color.rgb, saturate((step - tEnter) / (tExit - 5.0)) * properties.fog), sample.a * 0.75);
    output = alpha_blend(output, sample);
    if (output.a > 0.99) { break; }
    if (step > tExit) { break; }
  }

  return alpha_blend(output, background);
}