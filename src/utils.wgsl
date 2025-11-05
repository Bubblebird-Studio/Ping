alias int = i32;
alias int2 = vec2<i32>;
alias int3 = vec3<i32>;
alias int4 = vec4<i32>;

alias uint = u32;
alias uint2 = vec2<u32>;
alias uint3 = vec3<u32>;
alias uint4 = vec4<u32>;

alias float = f32;
alias float2 = vec2<f32>;
alias float3 = vec3<f32>;
alias float4 = vec4<f32>;

alias float3x3 = mat3x3<f32>;
alias float4x4 = mat4x4<f32>;

const PI = 3.14159265358;
const TAU = 6.28318530717;

const NOISE_TYPE_RANDOM = 0;
const NOISE_TYPE_PERLIN = 1;
const NOISE_TYPE_VORONOI = 2;

const VORONOI_DISTANCE_TYPE_EUCLIDEAN = 0;
const VORONOI_DISTANCE_TYPE_SQUARED = 1;
const VORONOI_DISTANCE_TYPE_MANHATTAN = 2;
const VORONOI_DISTANCE_TYPE_CHEBYSHEV = 3;

const BINDING_INFO_BUFFER_SIZE = 8; // the offset at the begining of a binding buffer that is used to carry informations such the buffer stride, or the absence of a connected node
const RENDER_TYPE_BASE = 0;
const RENDER_TYPE_LIT = 1;

const VALUE_TYPE_VALUE = 0;
const VALUE_TYPE_NORMALX = 1;
const VALUE_TYPE_NORMALY = 2;
const VALUE_TYPE_0 = 3;
const VALUE_TYPE_1 = 4;

const UP = float3(1.0, 0.0, 0.0);
const DOWN = float3(-1.0, 0.0, 0.0);
const RIGHT = float3(0.0, 1.0, 0.0);
const LEFT = float3(0.0, -1.0, 0.0);
const FORWARD = float3(0.0, 0.0, 1.0);
const BACK = float3(0.0, 0.0, -1.0);
const QUATERNION_IDENTITY = float4(0.0, 0.0, 0.0, 1.0);

struct Globals {
  resolutionX: float,
  resolutionY: float,
  resolutionZ: float,
};


struct Render {
  renderType: float,
  lightPositionX: float,
  lightPositionY: float,
  activeGenerator: float,
}


struct BindingInfo {
  stride: uint,
  connected: bool,
}


fn remap(value: float, fromMin: float, fromMax: float, toMin: float, toMax: float) -> float {
    return toMin + (value - fromMin) * (toMax - toMin) / (fromMax - fromMin);
}


fn imod(a: int, b: int) -> int {
    return ((a % b) + b) % b;
}


fn fmod(a: float, b: float) -> float {
    return ((a % b) + b) % b;
}


fn fmod3(a: float3, b: float3) -> float3 {
    return ((a % b) + b) % b;
}


fn get_index(coord: uint3, resolution: uint3) -> uint {
  return coord.x + resolution.x * coord.y + resolution.x * resolution.y * coord.z + BINDING_INFO_BUFFER_SIZE;
}


fn get_index_offset(coord: uint3, resolution: uint3, offset: int3) -> uint {
  let x = uint(imod(int(coord.x) + offset.x, int(resolution.x)));
  let y = uint(imod(int(coord.y) + offset.y, int(resolution.y)));
  let z = uint(imod(int(coord.z) + offset.z, int(resolution.z)));
  return x + resolution.x * y + resolution.x * resolution.y * z + BINDING_INFO_BUFFER_SIZE;
}


fn load_vec4(buffer: ptr<storage, array<float>, read>, index: uint, stride: uint) -> float4 {
    let base = index * stride;
    return float4(
      (*buffer)[base + 0u],
      (*buffer)[base + 1u],
      (*buffer)[base + 2u],
      (*buffer)[base + 3u]
    );
}


