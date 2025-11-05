<template>
  <div class="m-2" style="width: 330px">
    <Slot :binding="bindings[0]" v-slot="{ connected }">
      <div class="input-group input-group-sm">
        <label class="input-group-text">Size</label>
        <Slider v-model="properties.size[0]" :disabled="connected" label="X" min="0.01" max="0.5" />
        <Slider v-model="properties.size[1]" :disabled="connected" label="Y" min="0.01" max="0.5" />
        <Slider v-model="properties.size[2]" :disabled="connected" label="Z" min="0.01" max="0.5" />
      </div>
    </Slot>
    <Slot :binding="bindings[1]" v-slot="{ connected }">
      <div class="input-group input-group-sm">
        <Slider v-model="properties.octaves" :disabled="connected" label="Octaves" min="1" max="10" decimals="0" />
        <span class="input-group-text" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Sets the number of noise layers combined to create fractal detail.">
          <i class="bi bi-question"></i>
        </span>
      </div>
    </Slot>
    <Slot :binding="bindings[2]" v-slot="{ connected }">
      <div class="input-group input-group-sm">
        <Slider v-model="properties.lacunarity" :disabled="connected" label="Lacunarity" min="1.0" max="10.0" />
        <span class="input-group-text" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Controls how quickly frequency increases with each octave, affecting texture detail.">
          <i class="bi bi-question"></i>
        </span>
      </div>
    </Slot>
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
    <Slot :binding="bindings[3]">Output</Slot>
  </div>
</template>

<script lang="ts">
import shader from "./PerlinNoise.wgsl?raw" with { type: "text" };
import { utilsShader, getRandomSeed, getNodePropertiesData } from "./../../utils.ts" with { type: "text" };
import { watch } from "vue";

const defaultProperties = {
  size: [0.2, 0.2, 0.2],
  octaves: 3,
  lacunarity: 2.0,
  seamless: true,
  seed: 1234,
  min: 0.0,
  max: 1.0,
};
const bindings = [
  { id: "size",       index: 0, format: 3, output: false },
  { id: "octaves",    index: 1, format: 1, output: false },
  { id: "lacunarity", index: 2, format: 1, output: false },
  { id: "output",     index: 3, format: 1, output: true },
];
let pipeline;

export default {
  type: "PerlinNoise",
  label: "Perlin Noise",
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
      getRandomSeed
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