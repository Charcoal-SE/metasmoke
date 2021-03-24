function disable(link) {
  link.tabIndex = -1;
  link.setAttribute('data-disabled', 'disabled');
}

function enable(link) {
  link.tabIndex = 0;
  link.removeAttribute('data-disabled');
}

const feedbackButtonClickHandler = () => {
  // If one of the feedback buttons are clicked, disable **ALL**
  // those buttons (which are actually <a> elements).
  document.querySelectorAll('.feedback-button').forEach(disable);
  window.setTimeout(() => {
    document.querySelectorAll('.feedback-button').forEach(enable);
  }, 2000);
};

const onLoadHandler = () => {
  document.querySelectorAll('.feedback-button').forEach(e => {
    e.addEventListener('click', feedbackButtonClickHandler);
  });
};

const onBeforeCacheHandler = () => {
  document.querySelectorAll('.feedback-button').forEach(e => {
    e.removeEventListener('click', feedbackButtonClickHandler);
    enable(e);
  });
  document.removeEventListener('turbolinks:load', onLoadHandler);
  document.removeEventListener('turbolinks:before-cache', onBeforeCacheHandler);
};

document.addEventListener('turbolinks:load', onLoadHandler);
document.addEventListener('turbolinks:before-cache', onBeforeCacheHandler);
