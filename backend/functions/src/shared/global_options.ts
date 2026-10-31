import { setGlobalOptions } from "firebase-functions/v2";

// Applies to every function defined after this module loads (shared/firebase
// imports it first, and every function module imports shared/firebase).
//  - one region for everything (callers use us-central1)
//  - maxInstances caps how far any single function can scale, so a traffic
//    spike or abuse can't run up an unbounded bill. Raise per function if a
//    real workload needs it.
setGlobalOptions({ region: "us-central1", maxInstances: 20 });
