/*
 * i18n_feedback widget — self-contained, no framework, no build step.
 *
 * Reads window.__i18nFeedback = { endpoint, locale, active }.
 *
 * A floating pill toggles "suggest mode", which is server state: the pill sets or
 * clears the i18n_feedback cookie and reloads, so the backend only prints the
 * "…text… ⟦some.key.path⟧" markers while proofreading. The markers are never shown
 * to the user — on load the widget strips each ⟦key⟧ token out of the DOM and
 * stashes the key on its element. A click on any such element opens a popover to
 * suggest a wording; navigation is frozen while the popover is open. Esc, or the
 * pill, exits.
 */
(function () {
  "use strict";

  var config = window.__i18nFeedback;
  if (!config || window.__i18nFeedbackLoaded) return;
  window.__i18nFeedbackLoaded = true;

  var LEFT = "⟦"; // ⟦
  var RIGHT = "⟧"; // ⟧
  var TOKEN = new RegExp(LEFT + "([^" + RIGHT + "]+)" + RIGHT);
  var TOKENS = new RegExp("\\s*" + LEFT + "[^" + RIGHT + "]+" + RIGHT, "g");
  var COOKIE = "i18n_feedback";
  var MARKED_ATTRS = ["placeholder", "title", "aria-label", "value"];
  var Z = 2147483000;

  var overlay = null;
  var proposedInput = null;
  var commentInput = null;
  var errorNode = null;
  var saveButton = null;
  var priorNode = null;

  function ready(fn) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", fn);
    } else {
      fn();
    }
  }

  ready(function () {
    injectStyles();
    if (config.showPill !== false) buildPill();
    document.addEventListener("keydown", handleKeydown);

    if (config.active) {
      document.documentElement.classList.add("i18nf-active");
      document.addEventListener("click", handleClick, true);
      document.addEventListener("turbo:load", strip);
      document.addEventListener("turbo:frame-load", strip);
      strip();
    }
  });

  // --- suggest-mode toggle --------------------------------------------------

  function toggle() {
    if (config.active) {
      document.cookie = COOKIE + "=; path=/; max-age=0";
    } else {
      document.cookie = COOKIE + "=1; path=/";
    }
    window.location.reload();
  }

  // --- marker stripping -----------------------------------------------------

  function strip() {
    var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
      acceptNode: function (node) {
        var tag = node.parentElement && node.parentElement.tagName;
        if (tag === "SCRIPT" || tag === "STYLE") return NodeFilter.FILTER_REJECT;
        return TOKEN.test(node.nodeValue) ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT;
      },
    });

    var nodes = [];
    while (walker.nextNode()) nodes.push(walker.currentNode);

    nodes.forEach(function (node) {
      var match = node.nodeValue.match(TOKEN);
      if (!match) return;
      var key = match[1];
      node.nodeValue = node.nodeValue.replace(TOKENS, "");
      var element = node.parentElement;
      if (element) {
        element.dataset.i18nKey = key;
        element.dataset.i18nValue = node.nodeValue.trim();
      }
    });

    MARKED_ATTRS.forEach(function (attr) {
      var selector = "[" + attr + '*="' + LEFT + '"]';
      document.querySelectorAll(selector).forEach(function (element) {
        element.setAttribute(attr, element.getAttribute(attr).replace(TOKENS, ""));
      });
    });
  }

  // --- interaction ----------------------------------------------------------

  function handleClick(event) {
    if (overlay && overlay.contains(event.target)) return;
    if (event.target.closest && event.target.closest(".i18nf-pill")) return;

    // Freeze navigation so a stray click can't leave the page mid-proofread.
    event.preventDefault();
    event.stopPropagation();

    var element = event.target.closest && event.target.closest("[data-i18n-key]");
    if (element) open(element.dataset.i18nKey, element.dataset.i18nValue || "");
  }

  function handleKeydown(event) {
    if (event.key !== "Escape") return;
    if (overlay) close();
    else if (config.active) toggle();
  }

  // --- pill -----------------------------------------------------------------

  function buildPill() {
    var pill = document.createElement("button");
    pill.type = "button";
    pill.className = "i18nf-pill" + (config.active ? " i18nf-pill-on" : "");
    pill.textContent = config.active ? "✓ Suggesting — tap to exit (Esc)" : "✎ " + labelText();
    pill.addEventListener("click", toggle);
    document.body.appendChild(pill);
  }

  function labelText() {
    return (config.pillLabel || "Suggest edits");
  }

  // --- popover --------------------------------------------------------------

  function open(key, currentValue) {
    close();

    overlay = el("div", "i18nf-overlay");
    overlay.addEventListener("click", function (event) {
      if (event.target === overlay) close();
    });

    var panel = el("div", "i18nf-panel");
    panel.appendChild(heading(key));

    priorNode = el("div");
    panel.appendChild(priorNode);

    panel.appendChild(field("Current text", readonly(currentValue)));

    proposedInput = textarea(currentValue);
    panel.appendChild(field("Suggested text", proposedInput));

    commentInput = input("Optional note for the developer");
    panel.appendChild(field("Comment", commentInput));

    errorNode = el("p", "i18nf-error");
    errorNode.style.display = "none";
    panel.appendChild(errorNode);

    panel.appendChild(actions(key, currentValue));

    overlay.appendChild(panel);
    document.body.appendChild(overlay);
    proposedInput.focus();
    loadPrior(key);
  }

  function close() {
    if (overlay) {
      overlay.remove();
      overlay = null;
    }
  }

  function loadPrior(key) {
    var params = new URLSearchParams({ key: key, locale: config.locale });
    fetch(config.endpoint + "?" + params.toString(), { headers: { Accept: "application/json" } })
      .then(function (response) {
        return response.ok ? response.json() : [];
      })
      .then(function (items) {
        if (items && items.length) renderPrior(items);
      })
      .catch(function () {
        // Best-effort context; ignore fetch/parse errors.
      });
  }

  function renderPrior(items) {
    if (!priorNode) return;

    var box = el("div", "i18nf-prior");
    var title = el("p", "i18nf-prior-title");
    title.textContent = "Already suggested (pending)";
    box.appendChild(title);

    var list = el("ul", "i18nf-prior-list");
    items.forEach(function (item) {
      var row = document.createElement("li");
      var who = item.author_label ? " — " + item.author_label : "";
      row.textContent = "“" + item.proposed_value + "”" + who;
      list.appendChild(row);
    });
    box.appendChild(list);

    priorNode.replaceWith(box);
    priorNode = box;
  }

  function actions(key, currentValue) {
    var wrapper = el("div", "i18nf-actions");

    var cancel = el("button", "i18nf-btn i18nf-btn-ghost");
    cancel.type = "button";
    cancel.textContent = "Cancel";
    cancel.addEventListener("click", close);

    saveButton = el("button", "i18nf-btn i18nf-btn-primary");
    saveButton.type = "button";
    saveButton.textContent = "Send suggestion";
    saveButton.addEventListener("click", function () {
      submit(key, currentValue);
    });

    wrapper.appendChild(cancel);
    wrapper.appendChild(saveButton);
    return wrapper;
  }

  function submit(key, currentValue) {
    var proposed = proposedInput.value.trim();
    if (!proposed) {
      showError("Please enter a suggestion.");
      return;
    }

    saveButton.disabled = true;

    fetch(config.endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-CSRF-Token": csrfToken(),
      },
      body: JSON.stringify({
        suggestion: {
          translation_key: key,
          locale: config.locale,
          old_value: currentValue,
          proposed_value: proposed,
          comment: commentInput.value.trim(),
          page_url: window.location.href,
        },
      }),
    })
      .then(function (response) {
        if (response.ok) {
          close();
        } else {
          saveButton.disabled = false;
          showError("Could not save the suggestion.");
        }
      })
      .catch(function () {
        saveButton.disabled = false;
        showError("Could not save the suggestion.");
      });
  }

  function showError(message) {
    errorNode.textContent = message;
    errorNode.style.display = "";
  }

  // --- small DOM builders ---------------------------------------------------

  function heading(key) {
    var wrapper = el("div", "i18nf-heading");
    var title = el("p", "i18nf-title");
    title.textContent = "Suggest a translation fix";
    var code = el("code", "i18nf-key");
    code.textContent = key;
    wrapper.appendChild(title);
    wrapper.appendChild(code);
    return wrapper;
  }

  function field(label, control) {
    var wrapper = el("label", "i18nf-field");
    var text = el("span", "i18nf-label");
    text.textContent = label;
    wrapper.appendChild(text);
    wrapper.appendChild(control);
    return wrapper;
  }

  function readonly(value) {
    var node = el("p", "i18nf-readonly");
    node.textContent = value;
    return node;
  }

  function textarea(value) {
    var node = el("textarea", "i18nf-input");
    node.rows = 3;
    node.value = value;
    return node;
  }

  function input(placeholder) {
    var node = el("input", "i18nf-input");
    node.type = "text";
    node.placeholder = placeholder;
    return node;
  }

  function el(tag, className) {
    var node = document.createElement(tag);
    if (className) node.className = className;
    return node;
  }

  function csrfToken() {
    var meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.content : "";
  }

  // --- styles ---------------------------------------------------------------

  function injectStyles() {
    if (document.getElementById("i18nf-styles")) return;
    var style = document.createElement("style");
    style.id = "i18nf-styles";
    style.textContent = [
      // Only the strings that actually resolve to a key are editable, so only
      // those get the copy cursor and a hover outline.
      ".i18nf-active [data-i18n-key] { cursor: copy; }",
      ".i18nf-active [data-i18n-key]:hover { outline: 1px dashed #2563eb; outline-offset: 2px; }",
      ".i18nf-pill { position: fixed; bottom: 16px; left: 16px; z-index: " + (Z + 1) + ";",
      "  font: 13px/1.2 system-ui, sans-serif; padding: 9px 14px; border-radius: 999px;",
      "  border: 1px solid rgba(0,0,0,.15); background: #fff; color: #111; cursor: pointer;",
      "  box-shadow: 0 4px 14px rgba(0,0,0,.18); }",
      ".i18nf-pill-on { background: #2563eb; color: #fff; border-color: #2563eb; }",
      ".i18nf-overlay { position: fixed; inset: 0; z-index: " + (Z + 2) + "; display: flex;",
      "  align-items: center; justify-content: center; padding: 16px;",
      "  background: rgba(0,0,0,.45); cursor: default; }",
      ".i18nf-panel { width: 28rem; max-width: 100%; max-height: 90vh; overflow: auto;",
      "  background: #fff; color: #111; border-radius: 12px; padding: 20px;",
      "  box-shadow: 0 20px 60px rgba(0,0,0,.35); font: 14px/1.5 system-ui, sans-serif; }",
      ".i18nf-panel > * + * { margin-top: 14px; }",
      ".i18nf-title { font-weight: 700; font-size: 15px; margin: 0; }",
      ".i18nf-key { display: block; margin-top: 2px; font-size: 12px; color: #666;",
      "  word-break: break-all; font-family: ui-monospace, monospace; }",
      ".i18nf-field { display: block; }",
      ".i18nf-label { display: block; margin-bottom: 4px; font-size: 12px; color: #666; }",
      ".i18nf-readonly { margin: 0; padding: 8px 10px; background: #f4f4f5; border-radius: 8px; }",
      ".i18nf-input { display: block; width: 100%; box-sizing: border-box; padding: 8px 10px;",
      "  border: 1px solid #d4d4d8; border-radius: 8px; font: inherit; }",
      ".i18nf-prior { padding: 10px 12px; background: #f4f4f5; border-radius: 8px; font-size: 13px; }",
      ".i18nf-prior-title { margin: 0 0 4px; font-weight: 600; color: #555; }",
      ".i18nf-prior-list { margin: 0; padding-left: 18px; }",
      ".i18nf-error { margin: 0; color: #dc2626; font-size: 13px; }",
      ".i18nf-actions { display: flex; justify-content: flex-end; gap: 8px; }",
      ".i18nf-btn { padding: 8px 14px; border-radius: 8px; border: 1px solid transparent;",
      "  font: inherit; cursor: pointer; }",
      ".i18nf-btn-ghost { background: transparent; color: #111; }",
      ".i18nf-btn-primary { background: #2563eb; color: #fff; }",
      ".i18nf-btn[disabled] { opacity: .6; cursor: default; }",
    ].join("\n");
    document.head.appendChild(style);
  }
})();
