// App.FetchBun.js
// Bun native fetch binding — replaces Affjax.Node (node:http compat layer)
// which hangs in forked fibers on Bun. See ADR-007.
//
// PS FFI calls are curried. PS functions compile to curried JS functions:
//   (a -> b -> Effect Unit) => function(a) { return function(b) { return function() { ... } } }
// So onSuccess(result) returns a thunk; onSuccess(result)() executes it.
// PS records compile to JS objects: { status, body } maps to { status: n, body: s }.
// PS Tuple compiles to { value0, value1 }.
//
// fetchImpl returns Effect (Effect Unit): the outer thunk starts the fetch,
// the inner thunk aborts it via AbortController. This lets makeAff cancel
// in-flight requests when a fiber is killed (e.g. server shutdown, timeout).

// fetchImpl :: String -> String -> Array (Tuple String String) -> String
//          -> (FetchResult -> Effect Unit) -> (String -> Effect Unit)
//          -> Effect (Effect Unit)
export function fetchImpl(url) {
  return function (method) {
    return function (headers) {
      return function (body) {
        return function (onSuccess) {
          return function (onError) {
            return function () {
              var controller = new AbortController();
              var hdrs = {};
              for (var i = 0; i < headers.length; i++) {
                hdrs[headers[i].value0] = headers[i].value1;
              }
              fetch(url, {
                method: method,
                headers: hdrs,
                body: body || undefined,
                signal: controller.signal,
              })
                .then(function (resp) {
                  return resp.text().then(function (text) {
                    onSuccess({ status: resp.status, body: text })();
                  });
                })
                .catch(function (err) {
                  // AbortError is expected when the canceler fires — don't
                  // surface it as an error to the PS side (the fiber is
                  // already being killed).
                  if (err && err.name === "AbortError") return;
                  onError(err.message || String(err))();
                });
              // Inner thunk: abort the in-flight fetch.
              return function () {
                controller.abort();
              };
            };
          };
        };
      };
    };
  };
}
