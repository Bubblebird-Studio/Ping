<template>
  <div class="m-2">
    <div class="input-group input-group-sm mb-1">
      <Slider v-model="properties.amount" label="Amount" min="0" max="256" decimals="0" />
    </div>
    <div class="input-group input-group-sm mb-1">
      <label class="input-group-text">Size</label>
      <Slider v-model="properties.size[0]" label="X" min="0.01" max="1.0" />
      <Slider v-model="properties.size[1]" label="Y" min="0.01" max="1.0" />
      <Slider v-model="properties.size[2]" label="Z" min="0.01" max="1.0" />
    </div>
    <div class="input-group input-group-sm mb-1">
      <label class="input-group-text">Position jitter</label>
      <Slider v-model="properties.positionJitter[0]" label="X" min="0.0" max="1.0" />
      <Slider v-model="properties.positionJitter[1]" label="Y" min="0.0" max="1.0" />
      <Slider v-model="properties.positionJitter[2]" label="Z" min="0.0" max="1.0" />
    </div>
    <div class="input-group input-group-sm mb-1">
      <label class="input-group-text">Rotation jitter</label>
      <Slider v-model="properties.rotationJitter[0]" label="X" min="0.0" max="1.0" />
      <Slider v-model="properties.rotationJitter[1]" label="Y" min="0.0" max="1.0" />
      <Slider v-model="properties.rotationJitter[2]" label="Z" min="0.0" max="1.0" />
    </div>
    <div class="input-group input-group-sm mb-1">
      <label class="input-group-text">Size jitter</label>
      <Slider v-model="properties.sizeJitter[0]" label="X" min="0.0" max="1.0" />
      <Slider v-model="properties.sizeJitter[1]" label="Y" min="0.0" max="1.0" />
      <Slider v-model="properties.sizeJitter[2]" label="Z" min="0.0" max="1.0" />
    </div>
    <div class="input-group input-group-sm input-group-sm">
      <label class="input-group-text" for="seed">Seed</label>
      <input type="number" class="form-control flex-grow-0" style="width: 100px" v-model.number="properties.seed" id="seed">
      <button class="btn btn-outline-secondary" type="button" @click="properties.seed = getRandomSeed()"><i class="bi bi-arrow-clockwise"></i></button>
      <span class="input-group-text" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Defines the starting point for random number generation, producing different noise patterns.">
        <i class="bi bi-question"></i>
      </span>
    </div>
    <Slot :binding="bindings[0]" v-slot="{ connected }">
      <div class="input-group input-group-sm mb-1">
        <ColorPicker v-model="properties.input" :disabled="connected"></ColorPicker>
      </div>
    </Slot>
    <Slot :binding="bindings[1]">
      <div class="input-group input-group-sm">
        <span class="input-group-text">Mask</span>
      </div>
    </Slot>
    <Slot :binding="bindings[2]">Output</Slot>
  </div>
</template>

<script lang="ts">
import shader from "./Scatterer.wgsl?raw" with { type: "text" };
import { utilsShader, getNodePropertiesData, getRandomSeed } from "./../../utils.ts" with { type: "text" };
import { watch } from "vue";

const defaultProperties = {
  input: [1.0, 1.0, 1.0, 1.0],
  size: [0.5, 0.5, 0.5, 0],
  positionJitter: [1.0, 1.0, 0.0, 0],
  sizeJitter: [0.5, 0.5, 0.0, 0],
  rotationJitter: [0.0, 0.0, 1.0, 0],
  amount: 2,
  seed: 1234,
};
const bindings = [
  { id: "input",  index: 0, format: 4, output: false },
  { id: "mask",   index: 1, format: 1, output: false },
  { id: "output", index: 2, format: 4, output: true },
];
let pipeline;

export default {
  type: "Scatterer",
  label: "Scatterer",
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