<template>
  <div class="nodeboard-container"
    @keydown.ctrl.d.prevent="emit('duplicate')"
    @contextmenu.prevent
    @mousedown="onMouseDown"
    @wheel.prevent="onScroll">
    <div ref="viewport" class="viewport" :style="style">
      <slot></slot>
      <div v-if="selecting" class="box-selection" :style="boxSelectionStyle"></div>
    </div>
    <div v-if="hasPanned || hasSelected" class="occluder" :class="{'selection': hasSelected, 'panning': hasPanned}"></div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, useTemplateRef, reactive , onMounted, watch, getCurrentInstance } from "vue";

const viewport = useTemplateRef("viewport");
const emit = defineEmits(["click", "contextmenu", "mousemove", "linkstart", "linkmove", "linkend", "selecting", "update:position", "update:zoom", "export", "copy", "duplicate"]);
const props = defineProps({
  position: {
    type: Object
  },
  zoom: {
    type: Number,
    default: 1
  },
  nodes: {
    type: Array,
    default: () => []
  },
  edges: {
    type: Array,
    default: () => []
  }
})

const selectionRect = ref({
  startX: 0,
  startY: 0,
  endX: 0,
  endY: 0,
})
const mousedown = ref(false);
const selecting = ref(false);
const hasSelected = ref(false);
const panning = ref(false);
const hasPanned = ref(false);

const style = computed(() => {
  return {
    transform: `scale(${props.zoom}) translate(${props.position.x}px, ${props.position.y}px)`,
  }
})


const boxSelectionStyle = computed(() => {
  const left = Math.min(selectionRect.value.startX, selectionRect.value.endX);
  const top = Math.min(selectionRect.value.startY, selectionRect.value.endY);
  const right = Math.max(selectionRect.value.startX, selectionRect.value.endX);
  const bottom = Math.max(selectionRect.value.startY, selectionRect.value.endY);
  const width = right - left;
  const height = bottom - top;
  return { left: left + 'px', top: top + 'px', width: width + 'px', height: height + 'px' }
})

onMounted(() => {
  window.addEventListener('mousemove', onMouseMove);
  window.addEventListener('mouseup', onMouseUp);
});


function onMouseDown(event: MouseEvent) {
  mousedown.value = true;
  if (event.which == 1) {
    hasPanned.value = false;
    panning.value = true;
  }
  if (event.which == 3) {
    const viewportRect = viewport.value.getBoundingClientRect();
    const clientX = (event.clientX - viewportRect.left) / props.zoom;
    const clientY = (event.clientY - viewportRect.top) / props.zoom;
    hasSelected.value = false;
    selecting.value = true;
    selectionRect.value.startX = selectionRect.value.endX = clientX;
    selectionRect.value.startY = selectionRect.value.endY = clientY;
  }
}


function onMouseUp(event: MouseEvent) {
  if (event.which == 1) {
    panning.value = false;
    if (mousedown.value == true && hasPanned.value == false) emit('click', event);
    hasPanned.value = false;
  }
  if (event.which == 3) {
    selecting.value = false;
    if (mousedown.value == true && hasSelected.value == false) emit('contextmenu', event);
    hasSelected.value = false;
  }
  mousedown.value = false;
}


function onMouseMove(event: MouseEvent) {
  const viewportRect = viewport.value.getBoundingClientRect();
  const clientX = (event.clientX - viewportRect.left) / props.zoom;
  const clientY = (event.clientY - viewportRect.top) / props.zoom;

  if (selecting.value == true) {
    hasSelected.value = true;

    selectionRect.value.endX = clientX;
    selectionRect.value.endY = clientY;

    emit("selecting", {
      minX: Math.min(selectionRect.value.startX, selectionRect.value.endX),
      minY: Math.min(selectionRect.value.startY, selectionRect.value.endY),
      maxX: Math.max(selectionRect.value.startX, selectionRect.value.endX),
      maxY: Math.max(selectionRect.value.startY, selectionRect.value.endY),
    });
  }
  if (panning.value == true) {
    hasPanned.value = true;
    emit("update:position", {
      x: props.position.x + event.movementX / props.zoom,
      y: props.position.y + event.movementY / props.zoom,
    });
  }
  emit("mousemove", {
    x: clientX,
    y: clientY,
  })
}


function onScroll(event: MouseEvent) {
  const delta = event.wheelDelta * 0.001 * Math.pow(props.zoom, 1.5);
  const zoom = Math.max(0.1, Math.min(props.zoom + delta, 5.0));
  emit("update:zoom", zoom);
}
</script>

<style lang="scss" scoped>
.nodeboard-container {
  height: 100%;
  width: 100%;
  background-color: var(--bs-body-bg);
  overflow: hidden;
  outline: none;

  .viewport {
    position: relative;
    top: 50%;
    left: 50%;
    width: 5000px;
    height: 5000px;
    transform-origin: 0% 0%;
    pointer-events: none;
  }

  .box-selection {
    position: absolute;
    top: 0px;
    left: 0px;
    width: 0px;
    height: 0px;
    background-color: rgba(var(--bs-primary-rgb), 0.25);
    border: 2px dashed var(--bs-primary);
    pointer-events: none;
    z-index: 2;
  }

  .occluder {
    position: absolute;
    top: 0px;
    height: 100%;
    width: 100%;

    &.selection {
      cursor: crosshair;
    }

    &.panning {
      cursor: move;
    }
  }
}
</style>
