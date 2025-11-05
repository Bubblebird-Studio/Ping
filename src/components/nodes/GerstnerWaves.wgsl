@group(0) @binding(0) var<storage, read_write> buffer_output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties {
  height: float,
  length: float,
  steepness: float,
  speed: float,
};

// Function to calculate Gertsner wave
fn gertsnerWave(uvw: float3, height: float, length: float, steepness: float, direction: float2, speed: float) -> float {
  let k = TAU / length;
  let w = speed * k;

  let phase = k * dot(direction, uvw.xy) - w * uvw.z;
  
  var wave = cos(phase);
  wave = sign(wave) * pow(abs(wave), steepness);
  return height * wave;
}


@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let index = get_index(coord, resolution);
  let uvw = float3(coord) / float3(resolution);
  let domainSize = 1.0;

  var v = 0.0;

  for (var i = 0u; i < 1u; i++) {
    let n = float(i) / 8.0;
    let angle = TAU * n * 0.2;
    let dir = float2(1.0, 0.0); //float2(cos(angle), sin(angle));

    let length = properties.length * (1.15 + n);

    var cycles = round(domainSize / max(length, 1e-4));
    cycles = max(cycles, 1); // at least 1 cycle
    
    let height = properties.height * (1.25 + n);
    let speed = properties.speed * (1.05 + n);
    let wave = gertsnerWave(uvw, height, domainSize / cycles, properties.steepness, dir, speed);
    v += wave;
  }

  buffer_output[index] = v * 0.5 + 0.5;
}