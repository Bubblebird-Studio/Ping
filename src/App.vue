<template>
  <div class="app-container" ref="container">
    <Nodeboard ref="nodeboard" tabindex="-1"
      :nodes="settings.nodes.concat([cursor])"
      :edges="settings.edges.concat([cursorEdge])"
      @linkstart="onLinkStart"
      @linkmove="onLinkMove"
      @linkend="onLinkEnd"
      @click="onNodeboardClick"
      @contextmenu="onContextMenu"
      @mousemove="onMouseMove"
      @selecting="onSelecting"
      @keyup.delete="onDeleteKey"
      @keyup.space="onSpaceKey"
      @export="exportImage"
      @copy="copyToClipboard"
      @duplicate="duplicate"
      v-model:position="settings.position"
      v-model:zoom="settings.zoom">
      <Edge v-for="edge in settings.edges"
        :key="`${edge.from} -> ${edge.to}`"
        :from="edge.from"
        :fromFormat="edge.fromFormat"
        :to="edge.to"
        :toFormat="edge.toFormat"
        :visible="edge.visible" />
      <Edge
        :from="cursorEdge.from"
        :fromFormat="cursorEdge.fromFormat"
        :to="cursorEdge.to"
        :toFormat="cursorEdge.toFormat"
        :visible="cursorEdge.visible" />
      <Node v-for="node in settings.nodes"
        :key="node.id"
        :id="node.id"
        :title="node.title"
        :visible="node.visible"
        :type="node.type"
        :zoom="settings.zoom"
        :position="node.position"
        v-model:selected="node.selected"
        v-model:evaluated="node.evaluated"
        v-model:properties="node.properties"
        v-model:activeNodeId="activeNodeId"
        @markDirty="dirty = true"
        @ongrab="onNodeGrab"
        @build="needsRebuild = true" />
      <Node 
        :id="cursor.id"
        :visible="cursor.visible"
        :type="cursor.type"
        v-model:position="cursor.position" />
    </Nodeboard>
    <div v-if="settings.nodes.length == 0 && settings.edges.length == 0" class="fixed-top p-5 text-center">
      <h4>There's not much here</h4>
      <p>Try adding a <a href="#" @click="addNode(viewerNode)">Viewer</a> and a <a href="#" @click="displayAddMenu = true">few other nodes</a></p>
      <p>Or load one of our cool <a href="#" @click="displayTemplateMenu = true">templates</a></p>
    </div>
    <div class="position-absolute top-0 start-0 p-3">
      <img src="@/assets/logo.png" class="pe-none user-select-none" alt="ping logo" />
    </div>
    <header class="fixed-top p-1 text-center pe-none user-select-none">
      {{ settings.name }} {{ dirty ? "*" : "" }}
    </header>
    <footer class="fixed-bottom p-1 d-flex justify-content-center align-items-center user-select-none">
      <p><small>Procedural Image Nodal Generator by Bubblebird Studio. <a href="https://bubblebirdstudio.com/" target="_blank">Buy our games</a> to support this tool!</small></p>
    </footer>
    <div class="position-absolute top-50 start-0 translate-middle-y m-3 toolbar">
      <div class="list-group">
        <button type="button" class="list-group-item list-group-item-action active" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Add a node..." @click="displayAddMenu = true">
          <i class="bi bi-plus-lg"></i>
        </button>
        <button type="button" class="list-group-item list-group-item-action" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="New..." @click="newSettings">
          <i class="bi bi-file-earmark-plus"></i>
        </button>
        <button type="button" class="list-group-item list-group-item-action" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Load..." @click="displayLoadMenu = true">
          <i class="bi bi-box-arrow-in-down"></i>
        </button>
        <button type="button" class="list-group-item list-group-item-action" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Save..." @click="displaySaveMenu = true">
          <i class="bi bi-floppy"></i>
        </button>
        <button type="button" class="list-group-item list-group-item-action" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Reset the view" @click="resetView()">
          <i class="bi bi-crosshair"></i>
        </button>
        <button type="button" class="list-group-item list-group-item-action" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Open the help window" @click="displayHelpMenu = true">
          <i class="bi bi-question-circle"></i>
        </button>
        <a role="button" class="list-group-item list-group-item-action" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Visit the GitHub page" href="https://github.com/Bubblebird-Studio/Ping" target="_blank">
          <i class="bi bi-github"></i>
        </a>
      </div>
    </div>
    <div v-if="error != ''" class="fixed-bottom alert alert-danger m-5" role="alert">
      <p>{{ error }}</p>
      <p>Open an issue on <a href="https://github.com/Bubblebird-Studio/Ping/issues" target="_blank">Github</a> to let us know what went wrong.</p>
    </div>
    <div v-if="warning != ''" class="fixed-bottom alert alert-warning m-5" role="warning">
      <p>{{ warning }}</p>
      <button type="button" class="list-group-item list-group-item-action" @click="warning = ''">
        Close <i class="bi bi-x-circle"></i>
      </button>
    </div>
  </div>
  <AddMenu v-if="displayAddMenu" :nodes="Nodes" :position="cursor.position" @addNode="addNode" @close="displayAddMenu = false"/>
  <SaveMenu v-if="displaySaveMenu" :collectionName="collectionName" :settings="settings" @save="saveSettings" @close="displaySaveMenu = false"/>
  <LoadMenu v-if="displayLoadMenu" :collectionName="collectionName" @load="loadSettings" @openTemplateMenu="displayTemplateMenu = true" @close="displayLoadMenu = false"/>
  <TemplateMenu v-if="displayTemplateMenu" @load="loadSettings" @close="displayTemplateMenu = false"/>
  <HelpMenu v-if="displayHelpMenu" @close="displayHelpMenu = false"/>
