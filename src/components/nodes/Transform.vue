<template>
  <div class="m-2">
    <Slot :binding="bindings[0]" v-slot="{ connected }">
      <div class="input-group input-group-sm mb-1">
        <label class="input-group-text">Position</label>
        <Slider v-model="properties.position[0]" :disabled="connected" label="X" />
        <Slider v-model="properties.position[1]" :disabled="connected" label="Y" />
        <Slider v-model="properties.position[2]" :disabled="connected" label="Z" />
      </div>
    </Slot>
    <Slot :binding="bindings[1]" v-slot="{ connected }">
      <div class="input-group input-group-sm mb-1">
        <label class="input-group-text">Rotation</label>
        <Slider v-model="properties.rotation[0]" :disabled="connected" label="X" />
        <Slider v-model="properties.rotation[1]" :disabled="connected" label="Y" />
        <Slider v-model="properties.rotation[2]" :disabled="connected" label="Z" />
      </div>
    </Slot>
    <Slot :binding="bindings[2]" v-slot="{ connected }">
      <div class="input-group input-group-sm mb-1">
        <label class="input-group-text">Scale</label>
        <Slider v-model="properties.scale[0]" :disabled="connected" label="X" />
        <Slider v-model="properties.scale[1]" :disabled="connected" label="Y" />
        <Slider v-model="properties.scale[2]" :disabled="connected" label="Z" />
      </div>
    </Slot>
    <div class="input-group input-group-sm">
      <label class="input-group-text" for="bilinearSampling">Smoothed</label>
      <div class="input-group-text">
        <input class="form-check-input mt-0" type="checkbox" id="bilinearSampling" v-model="properties.bilinearSampling">
      </div>
    </div>
    <Slot :binding="bindings[3]" v-slot="{ connected }">
      <div class="input-group input-group-sm">
        <Slider v-model="properties.input" :disabled="connected" label="Input" />
      </div>
    </Slot>
    <Slot :binding="bindings[4]">Output</Slot>
  </div>
</template>

<script lang="ts">
import shader from "./Transform.wgsl?raw" with { type: "text" };
import { utilsShader, getNodePropertiesData } from "./../../utils.ts" with { type: "text" };
import { watch } from "vue";

const defaultProperties = {
  position: [0.0, 0.0, 0.0, 0],
  rotation: [0.0, 0.0, 0.0, 0],
  scale: [1.0, 1.0, 1.0, 0],
  input: 0.0,
  bilinearSampling: true,
};
const bindings = [
  { id: "position", index: 0, format: 3, output: false },
  { id: "rotation", index: 1, format: 3, output: false },
  { id: "scale",    index: 2, format: 3, output: false },
  { id: "input",    index: 3, format: 0, output: false },
  { id: "output",   index: 4, format: 0, output: true },
];
let pipeline;

export default {
  type: "Transform",
  label: "Transform",
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