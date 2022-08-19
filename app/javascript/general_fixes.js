import { onLoad } from './util';

setTimeout(() => {
  /* This is a patch to remove duplicated bootstrap-select dropdown selections.
   * It would be better to prevent these from being created.
   * This is added to onLoad() from a setTimeout, so it ends up being called
   * after other functions. Putting the operation within a setTimeout that's
   * called on each load results in the duplicate being visible briefly.
   */
  onLoad(() => {
    $('.dropdown.bootstrap-select > .dropdown.bootstrap-select').each(function () {
      const useSelect = $(this);
      useSelect.parent().replaceWith(useSelect);
    });
  });
}, 100);
