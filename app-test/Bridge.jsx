// https://primitives.solidjs.community/package/websocket/

import { createSignal, createEffect, onCleanup } from "solid-js";
import { createWS, createWSState } from "@solid-primitives/websocket";

const ws = createWS('http://127.0.0.1:8000/websocket');
const wsState = createWSState(ws)

createEffect (() => {
  const msg = ws.message();
  console.log(msg);
})