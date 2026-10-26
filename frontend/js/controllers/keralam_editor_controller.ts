/**
 * Keralam Editor Stimulus controller (Quill-backed, interactive).
 *
 * Renders a Quill rich-text editor inside the controlled element.
 * Quill owns its own state; on submit the latest Delta JSON is
 * written into the form's hidden input. Companion to
 * components/editor.templ.
 *
 * Image/file uploads are outsourced to the app via the
 * "keralam:editor:upload-image" / "keralam:editor:upload-file" custom
 * events (see requestUpload below) rather than a global setter —
 * listen on `document` and set `event.detail.promise` to a
 * `Promise<string>` resolving to the uploaded file's URL.
 */
import { Controller } from "@hotwired/stimulus";
import Quill, { type Op } from "quill";
import QuillTableBetter from "quill-table-better";

import { ensureTableBetterPlugin } from "../editor/quill-setup";

interface DeltaLike {
    ops: Op[];
}

interface EditorConfig {
    name?: string;
    placeholder?: string;
    value?: string;
    richText?: boolean;
    theme?: string;
    toolbar?: boolean;
    tables?: boolean;
    images?: boolean;
    files?: boolean;
    required?: boolean;
    disabled?: boolean;
    maxLength?: number;
    ariaLabel?: string;
    ariaDescribedBy?: string;
}

interface TableBetterModule {
    insertTable(rows: number, cols: number): void;
}

const HEADER_LABELS: Record<string, string> = {
    "false": "Paragraph",
    "1": "Heading 1",
    "2": "Heading 2",
    "3": "Heading 3",
};

function safeJSON(raw: string): DeltaLike | null {
    if (!raw) return null;
    try {
        return JSON.parse(raw) as DeltaLike;
    } catch {
        return null;
    }
}

function defaultDelta(): DeltaLike {
    return { ops: [{ insert: "\n" }] };
}

// Plain-text toolbar: inline + block formatting only, no headers/lists/tables.
function plainTextToolbarOptions(): unknown[] {
    return [
        ["bold", "italic", "underline", "strike"],
        ["link", "clean"],
    ];
}

// Rich-text toolbar: full Snow set plus tables / images when enabled.
function richTextToolbarOptions(tables: boolean, images: boolean): unknown[] {
    const groups: unknown[] = [
        [{ header: [false, 1, 2, 3] }, "blockquote", "code-block"],
        [{ font: [] }],
        ["bold", "italic", "underline", "strike"],
        [{ list: "ordered" }, { list: "bullet" }, { list: "check" }],
        [{ script: "sub" }, { script: "super" }],
    ];
    if (tables) groups.push(["table-better"]);
    groups.push(["link"]);
    if (images) groups.push(["image"]);
    return groups;
}

export default class EditorController extends Controller {
    static targets = ["content", "toolbar", "counter", "tableDropdown", "headerDropdown"];
    static values = {
        config: { type: Object, default: {} },
    };

    declare readonly contentTarget: HTMLElement;
    declare readonly hasContentTarget: boolean;
    declare readonly toolbarTarget: HTMLElement;
    declare readonly hasToolbarTarget: boolean;
    declare readonly counterTarget: HTMLElement;
    declare readonly hasCounterTarget: boolean;
    declare readonly tableDropdownTarget: HTMLElement;
    declare readonly hasTableDropdownTarget: boolean;
    declare readonly headerDropdownTarget: HTMLElement;
    declare readonly hasHeaderDropdownTarget: boolean;
    declare configValue: EditorConfig;

    quill!: Quill;
    private pendingUploads = 0;
    private hiddenInput: HTMLInputElement | null = null;
    private cleanups: Array<() => void> = [];

