<template>
  <div class="modal fade" ref="modal" tabindex="-1">
    <div class="modal-dialog modal-dialog-scrollable">
      <div class="modal-content">
        <div class="modal-header">
          <h1 class="modal-title fs-5" id="loadBackdropLabel"><i class="bi bi-box2-heart"></i> Browse templates</h1>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body">
          <div class="mb-3">
            <div class="list-group templates">
              <div v-for="template in templates" class="template" role="group" @click.stop="load(template.settings)">
                <div class="flipbook" :style="templateBackgroundStyle(template.thumbnail)"></div>
                <div class="info">
                  <h5 class="title">{{ template.name }}</h5>
                  <small class="description">{{ template.description }}</small>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <label for="recipient-name" class="col-form-label">Templates made with <i class="bi bi-heart-fill"></i> by <a href="https://bubblebirdstudio.com/" target="_blank">Bubblebird Studio</a>. Enjoy!</label>
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, onUnmounted, computed, useTemplateRef } from "vue";
import { templates } from "./Templates.json";

let modalBs;

const emit = defineEmits(["close", "load"]);
const modal = useTemplateRef("modal");
const props = defineProps({
  
});

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


function templateBackgroundStyle(thumbnail) {
  return {backgroundImage: `url(/templates_thumbnails/${thumbnail})`}
}


function onShown() {
  
}


function onHidden() {
  emit("close");
}
</script>


<style lang="scss" scoped>
.templates {
  gap: 16px;

  .template {
    width: 100%;
    height: 64px;
    border-radius: 4px;
    position: relative;
    overflow: hidden;
    box-shadow: 0px 6px 8px #0000004e;
    transition: background-color 0.5s;
    background-color: var(--bs-tertiary-bg);
    display: flex;
    cursor: pointer;

    .flipbook {
      flex: 0 0 auto;
      width: 64px;
      height: 64px;
      background-repeat: no-repeat;
      will-change: background-position;

      @keyframes flipbook-horizontal {
        from { background-position: 0% 0%; }
        to   { background-position: 100% 0%; }
      }
    }

    .info {
      flex: 1 1 auto;
      padding: 8px;
      display: flex;
      flex-direction: row;
      justify-content: center;
      align-items: center;

      .title {
        flex: 1 0 auto;
        width: 128px;
      }

      .description {
        font-size: 0.75rem;
        width: 100%;
      }
    }

    &:hover {
      box-shadow: 0px 9px 12px #00000081;
      background-color: var(--bs-border-color);

      .flipbook {
        animation: flipbook-horizontal
                  calc(32 / 12 * 1s)
                  steps(31) running infinite;
      }
    }
  }
}

</style>