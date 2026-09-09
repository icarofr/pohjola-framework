// Shared helper for parsing Datastar's SSE wire format in e2e specs.

/**
 * Extracts the rendered HTML payload out of a `datastar-patch-elements` SSE
 * event body -- mirrors App.Layout.Scripts.dsShellRouterScript's own parsing
 * exactly, since that's the real client-side consumer this stands in for.
 */
export function extractDatastarPatch(sseBody) {
  const marker = "data: elements ";
  const i = sseBody.indexOf(marker);
  if (i === -1) {
    throw new Error("not a datastar-patch-elements event: " + sseBody.slice(0, 200));
  }
  return sseBody.slice(i + marker.length).split("\n\n")[0];
}
