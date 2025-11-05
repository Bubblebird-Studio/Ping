<template>
  <div class="m-2">
    <Slot :binding="bindings[0]">
      <div class="input-group input-group-sm">
        <span class="input-group-text">Input</span>
      </div>
    </Slot>
    <Slot :binding="bindings[1]" v-slot="{ connected }">
      <div class="input-group input-group-sm">
        <Slider v-model="properties.fromMin" :disabled="connected" label="From min" />
      </div>
    </Slot>
    <Slot :binding="bindings[2]" v-slot="{ connected }">
      <div class="input-group input-group-sm">
        <Slider v-model="properties.fromMax" :disabled="connected" label="From max" />
      </div>
    </Slot>
    <Slot :binding="bindings[3]" v-slot="{ connected }">
      <div class="input-group input-group-sm">
        <Slider v-model="properties.toMin" :disabled="connected" label="To min" />
      </div>
    </Slot>
    <Slot :binding="bindings[4]" v-slot="{ connected }">
      <div class="input-group input-group-sm">
        <Slider v-model="properties.toMax" :disabled="connected" label="To max" />
      </div>
    </Slot>
    <Slot :binding="bindings[5]">Output</Slot>
  </div>
</template>

<script lang="ts">
import shader from "./Remap.wgsl?raw" with { type: "text" };
import { utilsShader, getNodePropertiesData } from "./../../utils.ts" with { type: "text" };
import { watch } from "vue";

const defaultProperties = {
  fromMin: 0.0,
  fromMax: 1.0,
  toMin: 0.0,
  toMax: 1.0,
};
const bindings = [
  { id: "input",   index: 0, format: 0, output: false },
  { id: "fromMin", index: 1, format: 0, output: false },
  { id: "fromMax", index: 2, format: 0, output: false },
  { id: "toMin",   index: 3, format: 0, output: false },
  { id: "toMax",   index: 4, format: 0, output: false },
  { id: "output",  index: 5, format: 0, output: true },
];
let pipeline;

export default {
  type: "Remap",
  label: "Remap",
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
      bindings
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