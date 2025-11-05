<template>
  <div class="modal fade" ref="modal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content">
        <div class="modal-header">
          <img src="@/assets/logo.png" alt="ping logo" />
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body">
          <div class="mb-3">
          <em class="modal-title fs-5">Procedural Image Nodal Generator</em>
            <h5>How to use</h5>
            <ul class="list-group">
              <li class="list-group-item"><i class="bi bi-arrows-move"></i> Left mouse button: Move</li>
              <li class="list-group-item"><i class="bi bi-bounding-box-circles"></i> Right mouse button: Box selection</li>
              <li class="list-group-item"><i class="bi bi-zoom-in"></i> Scroll: Zoom in or out</li>
              <li class="list-group-item"><i class="bi bi-copy"></i> Ctrl-D: Duplicate</li>
              <li class="list-group-item"><i class="bi bi-plus-lg"></i> Use the "plus button" in the toolbar to add new nodes</li>
            </ul>
          </div>
          <div class="mb-3">
            <h5>Buy our games to support this tool</h5>
            <div class="d-flex gap-3">
              <div class="game">
                <a href="https://store.steampowered.com/app/1549550/Haven_Park/" target="_blank"><img class="img-fluid" src="@/assets/havenpark_library_capsule.jpg" /></a>
              </div>
              <div class="game">
                <a href="https://store.steampowered.com/app/2343920/Trackline_Express/" target="_blank"><img class="img-fluid" src="@/assets/trackline_library_capsule.jpg" /></a>
              </div>
              <div class="game">
                <a href="https://store.steampowered.com/app/3199540/TurboSquad/" target="_blank"><img class="img-fluid" src="@/assets/turbosquad_library_capsule.jpg" /></a>
              </div>
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
import { ref, onMounted, onUnmounted, computed, useTemplateRef } from "vue";

let modalBs;

const emit = defineEmits(["close"]);
const modal = useTemplateRef("modal");
const props = defineProps({
  settingsCollection: {
    type: Object,
    default: () => {}
  },
});

onMounted(() => {
  modalBs = new bootstrap.Modal(modal.value);
  modal.value.addEventListener("shown.bs.modal", onShown);
  modal.value.addEventListener("hidden.bs.modal", onHidden);
  modalBs.show();
});


function onShown() {
  
}


function onHidden() {
  emit("close");
}
</script>

<style lang="scss" scoped>

.game {
  flex: 1;

  img {
    width: 100%;
    height: auto;
    border-radius: 5px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    transition: transform 0.2s;

    &:hover {
      transform: scale(1.05);
    }
  }
}
</style>