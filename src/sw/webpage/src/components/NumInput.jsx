import { createSignal } from 'solid-js';

export default function NumInput() {
  const [value, setValue] = createSignal(0);

  const handleInput = (e) => {
    const newValue = Math.min(256, Math.max(0, parseInt(e.target.value) || 0));
    setValue(newValue);
  };

  return (
    <input
      type="number"
      min="0"
      max="256"
      value={value()}
      onInput={handleInput}
      class="w-32 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
    />
  );
}