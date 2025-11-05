<template>
  <svg v-if="visible" class="edge-container">
    <defs>
      <linearGradient :id="`gradient_${from}-${to}`" x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" :stop-color="fromFormatColor" />
        <stop offset="100%" :stop-color="toFormatColor" />
      </linearGradient>
    </defs>
    <g>
      <path
        :d="d"
        class="path"
        :stroke="`url(#gradient_${from}-${to})`"
        fill="none">
      </path>
    </g>
  </svg>
</template>

<script setup lang="ts">
import { ref, computed, getCurrentInstance , onMounted } from "vue";
import Nodes from "./nodes.ts";

const instance = getCurrentInstance();
const update = ref(0);
const props = defineProps({
  from: {
    type: String,
    required: true
  },
  fromFormat: {
    type: Number,
    default: 0
  },
  to: {
    type: String,
    required: true
  },
  toFormat: {
    type: Number,
    default: 0
  },
  visible: {
    type: Boolean,
    default: true
  }
});


const nodeboard = computed(() => {
  return instance.parent;
});


const fromNode = computed(() => {
  const nodes = nodeboard.value.props.nodes;
  const fromNodeId = props.from.split('/')[0];
  return nodes.find(node => node.id === fromNodeId);
})


const toNode = computed(() => {
  const nodes = nodeboard.value.props.nodes;
  const toNodeId = props.to.split('/')[0];
  return nodes.find(node => node.id === toNodeId);
})

const d = computed(() => {
  const u = update.value * 0;
  const fromSlotDot = document.getElementById(props.from);
  const toSlotDot = document.getElementById(props.to);
  const fromNodeSlot = props.from.split('/')[1];
  const toNodeSlot = props.to.split('/')[1];
  const nodeboard = instance.parent;
  const viewport = nodeboard.refs.viewport;
  const zoom = nodeboard.props.zoom;

  let fromX = 0;
  let fromY = 0;
  let toX = 0;
  let toY = 0;
  let viewportX = 0;
  let viewportY = 0;

  if (viewport) {
    const viewportRect = viewport.getBoundingClientRect();
    viewportX = viewportRect.left;
    viewportY = viewportRect.top;
  }
  if (fromNode.value) {
    fromX = fromNode.value.position.x;
    fromY = fromNode.value.position.y;
  }
  if (toNode.value) {
    toX = toNode.value.position.x;
    toY = toNode.value.position.y;
  }
  if (fromSlotDot) {
    const rect = fromSlotDot.getBoundingClientRect();
    fromX = (rect.left - viewportX + rect.width / 2) / zoom + u;
    fromY = (rect.top - viewportY + rect.height / 2) / zoom + u;
  }
  if (toSlotDot) {
    const rect = toSlotDot.getBoundingClientRect();
    toX = (rect.left - viewportX + rect.width / 2) / zoom + u;
    toY = (rect.top - viewportY + rect.height / 2) / zoom + u;
  }

  return `M ${fromX} ${fromY} L ${toX} ${toY}`;
});


const fromFormatColor = computed(() => {
  if (props.fromFormat <= 0) return "#adb5bd";
  if (props.fromFormat == 1) return "#23cd9a";
  if (props.fromFormat == 2) return "#0dcaf0";
  if (props.fromFormat == 3) return "#0d6efd";
  if (props.fromFormat == 4) return "#6f42c1";
});


const toFormatColor = computed(() => {
  if (props.toFormat <= 0) return "#adb5bd";
  if (props.toFormat == 1) return "#23cd9a";
  if (props.toFormat == 2) return "#0dcaf0";
  if (props.toFormat == 3) return "#0d6efd";
  if (props.toFormat == 4) return "#6f42c1";
});


onMounted(() => {
  refresh();
})

function refresh() {
  update.value++;
}

</script>

<style lang="scss" scoped>
.edge-container {
  position: absolute;
  overflow: visible;

  path {
    //stroke: var(--bs-primary);
    stroke-width: 2px;
    pointer-events: none;
    stroke-linecap: round;
    stroke-dasharray: 4 4;
    /* Animate dash offset by one dash+gap so motion is seamless */
    animation: dash-move 0.5s linear infinite;
    filter: drop-shadow(3px 3px 2px rgba(0, 0, 0, 0.7));
  }

  
  /* The animation moves stroke-dashoffset by dash+gap */
  @keyframes dash-move {
    to {
      stroke-dashoffset: -8;
    }
  }
}
</style>