</template>

<script setup lang="ts">
import { ref, computed, useTemplateRef, reactive, onMounted, watch, nextTick } from "vue";
import { getTiles, getNodePropertiesData } from "./utils.ts";
import Nodeboard from "./components/Nodeboard.vue";
import Node from "./components/Node.vue";
import Edge from "./components/Edge.vue";
import Nodes from "./components/nodes.ts";
import AddMenu from "./components/AddMenu.vue";
import SaveMenu from "./components/SaveMenu.vue";
import LoadMenu from "./components/LoadMenu.vue";
import TemplateMenu from "./components/TemplateMenu.vue";
import HelpMenu from "./components/HelpMenu.vue";
import UPNG from "./UPNG.js";


interface Globals {
  resolution: Resolution;
}

interface Binding {
  id: String;
  index: Number;
  output: Boolean;
  buffer: GPUBuffer;
  nodeItem: NodeTreeItem;
}

interface NodeTreeItem {
  id: string;
  type: string;
  node: Object;
  bindings: Binding[];
  properties: Object;
  propertiesBuffer: GPUBuffer;
  globals: Globals;
  globalsBuffer: GPUBuffer;
  duration: number;
}

let device: any;
let needsRebuild = false;
let lastRenderTimestamp = 0;
let nodeTrees: NodeTreeItem[] = [];

const error = ref("");
const warning = ref("");
const nodeSearch = ref("");
const dirty = ref(false);
const displayAddMenu = ref(false);
const displaySaveMenu = ref(false);
const displayLoadMenu = ref(false);
const displayHelpMenu = ref(false);
const displayTemplateMenu = ref(false);
const collectionName = "ProceduralTextureGeneratorSettingsCollection";
const cursor = ref({ id: "cursor", type: "Cursor", visible: false, position: {x: 0, y: 0} });
const cursorEdge = ref({ from: "cursor/0", fromFormat: 1, to: "cursor/0", toFormat: 1, visible: false });
const container = useTemplateRef("container");
const nodeboard = useTemplateRef("nodeboard");
const activeNodeId = ref("");
const selectedNodes = computed(() => settings.nodes.filter(n => n.selected || n.id == activeNodeId.value));
const settings = reactive({
  name: "Untitled",
  position: { x: 0, y: 0 },
  lastSaved: 0,
  zoom: 0.8,
  nodes: [],
  edges: []
});
const previousSession = localStorage.getItem("previousSession");
const viewerNode = { type: "Viewer", position: { x: 400, y: 0 } }
const BINDING_INFO_BUFFER_SIZE = 8; // [stride (int), connected (bool)]


