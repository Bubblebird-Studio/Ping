@group(0) @binding(0) var<storage, read> buffer_input: array<float>;
@group(0) @binding(1) var<storage, read_write> buffer_output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties {
  color1: float4,
  color2: float4,
  color3: float4,
  color4: float4,
  color5: float4,
  color6: float4,
  color7: float4,
  color8: float4,
  color9: float4,
  color10: float4,
  color11: float4,
  color12: float4,
  color13: float4,
  color14: float4,
  color15: float4,
  color16: float4,
  location1: float,
  location2: float,
  location3: float,
  location4: float,
  location5: float,
  location6: float,
  location7: float,
  location8: float,
  location9: float,
  location10: float,
  location11: float,
  location12: float,
  location13: float,
  location14: float,
  location15: float,
  location16: float,
};


@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let info_input = BindingInfo(uint(buffer_input[0]), buffer_input[1] != 0.0);

  let index = get_index(coord, resolution);
  let val = buffer_input[index * info_input.stride];
  
  var gradient = properties.color1;
  gradient = mix(gradient, properties.color2, saturate(remap(val, properties.location1, properties.location2, 0, 1)));
  gradient = mix(gradient, properties.color3, saturate(remap(val, properties.location2, properties.location3, 0, 1)));
  gradient = mix(gradient, properties.color4, saturate(remap(val, properties.location3, properties.location4, 0, 1)));
  gradient = mix(gradient, properties.color5, saturate(remap(val, properties.location4, properties.location5, 0, 1)));
  gradient = mix(gradient, properties.color6, saturate(remap(val, properties.location5, properties.location6, 0, 1)));
  gradient = mix(gradient, properties.color7, saturate(remap(val, properties.location6, properties.location7, 0, 1)));
  gradient = mix(gradient, properties.color8, saturate(remap(val, properties.location7, properties.location8, 0, 1)));
  gradient = mix(gradient, properties.color9, saturate(remap(val, properties.location8, properties.location9, 0, 1)));
  gradient = mix(gradient, properties.color10, saturate(remap(val, properties.location9, properties.location10, 0, 1)));
  gradient = mix(gradient, properties.color11, saturate(remap(val, properties.location10, properties.location11, 0, 1)));
  gradient = mix(gradient, properties.color12, saturate(remap(val, properties.location11, properties.location12, 0, 1)));
  gradient = mix(gradient, properties.color13, saturate(remap(val, properties.location12, properties.location13, 0, 1)));
  gradient = mix(gradient, properties.color14, saturate(remap(val, properties.location13, properties.location14, 0, 1)));
  gradient = mix(gradient, properties.color15, saturate(remap(val, properties.location14, properties.location15, 0, 1)));
  gradient = mix(gradient, properties.color16, saturate(remap(val, properties.location15, properties.location16, 0, 1)));

  buffer_output[index * 4 + 0] = gradient.r;
  buffer_output[index * 4 + 1] = gradient.g;
  buffer_output[index * 4 + 2] = gradient.b;
  buffer_output[index * 4 + 3] = gradient.a;
}