import { createEffect, createSignal, onCleanup, Switch } from "solid-js";
{ /*import { setBoolAttribute } from "solid-js/web";
import { buildErrorMessage } from "vite"; */ }

const options = {
  def: Wolfram,
  red: Red,
  blue: Blue,
  greyscale: Greyscale
}


export default function Dropdown(props){
  const [choice, setChoice] = createSignal("def");

  return (
    <div
      class="bg-white p-4 text-center"
      classList={{"rounded-md": props.rounded}}
    >
      {props.children}
      <select value={choice()} onInput={e => setChoice(e.currentTarget.value)}>
        <For each={Object.keys(options)}>{
          coloring => <option value={coloring}>{coloring}</option>
        }</For>
      </select>
      <Switch fallback={<Wolfram />}>
        <Match when={choice() === "red"} ><Red /></Match>
        <Match when={choice() === "blue"} ><Blue /></Match>
        <Match when={choice() === "greyscale"} ><Greyscale /></Match>
      </Switch>
    </div>
  )
}