onMounted(async () => {
  [...container.value.querySelectorAll("[data-bs-toggle='tooltip']")].map(e => new bootstrap.Tooltip(e));
  window.addEventListener("mouseup", onMouseUp);
  const settingsCollection = JSON.parse(localStorage.getItem(collectionName) || "{}");
  const previous = settingsCollection[previousSession];
  if (previous) {
    loadSettings(previous);
  } else {
    displayTemplateMenu.value = true;
  }
  try {
    const adapter = await navigator.gpu.requestAdapter();
    const requiredLimits = {
      maxBufferSize: 2147483644,
      maxStorageBufferBindingSize: 2147483644,
      maxTextureDimension2D: 16384,
      maxComputeInvocationsPerWorkgroup: 512
    };
    if (adapter.limits.maxBufferSize < requiredLimits.maxBufferSize || adapter.limits.maxStorageBufferBindingSize < requiredLimits.maxStorageBufferBindingSize) {
      requiredLimits.maxBufferSize = adapter.limits.maxBufferSize;
      requiredLimits.maxStorageBufferBindingSize = adapter.limits.maxStorageBufferBindingSize;
      warning.value = `Your browser doesn't meet the required buffer size limits. Higher image resolution output might not work.`;
    }
    if (adapter.limits.maxTextureDimension2D < requiredLimits.maxTextureDimension2D) {
      requiredLimits.maxTextureDimension2D = adapter.limits.maxTextureDimension2D;
      warning.value = `Your browser doesn't meet the required texture dimension limit. Higher image resolution output might not work.`;
    }
    if (adapter.limits.maxComputeInvocationsPerWorkgroup < requiredLimits.maxComputeInvocationsPerWorkgroup) {
      requiredLimits.maxComputeInvocationsPerWorkgroup = adapter.limits.maxComputeInvocationsPerWorkgroup;
      warning.value = `Your browser doesn't meet the required compute invocations per workgroup limit. Some nodes might not work as expected.`;
    }
    device = await adapter.requestDevice({ requiredLimits });
    renderLoop();
  } catch(e) {
    error.value = `Your browser doesn't support WebGPU. Error: ${e.message}`;
    console.error(e);
  }
})


function onMouseMove(event) {
  cursor.value.position.x = event.x;
  cursor.value.position.y = event.y;
}


function onSelecting(rect) {
  settings.nodes.forEach(node => {
    node.selected = node.position.x > rect.minX && node.position.x < rect.maxX && node.position.y > rect.minY && node.position.y < rect.maxY
  });
}


function onNodeboardClick(event) {
  settings.nodes.forEach(node => node.selected = false);
  activeNodeId.value = "";
}


function onNodeGrab(event) {
  selectedNodes.value.forEach(node => {
    node.position.x += event.movementX;
    node.position.y += event.movementY;
  });
}


function onMouseUp() {
  cursorEdge.value.visible = false;
  cursorEdge.value.from = "cursor/0";
}


function onLinkStart(event) {
  cursorEdge.value.visible = true;
  cursorEdge.value.from = event.id;
  cursorEdge.value.fromFormat = event.binding.format;
  cursorEdge.value.toFormat = event.binding.format;
}


function onLinkMove(event) {
  const existingEdgeIndex = settings.edges.findIndex(e => e.to == event.id);
  if (existingEdgeIndex != -1) {
    const edgeToRemove = settings.edges[existingEdgeIndex];
    settings.edges.splice(existingEdgeIndex, 1);
    cursorEdge.value.visible = true;
    cursorEdge.value.from = edgeToRemove.from;
    cursorEdge.value.fromFormat = edgeToRemove.fromFormat;
    cursorEdge.value.toFormat = edgeToRemove.toFormat;
  }
  needsRebuild = true;
  dirty.value = true;
}


function onLinkEnd(event) {
  const isOutput = event.binding.output;
  const fromNotSet = cursorEdge.value.from === "cursor/0";
  const selfLinking = cursorEdge.value.from === event.id;
  const sameNode = cursorEdge.value.from.split('/')[0] === event.id.split('/')[0];

  if (!selfLinking && !sameNode && !isOutput && !fromNotSet) {
    const existingEdgeIndex = settings.edges.findIndex(e => e.to === event.id);
    const newEdge = { 
      from: cursorEdge.value.from,
      fromFormat: cursorEdge.value.fromFormat,
      to: event.id,
      toFormat: event.binding.format,
      visible: true
    };

    if (existingEdgeIndex != -1) {
      settings.edges.splice(existingEdgeIndex, 1)
    }
    settings.edges.push(newEdge);
  }
  needsRebuild = true;
  dirty.value = true;
}


