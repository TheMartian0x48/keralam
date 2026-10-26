import { Controller } from '@hotwired/stimulus';

const filesLimit = 100;

/**
 * A file picker that also takes drops and pastes.
 *
 * The real control is the <input type=file> behind the area, so a click works without any
 * script. This adds drop and paste, a list of the chosen files, and the limits the server
 * markup declares (accept, one file or many, count, size). The limits are a convenience for
 * the person filling in the form, not a security check: the server must check them again.
 *
 * Files reach the input exactly once per user action. Setting input.files does not fire a
 * change event, and this code never dispatches one itself, so nothing loops.
 */
export default class DropzoneController extends Controller<HTMLElement> {
    static values = {
        disabled: { type: Boolean, default: false },
        multiple: { type: Boolean, default: false },
        accept: { type: String, default: '' },
        maxFiles: { type: Number, default: 0 },
        maxBytes: { type: Number, default: 0 },
        removeLabel: { type: String, default: 'Remove' },
    };

    static targets = ['fileInput', 'content', 'preview', 'fileList', 'status', 'rejections'];

    declare disabledValue: boolean;
    declare multipleValue: boolean;
    declare acceptValue: string;
    declare maxFilesValue: number;
    declare maxBytesValue: number;
    declare removeLabelValue: string;
    declare readonly fileInputTarget: HTMLInputElement;
    declare readonly contentTarget: HTMLElement;
    declare readonly previewTarget: HTMLElement;
    declare readonly fileListTarget: HTMLElement;
    declare readonly statusTarget: HTMLElement;
    declare readonly rejectionsTarget: HTMLElement;

    connect(): void {
        this._render(Array.from(this.fileInputTarget.files ?? []));
    }

    // A zone that is disabled still cancels the drag, or the browser opens the file.
    dragover(e: DragEvent): void {
        e.preventDefault();
        if (this.disabledValue) {
            if (e.dataTransfer) e.dataTransfer.dropEffect = 'none';
            return;
        }
        this.element.setAttribute('data-dragging', 'true');
    }

    dragleave(e: DragEvent): void {
        if (e.relatedTarget instanceof Node && this.element.contains(e.relatedTarget)) return;
        this.element.removeAttribute('data-dragging');
    }

    drop(e: DragEvent): void {
        e.preventDefault();
        this.element.removeAttribute('data-dragging');
        if (this.disabledValue) return;
        const files = e.dataTransfer?.files;
        if (files && files.length > 0) this._take(Array.from(files));
    }

    paste(e: ClipboardEvent): void {
        if (this.disabledValue) return;
        const pasted: File[] = [];
        for (const item of Array.from(e.clipboardData?.items ?? [])) {
            const file = item.kind === 'file' ? item.getAsFile() : null;
            if (file) pasted.push(file);
        }
        if (pasted.length > 0) {
            e.preventDefault();
            this._take(pasted);
        }
    }

    // The native chooser already put the files in the input; check them like any others.
    change(): void {
        this._take(Array.from(this.fileInputTarget.files ?? []), true);
    }

    removeFile(e: Event): void {
        if (this.disabledValue) return;
        const button = (e.currentTarget as HTMLElement);
        const index = Number(button.dataset.index ?? -1);
        const files = Array.from(this.fileInputTarget.files ?? []);
        if (index < 0 || index >= files.length) return;
        const removed = files[index].name;
        files.splice(index, 1);
        this._set(files);
        this._announce(`${removed} removed`);
    }

