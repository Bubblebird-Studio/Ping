<template>
  <div class="m-2" style="width: 450px">
    <small class="font-monospace">[args] coord: uint3, resolution: uint3, input: float[], inputFormat: uint</small>
    <textarea class="form-control font-monospace" id="floatingTextarea" spellcheck="false" style="height: 200px" v-model="properties.functionBody" @keyup.stop></textarea>
    <small class="font-monospace">[return] float4</small>
    <div class="alert alert-danger text-truncate my-1" role="alert" v-if="properties.compilationError != ''">
      {{ properties.compilationError }}
    </div>
    <div class="alert alert-success my-1" role="alert" v-else>
      WGSL Shader successfully compiled
    </div>
    <Slot :binding="bindings[0]">Input</Slot>
    <Slot :binding="bindings[1]">Output</Slot>
  </div>
</template>

<script lang="ts">
import shader from "./Custom.wgsl?raw" with { type: "text" };
import { utilsShader, getNodePropertiesData } from "./../../utils.ts" with { type: "text" };
import { watch } from "vue";

const defaultProperties = {
  functionBody:
`let index = get_index(coord, resolution);
let r = input[index * inputFormat + 0];
let g = input[index * inputFormat + 1];
let b = input[index * inputFormat + 2];
return float4(1.0 - r, 1.0 - g, 1.0 - b, 1.0);`,
  compilationError: "",
};
const bindings = [
  { id: "input",  index: 0, format: 0, output: false },
  { id: "output", index: 1, format: 4, output: true },
];

export default {
  type: "Custom",
  label: "Custom function",
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
  emits: ["build"],
  setup(props, { emit }) {
    watch(() => props.properties.functionBody, () => emit("build"));
    return {
      props,
      bindings
    }
  },
  build(device, nodeTreeItem) {
    const customFunctionBody = `
      fn customFunction(coord: uint3, resolution: uint3, input: ptr<storage, array<float>, read>, inputFormat: uint) -> float4 {
        ${nodeTreeItem.properties.functionBody}
      }
    `;
    const bindGroupLayout = device.createBindGroupLayout({entries: bindings.map(binding => ({binding: binding.index, visibility: GPUShaderStage.COMPUTE, buffer: {type: binding.output ? "storage" : "read-only-storage"}}))});
    const globalsBindGroupLayout = device.createBindGroupLayout({entries: [{binding: 0, visibility: GPUShaderStage.COMPUTE | GPUShaderStage.FRAGMENT, buffer: {type: "uniform"}}]});
    const propertiesBindGroupLayout = device.createBindGroupLayout({entries: [{binding: 0, visibility: GPUShaderStage.COMPUTE, buffer: {type: "uniform"}}]});
    const pipelineLayout = device.createPipelineLayout({bindGroupLayouts: [bindGroupLayout, globalsBindGroupLayout, propertiesBindGroupLayout]});
    let shaderModule = device.createShaderModule({ code: utilsShader+customFunctionBody+shader });

    shaderModule.getCompilationInfo().then(info => {
      let error = ""
      if (info.messages.length > 0) {
        for (const msg of info.messages) {
          error += `${msg.message} (line ${msg.lineNum}, col ${msg.linePos})`;
        }
        console.error(error);
      }
      nodeTreeItem.properties.compilationError = error;
    });
    
    nodeTreeItem.pipeline = device.createComputePipeline({layout: pipelineLayout, compute: {module: shaderModule, entryPoint: "main"}});
  },
  evaluate(device, commandEncoder, nodeTreeItem, entries) {
    const dispatchX = Math.ceil(nodeTreeItem.globals.resolution.x / 8);
    const dispatchY = Math.ceil(nodeTreeItem.globals.resolution.y / 8);
    const dispatchZ = Math.ceil(nodeTreeItem.globals.resolution.z / 8);
    const pass = commandEncoder.beginComputePass();
    pass.setPipeline(nodeTreeItem.pipeline);
    pass.setBindGroup(0, device.createBindGroup({layout: nodeTreeItem.pipeline.getBindGroupLayout(0), entries}));
    pass.setBindGroup(1, device.createBindGroup({layout: nodeTreeItem.pipeline.getBindGroupLayout(1), entries: [{binding: 0, resource: {buffer: nodeTreeItem.globalsBuffer}}]}));
    pass.setBindGroup(2, device.createBindGroup({layout: nodeTreeItem.pipeline.getBindGroupLayout(2), entries: [{binding: 0, resource: {buffer: nodeTreeItem.propertiesBuffer}}]}));
    device.queue.writeBuffer(nodeTreeItem.propertiesBuffer, 0, getNodePropertiesData(nodeTreeItem.properties));
    pass.dispatchWorkgroups(dispatchX, dispatchY, dispatchZ);
    pass.end();
  },
}
</script>