function onContextMenu(event) {
  // the timeout prevents from opening the default context menu
  setTimeout(() => {
    displayAddMenu.value = true;
  }, 1);
}


function onDeleteKey() {
  for (const nodeToDelete of selectedNodes.value) {
    settings.nodes.splice(settings.nodes.indexOf(nodeToDelete), 1);
    const edgesToDelete = settings.edges.filter(n => n.to.startsWith(nodeToDelete.id) || n.from.startsWith(nodeToDelete.id));
    for (const edgeToDelete of edgesToDelete) {
      settings.edges.splice(settings.edges.indexOf(edgeToDelete), 1)
    }
  }
  needsRebuild = true;
  dirty.value = true;
}


function onSpaceKey() {
  displayAddMenu.value = true;
}


function addNode({ type, position }) {
  const newNode = {
    id: crypto.randomUUID(),
    type,
    visible: true,
    selected: false,
    position: { x: position.x, y: position.y },
    properties: JSON.parse(JSON.stringify((Nodes[type].defaultProperties))),
  }
  settings.nodes.push(newNode);
  dirty.value = true;
}


function duplicate(event) {
  // edges endpoint mapping
  const nodesIdsMap = new Map();
  if (selectedNodes.value.length == 0) return;
  const duplicatedNodes = [];
  const nodesToDuplicate = selectedNodes.value.map(node => {
    const newNode = JSON.parse(JSON.stringify(node));
    newNode.id = crypto.randomUUID();
    newNode.position.x += 50;
    newNode.position.y += 50;
    duplicatedNodes.push(newNode);
    node.selected = false;
    activeNodeId.value = newNode.id;
    nodesIdsMap.set(node.id, newNode.id);
    return newNode;
  });
  // duplicate the edges that link the selected nodes together as well
  const edgesToDuplicate = settings.edges.filter(edge => nodesIdsMap.keys().some(id => id === edge.from.split("/")[0]) && nodesIdsMap.keys().some(id => id === edge.to.split("/")[0]));
  edgesToDuplicate.forEach(edge => {
    const newEdge = JSON.parse(JSON.stringify(edge));
    const fromNodeId = newEdge.from.split("/")[0];
    const toNodeId = newEdge.to.split("/")[0];
    const newFromId = nodesIdsMap.get(fromNodeId);
    const newToId = nodesIdsMap.get(toNodeId);
    const fromSlot = newEdge.from.split("/")[1];
    const toSlot = newEdge.to.split("/")[1];
    newEdge.from = `${newFromId}/${fromSlot}`;
    newEdge.to = `${newToId}/${toSlot}`;
    newEdge.fromFormat = edge.fromFormat;
    newEdge.toFormat = edge.toFormat;
    newEdge.visible = true;
    settings.edges.push(newEdge);
  });
  settings.nodes.push(...nodesToDuplicate);
  dirty.value = true;
}