fn sample_buffer_rw(buffer: ptr<storage, array<float>, read_write>, resolution: uint3, uvw: float3, stride: uint, offset: uint) -> float {
  let texel = (uvw + float3(1.0)) * float3(resolution) - 0.5;
  let base = uint3(texel);
  let frac = texel - float3(base);

  let i000 = get_index_offset(base, resolution, int3(0, 0, 0));
  let i100 = get_index_offset(base, resolution, int3(1, 0, 0));
  let i010 = get_index_offset(base, resolution, int3(0, 1, 0));
  let i110 = get_index_offset(base, resolution, int3(1, 1, 0));
  let i001 = get_index_offset(base, resolution, int3(0, 0, 1));
  let i101 = get_index_offset(base, resolution, int3(1, 0, 1));
  let i011 = get_index_offset(base, resolution, int3(0, 1, 1));
  let i111 = get_index_offset(base, resolution, int3(1, 1, 1));

  let c000 = buffer[i000 * stride + offset];
  let c100 = buffer[i100 * stride + offset];
  let c010 = buffer[i010 * stride + offset];
  let c110 = buffer[i110 * stride + offset];
  let c001 = buffer[i001 * stride + offset];
  let c101 = buffer[i101 * stride + offset];
  let c011 = buffer[i011 * stride + offset];
  let c111 = buffer[i111 * stride + offset];

  let c00 = mix(c000, c100, frac.x);
  let c10 = mix(c010, c110, frac.x);
  let c01 = mix(c001, c101, frac.x);
  let c11 = mix(c011, c111, frac.x);

  let c0 = mix(c00, c10, frac.y);
  let c1 = mix(c01, c11, frac.y);

  return mix(c0, c1, frac.z);
}


fn sample_buffer(buffer: ptr<storage, array<float>, read>, resolution: uint3, uvw: float3, stride: uint, offset: uint) -> float {
  let texel = (uvw + float3(1.0)) * float3(resolution) - 0.5;
  let base = uint3(texel);
  let frac = texel - float3(base);

  let i000 = get_index_offset(base, resolution, int3(0, 0, 0));
  let i100 = get_index_offset(base, resolution, int3(1, 0, 0));
  let i010 = get_index_offset(base, resolution, int3(0, 1, 0));
  let i110 = get_index_offset(base, resolution, int3(1, 1, 0));
  let i001 = get_index_offset(base, resolution, int3(0, 0, 1));
  let i101 = get_index_offset(base, resolution, int3(1, 0, 1));
  let i011 = get_index_offset(base, resolution, int3(0, 1, 1));
  let i111 = get_index_offset(base, resolution, int3(1, 1, 1));

  let c000 = buffer[i000 * stride + offset];
  let c100 = buffer[i100 * stride + offset];
  let c010 = buffer[i010 * stride + offset];
  let c110 = buffer[i110 * stride + offset];
  let c001 = buffer[i001 * stride + offset];
  let c101 = buffer[i101 * stride + offset];
  let c011 = buffer[i011 * stride + offset];
  let c111 = buffer[i111 * stride + offset];

  let c00 = mix(c000, c100, frac.x);
  let c10 = mix(c010, c110, frac.x);
  let c01 = mix(c001, c101, frac.x);
  let c11 = mix(c011, c111, frac.x);

  let c0 = mix(c00, c10, frac.y);
  let c1 = mix(c01, c11, frac.y);

  return mix(c0, c1, frac.z);
}


fn sample_buffer4(buffer: ptr<storage, array<float>, read>, resolution: uint3, stride: uint, uvw: float3) -> float4 {
  let texel = (uvw + float3(1.0)) * float3(resolution);
  let base = uint3(texel);
  let frac = texel - float3(base);

  let i000 = get_index_offset(base, resolution, int3(0, 0, 0));
  let i100 = get_index_offset(base, resolution, int3(1, 0, 0));
  let i010 = get_index_offset(base, resolution, int3(0, 1, 0));
  let i110 = get_index_offset(base, resolution, int3(1, 1, 0));
  let i001 = get_index_offset(base, resolution, int3(0, 0, 1));
  let i101 = get_index_offset(base, resolution, int3(1, 0, 1));
  let i011 = get_index_offset(base, resolution, int3(0, 1, 1));
  let i111 = get_index_offset(base, resolution, int3(1, 1, 1));

  let c000 = load_vec4(buffer, i000, stride);
  let c100 = load_vec4(buffer, i100, stride);
  let c010 = load_vec4(buffer, i010, stride);
  let c110 = load_vec4(buffer, i110, stride);
  let c001 = load_vec4(buffer, i001, stride);
  let c101 = load_vec4(buffer, i101, stride);
  let c011 = load_vec4(buffer, i011, stride);
  let c111 = load_vec4(buffer, i111, stride);

  let c00 = mix(c000, c100, frac.x);
  let c10 = mix(c010, c110, frac.x);
  let c01 = mix(c001, c101, frac.x);
  let c11 = mix(c011, c111, frac.x);

  let c0 = mix(c00, c10, frac.y);
  let c1 = mix(c01, c11, frac.y);

  return mix(c0, c1, frac.z);
}


