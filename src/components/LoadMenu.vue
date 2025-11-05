<template>
  <div class="modal fade" ref="modal" tabindex="-1">
    <div class="modal-dialog modal-dialog-scrollable">
      <div class="modal-content">
        <div class="modal-header">
          <h1 class="modal-title fs-5" id="loadBackdropLabel"><i class="bi bi-floppy"></i> Load</h1>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body">
          <div class="mb-3">
            <label for="importSettings" class="form-label">Import JSON file</label>
            <input class="form-control" id="importSettings" type="file" accept=".json" @change="importJson">
          </div>
          <div class="d-flex justify-content-between mb-3">
            <label for="importSettings" class="form-label">Browse templates</label>
            <button type="button" class="btn btn-secondary" @click="browseTemplates">Browse</button>
          </div>
          <div class="mb-3">
            <label for="recipient-name" class="col-form-label">Load from local storage</label>
            <div class="list-group">
              <div v-for="settings in settingsCollection" class="btn-group mt-3 d-flex" role="group">
                <button type="button" class="btn btn-secondary flex-grow-1" @click.stop="load(settings)">{{ settings.name }}</button>
                <button type="button" class="btn btn-danger flex-grow-0" @click.stop="remove(settings)"><i class="bi bi-trash3"></i></button>
              </div>
              <div v-if="Object.keys(settingsCollection).length == 0"><p class="text-info"><i class="bi bi-info-circle"></i> No settings saved on this browser.</p></div>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, onUnmounted, computed, useTemplateRef } from "vue";

let modalBs;

const emit = defineEmits(["close", "load", "remove", "openTemplateMenu"]);
const modal = useTemplateRef("modal");
const props = defineProps({
  collectionName: {
    type: String,
    required: true
  }
});
const settingsCollection = reactive(JSON.parse(localStorage.getItem(props.collectionName) || "{}"));

onMounted(() => {
  modalBs = new bootstrap.Modal(modal.value);
  modal.value.addEventListener("shown.bs.modal", onShown);
  modal.value.addEventListener("hidden.bs.modal", onHidden);
  modalBs.show();
});


function load(settings) {
  emit("load", settings);
  modalBs.hide();
}


function remove(settings) {
  if (confirm(`Really delete setting ${settings.name}?`)) {
    delete settingsCollection[settings.name];
    localStorage.setItem(props.collectionName, JSON.stringify(settingsCollection));
  }
}


function importJson(event) {
  const file = event.target.files[0];
  if (!file) return;

  const reader = new FileReader();
  reader.onload = function(e) {
    try {
      const jsonObject = JSON.parse(e.target.result);
      emit("load", jsonObject);
      modalBs.hide();
    } catch (err) {
      console.error("Invalid JSON:", err);
    }
  };
  reader.readAsText(file);
}


function browseTemplates() {
  //emit("close");
  modalBs.hide();
  emit("openTemplateMenu");
}


function onShown() {
  
}


function onHidden() {
  emit("close");
}

</script>