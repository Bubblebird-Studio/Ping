<template>
  <div ref="viewer" class="viewer checker">
    <div class="gradient" :style="style"></div>
  </div>
  <div class="stops" @mousedown.self="addStop">
    <div v-for="(stop, i) in stops" class="stop"
      :class="{'selected': selectedStop == stop}"
      :style="{left: stop.location * 100 + '%'}"
      @mousedown.stop="mouseDownOnStop(stop, i)">
      <div class="color" :style="{backgroundColor: toRgbHex(stop.color)}"></div>
    </div>
  </div>
  <div class="stop-editor mb-2" v-if="selectedStop !== undefined">
    <ColorPicker v-model="selectedStop.color" class="mb-2"></ColorPicker>
    <div class="input-group input-group-sm">
      <Slider v-model="selectedStop.location" label="Location" min="0.0" max="1.0" />
      <button type="button" class="btn btn-outline-secondar" @click="removeStop(selectedStop)">
        <i class="bi bi-trash"></i>
      </button>
    </div>
  </div>
</template>

<script lang="ts">
import { ref, computed, onMounted, onUnmounted } from "vue";
import { toHex, toRgbHex } from "./../utils.ts" with { type: "text" };

export default {
  props: {
    stops: {
      type: Array,
      required: true
    },
  },
  setup(props) {
    const viewer = ref(null);
    const grabbing = ref(false);
    const selectedStopIndex = ref(0);
    const selectedStop = computed(() => {
      return props.stops[selectedStopIndex.value];
    });
    const style = computed(() => {
      const g = props.stops.slice().sort((a, b) => a.location - b.location).map(s => {
        return `${toHex(s.color)} ${s.location * 100}%`;
      });
      return `background: linear-gradient(90deg, ${g.join(", ")})`;
    });

    const width = computed(() => {
      return viewer.value.offsetWidth;
    })
    
    onMounted(() => {
      window.addEventListener("mousemove", onMouseMove);
      window.addEventListener("mouseup", onMouseUp);
    });

    onUnmounted(() => {
      window.removeEventListener("mousemove", onMouseMove);
      window.removeEventListener("mouseup", onMouseUp);
    });

    function mouseDownOnStop(stop, i) {
      grabbing.value = true;
      selectedStopIndex.value = i;
    }

    function onMouseMove(event) {
      if (selectedStop.value && grabbing.value) {
        const inc = event.movementX / width.value;
        selectedStop.value.location += inc;
        selectedStop.value.location = Math.round(Math.min(Math.max(selectedStop.value.location, 0), 1) * 1000) / 1000;
      }
    }

    function onMouseUp(event) {
      grabbing.value = false;
    }

    function addStop(event) {
      const location = Math.round(Math.min(Math.max(event.offsetX / width.value, 0), 1) * 1000) / 1000;
      const newStop = { location, color: [0, 0, 0, 1.0] }
      props.stops.push(newStop);
      selectedStopIndex.value = props.stops.indexOf(newStop);
      grabbing.value = true;
    }

    function removeStop(stop) {
      if (props.stops.length <= 1) return;
      const index = props.stops.indexOf(stop);
      props.stops.splice(index, 1);
      selectedStopIndex.value = 0;
    }

    return {
      style,
      viewer,
      selectedStop,
      mouseDownOnStop,
      addStop,
      removeStop,
      toRgbHex
    }
  }
}
</script>

<style lang="scss" scoped>
@use "./../style.css";

.viewer {
  width: 100%;
  height: 50px;
  border: 1px solid grey;
  background-color: #e5e5f7;
  opacity: 0.8;

  .gradient {
    width: 100%;
    height: 100%;
  }
}

.stops {
  position: relative;
  width: 100%;
  height: 20px;
  cursor: pointer;
  
  .stop {
    position: absolute;
    width: 12px;
    height: 12px;
    background: rgb(255, 255, 255);
    transform: translate(-50%, -50%) rotate(45deg);
    padding: 2px;
    user-select: none;

    &.selected {
      border: 2px solid var(--bs-primary);
    }

    .color {
      width: 100%;
      height: 100%;
    }
  }
}

.stop-editor {
  width: 100%;
}
</style>