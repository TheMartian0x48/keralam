/**
 * Shared Quill bootstrap for the Keralam editor controllers.
 *
 * Overrides Quill's toolbar icons with Keralam-styled glyphs before any
 * Quill instance is constructed. Snow's BaseTheme.buildButtons()
 * rewrites every `class="ql-X"` button's innerHTML on first mount;
 * without this, the buttons get Quill's stock 18x18 Snow glyphs and
 * our Keralam icons get clobbered.
 *
 * Also exposes `ensureTableBetterPlugin()`, an idempotent registration
 * of the quill-table-better module. Both `EditorController` and
 * `EditorProseController` import this module — consolidating the icon
 * override and the table-better registration in one place keeps them
 * from happening twice now that both controllers ship in the same
 * bundle. Quill's own vendor CSS is bundled separately, via
 * src/css/main.css.
 */
import Quill from "quill";
import QuillTableBetter from "quill-table-better";
import QuillIcons from "quill/ui/icons";

import keralamIcons from "./editor.icons";

// Quill's import-bindings are captured at module load — Snow theme's
// `icons` variable points at the same plain object we get from
// `import QuillIcons from "quill/ui/icons"`. Mutate that object in-place
// (Object.assign) so both bindings see the additions.
Object.assign(QuillIcons, keralamIcons);

// Also register via Quill.imports so any code path that reads the
// icons through `Quill.import("ui/icons")` after construction sees
// the same merged map.
Quill.register({ "ui/icons": QuillIcons }, true);

let tableBetterRegistered = false;
export function ensureTableBetterPlugin(): void {
    if (tableBetterRegistered) return;
    Quill.register({ "modules/table-better": QuillTableBetter }, true);
    tableBetterRegistered = true;
}
