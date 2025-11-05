<template>
  <div class="m-2">
    <div class="input-group input-group-sm mb-1">
      <select class="form-select" v-model.number="properties.operation">
        <option v-for="(operation, i) in operations" :value="i">{{ operation }}</option>
      </select>
    </div>
    <Slot :binding="bindings[0]" v-slot="{ connected }">
      <div class="input-group input-group-sm">
        <Slider v-model="properties.a" :disabled="connected" label="A" />
      </div>
    </Slot>
    <Slot :binding="bindings[1]" v-slot="{ connected }">
      <div class="input-group input-group-sm">
        <Slider v-model="properties.b" :disabled="connected" label="B" />
      </div>
    </Slot>
    <Slot :binding="bindings[2]">Output</Slot>
  </div>
</template>

<script lang="ts">
import shader from "./Math.wgsl?raw" with { type: "text" };
import { utilsShader, getNodePropertiesData } from "./../../utils.ts" with { type: "text" };
import { watch } from "vue";

const defaultProperties = {
  operation: 0,
  a: 0.5,
  b: 0.5,
};
const bindings = [
  { id: "inputA", index: 0, format: 0, output: false },
  { id: "inputB", index: 1, format: 0, output: false },
  { id: "output", index: 2, format: 0, output: true }
];
const operations = [
  "Add",
  "Substract",
  "Multiply",
  "Divide",
  "Power",
  "Log",
  "Square root",
  "Inverse square root",
  "Absolute",
  "Exp",
  "Min",
  "Max",
  "Less than",
  "Greater than",
  "Sign",
  "Round",
  "Floor",
  "Ceil",
  "Fraction",
  "Modulo",
  "Sine",
  "Cosine",
  "Tangent",
  "Arcsine",
  "Arccosine",
  "Arctangent",
  "Arctan2",
  "Hyperbolic Sine",
  "Hyperbolic Cosine",
  "Hyperbolic Tangent",
];
let pipeline;

export default {
  type: "Math",
  label: "Math",
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
      operations
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