import { Controller } from '@hotwired/stimulus';

/**
 * Closes the native <dialog> it is attached to.
 *
 * Opening needs no script: a button with command="show-modal" and
 * commandfor="<dialog id>" does it declaratively. Closing from inside the dialog
 * is a click handler here, instead of an inline onclick, so the page works under
 * a strict Content-Security-Policy.
 */
export default class DialogController extends Controller<HTMLDialogElement> {
    close(): void {
        this.element.close();
    }
}