function buildTree(node: any, globals: Globals, depth: Number, path: NodeTreeItem[]): NodeTreeItem {
  if (depth > 50) throw new Error(`Infinite loop detected at node ${node.type} (${node.id})`);
  const nodeId = node.id;
  const nodeDescription = Nodes[node.type];
  const propertiesBuffer = device.createBuffer({ label: `Properties (${node.type} ${node.id})`, size: 2048 * 4, usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST });
  const globalsBuffer = device.createBuffer({ label: `Globals (${node.type} ${node.id})`, size: 2048 * 4, usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST });
  const startTime = performance.now();
  node.evaluated = false;
  let nodeTreeItem: NodeTreeItem = path.find(n => n.node.id == node.id);
  if (!nodeTreeItem) {
    nodeTreeItem = {
      id: nodeId,
      type: node.type,
      node,
      bindings: [],
      properties: node.properties,
      propertiesBuffer,
      globals,
      globalsBuffer
    };
    path.push(nodeTreeItem);
  } else {
    return nodeTreeItem;
  }
  nodeDescription.build(device, nodeTreeItem);
  globals = nodeTreeItem.globals;
  device.queue.writeBuffer(globalsBuffer, 0, new Float32Array([globals.resolution.x, globals.resolution.y, globals.resolution.z]));

  for (let { id, index, format, inheritGroup, output } of nodeDescription.bindings) {
    let buffer, nodeItem;

    if (output == false) {
      // INPUTS
      const inputEdges = settings.edges.filter(e => e.to.split("/")[0] === node.id);
      const bindingInputEdge = inputEdges.find(e => e.to.split("/")[1] === id);
      if (bindingInputEdge) {
        const inputNodeId = bindingInputEdge.from.split("/")[0];
        const inputNode = settings.nodes.find(n => n.id === inputNodeId);
        if (!inputNode) throw new Error(`Node "${inputNodeId}" not found`);
        const inputNodeTreeItem = buildTree(inputNode, globals, ++depth, path);
        const outputBindingId = bindingInputEdge.from.split("/")[1];
        const inputBinding = inputNodeTreeItem.bindings.find(b => b.id == outputBindingId);
        if (!inputBinding) throw new Error(`Binding "${outputBindingId}" not found on node ${inputNodeTreeItem.type} (${inputNodeTreeItem.id})`);
        const displayFormat = format <= 0 ? inputBinding.format : format;
        bindingInputEdge.toFormat = displayFormat;
        format = inputBinding.format;
        buffer = inputBinding.buffer;
        nodeItem = inputNodeTreeItem;
      } else {
        format = format <= 0 ? 1 : format;
        buffer = device.createBuffer({
          label: `Binding (${nodeId}/${id})`,
          size: BINDING_INFO_BUFFER_SIZE * 16,
          usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST,
        });
      }
    } else {
      // OUTPUTS
      const outputEdges = settings.edges.filter(e => e.from.split("/")[0] === node.id);
      const bindingOutputEdges = outputEdges.filter(e => e.from.split("/")[1] === id);
      const inheriterBinding = nodeDescription.bindings.find(b => b.format == format && b.output == false);
      const inheritedFormat = nodeTreeItem.bindings.find(b => b.id == inheriterBinding?.id)?.format;
      format = format <= 0 ? inheritedFormat : format;
      bindingOutputEdges.forEach(e => e.fromFormat = format);
      buffer = device.createBuffer({
        label: `Binding (${nodeId}/${id})`,
        size: globals.resolution.x * globals.resolution.y * globals.resolution.z * format * 4 + BINDING_INFO_BUFFER_SIZE * 16, // "* 16" might be necessary for mem alignment
        usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST | GPUBufferUsage.COPY_SRC,
      });
    }

    // write binding infos to let the GPU know the format of the buffer and whether a node is connected or not
    // these infos are written at the begining of each binding buffer, and are of size BINDING_INFO_BUFFER_SIZE
    const hasConnectedNode = nodeItem ? 1.0 : 0.0;
    const bindingInfoData = new Float32Array([format, hasConnectedNode]);
    device.queue.writeBuffer(buffer, 0, bindingInfoData);

    nodeTreeItem.bindings.push({ id, index, format, output, buffer, nodeItem });
  }
  nodeTreeItem.duration = performance.now() - startTime;
  return nodeTreeItem;
}


function evaluateNodeTreeItem(nodeTreeItem: NodeTreeItem, path: NodeTreeItem[]): Boolean {
  const nodeDescription = Nodes[nodeTreeItem.type];
  const entries = [];
  const startTime = performance.now();
  let needEvaluation = !nodeTreeItem.node.evaluated;

  for (const binding of nodeTreeItem.bindings) {
    entries.push({ binding: binding.index, resource: { buffer: binding.buffer } });
    if (binding.nodeItem && binding.output == false) {
      needEvaluation |= evaluateNodeTreeItem(binding.nodeItem, path);
    }
  }
  if (needEvaluation) {
    path.push(nodeTreeItem);
    const commandEncoder = device.createCommandEncoder();
    nodeDescription.evaluate(device, commandEncoder, nodeTreeItem, entries);
    device.queue.submit([commandEncoder.finish()]);
    //nodeTreeItem.node.evaluated = true;
  }
  nodeTreeItem.duration = performance.now() - startTime;
  return needEvaluation;
}


