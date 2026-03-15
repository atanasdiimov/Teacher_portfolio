document.documentElement.classList.add("app-ready");

function forEachElements(elements, callback) {
  Array.prototype.forEach.call(elements, callback);
}

function removeElement(element) {
  if (!element || !element.parentNode) {
    return;
  }

  element.parentNode.removeChild(element);
}

function getNow() {
  if (window.performance && typeof window.performance.now === "function") {
    return window.performance.now();
  }

  return Date.now();
}

const siteLoader = document.querySelector("[data-site-loader]");

if (siteLoader) {
  const mediaQuery = typeof window.matchMedia === "function"
    ? window.matchMedia("(prefers-reduced-motion: reduce)")
    : null;
  const prefersReducedMotion = !!(mediaQuery && mediaQuery.matches);
  const minimumVisibleMs = prefersReducedMotion ? 0 : 900;
  const removeDelayMs = prefersReducedMotion ? 0 : 720;
  const loadStartedAt = getNow();
  let loaderHidden = false;

  function hideSiteLoader() {
    if (loaderHidden) {
      return;
    }

    loaderHidden = true;

    if (document.body) {
      document.body.classList.remove("is-loading");
    }

    siteLoader.classList.add("is-hidden");
    siteLoader.setAttribute("aria-hidden", "true");

    window.setTimeout(function () {
      removeElement(siteLoader);
    }, removeDelayMs);
  }

  function finishWhenReady() {
    const elapsed = getNow() - loadStartedAt;
    const remaining = Math.max(0, minimumVisibleMs - elapsed);
    window.setTimeout(hideSiteLoader, remaining);
  }

  function onWindowLoad() {
    finishWhenReady();
    window.removeEventListener("load", onWindowLoad);
  }

  function onPageShow() {
    finishWhenReady();
    window.removeEventListener("pageshow", onPageShow);
  }

  if (document.readyState === "complete") {
    finishWhenReady();
  } else {
    window.addEventListener("load", onWindowLoad);
  }

  window.addEventListener("pageshow", onPageShow);
  window.setTimeout(hideSiteLoader, 4000);
}

const currentPage = document.body ? document.body.dataset.page : "";
const nav = document.querySelector("[data-nav]");
const navToggle = document.querySelector("[data-nav-toggle]");

if (nav && currentPage) {
  forEachElements(nav.querySelectorAll("a"), function (link) {
    if (link.dataset.page === currentPage) {
      link.classList.add("is-active");
      link.setAttribute("aria-current", "page");
    }
  });
}

if (nav && navToggle) {
  navToggle.addEventListener("click", function () {
    const expanded = navToggle.getAttribute("aria-expanded") === "true";
    navToggle.setAttribute("aria-expanded", String(!expanded));

    if (expanded) {
      nav.classList.remove("is-open");
    } else {
      nav.classList.add("is-open");
    }
  });

  forEachElements(nav.querySelectorAll("a"), function (link) {
    link.addEventListener("click", function () {
      nav.classList.remove("is-open");
      navToggle.setAttribute("aria-expanded", "false");
    });
  });
}

const revealElements = document.querySelectorAll(".reveal");

if (revealElements.length) {
  if ("IntersectionObserver" in window) {
    const observer = new IntersectionObserver(
      function (entries) {
        forEachElements(entries, function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-visible");
            observer.unobserve(entry.target);
          }
        });
      },
      {
        threshold: 0.12,
      }
    );

    forEachElements(revealElements, function (element) {
      observer.observe(element);
    });
  } else {
    forEachElements(revealElements, function (element) {
      element.classList.add("is-visible");
    });
  }
}

forEachElements(document.querySelectorAll("[data-portrait]"), function (image) {
  const shell = image.closest("[data-portrait-shell]");

  if (!shell) {
    return;
  }

  function showFallback() {
    shell.classList.add("is-fallback");
  }

  function showImage() {
    shell.classList.remove("is-fallback");
  }

  image.addEventListener("load", function () {
    if (image.naturalWidth > 0) {
      showImage();
    } else {
      showFallback();
    }
  });

  image.addEventListener("error", showFallback);

  if (image.complete && image.naturalWidth > 0) {
    showImage();
  } else {
    showFallback();
  }
});

function formatExperience(startDate, now) {
  let years = now.getFullYear() - startDate.getFullYear();
  let months = now.getMonth() - startDate.getMonth();

  if (now.getDate() < startDate.getDate()) {
    months -= 1;
  }

  if (months < 0) {
    years -= 1;
    months += 12;
  }

  if (years < 0) {
    return "0 г. 0 мес.";
  }

  return years + " г. " + months + " мес.";
}

forEachElements(document.querySelectorAll("[data-experience-start]"), function (element) {
  const startValue = element.getAttribute("data-experience-start");
  const startDate = new Date(startValue + "T00:00:00");
  const now = new Date();

  if (Number.isNaN(startDate.getTime())) {
    return;
  }

  if (now < startDate) {
    element.textContent = "0 г. 0 мес.";
    return;
  }

  element.textContent = formatExperience(startDate, now);
});

const contactForm = document.querySelector("[data-contact-form]");

if (contactForm) {
  const helper = document.querySelector("[data-contact-helper]");
  const note = document.querySelector("[data-contact-note]");
  const isLocalFile = window.location.protocol === "file:";

  if (isLocalFile) {
    if (note) {
      note.textContent = "";
    }

    if (helper) {
      helper.textContent = "";
    }
  }

  contactForm.addEventListener("submit", function (event) {
    if (!isLocalFile) {
      return;
    }

    event.preventDefault();

    function getFieldValue(name, fallbackValue) {
      const field = contactForm.querySelector('[name="' + name + '"]');

      if (!field || typeof field.value !== "string") {
        return fallbackValue;
      }

      const value = field.value.trim();
      return value || fallbackValue;
    }

    const email = contactForm.getAttribute("data-contact-email") || "";
    const name = getFieldValue("name", "");
    const sender = getFieldValue("email", "");
    const subject = getFieldValue("subject", "Съобщение от портфолиото");
    const message = getFieldValue("message", "");
    const bodyLines = [
      "Име: " + name,
      "Имейл: " + sender,
      "",
      "Съобщение:",
      message,
    ];

    const mailtoUrl = "mailto:" + email + "?subject=" + encodeURIComponent(subject) + "&body=" + encodeURIComponent(bodyLines.join("\n"));
    window.location.href = mailtoUrl;
  });
}

forEachElements(document.querySelectorAll("[data-gallery-toggle]"), function (button) {
  button.addEventListener("click", function () {
    const controlsId = button.getAttribute("aria-controls");
    const panel = controlsId ? document.getElementById(controlsId) : null;

    if (!panel) {
      return;
    }

    const isExpanded = button.getAttribute("aria-expanded") === "true";
    button.setAttribute("aria-expanded", String(!isExpanded));
    panel.hidden = isExpanded;
  });
});