    // Applies the limits to incoming files and then replaces the selection.
    private _take(incoming: File[], fromInput = false): void {
        const rejected: string[] = [];
        let accepted: File[] = [];
        for (const file of incoming.slice(0, filesLimit * 2)) {
            const problem = this._problem(file);
            if (problem) rejected.push(`${file.name} ${problem}`);
            else accepted.push(file);
        }

        // A drop or a paste adds to a many-file zone and replaces in a one-file zone.
        // The chooser already replaced the input's list, so it is taken as is.
        const kept = this.multipleValue && !fromInput ? Array.from(this.fileInputTarget.files ?? []) : [];
        let combined = [...kept, ...accepted];

        const limit = this.multipleValue ? this.maxFilesValue : 1;
        if (limit > 0 && combined.length > limit) {
            const extra = combined.length - limit;
            // One file in a single zone replaces; a many zone keeps the first ones.
            combined = this.multipleValue ? combined.slice(0, limit) : combined.slice(-1);
            if (this.multipleValue) rejected.push(`${extra} more ${extra === 1 ? 'file' : 'files'} not added: at most ${limit}`);
        }

        this._reject(rejected);
        this._set(combined);
        if (combined.length > 0 || rejected.length === 0) {
            this._announce(`${combined.length} ${combined.length === 1 ? 'file' : 'files'} selected`);
        }
    }

    private _problem(file: File): string {
        if (this.maxBytesValue > 0 && file.size > this.maxBytesValue) {
            return `is larger than ${this._size(this.maxBytesValue)}`;
        }
        if (this.acceptValue && !this._accepted(file)) return 'is not an accepted type';
        return '';
    }

    // The same rules as the accept attribute: extensions, MIME types, and type/* wildcards.
    private _accepted(file: File): boolean {
        const name = file.name.toLowerCase();
        const type = file.type.toLowerCase();
        return this.acceptValue.split(',').map(t => t.trim().toLowerCase()).filter(Boolean).some(token => {
            if (token.startsWith('.')) return name.endsWith(token);
            if (token.endsWith('/*')) return type.startsWith(token.slice(0, -1));
            return type === token;
        });
    }

    // Puts the files in the input, so they submit with the form, and redraws the list.
    // Assigning input.files fires no change event: nothing here can loop.
    private _set(files: File[]): void {
        const transfer = new DataTransfer();
        files.forEach(file => transfer.items.add(file));
        this.fileInputTarget.files = transfer.files;
        this._render(files);
        this.dispatch('change', { detail: { files }, bubbles: true });
    }

    private _render(files: File[]): void {
        const has = files.length > 0;
        this.contentTarget.hidden = has;
        this.previewTarget.hidden = !has;

        this.fileListTarget.replaceChildren();
        files.forEach((file, index) => {
            const item = document.createElement('li');
            item.className = 'dropzone__file-item';

            const info = document.createElement('span');
            info.className = 'dropzone__file-info';
            const name = document.createElement('span');
            name.className = 'dropzone__file-name';
            name.textContent = file.name;
            const size = document.createElement('span');
            size.className = 'dropzone__file-size';
            size.textContent = this._size(file.size);
            info.append(name, size);

            const remove = document.createElement('button');
            remove.type = 'button';
            remove.className = 'dropzone__file-remove';
            remove.dataset.index = String(index);
            remove.setAttribute('aria-label', `${this.removeLabelValue} ${file.name}`);
            remove.setAttribute('data-action', 'click->keralam-dropzone#removeFile');
            const icon = document.createElement('i');
            icon.className = 'icon icon--sm ph ph-x';
            icon.setAttribute('aria-hidden', 'true');
            remove.append(icon);

            item.append(info, remove);
            this.fileListTarget.append(item);
        });
    }

    private _reject(messages: string[]): void {
        this.rejectionsTarget.replaceChildren();
        messages.slice(0, 10).forEach(message => {
            const line = document.createElement('div');
            line.textContent = message;
            this.rejectionsTarget.append(line);
        });
    }

    private _announce(text: string): void {
        this.statusTarget.textContent = text;
    }

    private _size(bytes: number): string {
        if (bytes < 1024) return `${bytes} B`;
        if (bytes < 1024 * 1024) return `${+(bytes / 1024).toFixed(1)} KB`;
        if (bytes < 1024 * 1024 * 1024) return `${+(bytes / (1024 * 1024)).toFixed(1)} MB`;
        return `${+(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB`;
    }
}
