<template>
  <div v-if="visible" class="node-container" ref="node" @mousedown.stop
    :class="{'selected': selected, 'active': props.activeNodeId == props.id, 'moving': mouseDown}"
    :style="{ left: position.x + 'px', top: position.y + 'px' }">
    <header class="px-3 py-1"
      @mousedown.stop="onMouseDown">
      {{ label }} {{ evaluated ? "" : "*" }}
    </header>
    <component :is="Nodes[type]" :id="id" :properties="properties" @build="build" @evaluate="evaluate"></component>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, useTemplateRef, reactive , onMounted, onUnmounted } from "vue";
import Nodes from "./../components/nodes.ts";

const node = useTemplateRef("node");
const emit = defineEmits(["mousedown", "mouseup", "ongrab", "update:selected", "update:activeNodeId", "build", "update:evaluated", "markDirty"]);
const props = defineProps({
  id: {
    type: String,
    required: true
  },
  title: {
    type: String,
    default: 'Node'
  },
  visible: {
    type: Boolean,
    default: true
  },
  selected: {
    type: Boolean,
    default: false
  },
  type: {
    type: String,
    default: 'Math'
  },
  activeNodeId: {
    type: String,
    default: ""
  },
  properties: {
    type: Object,
    default: () => ({})
  },
  evaluated: {
    type: Boolean,
    default: false
  },
  position: {
    type: Object,
    default: () => ({ x: 0, y: 0 })
  },
  zoom: {
    type: Number,
    default: 1
  }
});

const label = computed(() => Nodes[props.type].label);
const hasMoved = ref(false);
const mouseDown = ref(false);

onMounted(() => {
  if (node.value) {
    [...node.value.querySelectorAll("[data-bs-toggle='tooltip']")].map(e => new bootstrap.Tooltip(e)); // doesn't work on hidden panels: use v-show instead of v-if
  }
  window.addEventListener('mousemove', onMouseMove);
  window.addEventListener('mouseup', onMouseUp);
});


onUnmounted(() => {
  window.removeEventListener('mousemove', onMouseMove);
})


function onMouseDown(event: MouseEvent) {
  mouseDown.value = true;
  hasMoved.value = false;
  emit("update:activeNodeId", props.id);
  //emit("mousedown", props.id);
  //emit("update:selected", true);
}


function onMouseUp(event: MouseEvent) {
  mouseDown.value = false;
  //if (hasMoved.value == false) emit("update:selected", false)
}


function onMouseMove(event: MouseEvent) {
  if (mouseDown.value) {
    hasMoved.value = true;
    emit("markDirty");
    emit('ongrab', { movementX: event.movementX / props.zoom, movementY: event.movementY / props.zoom });
  }
}


function build() {
  emit('build');
  emit("markDirty");
}


function evaluate() {
  emit('update:evaluated', false);
  emit("markDirty");
}
</script>

<style lang="scss" scoped>
.node-container {
  position: absolute;
  background-color: var(--bs-secondary-bg);
  border: 1px solid var(--bs-secondary-bg);
  border-radius: 8px;
  pointer-events: all;
  min-width: 250px;
  box-shadow: 1px 1px 12px 0px #0000009e;
  transform: translate(-50%, -50%);

  &.selected {
    border-color: var(--bs-primary) !important;
  }

  &.active {
    border-color: var(--bs-secondary);
    z-index: 1;
  }

  header {
    text-align: center;
    user-select: none;
    background-color: var(--bs-body-bg);
    border-radius: 8px 8px 0 0;
    cursor: grab;
  }

  &.moving {
    header {
      cursor: grabbing;
    }
  }
}
</style>