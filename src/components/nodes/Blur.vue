<template>
  <div class="m-2">
    <div class="input-group input-group-sm mb-1">
      <select class="form-select" disabled v-model.number="props.properties.blurType">
        <option v-for="(dir, i) in blurTypes" :value="i">{{ dir }}</option>
      </select>
    </div>
    <Slot :binding="bindings[1]" v-slot="{ connected }">
      <div class="input-group input-group-sm">
        <Slider v-model="properties.scale" label="scale" min="0" max="0.25" />
      </div>
    </Slot>
    <Slot :binding="bindings[2]" v-slot="{ connected }">
      <div class="input-group input-group-sm">
        <Slider v-model="properties.sigma" label="Sigma" min="0.01" max="3.0" />
        <span class="input-group-text" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Standard deviation">
          <i class="bi bi-question"></i>
        </span>
      </div>
    </Slot>
    <Slot :binding="bindings[3]" v-slot="{ connected }">
      <div class="input-group input-group-sm">
        <Slider v-model="properties.samples" label="Samples" min="4" max="64" decimals="0" />
        <span v-show="properties.samples > 48" class="input-group-text text-danger" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="High samples value decreases performances!">
          <i class="bi bi-exclamation-triangle-fill"></i>
        </span>
      </div>
    </Slot>
    <Slot :binding="bindings[0]">
      <div class="input-group input-group-sm">
        <span class="input-group-text">Input</span>
      </div>
    </Slot>
    <Slot :binding="bindings[5]">Output</Slot>
  </div>
</template>

<script lang="ts">
import shader from "./Blur.wgsl?raw" with { type: "text" };
import { utilsShader, getNodePropertiesData } from "./../../utils.ts" with { type: "text" };
import { watch } from "vue";

const type = "Blur";
const defaultProperties = {
  blurType: 0,
  scale: 0.1,
  sigma: 1.0,
  samples: 16,
};
const bindings = [
  { id: "input",   index: 0, format: 0, output: false },
  { id: "scale",   index: 1, format: 1, output: false },
  { id: "sigma",   index: 2, format: 1, output: false },
  { id: "samples", index: 3, format: 1, output: false },
  { id: "tmp",     index: 4, format: 0, output: true }, // intermediary buffer (hidden)
  { id: "output",  index: 5, format: 0, output: true },
];
const blurTypes = ["Box", "Gaussian"];
let horizontalBlurPipeline, verticalBlurPipeline;

export default {
  type,
  label: "Blur",
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
      blurTypes
    }
  },
  build(device) {
    const bindGroupLayout = device.createBindGroupLayout({entries: bindings.map(binding => ({binding: binding.index, visibility: GPUShaderStage.COMPUTE, buffer: {type: binding.output ? "storage" : "read-only-storage"}}))});
    const globalsBindGroupLayout = device.createBindGroupLayout({entries: [{ binding: 0, visibility: GPUShaderStage.COMPUTE | GPUShaderStage.FRAGMENT, buffer: { type: "uniform" }}]});
    const propertiesBindGroupLayout = device.createBindGroupLayout({entries: [{ binding: 0, visibility: GPUShaderStage.COMPUTE, buffer: { type: "uniform" }}]});
    const pipelineLayout = device.createPipelineLayout({bindGroupLayouts: [bindGroupLayout, globalsBindGroupLayout, propertiesBindGroupLayout]});
    horizontalBlurPipeline = device.createComputePipeline({layout: pipelineLayout, compute: {module: device.createShaderModule({ code: utilsShader+shader }), entryPoint: "horizontal" }});
    verticalBlurPipeline = device.createComputePipeline({layout: pipelineLayout, compute: {module: device.createShaderModule({ code: utilsShader+shader }), entryPoint: "vertical" }});
  },
  evaluate(device, commandEncoder, nodeTreeItem, entries) {
    const dispatchX = Math.ceil(nodeTreeItem.globals.resolution.x / 8);
    const dispatchY = Math.ceil(nodeTreeItem.globals.resolution.y / 8);
    const dispatchZ = Math.ceil(nodeTreeItem.globals.resolution.z / 8);
    const pass = commandEncoder.beginComputePass();

    device.queue.writeBuffer(nodeTreeItem.propertiesBuffer, 0, getNodePropertiesData(nodeTreeItem.properties));
    pass.setBindGroup(1, device.createBindGroup({ layout: horizontalBlurPipeline.getBindGroupLayout(1), entries: [ { binding: 0, resource: { buffer: nodeTreeItem.globalsBuffer }}]}));
    pass.setBindGroup(2, device.createBindGroup({ layout: horizontalBlurPipeline.getBindGroupLayout(2), entries: [ { binding: 0, resource: { buffer: nodeTreeItem.propertiesBuffer }}]}));

    pass.setPipeline(horizontalBlurPipeline);
    pass.setBindGroup(0, device.createBindGroup({ layout: horizontalBlurPipeline.getBindGroupLayout(0), entries }));
    pass.dispatchWorkgroups(dispatchX, dispatchY, dispatchZ);

    pass.setPipeline(verticalBlurPipeline);
    pass.setBindGroup(0, device.createBindGroup({ layout: verticalBlurPipeline.getBindGroupLayout(0), entries }));
    pass.dispatchWorkgroups(dispatchX, dispatchY, dispatchZ);
    pass.end();
  },
}
</script>