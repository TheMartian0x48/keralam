import { Controller } from '@hotwired/stimulus';

/**
 * Lets Escape dismiss a tooltip without moving the pointer or the focus (WCAG 1.4.13).
 *
 * The tooltip opens from CSS (:hover and :focus-within). Escape sets data-dismissed, which
 * the CSS honours; leaving the element, or focusing or hovering it again, clears it.
 */
export default class TooltipController extends Controller<HTMLElement> {
    connect(): void {
        this.element.addEventListener('pointerenter', this.reset);
        this.element.addEventListener('pointerleave', this.reset);
        this.element.addEventListener('focusin', this.reset);
    }

    disconnect(): void {
        this.element.removeEventListener('pointerenter', this.reset);
        this.element.removeEventListener('pointerleave', this.reset);
        this.element.removeEventListener('focusin', this.reset);
    }

    dismiss(e: KeyboardEvent): void {
        if (e.key === 'Escape') this.element.setAttribute('data-dismissed', '');
    }

    private reset = (): void => {
        this.element.removeAttribute('data-dismissed');
    };
}