    connect(): void {
        const config = this.configValue;
        if (!this.hasContentTarget) {
            console.warn("[keralam.editor] mount failed: missing content target", this.element);
            return;
        }

        const theme = config.theme === "bubble" ? "bubble" : "snow";
        const modules: Record<string, unknown> = {
            toolbar: config.toolbar === false
                ? false
                : this.hasToolbarTarget
                    ? { container: this.toolbarTarget }
                    : config.richText
                        ? richTextToolbarOptions(!!config.tables, !!config.images)
                        : plainTextToolbarOptions(),
        };

        // Every rich-text editor needs the table-better module present
        // (not just ones with Tables enabled): registering table-better
        // globally overrides Quill's toolbar module so its header/list
        // handlers unconditionally call this.getTableBetter(), which
        // throws if a given instance has no table-better module of its
        // own. See plans/2026-09-05-editor-stimulus-ts-migration.md.
        if (config.richText) {
            ensureTableBetterPlugin();
            modules.table = false;
            modules["table-better"] = {
                language: "en_US",
                menus: ["column", "row", "merge", "wrap", "delete"],
                toolbarTable: false,
            };
            modules.keyboard = { bindings: QuillTableBetter.keyboardBindings };
        }

        if (config.images && config.richText) {
            const toolbarConfig = (typeof modules.toolbar === "object" && modules.toolbar !== null
                ? modules.toolbar
                : {}) as Record<string, unknown>;
            modules.toolbar = toolbarConfig;
            toolbarConfig.handlers = {
                ...(toolbarConfig.handlers as Record<string, unknown> | undefined),
                image: (value: unknown) => {
                    if (value) {
                        const input = document.createElement("input");
                        input.type = "file";
                        input.accept = "image/*";
                        input.addEventListener("change", () => {
                            const file = input.files?.[0];
                            if (file) this.insertImageFromFile(file);
                            input.value = "";
                        });
                        input.click();
                    } else {
                        this.quill.format("image", false);
                    }
                },
            };
        }

        if (config.files && config.richText) {
            const toolbarConfig = (typeof modules.toolbar === "object" && modules.toolbar !== null
                ? modules.toolbar
                : {}) as Record<string, unknown>;
            modules.toolbar = toolbarConfig;
            toolbarConfig.handlers = {
                ...(toolbarConfig.handlers as Record<string, unknown> | undefined),
                "attach-file": () => {
                    const input = document.createElement("input");
                    input.type = "file";
                    input.addEventListener("change", () => {
                        const file = input.files?.[0];
                        if (file) this.insertFileFromFile(file);
                        input.value = "";
                    });
                    input.click();
                },
            };
        }

        this.quill = new Quill(this.contentTarget, {
            theme,
            modules,
            placeholder: config.placeholder || undefined,
            readOnly: !!config.disabled,
        });

        // Strip inline `style` attributes from pasted content. Quill
        // preserves them by default; this matcher walks the paste's
        // HTML and removes `style` from every element before Quill
        // converts to Delta. Other attributes (`class`, `data-*`,
        // `href`, etc.) are left intact.
        this.quill.clipboard.addMatcher("[style]", (node, delta) => {
            if (node instanceof Element) node.removeAttribute("style");
            return delta;
        });

        // Hydrate from initial Delta if provided.
        if (config.value) {
            const parsed = safeJSON(config.value);
            if (parsed && Array.isArray(parsed.ops)) {
                try {
                    this.quill.setContents(parsed.ops);
                } catch (e) {
                    console.warn("[keralam.editor] could not apply initial Delta:", e);
                }
            }
        }

        // Accessibility wiring.
        const editingHost = this.quill.root;
        if (config.ariaLabel) editingHost.setAttribute("aria-label", config.ariaLabel);
        if (config.ariaDescribedBy) editingHost.setAttribute("aria-describedby", config.ariaDescribedBy);
        editingHost.setAttribute("role", "textbox");
        editingHost.setAttribute("aria-multiline", "true");

        // Counter wiring.
        if (this.hasCounterTarget) {
            const onChange = () => {
                const len = this.plainTextLength();
                if (config.maxLength) {
                    this.counterTarget.textContent = `${len} / ${config.maxLength}`;
                    this.counterTarget.classList.toggle("editor__counter--over", len > config.maxLength);
                } else {
                    this.counterTarget.textContent = String(len);
                }
            };
            this.quill.on("text-change", onChange);
            this.cleanups.push(() => this.quill.off("text-change", onChange));
            onChange();
        }

        // Required-state a11y: keep aria-invalid in sync.
        if (config.required) {
            const onChange = () => {
                const len = this.plainTextLength();
                editingHost.setAttribute("aria-invalid", "false");
                editingHost.setAttribute("aria-required", "true");
                if (len === 0) {
                    editingHost.setAttribute("data-empty", "true");
                } else {
                    editingHost.removeAttribute("data-empty");
                }
            };
            this.quill.on("text-change", onChange);
            this.cleanups.push(() => this.quill.off("text-change", onChange));
            onChange();
        }

        // Keep the hidden input in sync on submit via the formdata event
        // so browsers that auto-build FormData get the latest snapshot
        // first, plus a submit-capture fallback for browsers that don't
        // fire `formdata` (older WebKit, programmatic submission, etc.).
        this.hiddenInput = this.findHiddenInput(config);
        const form = this.hiddenInput?.form ?? null;
        if (form) {
            const onFormData = () => this.syncHiddenFromQuill();
            form.addEventListener("formdata", onFormData);
            this.cleanups.push(() => form.removeEventListener("formdata", onFormData));

            const onSubmit = () => this.syncHiddenFromQuill();
            form.addEventListener("submit", onSubmit, true);
            this.cleanups.push(() => form.removeEventListener("submit", onSubmit, true));
        }

        // Initial sync so server-side rendering reflects whatever was loaded.
        this.syncHiddenFromQuill();

        // Header dropdown label tracks the current header format at the
        // cursor. Listens to editor-change so keyboard shortcuts
        // (Mod-Alt-0/1/2/3) and Quill's own format changes keep the
        // label in sync. Click handling for both dropdowns is wired via
        // data-action in the template (pickTableSize / pickHeader).
        if (config.richText && this.hasHeaderDropdownTarget) {
            this.quill.on("editor-change", this.syncHeaderLabel);
            this.syncHeaderLabel();
            this.cleanups.push(() => this.quill.off("editor-change", this.syncHeaderLabel));
        }

        this.dispatch("ready", { prefix: "keralam:editor", detail: { quill: this.quill } });
    }

