import { Controller } from '@hotwired/stimulus';

export default class AlertController extends Controller {
    static values = {
        timeout: { type: Number, default: 0 },
    };

    declare timeoutValue: number;
    private _timer: ReturnType<typeof setTimeout> | null = null;

    connect(): void {
        this.element.setAttribute('data-state', 'visible');
        if (this.timeoutValue > 0) {
            this._timer = setTimeout(() => this.dismiss(), this.timeoutValue);
        }
    }

    disconnect(): void {
        if (this._timer) clearTimeout(this._timer);
    }

    dismiss(): void {
        this.element.setAttribute('data-state', 'hidden');
        const duration = this._transitionDuration();
        setTimeout(() => this.element.remove(), duration);
    }

    maybeEscape(e: KeyboardEvent): void {
        if (e.key === 'Escape' && this.element.contains(document.activeElement)) {
            this.dismiss();
        }
    }

    private _transitionDuration(): number {
        const style = getComputedStyle(this.element);
        const raw = style.transitionDuration || '0s';
        return parseFloat(raw) * (raw.endsWith('ms') ? 1 : 1000);
    }
}
