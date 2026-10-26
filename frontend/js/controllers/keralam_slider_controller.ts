import { Controller } from '@hotwired/stimulus';

/**
 * Keeps a slider's filled track and its readout in step with the thumb.
 *
 * The server writes the starting fill (--slider-pct on the input) and the starting number;
 * this updates both on every input event. The readout is an <output>, not a live region:
 * the slider announces its own value to a screen reader.
 */
export default class SliderController extends Controller<HTMLElement> {
    static targets = ['input', 'output'];
    static values = {
        unit: { type: String, default: '' },
    };

    declare readonly inputTarget: HTMLInputElement;
    declare readonly hasOutputTarget: boolean;
    declare readonly outputTarget: HTMLOutputElement;
    declare unitValue: string;

    connect(): void {
        this.update();
    }

    update(): void {
        const input = this.inputTarget;
        const low = input.min === '' ? 0 : Number(input.min);
        const high = input.max === '' ? 100 : Number(input.max);
        const percent = high > low ? ((Number(input.value) - low) / (high - low)) * 100 : 0;
        input.style.setProperty('--slider-pct', `${Math.min(Math.max(percent, 0), 100).toFixed(2)}%`);
        if (this.hasOutputTarget) this.outputTarget.textContent = `${input.value}${this.unitValue}`;
    }
}
