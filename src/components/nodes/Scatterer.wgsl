@group(0) @binding(0) var<storage, read> buffer_input: array<float>;
@group(0) @binding(1) var<storage, read> buffer_mask: array<float>;
@group(0) @binding(2) var<storage, read_write> buffer_output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties { // watch out for mem alignment
  input: float4,
  size: float4,
  position_jitter: float4,
  size_jitter: float4,
  rotation_jitter: float4,
  amount: float,
  seed: float,
};


@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));
  let dimensionality = float3(select(0.0, 1.0, resolution.x > 1), select(0.0, 1.0, resolution.y > 1), select(0.0, 1.0, resolution.z > 1));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let index = get_index(coord, resolution);
  let info_input = BindingInfo(uint(buffer_input[0]), buffer_input[1] != 0.0);
  let info_mask = BindingInfo(uint(buffer_mask[0]), buffer_mask[1] != 0.0);
  let info_output = BindingInfo(uint(buffer_output[0]), buffer_output[1] != 0.0);

  let amount = uint(properties.amount);
  let seed = uint(properties.seed);
  var size = properties.size.xyz;
  
  let grid_resolution = int3(floor(float3(1.0) / size));
  var position = float3(coord) / float3(resolution) * float3(grid_resolution);
  //position = position % float3(resolution);

  var output = float4(0.0, 0.0, 0.0, 0.0);

  for (var l = 0u; l < amount; l++) {
    let p = position + dimensionality * float3(float(l % 2) * 0.5, float(l % 3) * 0.5, float(l % 5) * 0.5);
    let pi = int3(floor(p)) % grid_resolution;
    let pf = fract(p);
    let cell_seed = hash_int3(pi) + seed + l;
    let rand_rotation = rand_vector(cell_seed + 5897u);

    var rotation = QUATERNION_IDENTITY;
    rotation = qmul(rotate_angle_axis(properties.rotation_jitter.x * TAU * rand_rotation.x, LEFT), rotation);
    rotation = qmul(rotate_angle_axis(properties.rotation_jitter.y * TAU * rand_rotation.y, UP), rotation);
    rotation = qmul(rotate_angle_axis(properties.rotation_jitter.z * TAU * rand_rotation.z, FORWARD), rotation);

    var cell_pos = (pf - dimensionality * 0.5) * 4.0;
    cell_pos += rand_vector(cell_seed) * properties.position_jitter.xyz;
    cell_pos = rotate_vector(cell_pos, rotation);
    cell_pos /= mix(float3(0.5), float3(rand01(cell_seed)), properties.size_jitter.xyz);

    var uvw = (cell_pos + dimensionality) * 0.5;

    let cell_coord = uint3(uvw * float3(resolution));
    let cell_index = get_index(clamp(cell_coord, uint3(0), resolution), resolution);

    let spherical_mask = step(length(cell_pos), 1.0);
    let mask = select(spherical_mask, buffer_mask[cell_index * info_mask.stride], info_mask.connected);
    var input = float4(0, 0, 0, 0);

    for (var i = 0u; i < info_input.stride; i++) {
      input[i] = select(properties.input[i], buffer_input[cell_index * info_input.stride + i], info_input.connected);
    }

    input.a *= mask;

    output = alpha_blend(input, output);
  }

  buffer_output[index * 4 + 0] = output.r;
  buffer_output[index * 4 + 1] = output.g;
  buffer_output[index * 4 + 2] = output.b;
  buffer_output[index * 4 + 3] = output.a;
}