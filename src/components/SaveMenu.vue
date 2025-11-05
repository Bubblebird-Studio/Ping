<template>
  <div class="modal fade" ref="modal" tabindex="-1">
    <div class="modal-dialog">
      <div class="modal-content">
        <div class="modal-header">
          <h1 class="modal-title fs-5" id="saveBackdropLabel"><i class="bi bi-floppy"></i> Save</h1>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body">
          <div class="mb-3">
            <label for="recipient-name" class="col-form-label">Choose a name for your project:</label>
            <input type="text" class="form-control mb-2" v-model="settings.name" ref="nameInput" @keypress.enter="save">
            <p class="text-warning">
              <i class="bi bi-info-circle"></i> If you save the settings to your browser's local storage, you might lose them if you clear the cache.
            </p>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-primary" data-bs-dismiss="modal" @click="exportJson">Export to JSON</button>
          <button type="button" class="btn btn-primary" data-bs-dismiss="modal" @click="save">Save to local storage</button>
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" @click="copyJson"><i class="bi bi-clipboard"></i></button>
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, useTemplateRef } from "vue";

let modalBs;

const emit = defineEmits(["close", "save"]);
const modal = useTemplateRef("modal");
const nameInput = useTemplateRef("nameInput");
const props = defineProps({
  collectionName: {
    type: String,
    required: true
  },
  settings: {
    type: Object,
    default: () => {}
  }
});

onMounted(() => {
  modalBs = new bootstrap.Modal(modal.value);
  modal.value.addEventListener("shown.bs.modal", onShown);
  modal.value.addEventListener("hidden.bs.modal", onHidden);
  modalBs.show();
});


function exportJson() {
  const jsonStr = JSON.stringify(props.settings, null, 2);
  const blob = new Blob([jsonStr], { type: "text/plain" });
  const link = document.createElement("a");
  link.href = URL.createObjectURL(blob);
  link.download = `${props.settings.name}.json`;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(link.href);
  modalBs.hide();
}


async function copyJson() {
  const jsonStr = JSON.stringify(props.settings, null, 2);
  const item = new ClipboardItem({ 'text/plain': jsonStr });
  await navigator.clipboard.write([item]);
}


function save() {
  const settingsCollection = JSON.parse(localStorage.getItem(props.collectionName) || "{}");
  if (settingsCollection[props.settings.name]) {
    if (confirm(`Local storage aleardy contains settings named ${props.settings.name}. Overwrite?`)) {
      emit("save", props.settings);
      modalBs.hide();
    } else {
      nameInput.value.select();
    }
  } else {
    emit("save", props.settings);
    modalBs.hide();
  }
}


function onShown() {
  nameInput.value.select();
}


function onHidden() {
  emit("close");
}

</script>