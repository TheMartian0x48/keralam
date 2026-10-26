import { Controller } from '@hotwired/stimulus';

const ITEM_SELECTOR = '[role="menuitem"]';

/**
 * Behaviour for the dropdown menu, a native <details>.
 *
 * <details> opens and closes on a click of its <summary>, and does nothing else.
 * This controller adds what a menu needs:
 *
 *   closes on     an outside click, Escape, a pick, or focus leaving the menu
 *   Escape / pick returns focus to the trigger
 *   ArrowDown/Up  on the trigger opens the menu and focuses the first/last item
 *   ArrowDown/Up  between items, wrapping at the ends
 *   Home / End    first / last item
 *
 * Items are taken out of the Tab order (tabindex -1), as in a menu: Tab leaves it.
 */
export default class DropdownController extends Controller<HTMLDetailsElement> {
    connect(): void {
        this.element.addEventListener('toggle', this._onToggle);
        this.element.addEventListener('keydown', this._onKeydown);
        this.element.addEventListener('focusout', this._onFocusOut);
        this.element.addEventListener('click', this._onClick);
        document.addEventListener('click', this._onDocumentClick);
        this._items().forEach(item => item.setAttribute('tabindex', '-1'));
        this._onToggle();
    }

    disconnect(): void {
        this.element.removeEventListener('toggle', this._onToggle);
        this.element.removeEventListener('keydown', this._onKeydown);
        this.element.removeEventListener('focusout', this._onFocusOut);
        this.element.removeEventListener('click', this._onClick);
        document.removeEventListener('click', this._onDocumentClick);
    }

    private get _trigger(): HTMLElement | null {
        return this.element.querySelector<HTMLElement>(':scope > summary');
    }

    private _items(): HTMLElement[] {
        return Array.from(this.element.querySelectorAll<HTMLElement>(ITEM_SELECTOR))
            .filter(item => !item.hasAttribute('disabled') && item.getAttribute('aria-disabled') !== 'true');
    }

    private _close(restoreFocus: boolean): void {
        if (!this.element.open) return;
        this.element.open = false;
        if (restoreFocus) this._trigger?.focus();
    }

    // Sync aria-expanded when <details> toggles (fires after the open state changes).
    private _onToggle = (): void => {
        this._trigger?.setAttribute('aria-expanded', String(this.element.open));
    };

    private _onDocumentClick = (e: MouseEvent): void => {
        if (this.element.open && !this.element.contains(e.target as Node)) {
            this._close(false);
        }
    };

    // A pick closes the menu. Labels and dividers are not items, so clicking them does not.
    private _onClick = (e: MouseEvent): void => {
        if ((e.target as Element).closest(ITEM_SELECTOR)) {
            this._close(true);
        }
    };

    // Closes only when focus moves to something outside; a null target (clicking a
    // non-focusable part of the menu) is not leaving it.
    private _onFocusOut = (e: FocusEvent): void => {
        const next = e.relatedTarget;
        if (next instanceof Node && !this.element.contains(next)) {
            this._close(false);
        }
    };

    private _onKeydown = (e: KeyboardEvent): void => {
        const trigger = this._trigger;
        const onTrigger = e.target === trigger;

        if (e.key === 'Escape') {
            if (this.element.open) {
                e.preventDefault();
                this._close(true);
            }
            return;
        }

        const items = this._items();
        if (items.length === 0) return;

        if (onTrigger) {
            if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
                e.preventDefault();
                this.element.open = true;
                (e.key === 'ArrowDown' ? items[0] : items[items.length - 1]).focus();
            }
            return;
        }

        const index = items.indexOf(document.activeElement as HTMLElement);
        let next = -1;
        switch (e.key) {
            case 'ArrowDown': next = (index + 1) % items.length; break;
            case 'ArrowUp': next = (index - 1 + items.length) % items.length; break;
            case 'Home': next = 0; break;
            case 'End': next = items.length - 1; break;
            default: return;
        }
        e.preventDefault();
        items[next].focus();
    };
}