    disconnect(): void {
        this.cleanups.forEach((fn) => {
            try {
                fn();
            } catch {
                /* noop */
            }
        });
        this.cleanups = [];
        try {
            this.quill?.enable(false);
        } catch {
            /* noop */
        }
    }

    // Table-size dropdown inside the toolbar: a single Keralam Dropdown
    // contains one DropdownItem per standard NxM dimension. The
    // [data-keralam-rows] / [data-keralam-cols] attrs on the picked item
    // carry the chosen size.
    pickTableSize(event: Event): void {
        const target = event.target as HTMLElement | null;
        const item = target?.closest(".dropdown__item") as HTMLElement | null;
        if (!item) return;
        const rows = parseInt(item.dataset.keralamRows ?? "", 10);
        const cols = parseInt(item.dataset.keralamCols ?? "", 10);
        if (!rows || !cols) return;
        this.quill.focus();
        const tableBetter = this.quill.getModule("table-better") as TableBetterModule;
        tableBetter.insertTable(rows, cols);
        if (this.hasTableDropdownTarget && this.tableDropdownTarget.tagName === "DETAILS") {
            this.tableDropdownTarget.removeAttribute("open");
        }
    }

    // Header dropdown (Paragraph / H1 / H2 / H3).
    pickHeader(event: Event): void {
        const target = event.target as HTMLElement | null;
        const item = target?.closest(".dropdown__item") as HTMLElement | null;
        if (!item) return;
        const raw = item.dataset.keralamHeader;
        if (raw === undefined) return;
        const value = raw === "false" ? false : parseInt(raw, 10);
        this.quill.focus();
        this.quill.format("header", value, "user");
        if (this.hasHeaderDropdownTarget && this.headerDropdownTarget.tagName === "DETAILS") {
            this.headerDropdownTarget.removeAttribute("open");
        }
    }

    private syncHeaderLabel = (): void => {
        if (!this.hasHeaderDropdownTarget) return;
        const triggerLabel = this.headerDropdownTarget.querySelector("summary > span:first-child");
        if (!triggerLabel || !this.quill.hasFocus()) return;
        const current = this.quill.getFormat()["header"];
        const value = current === undefined ? "false" : String(current);
        triggerLabel.textContent = HEADER_LABELS[value] ?? "Paragraph";
    };

    // ------------------------------------------------------------------
    // Public API — replaces the old window.keralam.editor.* global.
    // ------------------------------------------------------------------

    getContents(): DeltaLike | null {
        try {
            return this.quill.getContents() as unknown as DeltaLike;
        } catch (e) {
            console.warn("[keralam.editor] getContents failed:", e);
            return null;
        }
    }

    setContents(delta: DeltaLike | string): boolean {
        const parsed = typeof delta === "string" ? safeJSON(delta) : delta;
        if (!parsed || !Array.isArray(parsed.ops)) return false;
        try {
            this.quill.setContents(parsed.ops);
            this.syncHiddenFromQuill();
            return true;
        } catch (e) {
            console.warn("[keralam.editor] setContents failed:", e);
            return false;
        }
    }

    getJSON(): string {
        const delta = this.getContents();
        return delta ? JSON.stringify(delta) : "";
    }

    setJSON(json: string): boolean {
        return this.setContents(json);
    }

    clear(): boolean {
        return this.setContents(defaultDelta());
    }

    getText(): string {
        return this.quill.getText() || "";
    }

    insertImage(src: string, altText?: string): boolean {
        const range = this.quill.getSelection(true) || { index: this.quill.getLength() - 1, length: 0 };
        this.quill.insertEmbed(range.index, "image", src, "user");
        if (altText) this.quill.formatText(range.index, 1, "alt", altText, "user");
        return true;
    }