fn hash_float3(v: float3) -> uint {
    var x: uint = bitcast<uint>(v.x);
    var y: uint = bitcast<uint>(v.y);
    var z: uint = bitcast<uint>(v.z);
    var h: uint = 0xdeadbeefu;
    h ^= x + 0x9e3779b9u + (h << 6) + (h >> 2);
    h ^= y + 0x9e3779b9u + (h << 6) + (h >> 2);
    h ^= z + 0x9e3779b9u + (h << 6) + (h >> 2);
    h ^= h >> 16;
    h *= 0x85ebca6bu;
    h ^= h >> 13;
    h *= 0xc2b2ae35u;
    h ^= h >> 16;
    return h;
}


fn hash_int3(v: int3) -> uint {
    var x: uint = bitcast<uint>(v.x);
    var y: uint = bitcast<uint>(v.y);
    var z: uint = bitcast<uint>(v.z);
    var h: uint = 0xdeadbeefu;
    h ^= x + 0x9e3779b9u + (h << 6) + (h >> 2);
    h ^= y + 0x9e3779b9u + (h << 6) + (h >> 2);
    h ^= z + 0x9e3779b9u + (h << 6) + (h >> 2);
    h ^= h >> 16;
    h *= 0x85ebca6bu;
    h ^= h >> 13;
    h *= 0xc2b2ae35u;
    h ^= h >> 16;
    return h;
}


fn hash_uint(x: uint) -> uint {
  var h = x;
  h ^= h >> 16;
  h *= 0x85ebca6b;
  h ^= h >> 13;
  h *= 0xc2b2ae35;
  h ^= h >> 16;
  return h;
}


fn rand_vector01(hash: uint) -> float3 {
  let x = hash_uint(hash ^ 0xA53C9A1F);
  let y = hash_uint(hash ^ 0xC2B2AE35);
  let z = hash_uint(hash ^ 0x27D4EB2F);
  
  return float3(float(x) / 4294967296.0, float(y) / 4294967296.0, float(z) / 4294967296.0);
}


fn rand_vector(hash: uint) -> float3 {
  return rand_vector01(hash) * 2.0 - 1.0;
}


fn rand01(hash: uint) -> float {
  // Mask to keep only the positive 31 bits
  let mixed = hash_uint(hash);
  let masked: uint = (mixed & 0x7FFFFFFF);
  // Convert to float and normalize to [0.0, 1.0)
  return float(masked) / float(0x7FFFFFFF);
}


fn rand(hash: uint) -> float {
  return rand01(hash) * 2.0 - 1.0;
}


fn alpha_blend(fg: float4, bg: float4) -> float4 {
  let outAlpha = fg.a + bg.a * (1.0 - fg.a);
  if (outAlpha == 0.0) {
    return float4(0.0);
  }

  let outRgb = (fg.rgb * fg.a + bg.rgb * bg.a * (1.0 - fg.a)) / outAlpha;
  return float4(outRgb, outAlpha);
}


// Quaternion multiplication
// http://mathworld.wolfram.com/Quaternion.html
fn qmul(q1: float4, q2: float4) -> float4 {
  return float4(
    q2.xyz * q1.w + q1.xyz * q2.w + cross(q1.xyz, q2.xyz),
    q1.w * q2.w - dot(q1.xyz, q2.xyz)
  );
}

// Vector rotation with a quaternion
// http://mathworld.wolfram.com/Quaternion.html
fn rotate_vector(v: float3, r: float4) -> float3 {
  return qmul(r, qmul(float4(v, 0), r * float4(-1, -1, -1, 1))).xyz;
}


fn rotate_angle_axis(angle: float, axis: float3) -> float4 {
  let sn = sin(angle * 0.5);
  let cs = cos(angle * 0.5);
  return float4(axis * sn, cs);
}


fn from_to_rotation(v1: float3, v2: float3) -> float4 {
  var q = float4(0.0);
  let d = dot(v1, v2);
  if (d < -0.999999) {
      let right = float3(1, 0, 0);
      let up = float3(0, 1, 0);
      var tmp = cross(right, v1);
      if (length(tmp) < 0.000001)
      {
          tmp = cross(up, v1);
      }
      tmp = normalize(tmp);
      q = rotate_angle_axis(PI, tmp);
  } else if (d > 0.999999) {
      q = QUATERNION_IDENTITY;
  } else {
      q = float4(cross(v1, v2), 1 + d);
      q = normalize(q);
  }
  return q;
}