<template>
  <canvas :id="'canvas_' + id"
    :class="{'volume': properties.mode == 1, 'large': properties.large}"
    @mousedown.stop="onMouseDown">
  </canvas>
  <div class="m-2">
    <div class="input-group input-group-sm mb-1">
      <label class="input-group-text" for="resolution">Resolution</label>
      <div class="input-group-text">
        <input type="range" class="form-range" min="3" max="8" id="resolution" style="width: 92px"
          :value="Math.log2(properties.resolution)"
          @input="event => properties.resolution = 1 << event.target.value">
      </div>
      <label class="input-group-text" for="resolution" style="width: 50px">{{ properties.resolution }}</label>
    </div>
    <div class="input-group input-group-sm mb-1">
      <label class="input-group-text" for="large">XL</label>
      <div class="input-group-text">
        <input class="form-check-input mt-0" type="checkbox" id="large" v-model="properties.large">
      </div>
      <label class="input-group-text" for="bilinearSampling">Smoothed</label>
      <div class="input-group-text">
        <input class="form-check-input mt-0" type="checkbox" id="bilinearSampling" v-model="properties.bilinearSampling">
      </div>
    </div>
    <div class="input-group input-group-sm mb-1">
      <label class="input-group-text" for="modes">Mode</label>
      <select class="form-select" v-model="properties.mode" id="modes">
        <option v-for="(mode, i) in modes" :value="i">{{ mode }}</option>
      </select>
    </div>
    <div class="input-group input-group-sm mb-1" v-if="properties.mode == 1">
      <button class="btn btn-outline-secondary" type="button" @click="resetRotation"><i class="bi bi-crosshair"></i></button>
      <Slider v-model="properties.raymarchingSamples" label="Samples" min="4" max="128" decimals="0" />
      <span v-show="properties.raymarchingSamples > 48" class="input-group-text text-danger" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="High samples value decreases performances!">
        <i class="bi bi-exclamation-triangle-fill"></i>
      </span>
      <Slider v-model="properties.fog" label="Fog" min="0.0" max="1.0" />
    </div>
    <div class="input-group input-group-sm mb-1" v-if="properties.mode == 2">
      <button class="btn btn-outline-secondary" type="button" @click="properties.playing = !properties.playing">
        <i v-if="properties.playing" class="bi bi-pause-fill"></i>
        <i v-else class="bi bi-play-fill"></i>
      </button>
      <Slider v-model="properties.time" label="Time" min="0.0" max="1.0" />
    </div>
    <Slot :binding="bindings[0]">
      <div class="input-group input-group-sm">
        <span class="input-group-text">Input</span>
      </div>
    </Slot>
  </div>
</template>

<script lang="ts">
import shader from "./Viewer.wgsl?raw" with { type: "text" };
import { utilsShader, getNodePropertiesData } from "./../../utils.ts" with { type: "text" };
import renderShader from "./../../renderShader.wgsl?raw" with { type: "text" };
import { ref, watch, onMounted, computed } from "vue";

const bindings = [
  { id: "input", index: 0, format: 4, output: false },
];
const defaultProperties = {
  eulerRotation: [0, 0, 0, 0], // XYZ + mem pad
  resolution: 128,
  time: 0,
  raymarchingSamples: 48,
  bilinearSampling: true,
  mode: 0,
  large: false,
  fog: 0.5,
  playing: false,
};
const modes = ["2D", "3D", "2D animated"];
let pipeline;
let pipelineVolume;


