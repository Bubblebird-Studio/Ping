<template>
  <div class="m-2">
    <div class="input-group input-group-sm mb-1">
      <label class="input-group-text" for="filename">Filename</label>
      <input type="text" class="form-control" v-model="properties.filename" id="filename" @keyup.stop>
      <label class="input-group-text" for="filename">.png</label>
    </div>
    <div class="input-group input-group-sm mb-1">
      <label class="input-group-text" for="resolution">Resolution X</label>
      <div class="input-group-text">
        <input type="range" class="form-range" min="0" max="12" id="resolution"
          :value="Math.log2(properties.resolution.x)"
          @input="event => properties.resolution.x = 1 << event.target.value">
      </div>
      <label class="input-group-text" for="resolution" style="width: 50px">{{ properties.resolution.x }}</label>
    </div>
    <div class="input-group input-group-sm mb-1">
      <label class="input-group-text" for="resolution">Resolution Y</label>
      <div class="input-group-text">
        <input type="range" class="form-range" min="0" max="12" id="resolution"
          :value="Math.log2(properties.resolution.y)"
          @input="event => properties.resolution.y = 1 << event.target.value">
      </div>
      <label class="input-group-text" for="resolution" style="width: 50px">{{ properties.resolution.y }}</label>
    </div>
    <div class="input-group input-group-sm mb-1">
      <label class="input-group-text" for="resolution">Resolution Z</label>
      <div class="input-group-text">
        <input type="range" class="form-range" min="0" max="12" id="resolution"
          :value="Math.log2(properties.resolution.z)"
          @input="event => properties.resolution.z = 1 << event.target.value">
      </div>
      <label class="input-group-text" for="resolution" style="width: 50px">{{ properties.resolution.z }}</label>
    </div>
    <!-- <div class="input-group input-group-sm mb-1">
      <label class="input-group-text" for="dimension">Dimension</label>
      <select class="form-select" id="dimension" v-model="properties.dimension">
        <option value="2d">2D</option>
        <option value="3d">3D</option>
      </select>
      <span v-show="properties.dimension == '3d' && properties.resolution > 256" class="input-group-text text-danger" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Resolution is too high for 3d. Generating an image will fall back to 2d.">
        <i class="bi bi-exclamation-triangle-fill"></i>
      </span>
    </div> -->
    <div class="input-group input-group-sm mb-1">
      <label class="input-group-text" for="layout">Layout</label>
      <select class="form-select" :disabled="properties.dimension == '2d'" id="layout" v-model="properties.layout">
        <option value="auto">Auto</option>
        <option value="square">Square</option>
        <option value="horizontal">Horizontal</option>
        <option value="vertical">Vertical</option>
      </select>
      <span class="input-group-text" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Lets you choose how to arrange the tiles (the slices of your volume texture) in 2D.">
        <i class="bi bi-question"></i>
      </span>
    </div>
    <div class="input-group input-group-sm mb-1">
      <label class="input-group-text" for="alphaMode">Alpha Mode</label>
      <select class="form-select" id="alphaMode" v-model.number="properties.alphaMode">
        <option :value="0">None</option>
        <option :value="1">Premultiplied</option>
        <option :value="2">Straight</option>
      </select>
      <span class="input-group-text" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Specifies how alpha channel is handled in the output image.">
        <i class="bi bi-question"></i>
      </span>
    </div>
    <div class="input-group input-group-sm mb-1">
      <label class="input-group-text" for="bitDepth">Bit depth</label>
      <select class="form-select" id="bitDepth" v-model.number="properties.bitDepth" disabled>
        <option :value="8">8 bit per channel</option>
        <option :value="16">16 bit per channel</option>
      </select>
    </div>
    <div class="input-group input-group-sm mb-1">
      {{ properties.resolution.x * tiles.x }} x {{ properties.resolution.y * tiles.y }} pixels<span class="px-2" v-if="tiles.x * tiles.y > 1">({{ tiles.x }} x {{ tiles.y }} tiles)</span>
    </div>
    <div class="btn-group input-group-sm mb-1" role="group">
      <button class="btn btn-primary" type="button" :disabled="tooLarge" @click="exportImage()"><i class="bi bi-download"></i> Export PNG</button>
      <button class="btn btn-secondary" type="button" :disabled="tooLarge" @click="copyImageToClipboard()"><i class="bi bi-copy"></i> Copy</button>
      <span v-show="tooLarge" class="input-group-text text-danger" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="The image size is too high!">
        <i class="bi bi-exclamation-triangle-fill"></i>
      </span>
    </div>
    <Slot :binding="bindings[0]">
      <div class="input-group input-group-sm">
        <span class="input-group-text">Input</span>
      </div>
    </Slot>
  </div>