    sync(): void {
        this.syncHiddenFromQuill();
    }

    // ------------------------------------------------------------------
    // Uploads — outsourced to the app via custom events. Listen on
    // `document` for "keralam:editor:upload-image" / "keralam:editor:upload-file"
    // and set `event.detail.promise` to a Promise<string> resolving to
    // the uploaded file's URL.
    // ------------------------------------------------------------------

    private requestUpload(kind: "image" | "file", file: File): Promise<string> | undefined {
        const event = this.dispatch(kind === "image" ? "upload-image" : "upload-file", {
            prefix: "keralam:editor",
            detail: { file, id: this.element.id, promise: undefined as Promise<string> | undefined },
        });
        return (event.detail as { promise?: Promise<string> }).promise;
    }

    private insertImageFromFile(file: File): void {
        const promise = this.requestUpload("image", file);
        if (!promise) {
            window.alert(
                "Image upload handler not configured.\n\n" +
                "Listen for the \"keralam:editor:upload-image\" event on document and " +
                "set event.detail.promise to a Promise<string> URL.",
            );
            return;
        }
        this.pendingUploads++;
        promise
            .then((url) => {
                if (!url) {
                    console.warn("[keralam.editor] upload-image handler resolved with no URL");
                    return;
                }
                const range = this.quill.getSelection(true) || { index: this.quill.getLength() - 1, length: 0 };
                this.quill.insertEmbed(range.index, "image", url, "user");
                this.quill.setSelection(range.index + 1, 0, "silent");
            })
            .catch((err) => {
                console.error("[keralam.editor] upload-image handler rejected:", err);
            })
            .finally(() => {
                this.pendingUploads = Math.max(0, this.pendingUploads - 1);
            });
    }

    // Uploads the File via the "keralam:editor:upload-file" event contract
    // and inserts a paperclip-iconed link wrapping the filename at the
    // current selection. The icon is drawn by
    // `css/components/editor.css`'s `a.keralam-file-link::before` rule
    // (Tabler paperclip as a data URI), so no inline SVG / emoji is
    // embedded in the document — keeps the Delta portable.
    private insertFileFromFile(file: File): void {
        const promise = this.requestUpload("file", file);
        if (!promise) {
            window.alert(
                "File upload handler not configured.\n\n" +
                "Listen for the \"keralam:editor:upload-file\" event on document and " +
                "set event.detail.promise to a Promise<string> URL.",
            );
            return;
        }
        this.pendingUploads++;
        promise
            .then((url) => {
                if (!url) {
                    console.warn("[keralam.editor] upload-file handler resolved with no URL");
                    return;
                }
                const range = this.quill.getSelection(true) || { index: this.quill.getLength() - 1, length: 0 };
                const insertIndex = range.index;
                const filename = file.name || "file";
                this.quill.insertText(insertIndex, filename, "user");
                this.quill.setSelection(insertIndex, filename.length, "user");
                this.quill.format("link", url, "user");
                const linkNode = this.quill.getLeaf(insertIndex)[0]?.domNode as HTMLElement | undefined;
                linkNode?.closest("a")?.classList.add("keralam-file-link");
                this.quill.setSelection(insertIndex + filename.length, 0, "silent");
            })
            .catch((err) => {
                console.error("[keralam.editor] upload-file handler rejected:", err);
            })
            .finally(() => {
                this.pendingUploads = Math.max(0, this.pendingUploads - 1);
            });
    }

    private findHiddenInput(config: EditorConfig): HTMLInputElement | null {
        let hidden = this.element.querySelector<HTMLInputElement>('input[type="hidden"]');
        if (!hidden && config.name) {
            const form = this.element.closest("form");
            if (form) {
                hidden = form.querySelector<HTMLInputElement>(
                    `input[type="hidden"][name="${CSS.escape(config.name)}"]`,
                );
            }
        }
        return hidden ?? null;
    }

    private syncHiddenFromQuill(): void {
        if (!this.hiddenInput) return;
        let delta;
        try {
            delta = this.quill.getContents();
        } catch (e) {
            console.warn("[keralam.editor] getContents failed:", e);
            return;
        }
        const ops = Array.isArray(delta?.ops) ? delta.ops : [];
        if (ops.length === 0 || (ops.length === 1 && ops[0].insert === "\n")) {
            this.hiddenInput.value = "";
        } else {
            this.hiddenInput.value = JSON.stringify(delta);
        }
    }

    private plainTextLength(): number {
        const text = this.quill.getText() || "";
        return text.endsWith("\n") ? text.length - 1 : text.length;
    }
}