function renderNodeTreeItem(nodeTreeItem: NodeTreeItem, deltaTime: Number) {
  const nodeDescription = Nodes[nodeTreeItem.type];
  const entries = [];

  for (const binding of nodeTreeItem.bindings) {
    entries.push({ binding: binding.index, resource: { buffer: binding.buffer } });
  }
  const commandEncoder = device.createCommandEncoder();
  if (nodeDescription.draw) {
    nodeDescription.draw(device, commandEncoder, nodeTreeItem, entries, deltaTime);
  }
  device.queue.submit([commandEncoder.finish()]);
}


function renderLoop() {
  requestAnimationFrame((timestamp) => {
    if (!lastRenderTimestamp) lastRenderTimestamp = timestamp;
    const deltaTime = (timestamp - lastRenderTimestamp) / 1000;
    try {
      tick(deltaTime);
    } catch (err) {
      console.error(err);
      error.value = err.message
    }
    lastRenderTimestamp = timestamp;
    renderLoop();
  });
}


function tick(deltaTime) {
  if (needsRebuild) {
    nodeTrees = [];
    const endpoints = settings.nodes.filter(n => n.type == "Viewer");
    for (const endpoint of endpoints) {
      const path = []
      const nodeTree = buildTree(endpoint, null, 0, path);
      if (path.length > 0) {
        console.log(`${endpoint.type} [${endpoint.id}] built ${path.length} nodes in ${Math.round(nodeTree.duration * 100) / 100}ms`);
      }
      nodeTrees.push(nodeTree);
    }
  }
  for (const nodeTree of nodeTrees) {
    const path = [];
    evaluateNodeTreeItem(nodeTree, path);
    if (path.length > 0) {
      console.log(`${nodeTree.type} [${nodeTree.id}] evaluated ${path.length} nodes in ${Math.round(nodeTree.duration * 100) / 100}ms`);
    }
  }
  for (const nodeTree of nodeTrees) {
    renderNodeTreeItem(nodeTree, deltaTime);
  }
  for (const p of settings.nodes) p.evaluated = true;
  needsRebuild = false;
}


function newSettings() {
  if (dirty.value) {
    if (confirm("You will lose any unsaved changes. Are you sure?")) {
      displayTemplateMenu.value = true;
    }
  } else {
    displayTemplateMenu.value = true;
  }
}


function resetView() {
  settings.position.x = 0;
  settings.position.y = 0;
  settings.zoom = 1;
}


async function createBlobFromBuffer(gpuBuffer: GPUBuffer, width: Number, height: Number, bitDepth: Number) {
  // Read GPU buffer into CPU memory
  const size = width * height * 4 * 4;
  const readBuffer = device.createBuffer({ size, usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ });
  const encoder = device.createCommandEncoder();
  encoder.copyBufferToBuffer(gpuBuffer, BINDING_INFO_BUFFER_SIZE * 16, readBuffer, 0, size);
  device.queue.submit([encoder.finish()]);

  await readBuffer.mapAsync(GPUMapMode.READ);
  const arrayBuffer = readBuffer.getMappedRange();
  const floatData = new Float32Array(arrayBuffer);
  let png = null;

  if (bitDepth == 8) {
  // Convert float32 (0–1) to 8-bit RGBA
    const u8 = new Uint8Array(width * height * 4);
    for (let i = 0; i < floatData.length; i++) {
      u8[i] = Math.round(Math.min(1.0, Math.max(0.0, floatData[i])) * 255);
    }
    png = UPNG.encode([u8.buffer], width, height, 0); // lossless RGBA8
  } else if (bitDepth == 16) {
    // Convert float32 (0–1) to float16
    const u16 = new Uint16Array(width * height * 4);
    for (let i = 0; i < floatData.length; i++) {
      u16[i] = Math.round(Math.min(1.0, Math.max(0.0, floatData[i])) * 65535);
    }
    // PNG stores data in big-endian, so we need to swap the endianness
    const u16s = swapEndian16(u16);
    png = UPNG.encodeLL([u16s.buffer], width, height, 3, 1, 16); // lossless RGBA16
  }

  const blob = new Blob([png], { type: "image/png" });
  readBuffer.unmap();
  return blob;
}


