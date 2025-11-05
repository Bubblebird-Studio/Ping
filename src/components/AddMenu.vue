<template>
  <div class="modal fade" ref="modal" tabindex="-1">
    <div class="modal-dialog modal-dialog-scrollable">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title"><i class="bi bi-plus-lg"></i> Add node</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-header">
          <div class="input-group mb-3">
            <input type="text" class="form-control" placeholder="Search..." aria-label="Search" v-model="nodeSearch" ref="searchInput">
            <button class="btn btn-outline-secondary" type="button" id="clear" @click="nodeSearch = ''">Clear</button>
          </div>
        </div>
        <div class="modal-body">
          <ul class="list-group">
            <button v-for="node in filteredNodes" type="button" class="list-group-item list-group-item-action" @click="addNode(node.type)">{{ node.label }}</button>
          </ul>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, useTemplateRef } from "vue";

let modalBs;

const nodeSearch = ref("");
const position = {x: 0, y: 0};
const modal = useTemplateRef("modal");
const searchInput = useTemplateRef("searchInput");
const emit = defineEmits(["addNode", "close"]);
const props = defineProps({
  nodes: {
    type: Object,
    default: () => {}
  },
  position: {
    type: Object,
    default: () => ({ x: 0, y: 0 })
  },
});


const filteredNodes = computed(() => {
  const result = [];
  const lowerKeyword = nodeSearch.value.toLowerCase();
  for (const key of Object.keys(props.nodes).sort()) {
    const node = props.nodes[key];
    const nameMatch = node.label?.toLowerCase().includes(lowerKeyword);
    const typeMatch = node.type?.toLowerCase().includes(lowerKeyword);
    if (nameMatch || typeMatch) result.push(node);
  }
  return result;
});


onMounted(() => {
  modalBs = new bootstrap.Modal(modal.value);
  modal.value.addEventListener("shown.bs.modal", onShown);
  modal.value.addEventListener("hidden.bs.modal", onHidden);
  position.x = props.position.x + 200;
  position.y = props.position.y + 200;
  modalBs.show();
});


onUnmounted(() => {
  //modal.value.removeEventListener("shown.bs.modal", onShown);
  //modal.value.removeEventListener("hidden.bs.modal", onHidden);
});


function addNode(type: String) {
  emit("addNode", { type, position });
  modalBs.hide();
}


function onShown() {
  searchInput.value.select();
}


function onHidden() {
  emit("close");
}
</script>

<style lang="scss" scoped>

</style>