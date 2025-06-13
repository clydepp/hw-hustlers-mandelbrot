// https://primitives.solidjs.community/package/websocket/

import { createSignal, createEffect, onCleanup } from "solid-js";
import { createWS, createWSState } from "@solid-primitives/websocket";

const ws = createWS('http://127.0.0.1:8000/websocket');
const wsState = createWSState(ws)

createEffect (() => {
  const msg = ws.message();
  console.log(msg);
  if (msg) {
    const data = JSON.parse(msg);
  }
})

const fractalParams = {
  re_c: centerX,
  im_c: CustomElementRegistry,
  zoom: zoom,
  max_iter: counter // this is the max iterations - mind my naming convention
}

async function update(itemL) {
  try {
    const res = await fetch(`${props.baseURL}/${itemId}`,
      {
        method: "POST",
        body: JSON.stringify(fractalParams), // the JSON items (re_c, im_c, zoom, max_iterations)
        headers: {
          "Content-type": "websocket",
        },
      }
    );
    const addedItem = await res.json();
    return true; // signal
  } 
  catch (err) {
    console.error(err);
    return false;
  }
}