</template>

<script lang="ts">
import shader from "./Output.wgsl?raw" with { type: "text" };
import { utilsShader, getTiles, getNodePropertiesData } from "./../../utils.ts" with { type: "text" };
import { computed, getCurrentInstance } from "vue";

const defaultProperties = {
  filename: "Texture",
  resolution: { x: 1024, y: 1024, z: 1 },
  layout: "auto",
  alphaMode: 2, // 0: none, 1: premultiplied, 2: straight
  bitDepth: 8, // 8, 16
};
const bindings = [
  { id: "input", index: 0, format: 4, output: false },
  { id: "output", index: 1, format: 4, output: true },
];

let canvas, context, pipeline;

export default {
  type: "Output",
  label: "Output",
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
  setup(props) {
    const instance = getCurrentInstance();
    
    const nodeboard = computed(() => {
      return instance.parent.parent;
    })

    const tiles = computed(() => {
      return getTiles(props.properties.resolution, props.properties.layout);
    })

    const tooLarge = computed(() => {
      return props.properties.resolution.x * tiles.value.x > 16384 || props.properties.resolution.y * tiles.value.y > 16384 ||
             props.properties.resolution.x * props.properties.resolution.y * props.properties.resolution.z * 16 > 2147483644;
    })

    function exportImage() {
      nodeboard.value.emit("export", props.id);
    }

    function copyImageToClipboard() {
      nodeboard.value.emit("copy", props.id);
    }

    return {
      props,
      tiles,
      bindings,
      tooLarge,
      exportImage,
      copyImageToClipboard
    }
  },
  build(device, nodeTreeItem) {
    const format = navigator.gpu.getPreferredCanvasFormat();
    if (pipeline === undefined) {
      const bindGroupLayout = device.createBindGroupLayout({entries: bindings.map(binding => ({binding: binding.index, visibility: GPUShaderStage.COMPUTE, buffer: {type: binding.output ? "storage" : "read-only-storage"}}))});
      const globalsBindGroupLayout = device.createBindGroupLayout({entries: [{ binding: 0, visibility: GPUShaderStage.COMPUTE, buffer: { type: "uniform" }}]});
      const propertiesBindGroupLayout = device.createBindGroupLayout({entries: [{ binding: 0, visibility: GPUShaderStage.COMPUTE, buffer: { type: "uniform" }}]});
      const pipelineLayout = device.createPipelineLayout({bindGroupLayouts: [bindGroupLayout, globalsBindGroupLayout, propertiesBindGroupLayout]});
      const shaderModule = device.createShaderModule({ code: utilsShader+shader });
      pipeline = device.createComputePipeline({layout: pipelineLayout, compute: {module: shaderModule, entryPoint: "main"}});
    }
    nodeTreeItem.globals = { resolution: nodeTreeItem.properties.resolution };
  },
  evaluate(device, commandEncoder, nodeTreeItem, entries) {
    const tiles = getTiles(nodeTreeItem.properties.resolution, nodeTreeItem.properties.layout);
    const dispatchX = Math.ceil(nodeTreeItem.globals.resolution.x * tiles.x / 8);
    const dispatchY = Math.ceil(nodeTreeItem.globals.resolution.y * tiles.y  / 8);
    const dispatchZ = 1;
    const pass = commandEncoder.beginComputePass();
    const propertiesData = new Float32Array([tiles.x, tiles.y, nodeTreeItem.properties.alphaMode]);
    pass.setPipeline(pipeline);
    pass.setBindGroup(0, device.createBindGroup({ layout: pipeline.getBindGroupLayout(0), entries }));
    pass.setBindGroup(1, device.createBindGroup({ layout: pipeline.getBindGroupLayout(1), entries: [ { binding: 0, resource: { buffer: nodeTreeItem.globalsBuffer }}]}));
    pass.setBindGroup(2, device.createBindGroup({ layout: pipeline.getBindGroupLayout(2), entries: [ { binding: 0, resource: { buffer: nodeTreeItem.propertiesBuffer }}]}));
    device.queue.writeBuffer(nodeTreeItem.propertiesBuffer, 0, propertiesData);
    pass.dispatchWorkgroups(dispatchX, dispatchY, dispatchZ);
    pass.end();
  },
}
</script>