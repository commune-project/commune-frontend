import "./style.css";
import {
  normalizeResponse,
  formatTime,
  formattingLocale,
  pluralCategory,
  readPreference,
  savePreference,
} from "./bridge.js";

let storage;
try {
  storage = window.localStorage;
} catch {
  storage = null;
}
const verificationToken =
  location.pathname === "/verify-email"
    ? new URLSearchParams(location.hash.slice(1)).get("token") || ""
    : "";
if (verificationToken)
  history.replaceState(null, "", location.pathname + location.search);
const csrf = () =>
  document.cookie
    .split(";")
    .map((v) => v.trim())
    .find((v) => v.startsWith("__Host-commune_csrf="))
    ?.split("=")
    .slice(1)
    .join("=") || "";
const formatTimes = () => {
  const locale = document.documentElement.lang || "en-US";
  for (const element of document.querySelectorAll("time[data-commune-time]")) {
    const source = element.getAttribute("datetime") || element.textContent || "";
    const formatted = formatTime(locale, source);
    if (element.textContent !== formatted) element.textContent = formatted;
  }
};
const wideMedia = window.matchMedia("(min-width: 1200px)");
const app = window.Elm.Main.init({
  node: document.getElementById("app"),
  flags: {
    languages: navigator.languages || ["en-US"],
    savedLocale: readPreference(storage),
    csrf: csrf(),
    verificationToken,
    wideLayout: wideMedia.matches,
  },
});

wideMedia.addEventListener("change", (event) => {
  app.ports.incoming.send({ kind: "layout", wide: event.matches });
});

let composition = false;
let compositionEndedAt = 0;
document.addEventListener("compositionstart", () => {
  composition = true;
  app.ports.incoming.send({ kind: "composition", active: true });
});
document.addEventListener("compositionend", () => {
  composition = false;
  compositionEndedAt = performance.now();
  app.ports.incoming.send({ kind: "composition", active: false });
});
document.addEventListener(
  "keydown",
  (event) => {
    if (
      event.key === "Enter" &&
      (event.isComposing ||
        composition ||
        event.keyCode === 229 ||
        performance.now() - compositionEndedAt < 80)
    ) {
      event.preventDefault();
    }
  },
  true,
);
app.ports.outgoing.subscribe((message) => {
  if (!message || typeof message.action !== "string") return;
  switch (message.action) {
    case "decode": {
      try {
        app.ports.incoming.send({
          kind: "decoded",
          id: message.id,
          status: message.status,
          value: normalizeResponse(message.body),
        });
      } catch {
        app.ports.incoming.send({
          kind: "decoded",
          id: message.id,
          status: 0,
          value: null,
        });
      }
      break;
    }
    case "locale":
      document.documentElement.lang = message.locale;
      document.documentElement.dir =
        import.meta.env.DEV &&
        new URLSearchParams(location.search).has("test-rtl")
          ? "rtl"
          : "ltr";
      savePreference(storage, message.locale);
      formatTimes();
      break;
    case "csrf":
      app.ports.incoming.send({ kind: "csrf", value: csrf() });
      break;
    case "format": {
      let numbers = [];
      try {
        numbers = message.numbers.map((value) => ({
          source: value,
          text: new Intl.NumberFormat(formattingLocale(message.locale)).format(
            value,
          ),
        }));
      } catch {
        numbers = message.numbers.map((value) => ({
          source: value,
          text: String(value),
        }));
      }
      const plurals = (Array.isArray(message.plurals) ? message.plurals : [])
        .filter(Number.isFinite)
        .map((value) => ({
          source: value,
          category: pluralCategory(message.locale, value),
        }));
      app.ports.incoming.send({
        kind: "formatted",
        locale: message.locale,
        times: [],
        numbers,
        plurals,
      });
      break;
    }
    case "focus":
      requestAnimationFrame(() => document.getElementById(message.id)?.focus());
      break;
    case "replace-range": {
      const element = document.getElementById(message.id);
      if (!element || typeof element.setRangeText !== "function") break;
      const size = element.value.length;
      const start = Math.max(0, Math.min(size, Number(message.start) || 0));
      const end = Math.max(start, Math.min(size, Number(message.end) || start));
      const text = typeof message.text === "string" ? message.text : "";
      element.focus();
      element.setRangeText(text, start, end, "end");
      const caret = Math.max(
        0,
        Math.min(element.value.length, Number(message.caret) || start + text.length),
      );
      element.setSelectionRange(caret, caret);
      element.dispatchEvent(new Event("input", { bubbles: true }));
      break;
    }
    case "dialog-open":
      requestAnimationFrame(() => {
        const dialog = document.getElementById(message.id);
        if (dialog && !dialog.open && typeof dialog.showModal === "function")
          dialog.showModal();
      });
      break;
    case "dialog-close": {
      const dialog = document.getElementById(message.id);
      if (dialog?.open) dialog.close();
      break;
    }
  }
});
formatTimes();
new MutationObserver(formatTimes).observe(document.body, {
  childList: true,
  subtree: true,
  characterData: true,
});
