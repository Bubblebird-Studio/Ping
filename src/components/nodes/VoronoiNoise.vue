<template>
  <div class="m-2" style="width: 330px">
    <Slot :binding="bindings[0]">
      <div class="input-group input-group-sm">
        <label class="input-group-text">UVW</label>
      </div>
    </Slot>
    <Slot :binding="bindings[1]" v-slot="{ connected }">
      <div class="input-group input-group-sm mb-1">
        <label class="input-group-text">Size</label>
        <Slider v-model="properties.size[0]" :disabled="connected" label="X" min="0.01" max="0.5"></Slider>
        <Slider v-model="properties.size[1]" :disabled="connected" label="Y" min="0.01" max="0.5"></Slider>
        <Slider v-model="properties.size[2]" :disabled="connected" label="Z" min="0.01" max="0.5"></Slider>
      </div>
    </Slot>
    <Slot :binding="bindings[2]" v-slot="{ connected }">
      <div class="input-group input-group-sm mb-1">
        <Slider v-model="properties.featureWeight1" :disabled="connected" label="Feature weight 1" min="-2.0" max="2.0" />
      </div>
    </Slot>
    <Slot :binding="bindings[3]" v-slot="{ connected }">
      <div class="input-group input-group-sm mb-1">
        <Slider v-model="properties.featureWeight2" :disabled="connected" label="Feature weight 2" min="-2.0" max="2.0" />
      </div>
    </Slot>
    <Slot :binding="bindings[4]" v-slot="{ connected }">
      <div class="input-group input-group-sm mb-1">
        <Slider v-model="properties.featureWeight3" :disabled="connected" label="Feature weight 3" min="-2.0" max="2.0" />
      </div>
    </Slot>
    <Slot :binding="bindings[5]" v-slot="{ connected }">
      <div class="input-group input-group-sm mb-1">
        <Slider v-model="properties.featureWeight4" :disabled="connected" label="Feature weight 4" min="-2.0" max="2.0" />
      </div>
    </Slot>
    <div class="input-group input-group-sm mb-1">
      <label class="input-group-text" for="distanceType">Distance type</label>
      <select class="form-select" v-model="properties.distanceType" id="distanceType">
        <option v-for="(distanceType, i) in distanceTypes" :value="i">{{ distanceType }}</option>
      </select>
      <span class="input-group-text" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Choose the algorithm to use for distance calculation">
        <i class="bi bi-question"></i>
      </span>
    </div>
    <div class="input-group input-group-sm mb-1">
      <label class="input-group-text" for="seamless">Seamless</label>
      <div class="input-group-text">
        <input class="form-check-input mt-0" type="checkbox" id="seamless" v-model.boolean="properties.seamless">
      </div>
      <span class="input-group-text" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Makes the image tileable.">
        <i class="bi bi-question"></i>
      </span>
    </div>
    <div class="input-group input-group-sm mb-1">
      <label class="input-group-text" for="seed">Seed</label>
      <input type="number" class="form-control flex-grow-0" style="width: 100px" v-model.number="properties.seed" id="seed">
      <button class="btn btn-outline-secondary" type="button" @click="properties.seed = getRandomSeed()"><i class="bi bi-arrow-clockwise"></i></button>
      <span class="input-group-text" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Defines the starting point for random number generation, producing different noise patterns.">
        <i class="bi bi-question"></i>
      </span>
    </div>
    <div class="input-group input-group-sm mb-1">
      <label class="input-group-text">Range</label>
      <Slider v-model="properties.min" label="Min" />
      <Slider v-model="properties.max" label="Max" />
    </div>
    <Slot :binding="bindings[6]">Output</Slot>
  </div>
</template>

<script lang="ts">
import shader from "./VoronoiNoise.wgsl?raw" with { type: "text" };
import { utilsShader, getNodePropertiesData, getRandomSeed } from "./../../utils.ts" with { type: "text" };
import { watch } from "vue";

const defaultProperties = {
  size: [0.2, 0.2, 0.2],
  featureWeight1: 1.0,
  featureWeight2: 0.0,
  featureWeight3: 0.0,
  featureWeight4: 0.0,
  distanceType: 0,
  seamless: true,
  seed: 1234,
  min: 0.0,
  max: 1.0,
};
const bindings = [
  { id: "uvw",            index: 0, format: 3, output: false },
  { id: "size",           index: 1, format: 3, output: false },
  { id: "weightFeature1", index: 2, format: 1, output: false },
  { id: "weightFeature2", index: 3, format: 1, output: false },
  { id: "weightFeature3", index: 4, format: 1, output: false },
  { id: "weightFeature4", index: 5, format: 1, output: false },
  { id: "output",         index: 6, format: 1, output: true },
];
const distanceTypes = ["Euclidean", "Squared", "Manhattan", "Chebyshev"];
let pipeline;

export default {
  type: "VoronoiNoise",
  label: "Voronoi Noise",
  bindings,
  defaultProperties,
  props: {
    id: {
      type: String,
      required: true
    },
    properties: {
      type: Object,
      default: () => defaultProperties
    },
  },
  emits: ["evaluate"],
  setup(props, { emit }) {
    watch(() => props.properties, () => emit('evaluate'), { deep: true });
    return {
      props,
      bindings,
      getRandomSeed,
      distanceTypes
    }
  },
  build(device, nodeTreeItem) {
    if (pipeline) return;
    const bindGroupLayout = device.createBindGroupLayout({entries: bindings.map(binding => ({binding: binding.index, visibility: GPUShaderStage.COMPUTE, buffer: {type: binding.output ? "storage" : "read-only-storage"}}))});
    const globalsBindGroupLayout = device.createBindGroupLayout({entries: [{binding: 0, visibility: GPUShaderStage.COMPUTE | GPUShaderStage.FRAGMENT, buffer: {type: "uniform"}}]});
    const propertiesBindGroupLayout = device.createBindGroupLayout({entries: [{binding: 0, visibility: GPUShaderStage.COMPUTE, buffer: {type: "uniform"}}]});
    const pipelineLayout = device.createPipelineLayout({bindGroupLayouts: [bindGroupLayout, globalsBindGroupLayout, propertiesBindGroupLayout]});
    pipeline = device.createComputePipeline({layout: pipelineLayout, compute: {module: device.createShaderModule({ code: utilsShader+shader }), entryPoint: "main"}});
  },
  evaluate(device, commandEncoder, nodeTreeItem, entries) {
    const dispatchX = Math.ceil(nodeTreeItem.globals.resolution.x / 8);
    const dispatchY = Math.ceil(nodeTreeItem.globals.resolution.y / 8);
    const dispatchZ = Math.ceil(nodeTreeItem.globals.resolution.z / 8);
    const pass = commandEncoder.beginComputePass();
    pass.setPipeline(pipeline);
    pass.setBindGroup(0, device.createBindGroup({layout: pipeline.getBindGroupLayout(0), entries}));
    pass.setBindGroup(1, device.createBindGroup({layout: pipeline.getBindGroupLayout(1), entries: [{binding: 0, resource: {buffer: nodeTreeItem.globalsBuffer}}]}));
    pass.setBindGroup(2, device.createBindGroup({layout: pipeline.getBindGroupLayout(2), entries: [{binding: 0, resource: {buffer: nodeTreeItem.propertiesBuffer}}]}));
    device.queue.writeBuffer(nodeTreeItem.propertiesBuffer, 0, getNodePropertiesData(nodeTreeItem.properties));
    pass.dispatchWorkgroups(dispatchX, dispatchY, dispatchZ);
    pass.end();
  },
}
</script>