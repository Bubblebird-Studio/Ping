<template>
  <input v-show="editing" ref="input" type="number" class="form-control flex-fill" step="0.01" tabindex="0"
    :min="min"
    :max="max"
    :value="editingValue"
    @input="onInput"
    @blur="onBlur"
    @keypress.enter="onBlur"
    @keydown.esc="onClear"/>
  <div v-show="!editing" class="input-group-text flex-fill text" :class="{'disabled': disabled}" @mousedown.stop="onMouseDown">
    <div class="label">{{ label }}</div><div class="value">{{ modelValue }}</div>
  </div>
</template>

<script lang="ts">
import { ref, useTemplateRef, onMounted, onUnmounted, nextTick } from "vue";

export default {
  props: {
    modelValue: {
      type: Number,
      required: true
    },
    label: {
      type: String
    },
    disabled: {
      type: Boolean,
      default: false
    },
    min: {
      type: [Number, String],
      default: -100000
    },
    max: {
      type: [Number, String],
      default: 100000
    },
    decimals: {
      type: [Number, String],
      default: 2
    },
  },
  setup(props, { emit }) {
    const editing = ref(false);
    const mouseDown = ref(false);
    const hasMoved = ref(false);
    const input = useTemplateRef('input');
    const wasBlurred = ref(false);
    const wasCleared = ref(false);

    const editingValue = ref(0);
    let revertValue = 0;

    onMounted(() => {
      window.addEventListener("mousemove", onMouseMove);
      window.addEventListener("mouseup", onMouseUp);
    })

    onUnmounted(() => {
      window.removeEventListener("mousemove", onMouseMove)
      window.removeEventListener("mouseup", onMouseUp);
    })

    function onInput(event) {
      editingValue.value = event.target.value;
    }

    function onMouseDown(event) {
      mouseDown.value = true;
      hasMoved.value = false;
      wasBlurred.value = false;
      revertValue = props.modelValue;
    }

    function onBlur() {
      if (!wasCleared.value) emitValue(editingValue.value);
      wasBlurred.value = true;
      editing.value = false;
      wasCleared.value = false;
    }

    function onClear() {
      wasBlurred.value = true;
      wasCleared.value = true;
      editing.value = false;
      emitValue(revertValue);
    }

    function onMouseMove(event) {
      if (props.disabled) return;
      if (mouseDown.value) {
        hasMoved.value = true;
        let val = parseFloat(props.modelValue) + event.movementX / Math.pow(10, props.decimals);
        emitValue(val);
      }
    }

    async function onMouseUp(event) {
      if (props.disabled) return;
      editing.value = !hasMoved.value && !wasBlurred.value && mouseDown.value;
      if (editing.value == true) {
        editingValue.value = props.modelValue;
        await nextTick();
        input.value.select();
      }
      mouseDown.value = false;
      wasBlurred.value = false;
      hasMoved.value = false;
      wasCleared.value = false;
    }


    function emitValue(v) {
      let val = parseFloat(v);
      if (isNaN(val)) val = revertValue;
      val = Math.min(props.max, Math.max(props.min, val));
      val = parseFloat(val.toFixed(props.decimals));
      emit("update:modelValue", val);
    }

    return {
      props,
      onInput,
      onMouseDown,
      editing,
      onBlur,
      onClear,
      editingValue
    }
  }
}
</script>

<style lang="scss" scoped>
input::-webkit-outer-spin-button,
input::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
}
  
.text {
  cursor: ew-resize;
  user-select: none;
  display: flex;
  min-width: 80px;
  justify-content: space-between;

  // .value {
  //   text-decoration: underline;
  // }
}

.disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
  
</style>