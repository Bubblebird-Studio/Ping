@group(0) @binding(0) var<storage, read> buffer_uvw: array<float>;
@group(0) @binding(1) var<storage, read> buffer_size: array<float>;
@group(0) @binding(2) var<storage, read> buffer_feature_weight1: array<float>;
@group(0) @binding(3) var<storage, read> buffer_feature_weight2: array<float>;
@group(0) @binding(4) var<storage, read> buffer_feature_weight3: array<float>;
@group(0) @binding(5) var<storage, read> buffer_feature_weight4: array<float>;
@group(0) @binding(6) var<storage, read_write> buffer_output: array<float>;
@group(1) @binding(0) var<uniform> globals: Globals;
@group(2) @binding(0) var<uniform> properties: Properties;

struct Properties {
  size: float3,
  feature_weight1: float,
  feature_weight2: float,
  feature_weight3: float,
  feature_weight4: float,
  distance_type: float,
  seamless: float,
  seed: float,
  min: float,
  max: float,
};



@compute @workgroup_size(8, 8, 8)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let resolution = uint3(uint(globals.resolutionX), uint(globals.resolutionY), uint(globals.resolutionZ));

  if (coord.x >= resolution.x || coord.y >= resolution.y || coord.z >= resolution.z) { return; }

  let index = get_index(coord, resolution);

  let info_uvw = BindingInfo(uint(buffer_uvw[0]), buffer_uvw[1] != 0.0);
  let info_size = BindingInfo(uint(buffer_size[0]), buffer_size[1] != 0.0);
  let info_feature_weight1 = BindingInfo(uint(buffer_feature_weight1[0]), buffer_feature_weight1[1] != 0.0);
  let info_feature_weight2 = BindingInfo(uint(buffer_feature_weight2[0]), buffer_feature_weight2[1] != 0.0);
  let info_feature_weight3 = BindingInfo(uint(buffer_feature_weight3[0]), buffer_feature_weight3[1] != 0.0);
  let info_feature_weight4 = BindingInfo(uint(buffer_feature_weight4[0]), buffer_feature_weight4[1] != 0.0);
  
  var size = float3(1.0);
  size.x = select(properties.size.x, buffer_size[index * info_size.stride + 0], info_size.connected);
  size.y = select(properties.size.y, buffer_size[index * info_size.stride + 1], info_size.connected);
  size.z = select(properties.size.z, buffer_size[index * info_size.stride + 2], info_size.connected);

  let feature_weight1 = select(properties.feature_weight1, buffer_feature_weight1[index * info_feature_weight1.stride], info_feature_weight1.connected);
  let feature_weight2 = select(properties.feature_weight2, buffer_feature_weight2[index * info_feature_weight2.stride], info_feature_weight2.connected);
  let feature_weight3 = select(properties.feature_weight3, buffer_feature_weight3[index * info_feature_weight3.stride], info_feature_weight3.connected);
  let feature_weight4 = select(properties.feature_weight4, buffer_feature_weight4[index * info_feature_weight4.stride], info_feature_weight4.connected);
  let distance_type = uint(properties.distance_type);
  let seamless = uint(properties.seamless) != 0u;
  let seed = uint(properties.seed);

  var uvw = float3(coord) / float3(resolution);

  if (info_uvw.connected) {
    uvw.x = fmod(buffer_uvw[index * 3 + 0], 1.0);
    uvw.y = fmod(buffer_uvw[index * 3 + 1], 1.0);
    uvw.z = fmod(buffer_uvw[index * 3 + 2], 1.0);
  }

  let grid_resolution = int3(floor(float3(1.0) / size));
  let cell_size = 1.0 / float3(grid_resolution);
  let cell = int3(floor(uvw * float3(grid_resolution)));

  let weights = float4(feature_weight1, feature_weight2, feature_weight3, feature_weight4);
  var min_distances = float4(999999.0, 999999.0, 999999.0, 999999.0);

  for (var dx = -1; dx <= 1; dx++) {
    for (var dy = -1; dy <= 1; dy++) {
      for (var dz = -1; dz <= 1; dz++) {
        var neighbor_cell = cell + int3(dx, dy, dz);
        if (seamless) {
          neighbor_cell = (neighbor_cell + grid_resolution) % grid_resolution;
        }

        let feature_point = (float3(neighbor_cell) + rand_vector01(hash_int3(neighbor_cell) + seed)) * cell_size;
        var delta = feature_point - uvw;
        if (seamless) {
          delta = min(abs(delta), 1.0 - abs(delta)); // toroidal distance
        }
        delta /= cell_size;
        var dist = 0.0;

        if (distance_type == VORONOI_DISTANCE_TYPE_EUCLIDEAN) {
          dist = length(delta);
        }
        if (distance_type == VORONOI_DISTANCE_TYPE_SQUARED) {
          dist = (delta.x * delta.x + delta.y * delta.y + delta.z * delta.z);
        }
        if (distance_type == VORONOI_DISTANCE_TYPE_MANHATTAN) {
          dist = abs(delta.x) + abs(delta.y) + abs(delta.z);
        }
        if (distance_type == VORONOI_DISTANCE_TYPE_CHEBYSHEV) {
          dist = max(max(abs(delta.x), abs(delta.y)), abs(delta.z));
        }

        // insert sorted
        if (dist < min_distances.x) {
          min_distances.w = min_distances.z;
          min_distances.z = min_distances.y;
          min_distances.y = min_distances.x;
          min_distances.x = dist;
        } else if (dist < min_distances.y) {
          min_distances.w = min_distances.z;
          min_distances.z = min_distances.y;
          min_distances.y = dist;
        } else if (dist < min_distances.z) {
          min_distances.w = min_distances.z;
          min_distances.z = dist;
        } else if (dist < min_distances.w) {
          min_distances.w = dist;
        }
      }
    }
  }

  let noise = dot(min_distances, weights);
  
  buffer_output[index] = remap(noise, 0.0, 1.0, properties.min, properties.max);
}