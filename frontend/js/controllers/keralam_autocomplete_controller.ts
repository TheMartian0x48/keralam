import { Controller } from '@hotwired/stimulus';

interface AutocompleteOption {
    label: string;
    value: string;
}

export default class AutocompleteController extends Controller {
    static values = {
        options: { type: Array, default: [] },
        initial: { type: String, default: '' },
    };

    static targets = ['input', 'menu', 'announcer', 'field'];

    declare optionsValue: AutocompleteOption[];
    declare initialValue: string;
    declare readonly inputTarget: HTMLInputElement;
    declare readonly menuTarget: HTMLElement;
    declare readonly announcerTarget: HTMLElement;
    declare readonly fieldTarget: HTMLInputElement;
    declare readonly hasFieldTarget: boolean;

    private _filtered: AutocompleteOption[] = [];
    private _highlighted = -1;
    private _open = false;
    // True while we move focus ourselves after a pick. Without it the input's own
    // focus handler would reopen the menu we just closed.
    private _restoringFocus = false;
    // True from mousedown on the list until the click completes.
    private _pointerInMenu = false;

    connect(): void {
        this.inputTarget.value = this.initialValue;
        this._filtered = this.optionsValue;
        this._renderMenu();
        this._setOpen(false);
        this._syncValidity();
    }

    search(): void {
        // Editing the text invalidates any earlier pick: the field holds a value
        // only while the text still names an option.
        this._setField('');
        const term = this.inputTarget.value.toLowerCase();
        this._filtered = term === ''
            ? this.optionsValue
            : this.optionsValue.filter(o => o.label.toLowerCase().includes(term));
        this._highlighted = -1;
        this._renderMenu();
        this._setOpen(true);
        this._announce();
    }

    navigate(e: KeyboardEvent): void {
        if (!this._open && e.key !== 'ArrowDown') return;
        switch (e.key) {
            case 'ArrowDown':
                e.preventDefault();
                if (!this._open) { this._setOpen(true); return; }
                this._highlighted = Math.min(this._highlighted + 1, this._filtered.length - 1);
                this._updateHighlight();
                break;
            case 'ArrowUp':
                e.preventDefault();
                this._highlighted = Math.max(this._highlighted - 1, 0);
                this._updateHighlight();
                break;
            case 'Enter':
                e.preventDefault();
                if (this._open && this._highlighted >= 0) {
                    this._selectOption(this._filtered[this._highlighted]);
                }
                break;
            case 'Escape':
                e.preventDefault();
                this._setOpen(false);
                this.inputTarget.focus();
                break;
        }
    }

    pressItem(): void {
        this._pointerInMenu = true;
    }

    selectItem(e: Event): void {
        this._pointerInMenu = false;
        const li = (e.target as HTMLElement).closest('li');
        if (!li) return;
        const idx = parseInt(li.dataset.index ?? '-1', 10);
        if (idx >= 0 && idx < this._filtered.length) {
            this._selectOption(this._filtered[idx]);
        }
    }

    highlightItem(e: Event): void {
        const li = (e.target as HTMLElement).closest('li');
        if (!li) return;
        this._highlighted = parseInt(li.dataset.index ?? '-1', 10);
        this._updateHighlight();
    }

    clickOutside(e: Event): void {
        if (!this.element.contains(e.target as Node)) {
            this._setOpen(false);
        }
    }

    focusOpen(): void {
        if (this._restoringFocus) return;
        this._setOpen(true);
    }

    // On blur, text that exactly matches an option's label counts as a pick.
    // Anything else leaves the field empty, so a form never submits free text.
    commit(e?: FocusEvent): void {
        if (e?.relatedTarget instanceof Node && this.menuTarget.contains(e.relatedTarget)) return;
        if (this._pointerInMenu) return;
        if (this.hasFieldTarget && this.fieldTarget.value !== '') return;
        const text = this.inputTarget.value;
        const match = this.optionsValue.find(o => o.label === text);
        if (match) {
            this._setField(match.value);
            this.dispatch('select', { detail: { value: match.value, label: match.label }, bubbles: true });
        }
    }

    private _selectOption(option: AutocompleteOption): void {
        this.inputTarget.value = option.label;
        this._setField(option.value);
        this._setOpen(false);
        this._restoringFocus = true;
        this.inputTarget.focus();
        this._restoringFocus = false;
        this.dispatch('select', { detail: { value: option.value, label: option.label }, bubbles: true });
    }

    // The hidden field is what a form submits: the machine value, never the label.
    private _setField(value: string): void {
        if (this.hasFieldTarget) this.fieldTarget.value = value;
        this._syncValidity();
    }

    // Browsers ignore `required` on hidden inputs, so the visible input carries
    // the rule: required means "pick an option", not "type something".
    private _syncValidity(): void {
        if (!this.hasFieldTarget) return;
        const missing = this.inputTarget.required && this.fieldTarget.value === '';
        this.inputTarget.setCustomValidity(missing ? 'Choose an option from the list.' : '');
    }

    private _setOpen(open: boolean): void {
        this._open = open;
        this.menuTarget.hidden = !open;
        this.inputTarget.setAttribute('aria-expanded', String(open));
        if (!open) {
            this._highlighted = -1;
            this._updateHighlight();
        }
    }

    private _renderMenu(): void {
        this.menuTarget.innerHTML = '';
        if (this._filtered.length === 0) {
            const li = document.createElement('li');
            li.className = 'autocomplete__item autocomplete__item--empty';
            li.setAttribute('role', 'option');
            li.setAttribute('aria-disabled', 'true');
            li.textContent = 'No results found.';
            this.menuTarget.appendChild(li);
            return;
        }
        this._filtered.forEach((opt, i) => {
            const li = document.createElement('li');
            li.className = 'autocomplete__item';
            li.setAttribute('role', 'option');
            li.setAttribute('aria-selected', 'false');
            li.dataset.index = String(i);
            li.id = `${this.element.id}-option-${i}`;
            li.textContent = opt.label;
            this.menuTarget.appendChild(li);
        });
    }

    private _updateHighlight(): void {
        const items = this.menuTarget.querySelectorAll<HTMLElement>('li[data-index]');
        items.forEach((li, i) => {
            const active = i === this._highlighted;
            li.classList.toggle('autocomplete__item--highlighted', active);
            li.setAttribute('aria-selected', String(active));
        });
        const activeId = this._highlighted >= 0 ? `${this.element.id}-option-${this._highlighted}` : '';
        this.inputTarget.setAttribute('aria-activedescendant', activeId);
    }

    private _announce(): void {
        const count = this._filtered.length;
        this.announcerTarget.textContent = count === 0
            ? 'No results found.'
            : `${count} result${count === 1 ? '' : 's'} available.`;
    }
}
