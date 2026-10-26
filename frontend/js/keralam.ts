/**
 * Keralam Library — main entry point
 * Registers all Stimulus controllers and initialises utilities.
 */

import { Application } from '@hotwired/stimulus';
import * as Stimulus from '@hotwired/stimulus';
import Quill, * as QuillNS from 'quill';

import AlertController      from './controllers/keralam_alert_controller';
import BadgeController      from './controllers/keralam_badge_controller';
import CheckboxController   from './controllers/keralam_checkbox_controller';
import AutocompleteController from './controllers/keralam_autocomplete_controller';
import DialogController     from './controllers/keralam_dialog_controller';
import DrawerController     from './controllers/keralam_drawer_controller';
import DropdownController   from './controllers/keralam_dropdown_controller';
import DropzoneController   from './controllers/keralam_dropzone_controller';
import EditorController     from './controllers/keralam_editor_controller';
import EditorProseController from './controllers/keralam_editor_prose_controller';
import SliderController     from './controllers/keralam_slider_controller';
import TabsController       from './controllers/keralam_tabs_controller';
import TimeController       from './controllers/keralam_time_controller';
import ToastController      from './controllers/keralam_toast_controller';
import TooltipController    from './controllers/keralam_tooltip_controller';
import ThemeController      from './controllers/keralam_theme_controller';

// ── Stimulus ────────────────────────────────────────────────────────────────
const app = Application.start();
app.register('keralam-alert',        AlertController);
app.register('keralam-badge',        BadgeController);
app.register('keralam-checkbox',     CheckboxController);
app.register('keralam-autocomplete', AutocompleteController);
app.register('keralam-dialog',       DialogController);
app.register('keralam-drawer',       DrawerController);
app.register('keralam-dropdown',     DropdownController);
app.register('keralam-dropzone',     DropzoneController);
app.register('keralam-editor',       EditorController);
app.register('keralam-editor-prose', EditorProseController);
app.register('keralam-slider',       SliderController);
app.register('keralam-tabs',         TabsController);
app.register('keralam-time',         TimeController);
app.register('keralam-toast',        ToastController);
app.register('keralam-tooltip',      TooltipController);
app.register('keralam-theme',        ThemeController);

// Merge Quill's named exports (Delta, Module, Parchment, ...) onto the
// Quill class itself, so window.keralam.Quill reads as one object rather
// than a class plus a separate namespace.
Object.assign(Quill, QuillNS);

window.keralam = { app, Stimulus, Quill: Quill as typeof Quill & typeof QuillNS };

// ── Shared utilities ─────────────────────────────────────────────────────────
const reducedMotionQuery = window.matchMedia('(prefers-reduced-motion: reduce)');

window.keralamUtils = {
    prefersReducedMotion: reducedMotionQuery.matches,

    escapeHtml(text: string): string {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    },
};

reducedMotionQuery.addEventListener('change', (e: MediaQueryListEvent) => {
    window.keralamUtils.prefersReducedMotion = e.matches;
});

