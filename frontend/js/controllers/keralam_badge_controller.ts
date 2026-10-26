import { Controller } from '@hotwired/stimulus';

export default class BadgeController extends Controller {
    dismiss(): void {
        this.dispatch('dismiss', { bubbles: true, cancelable: true });
        this.element.remove();
    }
}
