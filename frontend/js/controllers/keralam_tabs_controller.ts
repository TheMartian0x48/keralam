import { Controller } from '@hotwired/stimulus';

export default class TabsController extends Controller {
    static values = {
        active: String,
        orientation: { type: String, default: 'horizontal' },
    };

    static targets = ['trigger', 'panel'];

    declare activeValue: string;
    declare orientationValue: string;
    declare readonly triggerTargets: HTMLElement[];
    declare readonly panelTargets: HTMLElement[];

    activeValueChanged(value: string): void {
        this.triggerTargets.forEach(trigger => {
            const isActive = trigger.dataset.value === value;
            trigger.dataset.state = isActive ? 'active' : 'inactive';
            trigger.setAttribute('aria-selected', String(isActive));
            trigger.setAttribute('tabindex', isActive ? '0' : '-1');
        });
        this.panelTargets.forEach(panel => {
            const isActive = panel.dataset.value === value;
            panel.dataset.state = isActive ? 'active' : 'inactive';
            panel.hidden = !isActive;
        });
    }

    select(e: Event): void {
        const trigger = (e.currentTarget as HTMLElement);
        const value = trigger.dataset.value;
        if (value) this.activeValue = value;
    }

    // Arrow keys follow the orientation (Left/Right in a row, Up/Down in a column);
    // Home and End jump to the ends. Disabled tabs are skipped.
    navigate(e: KeyboardEvent): void {
        const triggers = this.triggerTargets.filter(t => !t.hasAttribute('disabled'));
        const idx = triggers.indexOf(e.currentTarget as HTMLElement);
        if (idx === -1) return;

        const vertical = this.orientationValue === 'vertical';
        const previousKey = vertical ? 'ArrowUp' : 'ArrowLeft';
        const nextKey = vertical ? 'ArrowDown' : 'ArrowRight';

        let next = idx;
        if (e.key === nextKey) next = (idx + 1) % triggers.length;
        else if (e.key === previousKey) next = (idx - 1 + triggers.length) % triggers.length;
        else if (e.key === 'Home') next = 0;
        else if (e.key === 'End') next = triggers.length - 1;
        else return;

        e.preventDefault();
        triggers[next].focus();
        triggers[next].click();
    }
}
