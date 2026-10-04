"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.auth = exports.db = void 0;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const auth_1 = require("firebase-admin/auth");
// One shared Admin SDK app instance across all function modules — avoids
// re-initializing per cold start when multiple functions from this
// codebase run in the same container.
if ((0, app_1.getApps)().length === 0) {
    (0, app_1.initializeApp)();
}
exports.db = (0, firestore_1.getFirestore)();
exports.auth = (0, auth_1.getAuth)();