function swapEndian16(array) {
  const buffer = array.buffer;
  const bytes = new Uint8Array(buffer);
  for (let i = 0; i < bytes.length; i += 2) {
    const tmp = bytes[i];
    bytes[i] = bytes[i + 1];
    bytes[i + 1] = tmp;
  }
  return array;
}

async function exportImage(nodeId: String, bitDepth: Number) {
  try {
    const endpoint = settings.nodes.find(node => node.id === nodeId);
    const nodeTree = buildTree(endpoint, null, 0, []);
    const path = [];
    evaluateNodeTreeItem(nodeTree, path);
    
    const tiles = getTiles(nodeTree.properties.resolution, nodeTree.properties.layout);
    const width = nodeTree.properties.resolution.x * tiles.x;
    const height = nodeTree.properties.resolution.y * tiles.y;
    const blob = await createBlobFromBuffer(nodeTree.bindings[1].buffer, width, height, nodeTree.properties.bitDepth);
    const link = document.createElement("a");
    link.download = nodeTree.properties.filename || "export.png";
    link.href = URL.createObjectURL(blob);
    link.click();
  } catch (e) {
    console.error(e);
    alert("Failed to export image: " + e);
  }
}


async function copyToClipboard(nodeId: String, bitDepth: Number) {
  try {
    const endpoint = settings.nodes.find(node => node.id === nodeId);
    const nodeTree = buildTree(endpoint, null, 0, []);
    const path = [];
    evaluateNodeTreeItem(nodeTree, path);
    
    const tiles = getTiles(nodeTree.properties.resolution, nodeTree.properties.layout);
    const width = nodeTree.properties.resolution.x * tiles.x;
    const height = nodeTree.properties.resolution.y * tiles.y;
    const blob = await createBlobFromBuffer(nodeTree.bindings[1].buffer, width, height, nodeTree.properties.bitDepth);
    const item = new ClipboardItem({ 'image/png': blob as Blob });
    await navigator.clipboard.write([item]);
    alert("Image copied to clipboard!");
  } catch (e) {
    console.error(e);
    alert("Failed to copy: " + e);
  }
}


async function loadSettings(loadedSettings: any) {
  try {
    settings.name = loadedSettings.name;
    settings.position.x = loadedSettings.position.x;
    settings.position.y = loadedSettings.position.y;
    settings.zoom = loadedSettings.zoom;
    settings.lastSaved = loadedSettings.lastSaved;
    settings.nodes.splice(0);
    settings.edges.splice(0);
    for (const node of loadedSettings.nodes) {
      // check properties compatibility
      const defaultProperties = Nodes[node.type].defaultProperties;
      const properties = {}
      for (const key in defaultProperties) {
        const property = node.properties[key];
        const defaultProperty = defaultProperties[key];
        if (typeof property === typeof defaultProperty) {
          properties[key] = property
        } else {
          properties[key] = defaultProperty
        }
      }
      node.properties = properties;
      settings.nodes.push(node);
    }
    for (const edge of loadedSettings.edges) settings.edges.push(edge);
    needsRebuild = true;
    dirty.value = false;
    document.title = loadedSettings.name + " - PING";
    localStorage.setItem("previousSession", settings.name);
  } catch(e) {
    error.value = `There was an error while loading this file. Error: ${e.message}`;
    console.error(e);
  }
}


function saveSettings(settings: Object) {
  try {
    const settingsCollection = JSON.parse(localStorage.getItem(collectionName) || "{}");
    const settingsCopy = JSON.parse(JSON.stringify(settings));
    settingsCopy.lastSaved = (new Date()).toString();
    settingsCollection[settingsCopy.name] = settingsCopy;
    localStorage.setItem(collectionName, JSON.stringify(settingsCollection));
    localStorage.setItem("previousSession", settings.name);
    dirty.value = false;
  } catch(e) {
    alert("Your settings collection is corrupted. Check the console");
    console.error(e);
    console.log(localStorage.getItem(collectionName));
  }
}
</script>

<style lang="scss" scoped>
@use './style.css';

.app-container {
  height: 100vh;

  .toolbar {
    background-color: var(--bs-light-bg-subtle);
    box-shadow: 1px 1px 20px 0px #0000009e;
  }
}
</style>
