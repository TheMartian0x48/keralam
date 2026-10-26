import { Controller } from '@hotwired/stimulus';

/**
 * Applies the indeterminate state to the native checkbox.
 *
 * `indeterminate` is a DOM property with no HTML attribute, so server-rendered
 * markup can only ask for it through data-indeterminate. The browser clears the
 * property itself when the user clicks, and the stylesheet draws the dash from
 * :indeterminate, so nothing else needs to be kept in step.
 */
export default class CheckboxController extends Controller {
    static targets = ['input'];

    declare readonly inputTarget: HTMLInputElement;
    declare readonly hasInputTarget: boolean;

    connect(): void {
        if (this.hasInputTarget && this.inputTarget.dataset.indeterminate === 'true') {
            this.inputTarget.indeterminate = true;
        }
    }
}
