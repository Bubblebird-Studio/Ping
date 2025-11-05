<template>
  <div class="slot-container mb-1" :class="`format${Format} ${binding.output ? 'output' : ''}`">
    <div :id="id" class="dot" @mousedown.stop="onMouseDown" @mouseup="onMouseUp">
      <div class="viz"></div>
    </div>
    <div class="label">
      <slot :connected="connected"></slot>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive , onMounted, watch, getCurrentInstance } from "vue";

const instance = getCurrentInstance();
//const emit = defineEmits(['click', 'mousedown', 'mouseup']);
const props = defineProps({
  binding: {
    type: Object
  }
});


const nodeboard = computed(() => {
  return instance.parent.parent.parent;
});


const id = computed(() => {
  return `${instance.parent.props.id}/${props.binding.id}`;
})

const inputEdges = computed(() => {
  return nodeboard.value.props.edges.filter(e => e.to == id.value);
});


const outputEdges = computed(() => {
  return nodeboard.value.props.edges.filter(e => e.from == id.value);
});


const Format = computed(() => {
  if (props.binding.output) {
    const outputEdge = outputEdges.value[0];
    return Math.max(outputEdge ? outputEdge.fromFormat : props.binding.format);
  } else {
    const inputEdge = inputEdges.value[0];
    return Math.max(0, inputEdge ? inputEdge.toFormat : props.binding.format);
  }
  return props.format;
});


const connected = computed(() => {
  return inputEdges.value.length > 0;
});


function onMouseDown(event: MouseEvent) {
  if (props.binding.output) {
    instance.parent.parent.parent.emit('linkstart', { id: id.value, binding: props.binding });
  } else {
    instance.parent.parent.parent.emit('linkmove', { id: id.value, binding: props.binding });
  }
}

function onMouseUp(event: MouseEvent) {
  instance.parent.parent.parent.emit('linkend', { id: id.value, binding: props.binding });
}

</script>

<style lang="scss" scoped>
.slot-container {
  position: relative;
  user-select: none;
  min-height: 24px;

  .dot {
    position: absolute;
    height: 24px;
    width: 24px;
    left: -9px;
    top: 50%;
    transform: translate(-50%, -50%);
    padding: 5px;
    cursor: pointer;

    .viz {
      height: 100%;
      width: 100%;
      background-color: #adb5bd;
      border-radius: 12px;
      pointer-events: none;
      border: 1px solid var(--bs-secondary-bg);
    }
  }

  &.output {
    .dot{
      left: unset;
      right: -33px;
    }

    .label {
      text-align: right;
    }
  }

  &.format0 .dot .viz {
    background-color: #adb5bd;
  }

  &.format1 .dot .viz {
    background-color: #23cd9a;
  }
  
  &.format2 .dot .viz {
    background-color: #0dcaf0;
  }

  &.format3 .dot .viz {
    background-color: #0d6efd;
  }

  &.format4 .dot .viz {
    background-color: #6f42c1;
  }
}
</style>