<template>
  <div class="input-group input-group-sm">
    <div class="input-group-text">
      <input type="color" :disabled="disabled" :value="toRgbHex(model)" @input="colorChange">
    </div>
    <Slider v-model="model[3]" :disabled="disabled" label="Alpha" min="0.0" max="1.0" />
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from "vue";
import { toRgbHex, fromRgbHex } from "./../utils.ts" with { type: "text" };

const model = defineModel();
const props = defineProps({
  disabled: {
    type: Boolean,
    default: false
  }
});

function colorChange(event) {
  const color = fromRgbHex(event.target.value);
  model.value[0] = color[0];
  model.value[1] = color[1];
  model.value[2] = color[2];
}
</script>