@group(0) @binding(0) var<storage, read> buffer_size: array<float>;
@group(0) @binding(1) var<storage, read> buffer_octaves: array<float>;
@group(0) @binding(2) var<storage, read> buffer_lacunarity: array<float>;
@group(0) @binding(3) var<storage, read_write> buffer_output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties {
  size: float3,
  octaves: float,
  lacunarity: float,
  seamless: float,
  seed: float,
  min: float,
  max: float,
};


fn grad(hash: uint, p: float3) -> float {
  let h = hash & 15;
  return dot(rand_vector(h), p);
}


fn fade(t: float3) -> float3 {
  return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}


@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let index = get_index(coord, resolution);
  let info_size = BindingInfo(uint(buffer_size[0]), buffer_size[1] != 0.0);
  let info_octaves = BindingInfo(uint(buffer_octaves[0]), buffer_octaves[1] != 0.0);
  let info_lacunarity = BindingInfo(uint(buffer_lacunarity[0]), buffer_lacunarity[1] != 0.0);
  let info_output = BindingInfo(uint(buffer_output[0]), buffer_output[1] != 0.0);

  var size = float3(1.0);
  size.x = select(properties.size.x, buffer_size[index * info_size.stride + 0], info_size.connected);
  size.y = select(properties.size.y, buffer_size[index * info_size.stride + 1], info_size.connected);
  size.z = select(properties.size.z, buffer_size[index * info_size.stride + 2], info_size.connected);

  let octaves = uint(select(properties.octaves, buffer_octaves[index * info_octaves.stride], info_octaves.connected));
  let lacunarity = select(properties.lacunarity, buffer_lacunarity[index * info_lacunarity.stride], info_lacunarity.connected);
  let seamless = uint(properties.seamless) != 0u;
  let seed = uint(properties.seed);

  let grid_resolution = int3(floor(float3(1.0) / size));
  let position = float3(coord) / float3(resolution) * float3(grid_resolution);
  var sum = 0.0;

  for (var i = 0u; i < min(octaves, 16u); i++)
  {
    let s = seed + i;
    let attenuation = floor(pow(lacunarity, float(i)));
    let p = position * attenuation;
    let pi = int3(floor(p));
    let pf = fract(p);
    let f = fade(pf);

    let period = select(int3(100000000), int3(grid_resolution * int(attenuation)), seamless);

    let n000 = grad(hash_int3((pi + int3(0, 0, 0)) % period) + s, pf - float3(0, 0, 0));
    let n001 = grad(hash_int3((pi + int3(0, 0, 1)) % period) + s, pf - float3(0, 0, 1));
    let n010 = grad(hash_int3((pi + int3(0, 1, 0)) % period) + s, pf - float3(0, 1, 0));
    let n011 = grad(hash_int3((pi + int3(0, 1, 1)) % period) + s, pf - float3(0, 1, 1));
    let n100 = grad(hash_int3((pi + int3(1, 0, 0)) % period) + s, pf - float3(1, 0, 0));
    let n101 = grad(hash_int3((pi + int3(1, 0, 1)) % period) + s, pf - float3(1, 0, 1));
    let n110 = grad(hash_int3((pi + int3(1, 1, 0)) % period) + s, pf - float3(1, 1, 0));
    let n111 = grad(hash_int3((pi + int3(1, 1, 1)) % period) + s, pf - float3(1, 1, 1));

    let x00 = mix(n000, n100, f.x);
    let x01 = mix(n001, n101, f.x);
    let x10 = mix(n010, n110, f.x);
    let x11 = mix(n011, n111, f.x);

    let y0 = mix(x00, x10, f.y);
    let y1 = mix(x01, x11, f.y);

    sum += mix(y0, y1, f.z) / attenuation;
  }

  buffer_output[index] = remap(sum, -1.0, 1.0, properties.min, properties.max);
}