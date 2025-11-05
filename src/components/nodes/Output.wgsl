@group(0) @binding(0) var<storage, read> buffer_input: array<float>;
@group(0) @binding(1) var<storage, read_write> buffer_output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties {
  tilesX: float,
  tilesY: float,
  alphaMode: float, // 0: none, 1: premultiplied, 2: straight
};


@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) layout_coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));
  let tiles = uint2(uint(properties.tilesX), uint(properties.tilesY));
  let alpha_mode = uint(properties.alphaMode);
  let layout_resolution = uint2(resolution.x * tiles.x, resolution.y * tiles.y);
  let layout_index = layout_coord.x + layout_resolution.x * layout_coord.y + BINDING_INFO_BUFFER_SIZE;

  if (layout_coord.x >= layout_resolution.x || layout_coord.y >= layout_resolution.y) { return; }

  let info_input = BindingInfo(uint(buffer_input[0]), buffer_input[1] != 0.0);

  let tile_x = layout_coord.x / resolution.x;
  let tile_y = layout_coord.y / resolution.y;
  let x = layout_coord.x % resolution.x;
  let y = layout_coord.y % resolution.y;
  let z = tile_x + tiles.x * tile_y;
  let coord = uint3(x, y, z);
  let index = get_index(coord, resolution);
  var input = float4(0.0, 0.0, 0.0, 1.0);

  for (var i = 0u; i < info_input.stride; i++) {
    input[i] = saturate(select(0.0, buffer_input[index * info_input.stride + i], info_input.connected));
  }

  if (alpha_mode == 1u) {
    // Premultiplied alpha
    buffer_output[layout_index * 4 + 0] = input[0] * input[3];
    buffer_output[layout_index * 4 + 1] = input[1] * input[3];
    buffer_output[layout_index * 4 + 2] = input[2] * input[3];
    buffer_output[layout_index * 4 + 3] = input[3];
  } else if (alpha_mode == 2u) {
    // Straight alpha
    buffer_output[layout_index * 4 + 0] = input[0];
    buffer_output[layout_index * 4 + 1] = input[1];
    buffer_output[layout_index * 4 + 2] = input[2];
    buffer_output[layout_index * 4 + 3] = input[3];
  } else {
    // No alpha
    buffer_output[layout_index * 4 + 0] = input[0];
    buffer_output[layout_index * 4 + 1] = input[1];
    buffer_output[layout_index * 4 + 2] = input[2];
    buffer_output[layout_index * 4 + 3] = 1.0;
  }
}
