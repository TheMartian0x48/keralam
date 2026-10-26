import { Controller } from '@hotwired/stimulus';

/**
 * Behaviour for the slide-over drawer, a native <dialog>.
 *
 * It can be opened three ways: a button with command="show-modal" and
 * commandfor="<id>", a window event (dispatchEvent(new CustomEvent('drawer:open',
 * { detail: '<id>' }))), or a call to open(). The page's scroll is locked whenever
 * the dialog is open, however it was opened, by watching its `open` attribute.
 */
export default class DrawerController extends Controller<HTMLDialogElement> {
    private _observer: MutationObserver | null = null;

    connect(): void {
        window.addEventListener('drawer:open', this._onOpen);
        this._observer = new MutationObserver(this._syncScrollLock);
        this._observer.observe(this.element, { attributes: true, attributeFilter: ['open'] });
        this._syncScrollLock();
    }

    disconnect(): void {
        window.removeEventListener('drawer:open', this._onOpen);
        this._observer?.disconnect();
        this._observer = null;
        if (this.element.open) document.body.style.overflow = '';
    }

    open(): void {
        if (!this.element.open) this.element.showModal();
    }

    close(): void {
        this.element.close();
    }

    // The panel fills only part of the dialog, so a click that lands on the dialog
    // itself is a click on the backdrop.
    backdropClick(e: MouseEvent): void {
        if (e.target === this.element) {
            this.close();
        }
    }

    private _onOpen = (e: Event): void => {
        if ((e as CustomEvent<string>).detail === this.element.id) {
            this.open();
        }
    };

    private _syncScrollLock = (): void => {
        document.body.style.overflow = this.element.open ? 'hidden' : '';
    };
}
