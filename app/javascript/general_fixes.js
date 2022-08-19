import { onLoad } from './util';

onLoad(() => {
  // This is a patch to remove duplicated dropdown selections.
  // It would be better to prevent these from being created.
  $('.dropdown.bootstrap-select > .dropdown.bootstrap-select').each(function () {
    const useSelect = $(this);
    useSelect.parent().replaceWith(useSelect);
  });
});

