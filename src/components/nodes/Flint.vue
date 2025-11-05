<template>
  <div class="m-2">
    <a href="https://store.steampowered.com/app/1549550/Haven_Park/" target="_blank"><img src="@/assets/flint.png" alt="Flint Node" class="w-16 h-16 mb-2" /></a>
  </div>
</template>

<script lang="ts">

const defaultProperties = {};
const bindings = [];

export default {
  type: "Flint",
  label: "Flint",
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
  emits: ["evaluate"],
  setup(props, { emit }) {
    return {
      props,
      bindings
    }
  },
  build(device, nodeTreeItem) {
    
  },
  evaluate(device, commandEncoder, nodeTreeItem, entries) {
    
  },
}
</script>