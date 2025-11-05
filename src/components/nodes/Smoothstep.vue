<template>
  <div class="m-2">
    <Slot :binding="bindings[0]" v-slot="{ connected }">
      <div class="input-group input-group-sm">
        <Slider v-model="properties.edge1" :disabled="connected" label="Edge 1" />
      </div>
    </Slot>
    <Slot :binding="bindings[1]" v-slot="{ connected }">
      <div class="input-group input-group-sm">
        <Slider v-model="properties.edge2" :disabled="connected" label="Edge 2" />
      </div>
    </Slot>
    <Slot :binding="bindings[2]" v-slot="{ connected }">
      <div class="input-group input-group-sm">
        <Slider v-model="properties.input" :disabled="connected" label="Input" />
      </div>
    </Slot>
    <Slot :binding="bindings[3]">Output</Slot>
  </div>
</template>

<script lang="ts">
import shader from "./Smoothstep.wgsl?raw" with { type: "text" };
import { utilsShader, getNodePropertiesData } from "./../../utils.ts" with { type: "text" };
import { watch } from "vue";

const defaultProperties = {
  edge1: 0.0,
  edge2: 1.0,
  input: 0.5,
};
const bindings = [
  { id: "edge1",  index: 0, format: 0, output: false },
  { id: "edge2",  index: 1, format: 0, output: false },
  { id: "input",  index: 2, format: 0, output: false },
  { id: "output", index: 3, format: 0, output: true },
];
let pipeline;

export default {
  type: "Smoothstep",
  label: "Smoothstep",
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