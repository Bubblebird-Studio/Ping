@group(0) @binding(0) var<storage, read> buffer_scale: array<float>;
@group(0) @binding(1) var<storage, read> buffer_bump: array<float>;
@group(0) @binding(2) var<storage, read_write> buffer_output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties {
  scale: float,
  format_x: float,
  format_y: float,
  format_z: float,
  remap: float,
};


@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let scale = float(properties.scale);
  let format_x = uint(properties.format_x);
  let format_y = uint(properties.format_y);
  let format_z = uint(properties.format_z);
  let remap = uint(properties.remap) != 0u;

  let info_scale = BindingInfo(uint(buffer_scale[0]), buffer_scale[1] != 0.0);
  let info_bump = BindingInfo(uint(buffer_bump[0]), buffer_bump[1] != 0.0);

  let index = get_index(coord, resolution);
  let indexL = get_index_offset(coord, resolution, int3(1, 0, 0));
  let indexT = get_index_offset(coord, resolution, int3(0, 1, 0));
  let indexF = get_index_offset(coord, resolution, int3(0, 0, 1));

  let s = select(scale, buffer_scale[index * info_scale.stride], info_scale.connected) * 0.1;

  let normal = float3(
    (buffer_bump[indexL * info_bump.stride] - buffer_bump[index * info_bump.stride]) * float(resolution.x) * s,
    (buffer_bump[indexT * info_bump.stride] - buffer_bump[index * info_bump.stride]) * float(resolution.y) * s,
    (buffer_bump[indexF * info_bump.stride] - buffer_bump[index * info_bump.stride]) * float(resolution.z) * s,
  );

  var output = normal;

  if (format_x == 0u) { output.x = normal.x; }
  if (format_x == 1u) { output.x = normal.y; }
  if (format_x == 2u) { output.x = normal.z; }
  if (format_x == 3u) { output.x = -normal.x; }
  if (format_x == 4u) { output.x = -normal.y; }
  if (format_x == 5u) { output.x = -normal.z; }
  if (format_x == 6u) { output.x = 0.0; }
  if (format_x == 7u) { output.x = 1.0; }

  if (format_y == 0u) { output.y = normal.x; }
  if (format_y == 1u) { output.y = normal.y; }
  if (format_y == 2u) { output.y = normal.z; }
  if (format_y == 3u) { output.y = -normal.x; }
  if (format_y == 4u) { output.y = -normal.y; }
  if (format_y == 5u) { output.y = -normal.z; }
  if (format_y == 6u) { output.y = 0.0; }
  if (format_y == 7u) { output.y = 1.0; }

  if (format_z == 0u) { output.z = normal.x; }
  if (format_z == 1u) { output.z = normal.y; }
  if (format_z == 2u) { output.z = normal.z; }
  if (format_z == 3u) { output.z = -normal.x; }
  if (format_z == 4u) { output.z = -normal.y; }
  if (format_z == 5u) { output.z = -normal.z; }
  if (format_z == 6u) { output.z = 0.0; }
  if (format_z == 7u) { output.z = 1.0; }

  output = select(output, output * 0.5 + 0.5, remap);

  buffer_output[index * 3 + 0] = output.x;
  buffer_output[index * 3 + 1] = output.y;
  buffer_output[index * 3 + 2] = output.z;
}