import { onLoad } from './util';

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

onLoad(() => {
  document.querySelectorAll('.feedback-button').forEach(e => {
    e.addEventListener('click', feedbackButtonClickHandler);
  });
});

document.addEventListener('turbolinks:before-cache', () => {
  document.querySelectorAll('.feedback-button').forEach(e => {
    e.removeEventListener('click', feedbackButtonClickHandler);
    enable(e);
  });
});
