/**
 * Keralam EditorProse Stimulus controller (client-side Delta renderer).
 *
 * Renders the `data-editor-prose-delta-value` JSON through a shared
 * offscreen Quill, calls `quill.getSemanticHTML(...)` to serialize, and
 * replaces the controlled element's innerHTML with the rendered output.
 *
 * Companion to components/editor_prose.templ.
 */
import { Controller } from '@hotwired/stimulus';
import Quill, { type Op } from 'quill';

import { ensureTableBetterPlugin } from '../editor/quill-setup';

ensureTableBetterPlugin();

interface DeltaLike {
    ops: Op[];
}

function safeParseDelta(raw: string | null): DeltaLike | null {
    if (!raw) return null;
    try {
        const parsed = JSON.parse(raw);
        if (parsed && Array.isArray(parsed.ops)) return parsed as DeltaLike;
        return null;
    } catch {
        return null;
    }
}

// Build a Quill host with a hidden toolbar mount point. table-better's
// `initWhiteList()` unconditionally calls `this.quill.getModule("toolbar")`
// and walks its container; if the toolbar module isn't registered it
// throws. We give it an empty, hidden toolbar so the module registers
// (no toolbar chrome shown) and `initWhiteList` is a no-op.
function buildQuillHost(): { host: HTMLDivElement; editor: HTMLDivElement; toolbarContainer: HTMLDivElement } {
    const host = document.createElement('div');
    host.setAttribute('aria-hidden', 'true');
    host.style.cssText =
        'position:absolute;left:-99999px;top:-99999px;width:1px;height:1px;overflow:hidden;';
    const toolbarContainer = document.createElement('div');
    toolbarContainer.style.display = 'none';
    const editor = document.createElement('div');
    host.appendChild(toolbarContainer);
    host.appendChild(editor);
    return { host, editor, toolbarContainer };
}

const SHARED_MODULES = {
    toolbar: { container: null as HTMLElement | null }, // set per-instance below
    table: false,
    'table-better': {
        language: 'en_US',
        menus: ['column', 'row', 'merge', 'wrap', 'delete'],
        toolbarTable: false,
    },
};

// One shared offscreen Quill per page. If the shared instance fails to
// initialize (CSS not loaded, browser quirk, etc.) we fall back to a
// fresh offscreen Quill per element — heavier on big pages but
// bulletproof.
let sharedQuill: Quill | null = null;
let sharedQuillError: unknown = null;

function getSharedQuill(): Quill | null {
    if (sharedQuill) return sharedQuill;
    if (sharedQuillError) return null;
    try {
        const { host, editor, toolbarContainer } = buildQuillHost();
        document.body.appendChild(host);
        const modules = { ...SHARED_MODULES, toolbar: { container: toolbarContainer } };
        sharedQuill = new Quill(editor, { theme: 'snow', modules });
        return sharedQuill;
    } catch (e) {
        sharedQuillError = e;
        return null;
    }
}

function renderWith(element: Element, delta: DeltaLike, quillInstance: Quill): void {
    quillInstance.setContents(delta.ops);
    const html = quillInstance.getSemanticHTML();
    element.innerHTML = html;
}

// Fallback for one element when the shared Quill isn't usable. Creates
// a fresh offscreen Quill (with a hidden toolbar container so table-
// better doesn't crash), renders, then removes the host.
function renderFallback(element: Element, delta: DeltaLike): void {
    const { host, editor, toolbarContainer } = buildQuillHost();
    document.body.appendChild(host);
    try {
        const modules = { ...SHARED_MODULES, toolbar: { container: toolbarContainer } };
        const quill = new Quill(editor, { theme: 'snow', modules });
        renderWith(element, delta, quill);
    } finally {
        if (host.parentNode) host.parentNode.removeChild(host);
    }
}

export default class EditorProseController extends Controller {
    static values = {
        delta: String,
    };

    declare deltaValue: string;

    // Fires once when the controller connects (with whatever value is
    // present) and again on every later change to
    // data-editor-prose-delta-value — covers both initial render and
    // in-place updates without a separate connect() hook.
    deltaValueChanged(): void {
        const delta = safeParseDelta(this.deltaValue);
        if (!delta) return;

        const shared = getSharedQuill();
        if (shared) {
            try {
                renderWith(this.element, delta, shared);
                return;
            } catch {
                sharedQuill = null;
                sharedQuillError = null;
            }
        }

        try {
            renderFallback(this.element, delta);
        } catch {
            // swallowed — element is left un-rendered on total failure
        }
    }
}
