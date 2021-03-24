const clickHandler = () => {
  // If one of the feedback buttons are clicked, disable **ALL**
  // those buttons (which are actually <a> elements).
  document.querySelectorAll('.feedback-button').forEach(e => {
    e.tabIndex = -1;
    e.setAttribute('data-disabled', 'disabled');
  });
};

const onLoadHandler = () => {
  document.querySelectorAll('.feedback-button').forEach(e => {
    e.addEventListener('click', clickHandler);
  });
};

const onBeforeCacheHandler = () => {
  document.querySelectorAll('.feedback-button').forEach(e => {
    e.removeEventListener('click', clickHandler);
    e.tabIndex = 0;
    e.removeAttribute('data-disabled');
  });
  document.removeEventListener('turbolinks:load', onLoadHandler);
  document.removeEventListener('turbolinks:before-cache', onBeforeCacheHandler);
};

document.addEventListener('turbolinks:load', onLoadHandler);
document.addEventListener('turbolinks:before-cache', onBeforeCacheHandler);
