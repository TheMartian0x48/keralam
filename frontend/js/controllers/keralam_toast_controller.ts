import { Controller } from '@hotwired/stimulus';

type ToastTypeValue = 'info' | 'success' | 'warning' | 'danger';
type ToastPositionValue = 'top-left' | 'top-center' | 'top-right' | 'bottom-left' | 'bottom-center' | 'bottom-right';

interface ShowToastOptions {
    // Milliseconds before it closes; 0 keeps it until closed. Omitted: 5 seconds for info and
    // success, never for warning and danger.
    duration?: number;
}

interface ToastDetail {
    message: string;
    type?: ToastTypeValue;
    title?: string;
    position?: ToastPositionValue;
    duration?: number;
}

const toastsMax = 5;
const durationDefault = 5000;
const durationMax = 60 * 60 * 1000;
const exitMilliseconds = 250;

const prefersReducedMotion = (): boolean =>
    window.matchMedia('(prefers-reduced-motion: reduce)').matches;

/**
 * Shows toasts in one container. The container is the page's only live region (the toasts
 * inside it carry no aria-live of their own), so a toast is announced once.
 *
 * A toast closes after its duration, but the countdown stops while the pointer or the focus
 * is on it, Escape closes the focused one, and at most five stay on screen.
 */
export default class ToastController extends Controller<HTMLElement> {
    static targets = ['template'];
    static values = {
        position: { type: String, default: 'bottom-right' },
    };

    declare positionValue: ToastPositionValue;
    declare readonly templateTarget: HTMLTemplateElement;

    connect(): void {
        window.addEventListener('toast:show', this._onShow);
        document.addEventListener('click', this._onTriggerClick);
        // Server-rendered toasts get the same pause and Escape behaviour.
        this.element.querySelectorAll<HTMLElement>('.toast').forEach(toast => this._attach(toast, 0));
    }

    disconnect(): void {
        window.removeEventListener('toast:show', this._onShow);
        document.removeEventListener('click', this._onTriggerClick);
    }

    dismiss(e: Event): void {
        const toast = (e.target as HTMLElement).closest<HTMLElement>('.toast');
        if (toast) this._dismissToast(toast);
    }

    showToast(
        message: string,
        type: ToastTypeValue = 'info',
        title = '',
        options: ShowToastOptions = {},
    ): HTMLElement {
        const role = (type === 'danger' || type === 'warning') ? 'alert' : null;

        const fragment = this.templateTarget.content.cloneNode(true) as DocumentFragment;
        const toast = fragment.querySelector('.toast') as HTMLElement;
        toast.classList.add(`toast--${type}`);
        if (role) toast.setAttribute('role', role);

        toast.querySelectorAll('[data-keralam-toast-icon]').forEach((icon) => {
            if (icon.getAttribute('data-keralam-toast-icon') === type) {
                icon.removeAttribute('hidden');
            } else {
                icon.remove();
            }
        });

        const titleEl = toast.querySelector('[data-keralam-toast-part="title"]');
        if (title) {
            titleEl!.textContent = title;
        } else {
            titleEl?.remove();
        }
        // textContent, never innerHTML: a message is text.
        toast.querySelector('[data-keralam-toast-part="message"]')!.textContent = message;

        const urgent = type === 'danger' || type === 'warning';
        const requested = options.duration;
        const duration = requested === undefined ? (urgent ? 0 : durationDefault) : Math.min(Math.max(requested, 0), durationMax);

        // The oldest goes first when a sixth arrives.
        const showing = this.element.querySelectorAll<HTMLElement>('.toast');
        for (let i = 0; i <= showing.length - toastsMax; i++) showing[i].remove();

        this.element.appendChild(toast);
        this._attach(toast, duration);
        return toast;
    }

    // Escape, and a countdown that holds while the pointer or focus is on the toast.
    private _attach(toast: HTMLElement, duration: number): void {
        toast.addEventListener('keydown', (e: KeyboardEvent) => {
            if (e.key === 'Escape') this._dismissToast(toast);
        });
        if (duration <= 0) return;

        let remaining = duration;
        let startedAt = 0;
        let timer = 0;
        let holds = 0;
        const start = (): void => {
            startedAt = Date.now();
            timer = window.setTimeout(() => {
                if (toast.isConnected) this._dismissToast(toast);
            }, remaining);
        };
        const hold = (): void => {
            if (holds++ > 0) return;
            window.clearTimeout(timer);
            remaining -= Date.now() - startedAt;
        };
        const release = (): void => {
            if (holds === 0 || --holds > 0) return;
            start();
        };
        toast.addEventListener('pointerenter', hold);
        toast.addEventListener('pointerleave', release);
        toast.addEventListener('focusin', hold);
        toast.addEventListener('focusout', release);
        start();
    }

    private _dismissToast(toast: HTMLElement): void {
        if (toast.dataset.leaving) return;
        toast.dataset.leaving = 'true';
        toast.style.opacity = '0';
        const position = this.positionValue;
        if (position.includes('right')) toast.style.transform = 'translateX(100%)';
        else if (position.includes('left')) toast.style.transform = 'translateX(-100%)';
        else if (position.includes('top')) toast.style.transform = 'translateY(-100%)';
        else toast.style.transform = 'translateY(100%)';

        const delay = prefersReducedMotion() ? 0 : exitMilliseconds;
        setTimeout(() => toast.remove(), delay);
    }

    private _onShow = (e: Event): void => {
        const detail = (e as CustomEvent<ToastDetail>).detail;
        // Only handle if this container matches the requested position
        const pos = detail.position ?? 'bottom-right';
        if (pos !== this.positionValue) return;
        this.showToast(detail.message, detail.type, detail.title, { duration: detail.duration });
    };

    // Any element with data-toast-message shows a toast when clicked. Only the container at
    // the element's position reacts, so this runs once per matching container.
    private _onTriggerClick = (e: Event): void => {
        const trigger = (e.target as HTMLElement).closest<HTMLElement>('[data-toast-message]');
        if (!trigger) return;
        const data = trigger.dataset;
        if ((data.toastPosition ?? 'bottom-right') !== this.positionValue) return;
        const type = (data.toastType ?? 'info') as ToastTypeValue;
        this.showToast(data.toastMessage ?? '', type, data.toastTitle ?? '');
    };
}

// Thin global shim — dispatches a custom event picked up by ToastController
declare global {
    interface Window {
        showToast(
            message: string,
            type?: ToastTypeValue,
            title?: string,
            position?: ToastPositionValue,
            options?: ShowToastOptions,
        ): void;
    }
}

window.showToast = (message, type = 'info', title = '', position = 'bottom-right', options = {}) => {
    window.dispatchEvent(new CustomEvent<ToastDetail>('toast:show', {
        detail: { message, type, title, position, ...options },
    }));
};
