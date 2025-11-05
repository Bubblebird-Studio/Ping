<template>
  <div class="gradient-container m-2">
    <GradientEditor :stops="props.properties.stops"></GradientEditor>
    <Slot :binding="bindings[0]">
      <div class="input-group input-group-sm">
        <span class="input-group-text">Input</span>
      </div>
    </Slot>
    <Slot :binding="bindings[1]">Output</Slot>
  </div>
</template>

<script lang="ts">
import shader from "./Gradient.wgsl?raw" with { type: "text" };
import { utilsShader, getNodePropertiesData } from "./../../utils.ts" with { type: "text" };
import { watch } from "vue";

const defaultProperties = {
  stops: [
    {
      location: 0.0,
      color: [0, 0, 0, 1],
    },
    {
      location: 1.0,
      color: [1, 1, 1, 1],
    }
  ]
};
const bindings = [
  { id: "input",  index: 0, format: 1, output: false },
  { id: "output", index: 1, format: 4, output: true },
];
const presets = [
  {
    stops: [
      {
        location: 0.0,
        color: [0, 0, 0.5, 1],
      },
      {
        location: 0.5,
        color: [0, 0.4, 1, 1],
      },
      {
        location: 0.55,
        color: [0.3, 1, 1, 0.0],
      }
    ]
  }
]
let pipeline;

function getStopsData(properties) {
  const stops = properties.stops.slice().sort((a, b) => a.location - b.location);
  const colorData = [];
  const locationdData = [];
  let previousStop = { color: [0, 0, 0, 1], location: 1 };
  for (let i = 0; i < 16; i++) {
    const stop = stops[i] || previousStop;
    previousStop = stop;
    colorData.push(stop.color[0]);
    colorData.push(stop.color[1]);
    colorData.push(stop.color[2]);
    colorData.push(stop.color[3]);
    locationdData.push(stop.location);
  }
  return new Float32Array(colorData.concat(locationdData));
}

export default {
  type: "Gradient",
  label: "Gradient",
  bindings,
  presets,
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
    device.queue.writeBuffer(nodeTreeItem.propertiesBuffer, 0, getStopsData(nodeTreeItem.properties));
    pass.dispatchWorkgroups(dispatchX, dispatchY, dispatchZ);
    pass.end();
  },
}
</script>

<style lang="scss" scoped>
.gradient-container {
  width: 350px;
}
</style>