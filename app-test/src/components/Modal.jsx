import { createSignal, Show } from 'solid-js';
import { Portal } from 'solid-js/web';

export default function Modal (props) {

  return (
    <Show when={props.isOpen()}>
      <Portal>
        <div 
          class="fixed inset-0 z-50 flex justify-center items-center bg-opacity-50 backdrop-blur-sm"
          // onClick={props.onClose} (commented out so modal is static)
        >
          <div 
            class="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-lg"
            style={{
              "width": "500px",
              "max-width": "60vw",
              "max-height": "auto",
              "overflow-y": "auto"
            }}
          >
            <div class="flex justify-between items-center mb-4">
              <h1 class="text-xl font-bold text-gray-900 dark:text-white">{props.title}</h1>
              <button 
                onClick={props.onClose}
                class="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 text-xl flex-shrink-0 ml-4"
              >
                ✕
              </button>
            </div>
            <div class="text-gray-600 dark:text-gray-300">
              {props.content}
            </div>
          </div>
        </div>
      </Portal>
    </Show>
  );
}