export default {
  type: "Viewer",
  label: "Viewer",
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
  emits: ["evaluate", "build"],
  setup(props, { emit }) {
    const mouseDown = ref(false);

    onMounted(() => {
      window.addEventListener("mousemove", onMouseMove);
      window.addEventListener("mouseup", onMouseUp);
    })

    watch(() => [props.properties.resolution, props.properties.large, props.properties.mode], () => {
      emit("build");
    });

    function onMouseDown() {
      mouseDown.value = true;
    }


    function onMouseMove(event) {
      if (mouseDown.value && props.properties.mode == 1) {
        props.properties.eulerRotation[0] += event.movementX * 0.005;
        props.properties.eulerRotation[1] += event.movementY * 0.005;
      }
    }


    function onMouseUp() {
      mouseDown.value = false;
    }


    function resetRotation() {
      props.properties.eulerRotation[0] = 0;
      props.properties.eulerRotation[1] = 0;
    }


    return {
      props,
      bindings,
      modes,
      onMouseDown,
      resetRotation
    }
  },
  build(device, nodeTreeItem) {
    const format = navigator.gpu.getPreferredCanvasFormat();
    //const format = "rgba16float";
    if (pipeline === undefined) {
      const bindGroupLayout = device.createBindGroupLayout({entries: bindings.map(binding => ({binding: binding.index, visibility: GPUShaderStage.COMPUTE | GPUShaderStage.FRAGMENT, buffer: {type: binding.output ? "storage" : "read-only-storage"}}))});
      const globalsBindGroupLayout = device.createBindGroupLayout({entries: [{ binding: 0, visibility: GPUShaderStage.COMPUTE | GPUShaderStage.FRAGMENT, buffer: { type: "uniform" }}]});
      const propertiesBindGroupLayout = device.createBindGroupLayout({entries: [{ binding: 0, visibility: GPUShaderStage.COMPUTE | GPUShaderStage.FRAGMENT, buffer: { type: "uniform" }}]});
      const pipelineLayout = device.createPipelineLayout({bindGroupLayouts: [bindGroupLayout, globalsBindGroupLayout, propertiesBindGroupLayout]});
      const shaderModule = device.createShaderModule({ code: utilsShader+shader });

      pipeline = device.createRenderPipeline({
        layout: pipelineLayout,
        vertex: { module: shaderModule, entryPoint: "vertex" },
        fragment: { module: shaderModule, entryPoint: "fragment", targets: [{ format }]},
        primitive: { topology: 'triangle-list' }
      });

      pipelineVolume = device.createRenderPipeline({
        layout: pipelineLayout,
        vertex: { module: shaderModule, entryPoint: "vertex" },
        fragment: { module: shaderModule, entryPoint: "fragmentVolume", targets: [{ format }]},
        primitive: { topology: 'triangle-list' }
      });
    }
    const canvas = document.getElementById("canvas_" + nodeTreeItem.id)
    const context = canvas.getContext("webgpu");
    if (!context) throw new Error("Can't get the webgpu context");
    context.configure({ device, format, alphaMode: "opaque" });

    let z = 1;
    if (nodeTreeItem.properties.mode == 1) z = nodeTreeItem.properties.resolution;
    if (nodeTreeItem.properties.mode == 2) z = 128;
    const resolution = {x: nodeTreeItem.properties.resolution, y: nodeTreeItem.properties.resolution, z};
    nodeTreeItem.globals = { resolution }
    nodeTreeItem.context = context;
    canvas.width = 256 * (nodeTreeItem.properties.large ? 2.0 : 1.0);
    canvas.height = 256 * (nodeTreeItem.properties.large ? 2.0 : 1.0);
  },
  evaluate(device, commandEncoder, nodeTreeItem, entries) {},
  draw(device, commandEncoder, nodeTreeItem, entries, deltaTime) {
    const view = nodeTreeItem.context.getCurrentTexture().createView();
    const pass = commandEncoder.beginRenderPass({ colorAttachments: [{ view, clearValue: { r: 0, g: 0, b: 0, a: 1 }, loadOp: 'load', storeOp: 'store' }]});
    if (nodeTreeItem.properties.mode == 1) pass.setPipeline(pipelineVolume);
    else pass.setPipeline(pipeline);
    pass.setBindGroup(0, device.createBindGroup({ layout: pipeline.getBindGroupLayout(0), entries }));
    pass.setBindGroup(1, device.createBindGroup({ layout: pipeline.getBindGroupLayout(1), entries: [ { binding: 0, resource: { buffer: nodeTreeItem.globalsBuffer }}]}));
    pass.setBindGroup(2, device.createBindGroup({ layout: pipeline.getBindGroupLayout(2), entries: [ { binding: 0, resource: { buffer: nodeTreeItem.propertiesBuffer }}]}));
    if (nodeTreeItem.properties.playing) {
      nodeTreeItem.properties.time += 0.1 * deltaTime;
      nodeTreeItem.properties.time %= 1.0;
      nodeTreeItem.properties.time = Math.round(nodeTreeItem.properties.time * 10000.0) / 10000.0;
    }
    device.queue.writeBuffer(nodeTreeItem.propertiesBuffer, 0, getNodePropertiesData(nodeTreeItem.properties));
    pass.draw(6);
    pass.end();
  }
}
</script>

<style lang="scss" scoped>
@use "./../../style.css";

canvas {
  width: 256px;
  height: 256px;

  &.volume {
    cursor: move;
  }

  &.large {
    width: 512px;
    height: 512px;
  }
}
</style>